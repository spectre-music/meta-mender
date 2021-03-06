FILES_${PN}_remove_mender-client-install = " /boot/EFI/BOOT/${SYSTEMD_BOOT_IMAGE} "
FILES_${PN}_append_mender-client-install = " ${MENDER_BOOT_PART_MOUNT_LOCATION}/EFI/BOOT/${SYSTEMD_BOOT_IMAGE} "

do_install_append() {
    if "${@bb.utils.contains('DISTRO_FEATURES', 'mender-client-install', 'true', 'false', d)}"; then
        install -d ${D}/${MENDER_BOOT_PART_MOUNT_LOCATION}
        mv ${D}/boot/EFI ${D}/${MENDER_BOOT_PART_MOUNT_LOCATION}
        rmdir ${D}/boot || true
    fi
}