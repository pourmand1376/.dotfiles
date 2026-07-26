#!/usr/bin/env python3
"""macOS streaming network standpoint test.

Probes infrastructure (interface, gateway, DNS, raw IP routing) and a set of
domestic / global / filtered websites, in parallel, and reports PASS/FAIL.

Why this exists in Python rather than the old shell version: the probes must be
reliably time-bounded. curl resolves names through getaddrinfo() ->
mDNSResponder. When the local resolver is bad or was just changed, that daemon
wedges and serialises every lookup, so ~14 "parallel" probes collapse into a
long sequential stall (the old script's occasional ~60s runs). No curl timeout
flag fixes that, because the hang lives inside another process's queue.

The fix here: never let curl resolve. We resolve each host ourselves with `dig`
(which bypasses mDNSResponder) under a hard SIGKILL cap, then hand curl the IP
via `--resolve`. A wedged system resolver can no longer stall a probe: it just
fails fast and that one site is reported as unresolved.
"""

import concurrent.futures as futures
import ipaddress
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from urllib.parse import urlparse

# --- Colors --------------------------------------------------------------
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
RESET = "\033[0m"

# Soft timeout handed to each tool; HARDCAP is the wall-clock kill we enforce
# ourselves (subprocess sends SIGKILL on overrun — uncatchable, unlike the old
# perl/alarm hardcap).
TIMEOUT = 2
HARDCAP = 3

AIRPORT = (
    "/System/Library/PrivateFrameworks/Apple80211.framework"
    "/Versions/Current/Resources/airport"
)

# Hosts shown explicitly in the DNS Resolution section.
DNS_HOSTS = ["digikala.com", "motamem.org", "www.google.com", "soft98.ir"]


def run(cmd, timeout=HARDCAP):
    """Run a command with a hard wall-clock cap.

    Returns (returncode, stdout). On overrun the child is SIGKILLed and we
    return code 124; a missing binary returns 127.
    """
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout
    except subprocess.TimeoutExpired:
        return 124, ""
    except (FileNotFoundError, OSError):
        return 127, ""


def is_ip(s):
    try:
        ipaddress.ip_address(s)
        return True
    except ValueError:
        return False


def print_status(name, ok, detail):
    tag = f"{GREEN}[PASS]{RESET}" if ok else f"{RED}[FAIL]{RESET}"
    print(f"  {tag} {name:<35} - {detail}")


def timed(fn, *args):
    """Run an infra check and append its wall-clock time to the detail."""
    start = time.monotonic()
    name, ok, detail = fn(*args)
    ms = int((time.monotonic() - start) * 1000)
    return name, ok, f"{detail} — {ms} ms"


# --- System facts --------------------------------------------------------

def active_interface():
    _, out = run(["route", "get", "default"])
    m = re.search(r"interface:\s*(\S+)", out)
    return m.group(1) if m else ""


def default_gateway():
    _, out = run(["route", "-n", "get", "default"])
    m = re.search(r"gateway:\s*(\S+)", out)
    return m.group(1) if m else ""


def dns_servers():
    _, out = run(["scutil", "--dns"])
    seen = []
    for s in re.findall(r"nameserver\[\d+\]\s*:\s*(\S+)", out):
        if s not in seen:
            seen.append(s)
    return seen


def local_ip(iface):
    if not iface:
        return ""
    _, out = run(["ipconfig", "getifaddr", iface])
    return out.strip()


def wifi_ssid(iface):
    if not iface:
        return ""
    _, out = run(["ipconfig", "getsummary", iface])
    m = re.search(r"\bSSID\s*:\s*(.+)", out)
    if m:
        return m.group(1).strip()
    rc, out = run([AIRPORT, "-I"])
    m = re.search(r"^\s*SSID:\s*(.+)$", out, re.M)
    return m.group(1).strip() if m else ""


def system_proxy():
    """Return a curl proxy URL for the active macOS system proxy, or ''."""
    _, out = run(["scutil", "--proxy"])

    def val(key):
        m = re.search(rf"\b{key}\s*:\s*(\S+)", out)
        return m.group(1) if m else ""

    if val("SOCKSEnable") == "1":
        host, port = val("SOCKSProxy"), val("SOCKSPort")
        if host and port:
            return f"socks5h://{host}:{port}"
    # Most macOS HTTPS/HTTP proxy entries describe an HTTP CONNECT proxy.
    for prefix in ("HTTPS", "HTTP"):
        if val(f"{prefix}Enable") == "1":
            host, port = val(f"{prefix}Proxy"), val(f"{prefix}Port")
            if host and port:
                return f"http://{host}:{port}"
    return ""


# --- DNS resolution (bypasses mDNSResponder) -----------------------------

