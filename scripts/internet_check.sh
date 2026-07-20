#!/usr/bin/env bash

# Run this once beforehand to make the Wi-Fi SSID visible:
# sudo ipconfig setverbose 1

# Each network probe is limited to approximately two seconds.
TIMEOUT_SECONDS=2
TIMEOUT_MS=2000

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
RESET=$'\033[0m'

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

print_status() {
  local step_name="$1"
  local status="$2"
  local details="$3"

  if [ "$status" -eq 0 ]; then
    printf "  ${GREEN}[PASS]${RESET} %-35s - %s\n" \
      "$step_name" "$details"
  else
    printf "  ${RED}[FAIL]${RESET} %-35s - %s\n" \
      "$step_name" "$details"
  fi
}

# macOS date does not reliably support `date +%s%3N`.
now_ms() {
  perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000'
}

get_system_proxy() {
  local proxy_info
  local proxy_host
  local proxy_port
  local enabled

  proxy_info=$(scutil --proxy)

  enabled=$(awk '/SOCKSEnable/ {print $3; exit}' <<<"$proxy_info")
  if [ "$enabled" = "1" ]; then
    proxy_host=$(awk '/SOCKSProxy/ {print $3; exit}' <<<"$proxy_info")
    proxy_port=$(awk '/SOCKSPort/ {print $3; exit}' <<<"$proxy_info")

    if [ -n "$proxy_host" ] && [ -n "$proxy_port" ]; then
      printf 'socks5h://%s:%s\n' "$proxy_host" "$proxy_port"
      return 0
    fi
  fi

  enabled=$(awk '/HTTPSEnable/ {print $3; exit}' <<<"$proxy_info")
  if [ "$enabled" = "1" ]; then
    proxy_host=$(awk '/HTTPSProxy/ {print $3; exit}' <<<"$proxy_info")
    proxy_port=$(awk '/HTTPSPort/ {print $3; exit}' <<<"$proxy_info")

    if [ -n "$proxy_host" ] && [ -n "$proxy_port" ]; then
      # Most macOS HTTPS proxy entries describe an HTTP CONNECT proxy.
      printf 'http://%s:%s\n' "$proxy_host" "$proxy_port"
      return 0
    fi
  fi

  enabled=$(awk '/HTTPEnable/ {print $3; exit}' <<<"$proxy_info")
  if [ "$enabled" = "1" ]; then
    proxy_host=$(awk '/HTTPProxy/ {print $3; exit}' <<<"$proxy_info")
    proxy_port=$(awk '/HTTPPort/ {print $3; exit}' <<<"$proxy_info")

    if [ -n "$proxy_host" ] && [ -n "$proxy_port" ]; then
      printf 'http://%s:%s\n' "$proxy_host" "$proxy_port"
      return 0
    fi
  fi

  printf '\n'
}

check_site_worker() {
  local url="$1"
  local filename="$2"
  local use_proxy="$3"

  local result
  local curl_exit
  local http_code
  local time_seconds
  local time_ms

  local curl_args=(
    --silent
    --show-error
    --location
    --head
    --output /dev/null
    --write-out "%{http_code}|%{time_total}"
    --connect-timeout "$TIMEOUT_SECONDS"
    --max-time "$TIMEOUT_SECONDS"
  )

  if [ "$use_proxy" = "true" ] && [ -n "$SYSTEM_PROXY" ]; then
    curl_args+=(--proxy "$SYSTEM_PROXY")
  else
    # Ensure direct probes do not inherit proxy environment variables.
    curl_args+=(--noproxy "*")
  fi

  result=$(curl "${curl_args[@]}" "$url" 2>/dev/null)
  curl_exit=$?

  http_code=${result%%|*}
  time_seconds=${result#*|}

  if [ "$result" = "$http_code" ]; then
    time_seconds="0"
  fi

  time_ms=$(
    awk -v seconds="${time_seconds:-0}" \
      'BEGIN { printf "%.0f", seconds * 1000 }'
  )

  if [ "$curl_exit" -eq 28 ]; then
    printf '1|Timed out after %s ms\n' "$time_ms" \
      >"$TMP_DIR/$filename"
  elif [ "$curl_exit" -ne 0 ]; then
    printf '1|Connection failed (curl %s) — %s ms\n' \
      "$curl_exit" "$time_ms" >"$TMP_DIR/$filename"
  elif [[ "$http_code" =~ ^[23][0-9][0-9]$ ]]; then
    printf '0|HTTP %s — %s ms\n' "$http_code" "$time_ms" \
      >"$TMP_DIR/$filename"
  elif [ -z "$http_code" ] || [ "$http_code" = "000" ]; then
    printf '1|Blocked or unreachable — %s ms\n' "$time_ms" \
      >"$TMP_DIR/$filename"
  else
    printf '1|HTTP %s (blocked/error) — %s ms\n' \
      "$http_code" "$time_ms" >"$TMP_DIR/$filename"
  fi
}

# Parse mode argument
SELECTED_MODE=""

case "${1:-}" in
direct | -d)
  SELECTED_MODE="DIRECT"
  ;;
