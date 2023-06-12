#!/bin/bash

# Check if running with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo privileges."
    exit 1
fi

# Prompt user for RAID device name
read -p "Enter the name of the RAID device to delete (e.g., /dev/md0): " raid_device

# Confirm deletion with user
read -p "WARNING: This will permanently delete the RAID array. Are you sure you want to proceed? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "RAID array deletion aborted."
    exit 0
fi

# Unmount the RAID array if mounted
if mountpoint -q "$raid_device"; then
    echo "Unmounting the RAID array..."
    sudo umount "$raid_device"
    if [ $? -ne 0 ]; then
        echo "Failed to unmount the RAID array. Exiting..."
        exit 1
    fi
fi

# Stop the RAID array
echo "Stopping the RAID array..."
sudo mdadm --stop "$raid_device"
if [ $? -ne 0 ]; then
    echo "Failed to stop the RAID array. Exiting..."
    exit 1
fi

# Remove the RAID array from mdadm.conf
echo "Removing the RAID array from mdadm.conf..."
sudo mdadm --remove "$raid_device"
if [ $? -ne 0 ]; then
    echo "Failed to remove the RAID array from mdadm.conf. Exiting..."
    exit 1
fi

# Update initramfs
echo "Updating initramfs..."
sudo update-initramfs -u
if [ $? -ne 0 ]; then
    echo "Failed to update initramfs. Exiting..."
    exit 1
fi

# Delete RAID device
echo "Deleting the RAID device..."
sudo mdadm --zero-superblock "$raid_device"
if [ $? -ne 0 ]; then
    echo "Failed to delete the RAID device. Exiting..."
    exit 1
fi

echo "RAID array deletion completed successfully !!!"