def resolve(host):
    """Resolve a hostname to an IP via dig, hard-capped. None on failure.

    dig reads /etc/resolv.conf and queries the server directly over UDP/53,
    so it never touches mDNSResponder and cannot wedge the way getaddrinfo can.
    """
    _, out = run(
        ["dig", "+short", "+time=2", "+tries=1", "A", host]
    )
    for line in out.splitlines():
        line = line.strip()
        if is_ip(line):
            return line
    return None


def resolve_timed(host):
    """Resolve a host and return (ip_or_None, elapsed_ms)."""
    start = time.monotonic()
    ip = resolve(host)
    return ip, int((time.monotonic() - start) * 1000)


# --- Site probes ---------------------------------------------------------

@dataclass
class Probe:
    label: str
    url: str
    use_proxy: bool
    ip: str = None  # pre-resolved IP for direct (non-proxy) probes


def check_site(probe, internet_ok, proxy):
    """Return (label, ok, detail) for a single website probe."""
    if not internet_ok:
        return probe.label, False, "Skipped — no internet"

    host = urlparse(probe.url).hostname
    args = [
        "curl", "--silent", "--show-error", "--head",
        "--output", "/dev/null",
        "--write-out", "%{http_code}|%{time_total}",
        "--connect-timeout", str(TIMEOUT),
        "--max-time", str(TIMEOUT),
    ]

    if probe.use_proxy and proxy:
        # Proxy resolves the name itself, so redirects are safe to follow.
        args += ["--proxy", proxy, "--location"]
    else:
        # Direct route: pin the IP so curl never calls getaddrinfo. We do NOT
        # follow redirects here — a cross-host redirect would trigger a fresh
        # getaddrinfo and reopen the wedge. A 3xx still counts as reachable.
        args += ["--noproxy", "*"]
        if not probe.ip:
            return probe.label, False, "Local DNS could not resolve host — skipped"
        args += ["--resolve", f"{host}:443:{probe.ip}"]

    args.append(probe.url)
    rc, out = run(args)
    code, _, tt = out.partition("|")
    ms = int(float(tt) * 1000) if tt else 0

    if rc == 124:
        return probe.label, False, f"Timed out after {ms} ms"
    if rc != 0:
        return probe.label, False, f"Connection failed (curl {rc}) — {ms} ms"
    if re.match(r"^[23]\d\d$", code):
        return probe.label, True, f"HTTP {code} — {ms} ms"
    if not code or code == "000":
        return probe.label, False, f"Blocked or unreachable — {ms} ms"
    return probe.label, False, f"HTTP {code} (blocked/error) — {ms} ms"


# --- Infrastructure probes ----------------------------------------------

def check_interface(iface, ip):
    if not iface:
        return "Local Network Interface", False, "No active network interface"
    ssid = wifi_ssid(iface)
    detail = f"Active on {iface}"
    if ip:
        detail += f" ({ip})"
    detail += f" — Wi-Fi SSID: {ssid}" if ssid else " — SSID unavailable or wired"
    return "Local Network Interface", True, detail


def check_ping(target):
    rc, _ = run(["ping", "-c", "1", "-t", str(TIMEOUT), target])
    return rc == 0


def check_gateway(gw):
    if not gw:
        return "Ping Default Gateway", False, "No gateway IP found"
    ok = check_ping(gw)
    msg = "Router reachable" if ok else "Router unreachable or timed out"
    return f"Ping Default Gateway ({gw})", ok, msg


def check_raw_ip():
    ok = check_ping("1.1.1.1")
    msg = "Global IP routing up" if ok else "Global IP unreachable or timed out"
    return "Ping Raw Global IP (1.1.1.1)", ok, msg


# --- Orchestration -------------------------------------------------------

def parse_mode():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg in ("direct", "-d"):
        return "DIRECT"
    if arg in ("proxy", "-p"):
        return "PROXY"
    print(f"{CYAN}Select Network Check Mode:{RESET}")
    print(f"  {GREEN}[1]{RESET} Proxy Mode (use macOS system proxy for global/filtered sites)")
    print(f"  {YELLOW}[2]{RESET} Direct Mode (bypass proxies and test the raw ISP connection)")
    try:
        choice = input("Enter choice (1 or 2): ").strip()
    except EOFError:
        choice = "1"
    return "DIRECT" if choice == "2" else "PROXY"


