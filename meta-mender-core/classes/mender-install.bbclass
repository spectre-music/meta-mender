# Class for those who want to install the Mender client into the image.

# ------------------------------ CONFIGURATION ---------------------------------

# The storage device that holds the device partitions.
MENDER_STORAGE_DEVICE ?= "/dev/mmcblk0"

# The base name of the devices that hold individual partitions.
# This is often MENDER_STORAGE_DEVICE + "p".
MENDER_STORAGE_DEVICE_BASE ?= "${MENDER_STORAGE_DEVICE}p"

# The partition number holding the boot partition.
MENDER_BOOT_PART ?= "${MENDER_STORAGE_DEVICE_BASE}1"

# The numbers of the two rootfs partitions in the A/B partition layout.
MENDER_ROOTFS_PART_A ?= "${MENDER_STORAGE_DEVICE_BASE}2"
MENDER_ROOTFS_PART_B ?= "${MENDER_STORAGE_DEVICE_BASE}3"

# The partition number holding the data partition.
MENDER_DATA_PART ?= "${MENDER_STORAGE_DEVICE_BASE}5"

# Device type of device when making an initial partitioned image.
MENDER_DEVICE_TYPE ?= "${MACHINE}"

# Space separated list of device types compatible with the built update.
MENDER_DEVICE_TYPES_COMPATIBLE ?= "${MACHINE}"

# Total size of the medium that mender sdimg will be written to. The size of
# rootfs partition will be calculated automatically by subtracting the size of
# boot and data partitions along with some predefined overhead (see
# MENDER_PARTITIONING_OVERHEAD_MB).
MENDER_STORAGE_TOTAL_SIZE_MB ?= "1024"

# Optional location where a directory can be specified with content that should
# be included on the data partition. Some of Mender's own files will be added to
# this (e.g. OpenSSL certificates).
MENDER_DATA_PART_DIR ?= ""

# Size of the data partition, which is preserved across updates.
MENDER_DATA_PART_SIZE_MB ?= "128"

# Size of the first (FAT) partition, that contains the bootloader
MENDER_BOOT_PART_SIZE_MB ?= "16"

# For performance reasons, we try to align the partitions to the SD
# card's erase block. It is impossible to know this information with
# certainty, but one way to find out is to run the "flashbench" tool on
# your SD card and study the results. If you do, feel free to override
# this default.
#
# 8MB alignment is a safe setting that might waste some space if the
# erase block is smaller.
MENDER_PARTITION_ALIGNMENT_MB ?= "8"

# The reserved space between the partition table and the first partition.
# Most people don't need to set this, and it will be automatically overridden
# in mender-uboot.bbclass.
MENDER_STORAGE_RESERVED_RAW_SPACE ??= "0"

# --------------------------- END OF CONFIGURATION -----------------------------


PREFERRED_VERSION_go-cross-arm ?= "1.7.%"
PREFERRED_VERSION_go-native ?= "1.7.%"

PREFERRED_VERSION_mender ?= "1.0.%"
PREFERRED_VERSION_mender-artifact ?= "1.0.%"
PREFERRED_VERSION_mender-artifact-native ?= "1.0.%"

IMAGE_INSTALL_append = " \
    mender \
    ca-certificates \
    mender-artifact-info \
    "

# Estimate how much space may be lost due to partitioning alignment. Use a
# simple heuristic for now - 4 partitions * alignment
def mender_get_part_overhead(d):
    align = d.getVar('MENDER_PARTITION_ALIGNMENT_MB', True)
    if align:
        return 4 * int(align)
    return 0

# Overhead lost due to partitioning.
MENDER_PARTITIONING_OVERHEAD_MB ?= "${@mender_get_part_overhead(d)}"


def mender_calculate_rootfs_size_kb(total_mb, boot_mb, data_mb, overhead_mb, reserved_space_size):
    # Space left in raw device.
    calc_space = (total_mb - boot_mb - data_mb - overhead_mb) * 1048576

    # Subtract reserved raw space.
    calc_space = calc_space - reserved_space_size

    # Split in two.
    calc_space = calc_space / 2

    # Turn into kiB.
    calc_space_kb = calc_space / 1024

    return int(calc_space_kb)

# Auto detect image size from other settings.
MENDER_CALC_ROOTFS_SIZE = "${@mender_calculate_rootfs_size_kb(${MENDER_STORAGE_TOTAL_SIZE_MB}, \
                                                              ${MENDER_BOOT_PART_SIZE_MB}, \
                                                              ${MENDER_DATA_PART_SIZE_MB}, \
                                                              ${MENDER_PARTITIONING_OVERHEAD_MB}, \
                                                              ${MENDER_STORAGE_RESERVED_RAW_SPACE})}"
# Gently apply this as the default image size.
# But subtract IMAGE_ROOTFS_EXTRA_SPACE, since it will be added automatically
# in later bitbake calculations.
IMAGE_ROOTFS_SIZE ?= "${@eval('${MENDER_CALC_ROOTFS_SIZE} - (${IMAGE_ROOTFS_EXTRA_SPACE})')}"