proxy | -p)
  SELECTED_MODE="PROXY"
  ;;
esac

if [ -z "$SELECTED_MODE" ]; then
  printf "${CYAN}Select Network Check Mode:${RESET}\n"
  printf "  ${GREEN}[1]${RESET} Proxy Mode (use macOS system proxy for global/filtered sites)\n"
  printf "  ${YELLOW}[2]${RESET} Direct Mode (bypass proxies and test the raw ISP connection)\n"
  read -r -p "Enter choice (1 or 2): " choice

  if [ "$choice" = "2" ]; then
    SELECTED_MODE="DIRECT"
  else
    SELECTED_MODE="PROXY"
  fi
fi

SYSTEM_PROXY=""

if [ "$SELECTED_MODE" = "PROXY" ]; then
  SYSTEM_PROXY=$(get_system_proxy)
fi

printf "\n${YELLOW}===============================================${RESET}\n"
printf "${YELLOW}   macOS Streaming Network Standpoint Test     ${RESET}\n"
printf "   Running Mode: ${CYAN}%s${RESET}\n" "$SELECTED_MODE"

if [ "$SELECTED_MODE" = "PROXY" ]; then
  if [ -n "$SYSTEM_PROXY" ]; then
    printf "   System Proxy: ${CYAN}%s${RESET}\n" "$SYSTEM_PROXY"
  else
    printf "   System Proxy: ${RED}Not detected; using direct route${RESET}\n"
  fi
fi

printf "   Per-probe timeout: ${CYAN}%s seconds${RESET}\n" "$TIMEOUT_SECONDS"
printf "${YELLOW}===============================================${RESET}\n"
printf "${CYAN}[*] Dispatching parallel probes...${RESET}\n\n"

ACTIVE_IF=$(
  route get default 2>/dev/null |
    awk '/interface:/ {print $2; exit}'
)

GATEWAY=$(
  route -n get default 2>/dev/null |
    awk '/gateway:/ {print $2; exit}'
)

SYSTEM_DNS=$(
  scutil --dns 2>/dev/null |
    awk '/nameserver\[[0-9]+\]/ {print $3; exit}'
)

# -------------------------------------------------------------------
# Group 1: Infrastructure
# -------------------------------------------------------------------

(
  start_ms=$(now_ms)

  if [ -z "$ACTIVE_IF" ]; then
    status=1
    message="No active network interface"
  else
    WIFI_SSID=$(
      ipconfig getsummary "$ACTIVE_IF" 2>/dev/null |
        awk -F': ' '/SSID/ {print $2; exit}' |
        xargs
    )

    if [ -z "$WIFI_SSID" ]; then
      AIRPORT_COMMAND="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

      if [ -x "$AIRPORT_COMMAND" ]; then
        WIFI_SSID=$(
          "$AIRPORT_COMMAND" -I 2>/dev/null |
            awk -F': ' '/ SSID/ {print $2; exit}' |
            xargs
        )
      fi
    fi

    status=0

    if [ -n "$WIFI_SSID" ]; then
      message="Active on $ACTIVE_IF (Wi-Fi SSID: $WIFI_SSID)"
    else
      message="Active on $ACTIVE_IF (SSID unavailable or wired connection)"
    fi
  fi

  elapsed_ms=$(($(now_ms) - start_ms))
  printf '%s|%s — %s ms\n' "$status" "$message" "$elapsed_ms"
) >"$TMP_DIR/j_if" &
PID_IF=$!

