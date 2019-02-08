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

all: firmware linux rfs

.PHONY: firmware os
firmware: u-boot-signed ppa-optee bootscript
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

.PHONY: bootscript
bootscript: $(O)/grapeboard_boot.scr
$(O)/grapeboard_boot.scr: grapeboard_boot.txt
	$(UBOOT_BUILD_PATH)/tools/mkimage -A arm64 -T script -C none -d $< $@

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
	CFG_TEE_CORE_LOG_LEVEL=2

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
$(O)/rootfs.tar.gz: rfs-additions
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

	@echo "Unpacking Ubuntu base to rootfs directory"
	sudo tar -C $(RFS_DIR) -xf $(O)/download/$(UBUNTU_BASE_FILENAME)

	@echo "Preparing rootfs for chroot"
	sudo cp /etc/resolv.conf $(RFS_DIR)/etc/resolv.conf
	sudo cp /usr/bin/qemu-aarch64-static $(RFS_DIR)/usr/bin/
	sudo cp /usr/bin/qemu-arm-static $(RFS_DIR)/usr/bin/

	@echo "Setting up user accounts"
	sudo chroot $(RFS_DIR) useradd -m -d /home/user -s /bin/bash user
	sudo chroot $(RFS_DIR) gpasswd -a user sudo
	echo "echo -e 'root\nroot\n' | passwd root" | sudo chroot $(RFS_DIR)
	echo "echo -e 'user\nuser\n' | passwd user" | sudo chroot $(RFS_DIR)

	@echo "Installing packages"
	sudo chroot $(RFS_DIR) apt-get --assume-yes install \
		sudo ssh vim udev kmod ifupdown net-tools

	@echo "Configuring network"
	sudo echo "auto eth0" >> $(RFS_DIR)/etc/network/interfaces
	sudo echo "iface eth0 inet dhcp" >> $(RFS_DIR)/etc/network/interfaces

