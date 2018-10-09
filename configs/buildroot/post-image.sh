#!/bin/bash

set -e

IMGDIR=$FBDIR/build/images
mkdir -p $IMGDIR
mkdir -p $FBDIR/packages/rfs/initrds
if [ "$ENDIANTYPE" = "be" ]; then
    endiantype=_be
fi
mkimage -A arm -T ramdisk -C gzip -d ${BINARIES_DIR}/rootfs.ext2.gz $IMGDIR/rootfs_buildroot_${DESTARCH}${endiantype}_ext2_${DISTROSCALE}.gz.uboot
if [ $DISTROSCALE = tiny ]; then
    cp ${BINARIES_DIR}/rootfs.cpio.gz $FBDIR/packages/rfs/initrds/initrd.$DESTARCH${endiantype}.cpio.gz
else
    cp ${BINARIES_DIR}/rootfs.cpio.gz $FBDIR/packages/rfs/initrds/initrd.$DESTARCH${endiantype}.cpio.$DISTROSCALE.gz
fi
cp ${BINARIES_DIR}/rootfs.ext2.gz $IMGDIR/rootfs_buildroot_${DESTARCH}${endiantype}_ext2_${DISTROSCALE}.gz
cp ${BINARIES_DIR}/rootfs.jffs2 $IMGDIR/rootfs_buildroot_${DESTARCH}${endiantype}_jffs2_${DISTROSCALE}
cp ${BINARIES_DIR}/rootfs.squashfs $IMGDIR/rootfs_buildroot_${DESTARCH}${endiantype}_squashfs_${DISTROSCALE}