(
  start_ms=$(now_ms)

  if [ -z "$GATEWAY" ]; then
    status=1
    message="No gateway IP found"
  elif ping -c 1 -W "$TIMEOUT_MS" "$GATEWAY" >/dev/null 2>&1; then
    status=0
    message="Router reachable"
  else
    status=1
    message="Router unreachable or timed out"
  fi

  elapsed_ms=$(($(now_ms) - start_ms))
  printf '%s|%s — %s ms\n' "$status" "$message" "$elapsed_ms"
) >"$TMP_DIR/j_gw" &
PID_GW=$!

(
  start_ms=$(now_ms)

  if [ -z "$SYSTEM_DNS" ]; then
    status=1
    message="No system DNS server found"
  else
    RESOLVED_IP=$(
      dig \
        +time="$TIMEOUT_SECONDS" \
        +tries=1 \
        +short \
        "@$SYSTEM_DNS" \
        digikala.com 2>/dev/null |
        tail -n 1
    )

    if [[ "$RESOLVED_IP" =~ ^[0-9a-fA-F:.]+$ ]]; then
      status=0
      message="Resolved digikala.com to $RESOLVED_IP"
    else
      status=1
      message="DNS lookup failed or timed out"
    fi
  fi

  elapsed_ms=$(($(now_ms) - start_ms))
  printf '%s|%s — %s ms\n' "$status" "$message" "$elapsed_ms"
) >"$TMP_DIR/j_ldns" &
PID_LDNS=$!

(
  start_ms=$(now_ms)

  if ping -c 1 -W "$TIMEOUT_MS" 1.1.1.1 >/dev/null 2>&1; then
    status=0
    message="Global IP routing up"
  else
    status=1
    message="Global IP unreachable or timed out"
  fi

  elapsed_ms=$(($(now_ms) - start_ms))
  printf '%s|%s — %s ms\n' "$status" "$message" "$elapsed_ms"
) >"$TMP_DIR/j_rawip" &
PID_RAWIP=$!

# -------------------------------------------------------------------
# Group 2: Domestic websites — always direct
# -------------------------------------------------------------------

check_site_worker \
  "https://digikala.com" \
  "w_digikala" \
  "false" &
PID_DIGI=$!

check_site_worker \
  "https://www.iranketab.ir" \
  "w_iranketab" \
  "false" &
PID_IRAN=$!

check_site_worker \
  "https://soft98.ir" \
  "w_soft98" \
  "false" &
PID_SOFT=$!

check_site_worker \
  "https://www.varzesh3.com" \
  "w_varzesh3" \
  "false" &
PID_VARZ=$!

# Global and filtered websites use the selected mode.
if [ "$SELECTED_MODE" = "PROXY" ]; then
  FLAG="true"
else
  FLAG="false"
fi

# -------------------------------------------------------------------
# Group 3: Global websites
# -------------------------------------------------------------------

check_site_worker \
  "https://www.wikipedia.org" \
  "w_wikipedia" \
  "$FLAG" &
PID_WIKI=$!

check_site_worker \
  "https://substack.com" \
  "w_substack" \
  "$FLAG" &
PID_SUB=$!

check_site_worker \
  "https://www.apple.com" \
  "w_apple" \
  "$FLAG" &
PID_APP=$!

check_site_worker \
  "https://www.google.com" \
  "w_google" \
  "$FLAG" &
PID_GOOG=$!

check_site_worker \
  "https://motamem.org" \
  "w_motamem" \
  "$FLAG" &
PID_MOT=$!

# -------------------------------------------------------------------
# Group 4: Filtered platforms
# -------------------------------------------------------------------

check_site_worker \
  "https://www.youtube.com" \
  "w_youtube" \
  "$FLAG" &
