#!/bin/bash

set -e

DESTDIR=$FBDIR/build/apps/components_$DESTARCH
cp $FBDIR/tools/flex-installer ${TARGET_DIR}/usr/bin
cp $FBDIR/configs/buildroot/lsdkstrap.sh ${TARGET_DIR}/etc/profile.d
mkdir -p ${TARGET_DIR}/usr/{include,local}

# setup PFE
if [ ! -f $FBDIR/build/firmware/qoriq-engine-pfe-bin/ls1012a/slow_path/ppfe_class_ls1012a.elf ]; then
    flex-builder -c qoriq-engine-pfe-bin
fi
mkdir -p $RFSDIR/lib/firmware
. $FBDIR/configs/board/ls1012ardb/manifest
cp $FBDIR/$pfe_kernel $RFSDIR/lib/firmware

if [ $DESTARCH = arm64 ]; then
    # setup restool
    if [ ! -f $DESTDIR/usr/local/bin/restool ]; then
        flex-builder -c restool
    fi
    cp $DESTDIR/usr/local/bin/{restool,ls-*} ${TARGET_DIR}/usr/bin

    # setip qbman
    if [ ! -f  $DESTDIR/usr/local/bin/qbman_test ]; then
	flex-builder -c qbman_userspace
    fi
    cp $DESTDIR/usr/local/bin/qbman_test ${TARGET_DIR}/usr/bin
    cp $DESTDIR/usr/local/lib/libqbman.a ${TARGET_DIR}/lib

    # setup openssl
    if  [ ! -f $DESTDIR/usr/local/bin/openssl ]; then
	flex-builder -c openssl
    fi
    cp $DESTDIR/usr/local/bin/{openssl,c_rehash} ${TARGET_DIR}/usr/bin
    cp -rf $DESTDIR/usr/local/lib/{engines*,libcrypto*,libssl*,ssl,pkgconfig} ${TARGET_DIR}/usr/lib

    # setup aiop
    if [ ! -f $DESTDIR/usr/bin/aiop_tool ]; then
	flex-builder -c gpp-aioptool
    fi
    if [ ! -f $DESTDIR/usr/local/aiop ]; then
	flex-builder -c aiopsl
    fi
    cp $DESTDIR/usr/bin/aiop_tool ${TARGET_DIR}/usr/bin
    cp -rf $DESTDIR/usr/local/aiop ${TARGET_DIR}/usr/local

    # setup crconf
    if [ ! -f $DESTDIR/usr/local/sbin/crconf ]; then
	flex-builder -c crconf
    fi
    cp $DESTDIR/usr/local/sbin/crconf ${TARGET_DIR}/usr/bin
fi

# setup kernel lib modules
libmodules=$FBDIR/build/linux/kernel/$DESTARCH/lib/modules
modulename=$(echo `ls -t $libmodules` | cut -d' ' -f1)
modulespath=$libmodules/$modulename
if [ -n "$modulename" ]; then
    if [ $DISTROSCALE = tiny -a -f $modulespath/kernel/drivers/staging/fsl_ppfe/pfe.ko ]; then
	mkdir -p ${TARGET_DIR}/lib/modules/$modulename/kernel/drivers/staging/fsl_ppfe
	cp -f $modulespath/kernel/drivers/staging/fsl_ppfe/pfe.ko \
	       ${TARGET_DIR}/lib/modules/$modulename/kernel/drivers/staging/fsl_ppfe
    else
	rm -rf ${TARGET_DIR}/lib/modules/*
	cp -rf $modulespath ${TARGET_DIR}/lib/modules
    fi
fi
