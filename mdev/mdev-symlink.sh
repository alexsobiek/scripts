#!/bin/bash

# ===============================================================================
# This script is intended to be called by mdev when a device is added or removed.
# It creates/removes symlinks for devices so that they can be accessed by name
# rather than by something like /dev/ttyUSB[0-9] which is variable.
# 
# Adding script to /etc/mdev.conf:
# For USB devices, find the following line:
# ttyUSB[0-9]    root:dialout 0660 @ln -sf $MDEV modem
# and replace it with: 
# ttyUSB[0-9]     root:dialout 0660 */PATH/TO/SCRIPT/mdev-symlink.sh
# ===============================================================================


# This script is called by mdev when a device is added or removed.
# It creates/removes symlinks in /dev for the device.

declare -A DEV_MAP;

# Map of device names to symlinks
# Format: DEV_MAP["idVendor:idProduct:serial"]="symlink_name"
DEV_MAP["10c4:ea60:0001"]="/dev/zwave"
DEV_MAP["10c4:ea60:1612a45e6445ed11873bc88f0a86e0b4"]="/dev/zigbee"

device="/sys$DEVPATH"

if [ "$ACTION" = "add" ]; then
    while [[ "$device" != "/sys" ]]; do
        if [ -e "$device/idVendor" ] && [ -e "$device/idProduct" ] && [ -e "$device/serial" ]; then
            idVendor=$(cat "$device/idVendor")
            idProduct=$(cat "$device/idProduct")
            serial=$(cat "$device/serial")
            key="$idVendor:$idProduct:$serial"
            if [[ -n "${DEV_MAP[$key]}" ]]; then
                echo "Found device $DEVPATH" >> /var/log/mdev.log
                echo "Creating symlink "/dev/$MDEV" -> ${DEV_MAP[$key]}" >> /var/log/mdev.log
                ln -s "/dev/$MDEV" "${DEV_MAP[$key]}"
            fi
            break
        fi
        device=$(dirname "$device")
    done
elif [ "$ACTION" = "remove" ]; then
    echo "Removed device $DEVPATH" >> /var/log/mdev.log
    for symlink in /dev/*; do
        if [ -L "$symlink" ] && [ ! -e "$symlink" ]; then
            echo "Removing symlink $symlink" >> /var/log/mdev.log
            rm "$symlink"
        fi
    done
fi
