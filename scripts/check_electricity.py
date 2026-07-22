#!/usr/bin/env python3
"""Fetch planned electricity blackouts (Barghe-Man / SAAPA) and add them to
macOS Calendar as events, deduplicated across runs.

Designed to be run from cron a couple of times each morning. Re-running is safe:
outages already turned into calendar events (tracked by their unique
tracking_code) are never added twice.

Config can be overridden via environment variables:
  ELEC_BILL_ID    the electricity bill id to query
  ELEC_TOKEN      bearer token for the API
  ELEC_CALENDAR   Calendar.app calendar name to add events to
  ELEC_ALARM_MIN  minutes-before alarm (0 disables)
  ELEC_DAYS_AHEAD how many days ahead to query
"""

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------
API_URL = "https://uiapi2.saapa.ir/api/ebills/PlannedBlackoutsReport"
# Secrets are NOT hardcoded — they must come from the environment (see ~/.localrc).
BILL_ID = os.environ.get("ELEC_BILL_ID", "")
# this is your Authorization token. get it from website https://bargheman.com/profile/blackout/my-blackouts Network tab PlannedBlackoutsReport request header
TOKEN = os.environ.get("ELEC_TOKEN", "")
CALENDAR = os.environ.get("ELEC_CALENDAR", "Main Calendar")
ALARM_MIN = int(os.environ.get("ELEC_ALARM_MIN", "30"))
DAYS_AHEAD = int(os.environ.get("ELEC_DAYS_AHEAD", "7"))
REQUEST_TIMEOUT = 15
RETRIES = 3

STATE_DIR = Path(
    os.environ.get("ELEC_STATE_DIR", Path.home() / ".local/state/electricity")
)
SEEN_FILE = STATE_DIR / "seen.json"
LOG_FILE = STATE_DIR / "electricity.log"


