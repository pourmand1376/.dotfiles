#!/usr/bin/env bash

# Color formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

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

# Programmatically read active macOS system proxy settings
get_system_proxy() {
  local proxy_info
  proxy_info=$(scutil --proxy)

  # 1. SOCKS Proxy
  local socks_enabled
  socks_enabled=$(echo "$proxy_info" | awk '/SOCKSEnable/ {print $3}')
  if [ "$socks_enabled" = "1" ]; then
    local host port
    host=$(echo "$proxy_info" | awk '/SOCKSProxy/ {print $3}')
    port=$(echo "$proxy_info" | awk '/SOCKSPort/ {print $3}')
    echo "socks5h://$host:$port"
    return 0
  fi

  # 2. HTTPS Proxy
  local https_enabled
  https_enabled=$(echo "$proxy_info" | awk '/HTTPSEnable/ {print $3}')
  if [ "$https_enabled" = "1" ]; then
    local host port
    host=$(echo "$proxy_info" | awk '/HTTPSProxy/ {print $3}')
    port=$(echo "$proxy_info" | awk '/HTTPSPort/ {print $3}')
    echo "https://$host:$port"
    return 0
  fi

  # 3. HTTP Proxy
  local http_enabled
  http_enabled=$(echo "$proxy_info" | awk '/HTTPEnable/ {print $3}')
  if [ "$http_enabled" = "1" ]; then
    local host port
    host=$(echo "$proxy_info" | awk '/HTTPProxy/ {print $3}')
    port=$(echo "$proxy_info" | awk '/HTTPPort/ {print $3}')
    echo "http://$host:$port"
    return 0
  fi
  echo ""
}

# Parse Command Line Arguments
SELECTED_MODE=""
if [ "$1" = "direct" ] || [ "$1" = "-d" ]; then
  SELECTED_MODE="DIRECT"
elif [ "$1" = "proxy" ] || [ "$1" = "-p" ]; then
  SELECTED_MODE="PROXY"
fi

# If no argument is provided, ask the user interactively
if [ -z "$SELECTED_MODE" ]; then
  echo -e "${CYAN}Select Network Check Mode:${RESET}"
  echo -e "  ${GREEN}[1]${RESET} Proxy Mode (Use macOS System Proxy for global/filtered sites)"
  echo -e "  ${YELLOW}[2]${RESET} Direct Mode (Bypass all proxies to test raw ISP connection)"
  read -rp "Enter choice (1 or 2): " choice
  if [ "$choice" = "2" ]; then
    SELECTED_MODE="DIRECT"
  else
    SELECTED_MODE="PROXY"
  fi
fi

# Configure Proxy based on selected mode
SYSTEM_PROXY=""
if [ "$SELECTED_MODE" = "PROXY" ]; then
  SYSTEM_PROXY=$(get_system_proxy)
fi

check_website_row() {
  local url="$1"
  local label="$2"
  local use_proxy="$3"

  local http_code
  if [ "$use_proxy" = "true" ] && [ -n "$SYSTEM_PROXY" ]; then
    http_code=$(curl -s -x "$SYSTEM_PROXY" -L -I -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null)
  else
    http_code=$(curl -s -L -I -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null)
  fi

  if [[ "$http_code" =~ ^[23][0-9][0-9]$ ]]; then
    print_status "$label" 0 "HTTP $http_code"
    return 0
  elif [ "$http_code" -eq 0 ] || [ -z "$http_code" ]; then
    print_status "$label" 1 "Connection Timed Out / Blocked"
    return 1
  else
    print_status "$label" 1 "HTTP $http_code (Blocked/Redirected)"
    return 1
  fi
}

echo -e "\n${YELLOW}===============================================${RESET}"
echo -e "${YELLOW}       macOS Network Diagnostic Standpoints    ${RESET}"
echo -e "       Running Mode: ${CYAN}$SELECTED_MODE${RESET}"
echo -e "${YELLOW}===============================================${RESET}\n"

if [ "$SELECTED_MODE" = "PROXY" ]; then
  if [ -n "$SYSTEM_PROXY" ]; then
    echo -e "${GREEN}[INFO] Active System Proxy Detected: $SYSTEM_PROXY${RESET}\n"
  else
    echo -e "${RED}[WARN] Proxy Mode requested, but NO active System Proxy was found in macOS Settings! Testing directly...${RESET}\n"
  fi
else
  echo -e "${YELLOW}[INFO] Direct Mode Active. Bypassing all system proxies.${RESET}\n"
