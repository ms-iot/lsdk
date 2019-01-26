# Makefile for building complete linux image for Scalys Grapeboard
# with LS1012A. Builds firmware components, linux kernel, and
# linux rootfs.

O ?= $(CURDIR)/build

CST_SRC_PATH = cst
UBOOT_SRC_PATH = u-boot
UBOOT_BUILD_PATH = $(O)/u-boot
OPTEE_BUILD_PATH = $(O)/optee
LINUX_BUILD_PATH = $(O)/linux
UBUNTU_BASE_URL = http://cdimage.ubuntu.com/ubuntu-base/releases/bionic/release/ubuntu-base-18.04-base-arm64.tar.gz
UBUNTU_BASE_FILENAME = $(notdir $(UBUNTU_BASE_URL))
RFS_DIR = $(O)/rfs

all: firmware os

.PHONY: firmware os
firmware: u-boot-signed ppa-optee
os: linux

.PHONY: u-boot-signed
u-boot-signed: u-boot $(O)/hdr_spl.out

.PHONY: u-boot
u-boot:
	CROSS_COMPILE=aarch64-linux-gnu- ARCH=aarch64 \
	$(MAKE) -C $(UBOOT_SRC_PATH) \
	grapeboard_pcie_qspi_spl_secureboot_defconfig O=$(UBOOT_BUILD_PATH)

	CROSS_COMPILE=aarch64-linux-gnu- ARCH=aarch64 \
	$(MAKE) -C $(UBOOT_SRC_PATH) O=$(UBOOT_BUILD_PATH)
	cp $(UBOOT_BUILD_PATH)/u-boot-with-spl-pbl.bin $(O)/

$(O)/hdr_spl.out: u-boot cst \
		  keys/srk.pub \
		  keys/srk.pri \
		  hab/input_spl_secure
	rm -rf $(O)/hab
	mkdir $(O)/hab
	cp keys/srk.pub $(O)/hab
	cp keys/srk.pri $(O)/hab
	cp hab/input_spl_secure $(O)/hab
	cp $(UBOOT_BUILD_PATH)/spl/u-boot-spl.bin $(O)/hab
	cd $(O)/hab && ../../cst/create_hdr_isbc input_spl_secure
	mv $(O)/hab/hdr_spl.out $@

.PHONY: cst
cst:
	$(MAKE) -C $(CST_SRC_PATH)

.PHONY: ppa-optee
ppa-optee: $(O)/ppa.itb
$(O)/ppa.itb: $(O)/ppa.its $(O)/tee.bin $(O)/monitor.bin
	cd $(O) && mkimage -f ppa.its ppa.itb

$(O)/ppa.its: ppa.its
	cp $< $@

$(O)/tee.bin: optee
	cp $(OPTEE_BUILD_PATH)/core/tee-pager.bin $@

.PHONY: optee
optee:
	CROSS_COMPILE64=aarch64-linux-gnu- \
	$(MAKE) -C optee_os O=$(OPTEE_BUILD_PATH) \
	PLATFORM=ls-ls1012grapeboard \
	CFG_ARM64_core=y \
	ARCH=arm \
	CFG_TEE_CORE_DEBUG=y \
	CFG_TEE_CORE_LOG_LEVEL=4

$(O)/monitor.bin: ppa
	cp ppa-generic/ppa/soc-ls1012/build/obj/monitor.bin $@

.PHONY: ppa
ppa:
	cd ppa-generic/ppa && CROSS_COMPILE=aarch64-linux-gnu- \
	./build clean ls1012
	cd ppa-generic/ppa && CROSS_COMPILE=aarch64-linux-gnu- \
	./build prod rdb spd=on ls1012

.PHONY: linux
linux: configure-linux compile-linux

.PHONY: configure-linux
configure-linux:
	CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
	$(MAKE) -C linux defconfig lsdk.config grapeboard_security.config \
	O=$(LINUX_BUILD_PATH)