# --------------------------------------------------------------------------
# Jalali <-> Gregorian conversion (pure, no external deps)
# --------------------------------------------------------------------------
def jalali_to_gregorian(jy, jm, jd):
    jy += 1595
    days = -355668 + (365 * jy) + ((jy // 33) * 8) + (((jy % 33) + 3) // 4) + jd
    if jm < 7:
        days += (jm - 1) * 31
    else:
        days += ((jm - 7) * 30) + 186
    gy = 400 * (days // 146097)
    days %= 146097
    if days > 36524:
        days -= 1
        gy += 100 * (days // 36524)
        days %= 36524
        if days >= 365:
            days += 1
    gy += 4 * (days // 1461)
    days %= 1461
    if days > 365:
        gy += (days - 1) // 365
        days = (days - 1) % 365
    gd = days + 1
    leap = (gy % 4 == 0 and gy % 100 != 0) or (gy % 400 == 0)
    sal = [0, 31, 29 if leap else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    gm = 0
    while gm < 13 and gd > sal[gm]:
        gd -= sal[gm]
        gm += 1
    return gy, gm, gd


def gregorian_to_jalali(gy, gm, gd):
    g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    if gy > 1600:
        jy = 979
        gy -= 1600
    else:
        jy = 0
        gy -= 621
    gy2 = gy + 1 if gm > 2 else gy
    days = (
        (365 * gy)
        + ((gy2 + 3) // 4)
        - ((gy2 + 99) // 100)
        + ((gy2 + 399) // 400)
        - 80
        + gd
        + g_d_m[gm - 1]
    )
    jy += 33 * (days // 12053)
    days %= 12053
    jy += 4 * (days // 1461)
    days %= 1461
    if days > 365:
        jy += (days - 1) // 365
        days = (days - 1) % 365
    if days < 186:
        jm = 1 + days // 31
        jd = 1 + (days % 31)
    else:
        jm = 7 + (days - 186) // 30
        jd = 1 + ((days - 186) % 30)
    return jy, jm, jd


def jalali_str(dt):
    jy, jm, jd = gregorian_to_jalali(dt.year, dt.month, dt.day)
    return f"{jy:04d}/{jm:02d}/{jd:02d}"


# --------------------------------------------------------------------------
# Small utilities
# --------------------------------------------------------------------------
def log(msg):
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{stamp}] {msg}"
    print(line)
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as fh:
            fh.write(line + "\n")
    except OSError:
        pass


def load_seen():
    try:
        with open(SEEN_FILE, encoding="utf-8") as fh:
            return set(json.load(fh))
    except (OSError, ValueError):
        return set()


def save_seen(seen):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = SEEN_FILE.with_suffix(".tmp")
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(sorted(seen), fh)
    tmp.replace(SEEN_FILE)


# --------------------------------------------------------------------------
# API
# --------------------------------------------------------------------------
def fetch_blackouts(from_date, to_date):
    payload = json.dumps(
        {"bill_id": BILL_ID, "from_date": from_date, "to_date": to_date}
    ).encode("utf-8")
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Referer": "https://bargheman.com/",
        "User-Agent": "Mozilla/5.0",
        "Accept": "application/json, text/plain, */*",
        "Content-Type": "application/json; charset=UTF-8",
    }
    last_err = None
    for attempt in range(1, RETRIES + 1):
        req = urllib.request.Request(
            API_URL, data=payload, headers=headers, method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
                body = resp.read().decode("utf-8")
            obj = json.loads(body)
            if obj.get("status") != 200:
                raise ValueError(
                    f"API status {obj.get('status')}: {obj.get('message')}"
                )
            return obj.get("data") or []
        except (urllib.error.URLError, ValueError, TimeoutError) as exc:
            last_err = exc
            log(f"fetch attempt {attempt}/{RETRIES} failed: {exc}")
    raise SystemExit(f"Could not fetch blackouts after {RETRIES} attempts: {last_err}")


# --------------------------------------------------------------------------
# Parsing an outage into concrete datetimes
# --------------------------------------------------------------------------
def parse_outage(item):
    """Return (start_dt, end_dt, summary, description, key) or None if unusable."""
    date_j = (item.get("outage_date") or "").strip()
    start_t = (item.get("outage_start_time") or item.get("outage_time") or "").strip()
    stop_t = (item.get("outage_stop_time") or "").strip()
    if not date_j or not start_t:
        return None

    try:
        jy, jm, jd = (int(x) for x in date_j.split("/"))
        gy, gm, gd = jalali_to_gregorian(jy, jm, jd)
        sh, sm = (int(x) for x in start_t.split(":")[:2])
        start_dt = datetime(gy, gm, gd, sh, sm)
    except (ValueError, TypeError):
        return None

    try:
        eh, em = (int(x) for x in stop_t.split(":")[:2])
        end_dt = datetime(gy, gm, gd, eh, em)
        if end_dt <= start_dt:  # spans midnight
            end_dt += timedelta(days=1)
    except (ValueError, TypeError):
        end_dt = start_dt + timedelta(hours=2)  # sensible default

    reason = (item.get("reason_outage") or "").strip()
    address = (item.get("outage_address") or item.get("address") or "").strip()
    tracking = item.get("tracking_code") or item.get("outage_number")
    key = str(tracking) if tracking else f"{date_j}_{start_t}_{stop_t}"

    summary = "⚡️ قطعی برق"  # ⚡️ قطعی برق
    if reason:
        summary += f" — {reason}"
    desc_lines = [
        f"تاریخ: {date_j}  ({start_t} - {stop_t or '?'})",
    ]
    if address:
        desc_lines.append(f"محدوده: {address}")
    if reason:
        desc_lines.append(f"دلیل: {reason}")
    desc_lines.append(f"tracking_code: {key}")
    description = "\n".join(desc_lines)
    return start_dt, end_dt, summary, description, key


# --------------------------------------------------------------------------
# Calendar (AppleScript)
# --------------------------------------------------------------------------
ADD_EVENT_SCRIPT = r"""
on run argv
    set calName to item 1 of argv
    set summ to item 2 of argv
    set theDesc to item 3 of argv
    set sy to (item 4 of argv) as integer
    set smo to (item 5 of argv) as integer
    set sd to (item 6 of argv) as integer
    set sh to (item 7 of argv) as integer
    set smi to (item 8 of argv) as integer
    set ey to (item 9 of argv) as integer
    set emo to (item 10 of argv) as integer
    set ed to (item 11 of argv) as integer
    set eh to (item 12 of argv) as integer
    set emi to (item 13 of argv) as integer
    set alarmMin to (item 14 of argv) as integer

    set startDate to current date
    set day of startDate to 1
    set year of startDate to sy
    set month of startDate to smo
    set day of startDate to sd
    set hours of startDate to sh
    set minutes of startDate to smi
    set seconds of startDate to 0

    set endDate to current date
    set day of endDate to 1
    set year of endDate to ey
    set month of endDate to emo
    set day of endDate to ed
    set hours of endDate to eh
    set minutes of endDate to emi
    set seconds of endDate to 0

    tell application "Calendar"
        tell calendar calName
            set newEvent to make new event with properties {summary:summ, start date:startDate, end date:endDate, description:theDesc}
            tell newEvent
                if alarmMin > 0 then
                    make new display alarm at end with properties {trigger interval:-alarmMin}
                end if
            end tell
        end tell
    end tell
end run
"""


def add_event(start_dt, end_dt, summary, description):
    args = [
        "osascript",
        "-",
        CALENDAR,
        summary,
        description,
        str(start_dt.year),
        str(start_dt.month),
        str(start_dt.day),
        str(start_dt.hour),
        str(start_dt.minute),
        str(end_dt.year),
        str(end_dt.month),
        str(end_dt.day),
        str(end_dt.hour),
        str(end_dt.minute),
        str(ALARM_MIN),
    ]
    proc = subprocess.run(args, input=ADD_EVENT_SCRIPT, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "osascript failed")


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
def main():
    dry_run = "--dry-run" in sys.argv or os.environ.get("ELEC_DRY_RUN") == "1"

    missing = [
        n for n, v in (("ELEC_BILL_ID", BILL_ID), ("ELEC_TOKEN", TOKEN)) if not v
    ]
    if missing:
        raise SystemExit(
            f"Missing required env var(s): {', '.join(missing)}. "
            "Set them in ~/.localrc (see the electricity block there)."
        )

    today = datetime.now()
    from_date = jalali_str(today)
    to_date = jalali_str(today + timedelta(days=DAYS_AHEAD))
    log(f"Querying blackouts for bill {BILL_ID}: {from_date} .. {to_date}")

    data = fetch_blackouts(from_date, to_date)
    log(f"API returned {len(data)} outage record(s)")

    seen = load_seen()
    added = 0
    skipped = 0
    for item in data:
        parsed = parse_outage(item)
        if not parsed:
            log(f"  skipping unparseable record: {item!r}")
            continue
        start_dt, end_dt, summary, description, key = parsed
        when = f"{start_dt:%Y-%m-%d %H:%M}-{end_dt:%H:%M}"
        if key in seen:
            skipped += 1
            log(f"  already added ({key}) {when}")
            continue
        if dry_run:
            log(f"  [dry-run] would add {when}  {summary}")
            continue
        try:
            add_event(start_dt, end_dt, summary, description)
        except RuntimeError as exc:
            log(f"  FAILED to add ({key}) {when}: {exc}")
            continue
        seen.add(key)
        added += 1
        log(f"  added → {when}  {summary}")

    if not dry_run:
        save_seen(seen)
    log(f"Done. added={added} skipped(existing)={skipped} total={len(data)}")


if __name__ == "__main__":
    main()