.PHONY: rfs-additions
rfs-additions: rfs-base \
	optee_client \
	optee_test \
	ftpm \
	cyres_test \
	qoriq-engine-pfe-bin/ls1012a/slow_path/ppfe_class_ls1012a.elf \
	qoriq-engine-pfe-bin/ls1012a/slow_path/ppfe_tmu_ls1012a.elf \

	@echo "Installing kernel modules to rootfs"
	sudo CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 \
	$(MAKE) -C linux modules_install \
	INSTALL_MOD_PATH=$(RFS_DIR) O=$(LINUX_BUILD_PATH)

	@echo "Copying PFE firmware to rootfs"
	sudo mkdir -p $(RFS_DIR)/lib/firmware
	sudo cp qoriq-engine-pfe-bin/ls1012a/slow_path/* \
		$(RFS_DIR)/lib/firmware

	@echo "Installing OPTEE client"
	sudo $(MAKE) -C optee_client install DESTDIR=$(RFS_DIR)/usr \
		CROSS_COMPILE=aarch64-linux-gnu- O=$(O)/optee_client

	@echo "Installing OPTEE test suite"
	sudo $(MAKE) -C optee_test install \
	DESTDIR=$(RFS_DIR) \
	CROSS_COMPILE=aarch64-linux-gnu- \
	TA_DEV_KIT_DIR=$(O)/optee/export-ta_arm64 \
	OPTEE_CLIENT_EXPORT=$(O)/optee_client/export \
	O=$(O)/optee_test

	@echo "Installing FTPM"
	sudo mkdir -p $(RFS_DIR)/lib/optee_armtz
	sudo cp $(O)/fTPM/bc50d971-d4c9-42c4-82cb-343fb7f37896.ta \
		$(RFS_DIR)/lib/optee_armtz

	@echo "Installing cyres_test"
	sudo cp cyres_test/host/cyres_test $(RFS_DIR)/usr/bin
	sudo cp cyres_test/ta/*.ta $(RFS_DIR)/lib/optee_armtz

.PHONY: rfs-prereqs
rfs-prereqs: /usr/bin/qemu-aarch64-static
/usr/bin/qemu-aarch64-static:
	@echo "Installing rootfs build tools"
	sudo apt-get --assume-yes \
		binfmt-support qemu-system-common qemu-user-static
	update-binfmts --enable qemu-aarch64

# download Ubuntu Base RootFS archive from Ubuntu
$(O)/download/$(UBUNTU_BASE_FILENAME):
	# only download if it doesn't already exist. To force it to be
	# re-downloaded, delete $(O)/download
	@if [ ! -f $@ ]; then \
	    echo "Downloading Ubuntu Base RootFS"; \
	    wget -c -P $(O)/download $(UBUNTU_BASE_URL); \
	fi

# Usage: make sdcard DEV=/dev/sdX
#
# Prepare a bootable SD card. You must have already built
# firmware, kernel, and rootfs
.PHONY: sdcard
sdcard:
	@if [ -z '$(DEV)' ]; then \
	    echo "DEV not specified. Usage: make sdcard DEV=/dev/sdx"; \
	    false; \
	fi

	@echo "Formatting SD card"
	sudo parted -s $(DEV) mklabel gpt
	# 1000MB boot partition for kernel and devicetree
	sudo parted -s $(DEV) mkpart primary ext4 1MiB 100MiB
	sudo parted -s $(DEV) set 1 boot on
	# Rest of disk for rootfs
	sudo parted -s $(DEV) mkpart primary ext4 100MiB 100%

	sleep 1
	sudo mkfs.ext4 -F -L boot $(DEV)1
	sudo mkfs.ext4 -F -L rootfs $(DEV)2

	-sudo mkdir -p /media/$(USER)/sdx1
	sudo mount $(DEV)1 /media/$(USER)/sdx1

	@echo "Setting up boot partition"
	-sudo mv /media/$(USER)/sdx1/Image /media/$(USER)/sdx1/Image.old
	sudo cp $(O)/install/Image /media/$(USER)/sdx1
	sudo cp $(O)/install/grapeboard.dtb /media/$(USER)/sdx1
	sudo cp $(O)/grapeboard_boot.scr /media/$(USER)/sdx1
	@echo "Flushing and unmounting boot partition ..."
	sudo umount /media/$(USER)/sdx1

	# copy rootfs
	@echo "Setting up rootfs"
	-sudo mkdir -p /media/$(USER)/sdx2
	sudo mount $(DEV)2 /media/$(USER)/sdx2
	sudo tar -C /media/$(USER)/sdx2 -xf $(O)/rootfs.tar.gz
	@echo "Flushing and unmounting rootfs ..."
	sudo umount /media/$(USER)/sdx2

	sudo udisksctl power-off -b $(DEV)
	@echo "SD Card successfully created. It is safe to remove."

# Usage: make eject DEV=/dev/sdd
# Eject and power off an SD card
.PHONY: eject
eject:
	-sudo udisksctl unmount -b $(DEV)
	-sudo udisksctl unmount -b $(DEV)
	-sudo udisksctl unmount -b $(DEV)
	-sudo udisksctl power-off -b $(DEV)
	@echo "SD card successfully ejected. It is safe to remove."

.PHONY: optee_client
optee_client:
	$(MAKE) -C optee_client \
		CROSS_COMPILE=aarch64-linux-gnu- O=$(O)/optee_client

.PHONY: optee_test
optee_test: optee_client optee
	$(MAKE) -C optee_test \
	CROSS_COMPILE=aarch64-linux-gnu- \
	TA_DEV_KIT_DIR=$(O)/optee/export-ta_arm64 \
	OPTEE_CLIENT_EXPORT=$(O)/optee_client/export \
	O=$(O)/optee_test

.PHONY: ftpm
ftpm: optee
	TA_DEV_KIT_DIR=$(OPTEE_BUILD_PATH)/export-ta_arm64 \
	TA_CPU=cortex-a53 TA_CROSS_COMPILE=aarch64-linux-gnu- \
	$(MAKE) -C ms-tpm-20-ref/Samples/ARM32-FirmwareTPM/optee_ta/fTPM \
	O=$(O)/fTPM

.PHONY: cyres_test
cyres_test: optee
	TA_DEV_KIT_DIR=$(OPTEE_BUILD_PATH)/export-ta_arm64 \
	TEEC_EXPORT=$(O)/optee_client/export \
	HOST_CROSS_COMPILE=aarch64-linux-gnu- \
	$(MAKE) -C cyres_test

.PHONY: clean
clean:
	rm -rf build
