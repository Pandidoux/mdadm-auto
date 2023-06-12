#!/bin/bash

# Check if running with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo privileges."
    exit 1
fi

# Install required packages
echo "Installing necessary packages..."
sudo apt install -y mdadm fdisk e2fsprogs

# Prompt user for RAID folder
read -p "Enter the folder name to mount the RAID array: " mount_folder

# Prompt user for RAID level
read -p "Enter the RAID level (e.g., 0, 1, 5, 6): " raid_level

# Prompt user for the number of disks
read -p "Enter the number of disks in the array: " num_disks

# Show the output of 'fdisk -l'
echo "Displaying disk information..."
sudo fdisk -l

# Prompt user for the disk names
echo "Enter the names of the disks (e.g., /dev/sda1, /dev/sdb1, ...)"
disks=()
for ((i=1; i<=$num_disks; i++)); do
    read -p "Disk $i: " disk
    disks+=("$disk")
done

# Create the RAID array
echo "Creating the RAID array..."
sudo mdadm --create --verbose /dev/md0 --level=$raid_level --raid-devices=$num_disks --bitmap-chunk=512K "${disks[@]}"
if [ $? -ne 0 ]; then
    echo "Failed to create the RAID array. Exiting..."
    exit 1
fi

# Format the RAID array
echo "Formatting the RAID array..."
sudo mkfs.ext4 /dev/md0
if [ $? -ne 0 ]; then
    echo "Failed to format the RAID array. Exiting..."
    exit 1
fi

# Mount the RAID array
echo "Mounting the RAID array..."
sudo mkdir -p "$mount_folder"
sudo mount /dev/md0 "$mount_folder"
if [ $? -ne 0 ]; then
    echo "Failed to mount the RAID array. Exiting..."
    exit 1
fi

# Update mdadm.conf and initramfs
echo "Updating mdadm.conf..."
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
if [ $? -ne 0 ]; then
    echo "Failed to update mdadm.conf. Exiting..."
    exit 1
fi

echo "Updating initramfs..."
sudo update-initramfs -u
if [ $? -ne 0 ]; then
    echo "Failed to update initramfs. Exiting..."
    exit 1
fi

# Add the mount options to /etc/fstab for automatic mounting
echo "Adding mount options to /etc/fstab..."
echo "/dev/md0 $mount_folder ext4 defaults,nofail,discard 0 0" | sudo tee -a /etc/fstab
if [ $? -ne 0 ]; then
    echo "Failed to add mount options to /etc/fstab. Exiting..."
    exit 1
fi

# Save RAID information
read -p "Enter the path to save the RAID info file: " raid_info_file
sudo mdadm --detail /dev/md0 > "$raid_info_file"
if [ $? -ne 0 ]; then
    echo "Failed to save RAID information. Exiting..."
    exit 1
fi

# Show the output of 'df' command
echo "Displaying disk usage..."
df -h -x devtmpfs -x tmpfs
if [ $? -ne 0 ]; then
    echo "Failed to display disk usage. Exiting..."
    exit 1
fi

echo "RAID $raid_level array creation and setup completed successfully !!!"
