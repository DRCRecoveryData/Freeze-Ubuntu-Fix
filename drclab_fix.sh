#!/usr/bin/env bash

# Ensure script is executed with root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Error: Please run this script using sudo.\e[0m"
  exit 1
fi

echo -e "\e[34m[*] Detecting Linux Distribution Family...\e[0m"

# Detect OS family
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_FAMILY=$ID_LIKE
    [ -z "$OS_FAMILY" ] && OS_FAMILY=$ID
else
    echo -e "\e[31m[-] Unable to detect OS release parameters. Defaulting to standard paths.\e[0m"
    OS_FAMILY="debian"
fi

# 1. Patch GRUB Defaults Matrix
GRUB_FILE="/etc/default/grub"
STABILITY_PARAMS="quiet splash amdgpu.runpm=0 i915.enable_guc=0 pci=noaer rdt=!l3,!l2 loglevel=3"

if [ -f "$GRUB_FILE" ]; then
    echo -e "\e[32m[+] Injecting core kernel parameters into ${GRUB_FILE}...\e[0m"
    cp "$GRUB_FILE" "${GRUB_FILE}.bak"
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${STABILITY_PARAMS}\"|" "$GRUB_FILE"
fi

# 2. Patch Chrony Path Mapping Intersections
CHRONY_CONF=""
[ -f "/etc/chrony/chrony.conf" ] && CHRONY_CONF="/etc/chrony/chrony.conf"
[ -f "/etc/chrony.conf" ] && CHRONY_CONF="/etc/chrony.conf"

if [ -n "$CHRONY_CONF" ]; then
    echo -e "\e[32m[+] Patching chrony configuration at ${CHRONY_CONF}...\e[0m"
    cp "$CHRONY_CONF" "${CHRONY_CONF}.bak"
    sed -i 's/ nts//g' "$CHRONY_CONF"
    systemctl restart chrony 2>/dev/null || systemctl restart chronyd 2>/dev/null
fi

# 3. Recompile Boot Menu Target Based on Distribution Family Architecture
echo -e "\e[32m[+] Recompiling bootloader configuration for system type: ${OS_FAMILY}...\e[0m"

case "$OS_FAMILY" in
    *debian*|*ubuntu*)
        update-grub
        ;;
    *fedora*|*rhel*|*centos*)
        if [ -f "/boot/efi/EFI/fedora/grub.cfg" ]; then
            grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
        else
            grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
        ;;
    *arch*)
        grub-mkconfig -o /boot/grub/grub.cfg
        ;;
    *)
        echo -e "\e[33m[*] Manual Step Required: Run your distribution's GRUB update command.\e[0m"
        ;;
esac

echo -e "\n\e[36m[+] Done! System structural fixes applied successfully!\e[0m"