.PHONY: compile-linux
compile-linux:
	CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
	$(MAKE) -C linux O=$(LINUX_BUILD_PATH)
	
	CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
	$(MAKE) -C linux modules O=$(LINUX_BUILD_PATH)

	CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
	$(MAKE) -C linux modules_install \
	INSTALL_MOD_PATH=$(O)/install O=$(LINUX_BUILD_PATH)

	CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
	$(MAKE) -C linux zinstall INSTALL_PATH=$(O)/install \
	O=$(LINUX_BUILD_PATH)

	CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
	$(MAKE) -C linux "freescale/grapeboard.dtb" O=$(LINUX_BUILD_PATH)

	cp $(LINUX_BUILD_PATH)/arch/arm64/boot/Image* $(O)/install
	cp $(LINUX_BUILD_PATH)/arch/arm64/boot/dts/freescale/grapeboard.dtb \
	$(O)/install

# Usage: sudo make update-linux-sdcard DEV=/dev/sdX
# Update linux on an SD card. You built a new version of the kernel
# using the compile-linux target, and you want to update the kernel
# on your SD card. Insert the SD card into the PC, determine the device
# (e.g. /dev/sdd), and run this target.
.PHONY: update-linux-sdcard
update-linux-sdcard:
	-mkdir -p /media/$(USER)/sdx2
	-mkdir -p /media/$(USER)/sdx3
	mount $(DEV)2 /media/$(USER)/sdx2
	mount $(DEV)3 /media/$(USER)/sdx3

	# copy new kernel image
	mv /media/$(USER)/sdx2/Image /media/$(USER)/sdx2/Image.old
	cp $(O)/install/Image /media/$(USER)/sdx2

	# copy new modules
	CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
        $(MAKE) -C linux modules_install \
        INSTALL_MOD_PATH=/media/$(USER)/sdx3 O=$(LINUX_BUILD_PATH)

	umount /media/$(USER)/sdx2
	umount /media/$(USER)/sdx3
	udisksctl power-off -b $(DEV)

# XXX this is not necessary
.PHONY: ramdisk_rootfs
ramdisk_rootfs: $(O)/ramdisk_rootfs_arm64.ext4.gz

