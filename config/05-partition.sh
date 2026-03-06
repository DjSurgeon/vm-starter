#!/bin/bash
# =============================================================================
# DevPod Configuration – 05-partition.sh
# Purpose: Define disk partitioning scheme (simplified, no LVM/LUKS).
# =============================================================================

# -----------------------------------------------------------------------------
# Boot partition – holds kernel and bootloader.
# -----------------------------------------------------------------------------
export PARTITION_BOOT_SIZE_MB="1024"			# Size in MB (1 GB) – Ubuntu recommends ≥1 GB for /boot

# -----------------------------------------------------------------------------
# Root partition – contains the entire system.
# -----------------------------------------------------------------------------
export PARTITION_ROOT_SIZE_MB="-1"				# -1 means "use remaining free space" (fill disk)

# -----------------------------------------------------------------------------
# Filesystem types for the partitions.
# -----------------------------------------------------------------------------
export FILESYSTEM_BOOT="ext4"					# ext4 is standard; older preseed used ext2, but ext4 is fine
export FILESYSTEM_ROOT="ext4"					# Root filesystem

# -----------------------------------------------------------------------------
# Swap – configured as a file (swapfile) instead of a separate partition.
# -----------------------------------------------------------------------------
export SWAP_SIZE_MB="2048"						# Size of swapfile in MB (2 GB)

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - This scheme is used by the Ubuntu installer via cloud‑init or preseed.
#   - Boot partition is mounted at /boot, root at /.
#   - Swapfile is created during first boot (see runcmd in cloud‑init).
#   - Compared to the original preseed.cfg (LUKS+LVM with 7 volumes), this is
#     drastically simplified – perfect for disposable development VMs.
# -----------------------------------------------------------------------------