#!/usr/bin/env bash

# Color formatting (ANSI-C Quoting style)
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
    printf "  ${GREEN}[PASS]${RESET} %-35s - %s\n" "$step_name" "$details"
  else
    printf "  ${RED}[FAIL]${RESET} %-35s - %s\n" "$step_name" "$details"
  fi
}

get_system_proxy() {
  local proxy_info=$(scutil --proxy)
  local socks_enabled=$(echo "$proxy_info" | awk '/SOCKSEnable/ {print $3}')
  if [ "$socks_enabled" = "1" ]; then
    echo "socks5h://$(echo "$proxy_info" | awk '/SOCKSProxy/ {print $3}'):$(echo "$proxy_info" | awk '/SOCKSPort/ {print $3}')"
    return 0
  fi
  local https_enabled=$(echo "$proxy_info" | awk '/HTTPSEnable/ {print $3}')
  if [ "$https_enabled" = "1" ]; then
    echo "https://$(echo "$proxy_info" | awk '/HTTPSProxy/ {print $3}'):$(echo "$proxy_info" | awk '/HTTPSPort/ {print $3}')"
    return 0
  fi
  local http_enabled=$(echo "$proxy_info" | awk '/HTTPEnable/ {print $3}')
  if [ "$http_enabled" = "1" ]; then
    echo "http://$(echo "$proxy_info" | awk '/HTTPProxy/ {print $3}'):$(echo "$proxy_info" | awk '/HTTPSPort/ {print $3}')"
    return 0
  fi
  echo ""
}

# Parse Mode Arguments
SELECTED_MODE=""
if [ "$1" = "direct" ] || [ "$1" = "-d" ]; then
  SELECTED_MODE="DIRECT"
elif [ "$1" = "proxy" ] || [ "$1" = "-p" ]; then
  SELECTED_MODE="PROXY"
fi

if [ -z "$SELECTED_MODE" ]; then
  printf "${CYAN}Select Network Check Mode:${RESET}\n"
  printf "  ${GREEN}[1]${RESET} Proxy Mode (Use macOS System Proxy for global/filtered sites)\n"
  printf "  ${YELLOW}[2]${RESET} Direct Mode (Bypass all proxies to test raw ISP connection)\n"
  read -rp "Enter choice (1 or 2): " choice
  [ "$choice" = "2" ] && SELECTED_MODE="DIRECT" || SELECTED_MODE="PROXY"
fi

SYSTEM_PROXY=""
[ "$SELECTED_MODE" = "PROXY" ] && SYSTEM_PROXY=$(get_system_proxy)

check_site_worker() {
  local url="$1" filename="$2" use_proxy="$3"
  local http_code
  if [ "$use_proxy" = "true" ] && [ -n "$SYSTEM_PROXY" ]; then
    http_code=$(curl -s -x "$SYSTEM_PROXY" -L -I -o /dev/null -w "%{http_code}" --connect-timeout 4 "$url" 2>/dev/null)
  else
    http_code=$(curl -s -L -I -o /dev/null -w "%{http_code}" --connect-timeout 4 "$url" 2>/dev/null)
  fi

  if [[ "$http_code" =~ ^[23][0-9][0-9]$ ]]; then
    echo "0|HTTP $http_code" >"$TMP_DIR/$filename"
  elif [ "$http_code" -eq 0 ] || [ -z "$http_code" ]; then
    echo "1|Connection Timed Out / Blocked" >"$TMP_DIR/$filename"
  else
    echo "1|HTTP $http_code (Blocked/Redirected)" >"$TMP_DIR/$filename"
  fi
}

printf "\n${YELLOW}===============================================${RESET}\n"
printf "${YELLOW}   macOS Streaming Network Standpoint Test     ${RESET}\n"
printf "   Running Mode: ${CYAN}$SELECTED_MODE${RESET}\n"
printf "${YELLOW}===============================================${RESET}\n"
printf "${CYAN}[*] Dispatched all parallel probes. Streaming segments live...${RESET}\n\n"

