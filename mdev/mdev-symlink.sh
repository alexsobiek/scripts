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
# Format: DEV_MAP["device_name"]="symlink_name"
# device name is the path, or the start of the path, of the device
DEV_MAP["/devices/platform/soc/3f980000.usb"]="/dev/zwave"



if [ "$ACTION" = "add" ]; then
    # Create device symlink
    for device in "${!DEV_MAP[@]}"; do
        echo $device;
        if [[ "$DEVPATH" == "$device"* ]]; then
            ln -s "/dev/$MDEV" "${DEV_MAP[$device]}"
        fi
    done
elif [ "$ACTION" = "remove" ]; then
    # Remove device symlink
    for device in "${!DEV_MAP[@]}"; do
        if [[ "$DEVPATH" == "$device"* ]]; then
            rm "${DEV_MAP[$device]}"
        fi
    done
fi