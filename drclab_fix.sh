#!/usr/bin/env bash

# Ensure script is executed with root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Error: Please run this script using sudo.\e[0m"
  exit 1
fi

echo -e "\e[34m[*] Starting DRCLAB stability configuration deployment...\e[0m"

# 1. Target Core System Kernel Stability Parameters (GRUB)
GRUB_FILE="/etc/default/grub"
BACKUP_GRUB="/etc/default/grub.bak.$(date +%F_%H%M%S)"

echo -e "\e[32m[+] Backing up current GRUB configuration to ${BACKUP_GRUB}...\e[0m"
cp "$GRUB_FILE" "$BACKUP_GRUB"

# Define the precise stability parameter block
STABILITY_PARAMS="quiet splash amdgpu.runpm=0 i915.enable_guc=0 pci=noaer rdt=!l3,!l2 loglevel=3"

echo -e "\e[32m[+] Injecting kernel stability flags into ${GRUB_FILE}...\e[0m"
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${STABILITY_PARAMS}\"|" "$GRUB_FILE"

# 2. Target Background Network Sync Stalls (chronyd)
CHRONY_CONF="/etc/chrony/chrony.conf"
if [ -f "$CHRONY_CONF" ]; then
    echo -e "\e[32m[+] Patching chrony to prevent TLS/NTS background loops...\e[0m"
    cp "$CHRONY_CONF" "${CHRONY_CONF}.bak"
    sed -i 's/ nts//g' "$CHRONY_CONF"
    systemctl restart chrony 2>/dev/null || systemctl restart chronyd 2>/dev/null
fi

# 3. Commit Architecture Configuration Arrays to System Matrix
echo -e "\e[32m[+] Recompiling GRUB bootloader configuration files...\e[0m"
update-grub

echo -e "\n\e[36m[+] Done! All freeze risk configurations have been resolved.\e[0m"