ACTIVE_IF=$(route get default 2>/dev/null | awk '/interface:/ {print $2}')
GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}')
SYSTEM_DNS=$(scutil --dns | awk '/nameserver\[0\]/ {print $3; exit}')

# ----------------------------------------------------
# FIRE ALL BACKGROUND PROCESSES & RECORD INDIVIDUAL PIDs
# ----------------------------------------------------

# Group 1: Infra (Using your exact Wi-Fi extraction sequence)
(
  if [ -z "$ACTIVE_IF" ]; then
    echo "1|No active network interface"
  else
    # Attempt 1: Get SSID using ipconfig (requires sudo ipconfig setverbose 1 once)
    WIFI_SSID=$(ipconfig getsummary "$ACTIVE_IF" 2>/dev/null | awk -F': ' '/SSID/ {print $2}' | xargs)

    # Attempt 2 Fallback: Private Apple80211 framework
    if [ -z "$WIFI_SSID" ]; then
      WIFI_SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk -F': ' '/ SSID/ {print $2}' | xargs)
    fi

    if [ -n "$WIFI_SSID" ]; then
      echo "0|Active on $ACTIVE_IF (Wi-Fi SSID: $WIFI_SSID)"
    else
      echo "0|Active on $ACTIVE_IF (Wired/Ethernet Connection)"
    fi
  fi
) >"$TMP_DIR/j_if" &
PID_IF=$!

(if [ -z "$GATEWAY" ]; then echo "1|No gateway IP found"; else
  ping -c 1 -t 2 "$GATEWAY" >/dev/null 2>&1
  echo "$?|Reaching router"
fi) >"$TMP_DIR/j_gw" &
PID_GW=$!
(if [ -z "$SYSTEM_DNS" ]; then echo "1|No system DNS found"; else
  RESOLVED_IP=$(dig +short @$SYSTEM_DNS digikala.com 2>/dev/null | tail -n1)
  if [[ "$RESOLVED_IP" =~ ^[0-9] ]]; then echo "0|Resolved digikala.com to $RESOLVED_IP"; else echo "1|Failed lookup"; fi
fi) >"$TMP_DIR/j_ldns" &
PID_LDNS=$!
(
  ping -c 1 -t 2 1.1.1.1 >/dev/null 2>&1
  echo "$?|Global IP routing up"
) >"$TMP_DIR/j_rawip" &
PID_RAWIP=$!

# Group 2: Domestic (Always Direct)
check_site_worker "https://digikala.com" "w_digikala" "false" &
PID_DIGI=$!
check_site_worker "https://www.iranketab.ir" "w_iranketab" "false" &
PID_IRAN=$!
check_site_worker "https://soft98.ir" "w_soft98" "false" &
PID_SOFT=$!
check_site_worker "https://www.varzesh3.com" "w_varzesh3" "false" &
PID_VARZ=$!

# Flags for Proxy vs Direct
[ "$SELECTED_MODE" = "PROXY" ] && FLAG="true" || FLAG="false"

# Group 3: Global Web Standpoints
check_site_worker "https://www.wikipedia.org" "w_wikipedia" "$FLAG" &
PID_WIKI=$!
check_site_worker "https://substack.com" "w_substack" "$FLAG" &
PID_SUB=$!
check_site_worker "https://www.apple.com" "w_apple" "$FLAG" &
PID_APP=$!
check_site_worker "https://www.google.com" "w_google" "$FLAG" &
PID_GOOG=$!
check_site_worker "https://motamem.org" "w_motamem" "$FLAG" &
PID_MOT=$!

