#!/usr/bin/env bash
# Linux + macOS: prints CSV row -> RAM,Storage,Storage Type,OS,Status
# Usage: ./inventory.sh            (add -H to print header)

[ "$1" = "-H" ] && echo "Model,Serial Number,RAM,Storage,Storage Type,OS,Status"

case "$(uname -s)" in
  Linux)
    MODEL=$(cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name 2>/dev/null | paste -sd' ' -)
    SERIAL=$(cat /sys/class/dmi/id/product_serial 2>/dev/null)
    [ -z "$SERIAL" ] && SERIAL=$(sudo -n dmidecode -s system-serial-number 2>/dev/null)
    RAM=$(awk '/MemTotal/ {printf "%.0f GB", $2/1024/1024}' /proc/meminfo)
    STORAGE=$(lsblk -dbn -o SIZE,TYPE 2>/dev/null | awk '$2=="disk"{s+=$1} END{printf "%.0f GB", s/1e9}')
    TYPES=$(lsblk -dn -o NAME,ROTA,TYPE 2>/dev/null | awk '$3=="disk"{
      if ($1 ~ /^nvme/) t="NVMe"; else if ($2==0) t="SSD"; else t="HDD"; print t}' | sort -u | paste -sd/ -)
    OS=$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Linux}")
    STATUS="Online (up $(uptime -p | sed 's/^up //'))"
    ;;
  Darwin)
    MODEL="Apple $(sysctl -n hw.model)"
    SERIAL=$(system_profiler SPHardwareDataType | awk -F': ' '/Serial Number/ {print $2; exit}')
    RAM=$(sysctl -n hw.memsize | awk '{printf "%.0f GB", $1/1024/1024/1024}')
    STORAGE=$(diskutil info / | awk -F'[()]' '/Disk Size|Container Total Space/ {split($2,a," "); printf "%.0f GB", a[1]/1e9; exit}')
    if diskutil info / | grep -q "Solid State:.*Yes"; then TYPES="SSD"; else TYPES="HDD"; fi
    OS="$(sw_vers -productName) $(sw_vers -productVersion)"
    STATUS="Online"
    ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

echo "\"${MODEL:-Unknown}\",\"${SERIAL:-Unknown}\",\"$RAM\",\"$STORAGE\",\"${TYPES:-Unknown}\",\"$OS\",\"$STATUS\""