fi

# ----------------------------------------------------
# 1. Check Wi-Fi / Local Interface Connection
# ----------------------------------------------------
ACTIVE_IF=$(route get default 2>/dev/null | awk '/interface:/ {print $2}')
if [ -z "$ACTIVE_IF" ]; then
  print_status "Local Network Interface" 1 "No active network interface detected."
  exit 1
else
  print_status "Local Network Interface" 0 "Active on interface: $ACTIVE_IF"
fi

# ----------------------------------------------------
# 2. Ping Default Gateway (Your Router)
# ----------------------------------------------------
GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}')
if [ -z "$GATEWAY" ]; then
  print_status "Gateway Identification" 1 "Could not find your router's gateway IP."
else
  ping -c 1 -t 2 "$GATEWAY" >/dev/null 2>&1
  print_status "Ping Default Gateway ($GATEWAY)" $? "Reaching your local router"
fi

# ----------------------------------------------------
# 3. Local DNS Resolution Check
# ----------------------------------------------------
SYSTEM_DNS=$(scutil --dns | awk '/nameserver\[0\]/ {print $3; exit}')
if [ -z "$SYSTEM_DNS" ]; then
  print_status "Local DNS Query" 1 "No system DNS server configured."
else
  RESOLVED_IP=$(dig +short @$SYSTEM_DNS digikala.com 2>/dev/null | tail -n1)
  if [ -n "$RESOLVED_IP" ] && [[ "$RESOLVED_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_status "Local DNS Query ($SYSTEM_DNS)" 0 "Resolved digikala.com to $RESOLVED_IP"
  else
    print_status "Local DNS Query ($SYSTEM_DNS)" 1 "Failed to resolve digikala.com"
  fi
fi

# ----------------------------------------------------
# 4. Ping Raw Global IP (No DNS)
# ----------------------------------------------------
ping -c 1 -t 2 1.1.1.1 >/dev/null 2>&1
IP_STATUS=$?
print_status "Ping Raw Global IP (1.1.1.1)" $IP_STATUS "Verifying global IP routing without DNS"

# ----------------------------------------------------
# 5. Domestic Web Access (Direct Route - Always bypassed)
# ----------------------------------------------------
echo -e "\n${CYAN}[*] Checking Domestic Websites (Direct Route):${RESET}"
DOMESTIC_SUCCESS=0
check_website_row "https://digikala.com" "digikala.com" "false" && DOMESTIC_SUCCESS=1
check_website_row "https://www.iranketab.ir" "iranketab.ir" "false" && DOMESTIC_SUCCESS=1
check_website_row "https://soft98.ir" "soft98.ir" "false" && DOMESTIC_SUCCESS=1
check_website_row "https://www.varzesh3.com" "varzesh3.com" "false" && DOMESTIC_SUCCESS=1

# ----------------------------------------------------
# 6. Filtered Web Access
# ----------------------------------------------------
if [ "$SELECTED_MODE" = "PROXY" ]; then
  echo -e "\n${CYAN}[*] Checking Filtered Websites (Proxy Route):${RESET}"
  USE_PROXY_FLAG="true"
else
  echo -e "\n${CYAN}[*] Checking Filtered Websites (Direct Route):${RESET}"
  USE_PROXY_FLAG="false"
fi

FILTERED_SUCCESS=0
check_website_row "https://www.youtube.com" "YouTube" "$USE_PROXY_FLAG" && FILTERED_SUCCESS=1
check_website_row "https://t.me" "Telegram" "$USE_PROXY_FLAG" && FILTERED_SUCCESS=1
check_website_row "https://www.instagram.com" "Instagram" "$USE_PROXY_FLAG" && FILTERED_SUCCESS=1
check_website_row "https://x.com" "Twitter / X" "$USE_PROXY_FLAG" && FILTERED_SUCCESS=1
check_website_row "https://www.facebook.com" "Facebook" "$USE_PROXY_FLAG" && FILTERED_SUCCESS=1

# ----------------------------------------------------
# 7. Unfiltered Global Web Access
# ----------------------------------------------------
echo -e "\n${CYAN}[*] Checking Unfiltered Global Web:${RESET}"
GLOBAL_SUCCESS=0
check_website_row "https://www.wikipedia.org" "Wikipedia" "$USE_PROXY_FLAG" && GLOBAL_SUCCESS=1

echo -e "\n${YELLOW}===============================================${RESET}\n"