# Group 4: Filtered Platform Web
check_site_worker "https://www.youtube.com" "w_youtube" "$FLAG" &
PID_YT=$!
check_site_worker "https://t.me" "w_telegram" "$FLAG" &
PID_TG=$!
check_site_worker "https://www.instagram.com" "w_instagram" "$FLAG" &
PID_IG=$!
check_site_worker "https://x.com" "w_twitter" "$FLAG" &
PID_TW=$!
check_site_worker "https://www.facebook.com" "w_facebook" "$FLAG" &
PID_FB=$!

# ----------------------------------------------------
# STREAM SECTIONS INTERACTIVELY IN ORDER
# ----------------------------------------------------

# --- Part 1: Infrastructure ---
printf "${YELLOW}[+] Infrastructure Standpoints:${RESET}\n"
wait $PID_IF
IFS="|" read -r status msg <"$TMP_DIR/j_if"
print_status "Local Network Interface" "$status" "$msg"
wait $PID_GW
IFS="|" read -r status msg <"$TMP_DIR/j_gw"
print_status "Ping Default Gateway ($GATEWAY)" "$status" "$msg"
wait $PID_LDNS
IFS="|" read -r status msg <"$TMP_DIR/j_ldns"
print_status "Local DNS Query ($SYSTEM_DNS)" "$status" "$msg"
wait $PID_RAWIP
IFS="|" read -r status msg <"$TMP_DIR/j_rawip"
print_status "Ping Raw Global IP (1.1.1.1)" "$status" "$msg"

# --- Part 2: Domestic ---
printf "\n${CYAN}[*] Domestic Websites (Direct Route):${RESET}\n"
wait $PID_DIGI
IFS="|" read -r status msg <"$TMP_DIR/w_digikala"
print_status "digikala.com" "$status" "$msg"
wait $PID_IRAN
IFS="|" read -r status msg <"$TMP_DIR/w_iranketab"
print_status "iranketab.ir" "$status" "$msg"
wait $PID_SOFT
IFS="|" read -r status msg <"$TMP_DIR/w_soft98"
print_status "soft98.ir" "$status" "$msg"
wait $PID_VARZ
IFS="|" read -r status msg <"$TMP_DIR/w_varzesh3"
print_status "varzesh3.com" "$status" "$msg"

# --- Part 3: Global ---
printf "\n${CYAN}[*] Global Web Standpoints (${SELECTED_MODE} Route):${RESET}\n"
wait $PID_WIKI
IFS="|" read -r status msg <"$TMP_DIR/w_wikipedia"
print_status "Wikipedia" "$status" "$msg"
wait $PID_SUB
IFS="|" read -r status msg <"$TMP_DIR/w_substack"
print_status "Substack" "$status" "$msg"
wait $PID_APP
IFS="|" read -r status msg <"$TMP_DIR/w_apple"
print_status "Apple" "$status" "$msg"
wait $PID_GOOG
IFS="|" read -r status msg <"$TMP_DIR/w_google"
print_status "Google" "$status" "$msg"
wait $PID_MOT
IFS="|" read -r status msg <"$TMP_DIR/w_motamem"
print_status "Motamem (motamem.org)" "$status" "$msg"

# --- Part 4: Filtered ---
printf "\n${CYAN}[*] Filtered Websites (${SELECTED_MODE} Route):${RESET}\n"
wait $PID_YT
IFS="|" read -r status msg <"$TMP_DIR/w_youtube"
print_status "YouTube" "$status" "$msg"
wait $PID_TG
IFS="|" read -r status msg <"$TMP_DIR/w_telegram"
print_status "Telegram" "$status" "$msg"
wait $PID_IG
IFS="|" read -r status msg <"$TMP_DIR/w_instagram"
print_status "Instagram" "$status" "$msg"
wait $PID_TW
IFS="|" read -r status msg <"$TMP_DIR/w_twitter"
print_status "Twitter / X" "$status" "$msg"
wait $PID_FB
IFS="|" read -r status msg <"$TMP_DIR/w_facebook"
print_status "Facebook" "$status" "$msg"

printf "\n${YELLOW}===============================================${RESET}\n\n"