def build_probes(mode):
    site_proxy = mode == "PROXY"
    domestic = [
        Probe("digikala.com", "https://digikala.com", False),
        Probe("iranketab.ir", "https://www.iranketab.ir", False),
        Probe("soft98.ir", "https://soft98.ir", False),
        Probe("varzesh3.com", "https://www.varzesh3.com", False),
    ]
    global_sites = [
        Probe("Wikipedia", "https://www.wikipedia.org", site_proxy),
        Probe("Substack", "https://substack.com", site_proxy),
        Probe("Apple", "https://www.apple.com", site_proxy),
        Probe("Google", "https://www.google.com", site_proxy),
        Probe("Motamem (motamem.org)", "https://motamem.org", site_proxy),
    ]
    filtered = [
        Probe("YouTube", "https://www.youtube.com", site_proxy),
        Probe("Telegram", "https://t.me", site_proxy),
        Probe("Instagram", "https://www.instagram.com", site_proxy),
        Probe("Twitter / X", "https://x.com", site_proxy),
        Probe("Facebook", "https://www.facebook.com", site_proxy),
    ]
    return domestic, global_sites, filtered


def main():
    mode = parse_mode()
    proxy = system_proxy() if mode == "PROXY" else ""

    iface = active_interface()
    gw = default_gateway()
    servers = dns_servers()
    ip = local_ip(iface)

    # --- Header + the facts the user asked to see up front ---------------
    print(f"\n{YELLOW}==============================================={RESET}")
    print(f"{YELLOW}   macOS Streaming Network Standpoint Test     {RESET}")
    print(f"   Running Mode:  {CYAN}{mode}{RESET}")
    print(f"   Local IP:      {CYAN}{ip or 'unknown'}{RESET}")
    print(f"   DNS resolvers: {CYAN}{', '.join(servers) or 'none'}{RESET}")
    if mode == "PROXY":
        if proxy:
            print(f"   System Proxy:  {CYAN}{proxy}{RESET}")
        else:
            print(f"   System Proxy:  {RED}Not detected; using direct route{RESET}")
    print(f"   Per-probe timeout: {CYAN}{TIMEOUT} seconds{RESET}")
    print(f"{YELLOW}==============================================={RESET}")
    print(f"{CYAN}[*] Dispatching parallel probes...{RESET}\n")

    start = time.monotonic()
    domestic, global_sites, filtered = build_probes(mode)
    all_probes = domestic + global_sites + filtered

    with futures.ThreadPoolExecutor(max_workers=len(all_probes) + 4) as ex:
        # Infrastructure, in parallel; printed in a fixed order.
        f_if = ex.submit(timed, check_interface, iface, ip)
        f_gw = ex.submit(timed, check_gateway, gw)
        f_raw = ex.submit(timed, check_raw_ip)

        print(f"{YELLOW}[+] Infrastructure Standpoints:{RESET}")
        for f in (f_if, f_gw, f_raw):
            print_status(*f.result())
        internet_ok = f_raw.result()[1]

        # --- Part 2: DNS resolution -------------------------------------
        # Resolve the reported hosts plus every direct probe host (so curl
        # can be handed an IP and never call getaddrinfo). Bounded via dig,
        # which bypasses the mDNSResponder wedge.
        direct_hosts = {
            urlparse(p.url).hostname
            for p in all_probes if not (p.use_proxy and proxy)
        }
        resolved = dict(zip(
            direct_hosts | set(DNS_HOSTS),
            ex.map(resolve_timed, direct_hosts | set(DNS_HOSTS)),
        ))
        for p in all_probes:
            if not (p.use_proxy and proxy):
                p.ip = resolved.get(urlparse(p.url).hostname, (None, 0))[0]

        print(f"\n{YELLOW}[+] DNS Resolution:{RESET}")
        for host in DNS_HOSTS:
            host_ip, ms = resolved.get(host, (None, 0))
            if host_ip:
                print_status(host, True, f"Resolved to {host_ip} — {ms} ms")
            else:
                print_status(host, False, f"Resolution failed or timed out — {ms} ms")

        # Fire all site probes at once; collect by label.
        futs = {
            ex.submit(check_site, p, internet_ok, proxy): p.label
            for p in all_probes
        }
        results = {}
        for f in futures.as_completed(futs):
            label, ok, detail = f.result()
            results[label] = (ok, detail)

    def show(group):
        for p in group:
            ok, detail = results[p.label]
            print_status(p.label, ok, detail)

    print(f"\n{CYAN}[*] Domestic Websites (DIRECT Route):{RESET}")
    show(domestic)
    print(f"\n{CYAN}[*] Global Web Standpoints ({mode} Route):{RESET}")
    show(global_sites)
    print(f"\n{CYAN}[*] Filtered Websites ({mode} Route):{RESET}")
    show(filtered)

    total = time.monotonic() - start
    print(f"\n{YELLOW}==============================================={RESET}")
    print(f"   Total probe time: {CYAN}{total * 1000:.0f} ms ({total:.2f} s){RESET}")
    print(f"{YELLOW}==============================================={RESET}\n")


if __name__ == "__main__":
    main()
