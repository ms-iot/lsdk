# Makefile for building complete linux image for Scalys Grapeboard
# with LS1012A. Builds firmware components, linux kernel, and
# linux rootfs.

O ?= $(CURDIR)/build

CST_SRC_PATH = cst
UBOOT_SRC_PATH = u-boot
UBOOT_BUILD_PATH = $(O)/u-boot
OPTEE_BUILD_PATH = $(O)/optee
LINUX_BUILD_PATH= $(O)/linux

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

.PHONY: ramdisk_rootfs
ramdisk_rootfs: $(O)/ramdisk_rootfs_arm64.ext4.gz

.PHONY: clean
clean:
	rm -rf build
