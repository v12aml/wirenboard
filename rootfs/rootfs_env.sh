services_disable() {
    # This disables startin services when installing packages
    echo exit 101 > ${ROOTFS_DIR}/usr/sbin/policy-rc.d
    chmod +x ${ROOTFS_DIR}/usr/sbin/policy-rc.d
}

services_enable() {
    rm -f ${ROOTFS_DIR}/usr/sbin/policy-rc.d
}

cleanup_chroot() {
    local ret=$?

    echo "Umount proc,dev,dev/pts in rootfs"
    [[ -L ${ROOTFS_DIR}/dev/ptmx ]] || umount ${ROOTFS_DIR}/dev/ptmx
    umount ${ROOTFS_DIR}/dev/pts
    umount ${ROOTFS_DIR}/proc
    umount ${ROOTFS_DIR}/sys

    services_enable

    return $ret
}

prepare_chroot() {
	# without devpts mount options you will likely end up looking why you can't open
	# new terminal window :)
	echo "Mount /proc, /sys, /dev, /dev/pts"
	mkdir -p ${ROOTFS_DIR}/{proc,sys,dev/pts}
	mount --bind /proc ${ROOTFS_DIR}/proc
	mount --bind /sys ${ROOTFS_DIR}/sys
	mount -t devpts devpts ${ROOTFS_DIR}/dev/pts -o "gid=5,mode=666,ptmxmode=0666,newinstance"
	rm -f ${ROOTFS_DIR}/dev/ptmx
	ln -s /dev/pts/ptmx ${ROOTFS_DIR}/dev/ptmx
	if [[ ! -L ${ROOTFS_DIR}/dev/ptmx ]]; then
	    if [[ -e ${ROOTFS_DIR}/dev/ptmx ]]; then
	        mount --bind ${ROOTFS_DIR}/dev/pts/ptmx ${ROOTFS_DIR}/dev/ptmx
	    else
	        ln -s /dev/pts/ptmx ${ROOTFS_DIR}/dev/ptmx
	    fi
	fi

	trap cleanup_chroot EXIT
}

# a few shortcuts
chr() {
    chroot ${ROOTFS_DIR} "$@"
}

chr_nofail() {
    chroot ${ROOTFS_DIR} "$@" || true
}

chr_apt() {
    chr apt-get install -y --force-yes "$@"
}

dbg() {
    chr ls -l /dev/pts
    chr ls -l /proc
}