PID_YT=$!

check_site_worker \
  "https://t.me" \
  "w_telegram" \
  "$FLAG" &
PID_TG=$!

check_site_worker \
  "https://www.instagram.com" \
  "w_instagram" \
  "$FLAG" &
PID_IG=$!

check_site_worker \
  "https://x.com" \
  "w_twitter" \
  "$FLAG" &
PID_TW=$!

check_site_worker \
  "https://www.facebook.com" \
  "w_facebook" \
  "$FLAG" &
PID_FB=$!

# -------------------------------------------------------------------
# Stream results in display order
# -------------------------------------------------------------------

printf "${YELLOW}[+] Infrastructure Standpoints:${RESET}\n"

wait "$PID_IF"
IFS="|" read -r status msg <"$TMP_DIR/j_if"
print_status "Local Network Interface" "$status" "$msg"

wait "$PID_GW"
IFS="|" read -r status msg <"$TMP_DIR/j_gw"
print_status "Ping Default Gateway ($GATEWAY)" "$status" "$msg"

wait "$PID_LDNS"
IFS="|" read -r status msg <"$TMP_DIR/j_ldns"
print_status "Local DNS Query ($SYSTEM_DNS)" "$status" "$msg"

wait "$PID_RAWIP"
IFS="|" read -r status msg <"$TMP_DIR/j_rawip"
print_status "Ping Raw Global IP (1.1.1.1)" "$status" "$msg"

printf "\n${CYAN}[*] Domestic Websites (DIRECT Route):${RESET}\n"

wait "$PID_DIGI"
IFS="|" read -r status msg <"$TMP_DIR/w_digikala"
print_status "digikala.com" "$status" "$msg"

wait "$PID_IRAN"
IFS="|" read -r status msg <"$TMP_DIR/w_iranketab"
print_status "iranketab.ir" "$status" "$msg"

wait "$PID_SOFT"
IFS="|" read -r status msg <"$TMP_DIR/w_soft98"
print_status "soft98.ir" "$status" "$msg"

wait "$PID_VARZ"
IFS="|" read -r status msg <"$TMP_DIR/w_varzesh3"
print_status "varzesh3.com" "$status" "$msg"

printf "\n${CYAN}[*] Global Web Standpoints (%s Route):${RESET}\n" \
  "$SELECTED_MODE"

wait "$PID_WIKI"
IFS="|" read -r status msg <"$TMP_DIR/w_wikipedia"
print_status "Wikipedia" "$status" "$msg"

wait "$PID_SUB"
IFS="|" read -r status msg <"$TMP_DIR/w_substack"
print_status "Substack" "$status" "$msg"

wait "$PID_APP"
IFS="|" read -r status msg <"$TMP_DIR/w_apple"
print_status "Apple" "$status" "$msg"

wait "$PID_GOOG"
IFS="|" read -r status msg <"$TMP_DIR/w_google"
print_status "Google" "$status" "$msg"

wait "$PID_MOT"
IFS="|" read -r status msg <"$TMP_DIR/w_motamem"
print_status "Motamem (motamem.org)" "$status" "$msg"

printf "\n${CYAN}[*] Filtered Websites (%s Route):${RESET}\n" \
  "$SELECTED_MODE"

wait "$PID_YT"
IFS="|" read -r status msg <"$TMP_DIR/w_youtube"
print_status "YouTube" "$status" "$msg"

wait "$PID_TG"
IFS="|" read -r status msg <"$TMP_DIR/w_telegram"
print_status "Telegram" "$status" "$msg"

wait "$PID_IG"
IFS="|" read -r status msg <"$TMP_DIR/w_instagram"
print_status "Instagram" "$status" "$msg"

wait "$PID_TW"
IFS="|" read -r status msg <"$TMP_DIR/w_twitter"
print_status "Twitter / X" "$status" "$msg"

wait "$PID_FB"
IFS="|" read -r status msg <"$TMP_DIR/w_facebook"
print_status "Facebook" "$status" "$msg"

printf "\n${YELLOW}===============================================${RESET}\n\n"