# stuff PFE binaries and kernel modules into rootfs, and zip it up
$(O)/ramdisk_rootfs_arm64.ext4.gz: \
	$(O)/download/ramdisk_rootfs_arm64.ext4.gz \
	qoriq-engine-pfe-bin/ls1012a/slow_path/ppfe_class_ls1012a.elf \
	qoriq-engine-pfe-bin/ls1012a/slow_path/ppfe_tmu_ls1012a.elf \

	# extract the ramdisk from the source file
	-sudo umount $(O)/mntrd
	-rm -f $(O)/ramdisk_rootfs_arm64.ext4
	gunzip --force --keep $(O)/download/ramdisk_rootfs_arm64.ext4.gz
	mv $(O)/download/ramdisk_rootfs_arm64.ext4 $(O)/

	# mount the ramdisk
	rm -rf $(O)/mntrd
	mkdir $(O)/mntrd
	sudo mount $(O)/ramdisk_rootfs_arm64.ext4 $(O)/mntrd

	# copy in the PFE firmware files
	sudo mkdir -p $(O)/mntrd/lib/firmware
	sudo cp qoriq-engine-pfe-bin/ls1012a/slow_path/* \
		$(O)/mntrd/lib/firmware

	# copy in the pfe kernel module
	kernelrelease=$$(cat $(LINUX_BUILD_PATH)/include/config/kernel.release) && \
	dir=lib/modules/$$kernelrelease/kernel/drivers/staging/fsl_ppfe && \
	sudo mkdir -p $(O)/mntrd/$$dir && \
	sudo cp $(O)/install/$$dir/pfe.ko $(O)/mntrd/$$dir

	# unmount the ramdisk and zip it up
	sudo umount $(O)/mntrd
	gzip $(O)/ramdisk_rootfs_arm64.ext4

# download ramdisk_rootfs_arm64.ext4.gz from NXP
$(O)/download/ramdisk_rootfs_arm64.ext4.gz:
	# only download if it doesn't already exist. To force it to be
	# re-downloaded, delete $(O)/download
	if [ ! -f $@ ]; then \
	    wget -c -P $(O)/download \
	    http://www.nxp.com/lgfiles/sdk/lsdk/ramdisk_rootfs_arm64.ext4.gz; \
	fi

# rootfs is the combination of
#   Base Image:
#       Ubuntu Base
#       Essential packages (udev, ssh, vim, ifupdown ...)
#       Network configuration
#       Users
#
#   Our additions:
#       Kernel modules
#       PFE firmware
#       OPTEE client lib
#       OPTEE test
#       FTPM
.PHONY: rfs
rfs: $(O)/rootfs.tar.gz
$(O)/rootfs.tar.gz: rfs-base rfs-additions
	# pack up rootfs into tar.gz
	cd $(RFS_DIR) && sudo tar -cf $@ .
	sudo chown $(USER):$(USER) $@

# We use /usr/bin/ssh as a proxy for whether the base image has been built.
# This typically only needs to done once.
# You can force rebuild of base image by deleting $(RFS_DIR)
.PHONY: rfs-base
rfs-base: $(RFS_DIR)/usr/bin/ssh
$(RFS_DIR)/usr/bin/ssh:
	rfs-prereqs \
	$(O)/download/$(UBUNTU_BASE_FILENAME) \

	sudo rm -rf $(RFS_DIR)
	mkdir -p $(RFS_DIR)

	# unpack ubuntu base to rfs dir
	sudo tar -C $(RFS_DIR) -xf $(O)/download/$(UBUNTU_BASE_FILENAME)

	# prepare for chroot
	sudo cp /etc/resolv.conf $(RFS_DIR)/etc/resolv.conf
	sudo cp /usr/bin/qemu-aarch64-static $(RFS_DIR)/usr/bin/
	sudo cp /usr/bin/qemu-arm-static $(RFS_DIR)/usr/bin/

	# setup users
	sudo chroot $(RFS_DIR) useradd -m -d /home/user -s /bin/bash user
	sudo chroot $(RFS_DIR) gpasswd -a user sudo
	echo "echo -e 'root\nroot\n' | passwd root" | sudo chroot $(RFS_DIR)
	echo "echo -e 'user\nuser\n' | passwd user" | sudo chroot $(RFS_DIR)

	# install packages
	sudo chroot $(RFS_DIR) apt-get --assume-yes install \
		sudo ssh vim udev kmod ifupdown net-tools

	# configure network
	sudo echo "auto eth0" >> $(RFS_DIR)/etc/network/interfaces
	sudo echo "iface eth0 inet dhcp" >> $(RFS_DIR)/etc/network/interfaces

.PHONY: rfs-additions
rfs-additions: \
	qoriq-engine-pfe-bin/ls1012a/slow_path/ppfe_class_ls1012a.elf \
	qoriq-engine-pfe-bin/ls1012a/slow_path/ppfe_tmu_ls1012a.elf \

	# install kernel modules
	sudo CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
	$(MAKE) -C linux modules_install \
	INSTALL_MOD_PATH=$(RFS_DIR) O=$(LINUX_BUILD_PATH)

	# copy PFE firmware
	sudo mkdir -p $(RFS_DIR)/lib/firmware
	sudo cp qoriq-engine-pfe-bin/ls1012a/slow_path/* \
		$(RFS_DIR)/lib/firmware

.PHONY: rfs-prereqs
rfs-prereqs: /usr/bin/qemu-aarch64-static
/usr/bin/qemu-aarch64-static:
	sudo apt-get --assume-yes \
		binfmt-support qemu-system-common qemu-user-static
	update-binfmts --enable qemu-aarch64

# download Ubuntu Base RootFS archive from Ubuntu
$(O)/download/$(UBUNTU_BASE_FILENAME):
	# only download if it doesn't already exist. To force it to be
	# re-downloaded, delete $(O)/download
	if [ ! -f $@ ]; then \
	    wget -c -P $(O)/download $(UBUNTU_BASE_URL); \
	fi


.PHONY: clean
clean:
	rm -rf build
