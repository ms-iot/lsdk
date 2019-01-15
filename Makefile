# Makefile for building complete linux image for Scalys Grapeboard
# with LS1012A. Builds firmware components, linux kernel, and
# linux rootfs.

ROOT ?= ..
BUILD_PATH ?= $(ROOT)/build

CST_SRC_PATH ?= $(ROOT)/cst
UBOOT_SRC_PATH ?= $(ROOT)/u-boot
UBOOT_BUILD_PATH ?= $(BUILD_PATH)/u-boot

all: u-boot $(BUILD_PATH)/hdr_spl.out

.PHONY: u-boot
u-boot:
	CROSS_COMPILE=aarch64-linux-gnu- ARCH=aarch64 \
	$(MAKE) -C $(UBOOT_SRC_PATH) \
	grapeboard_pcie_qspi_spl_secureboot_defconfig O=$(UBOOT_BUILD_PATH)

	CROSS_COMPILE=aarch64-linux-gnu- ARCH=aarch64 \
	$(MAKE) -C $(UBOOT_SRC_PATH) O=$(UBOOT_BUILD_PATH)

$(BUILD_PATH)/hdr_spl.out: u-boot cst \
			   tools/secureboot/srk.pub \
			   tools/secureboot/srk.pri \
			   input_spl_secure
	rm -rf $(BUILD_PATH)/cst
	mkdir $(BUILD_PATH)/cst
	cp tools/secureboot/srk.pub $(BUILD_PATH)/cst
	cp tools/secureboot/srk.pri $(BUILD_PATH)/cst
	cp tools/secureboot/input_spl_secure $(BUILD_PATH)/cst
	cp $(UBOOT_BUILD_PATH)/spl/u-boot-spl.bin $(BUILD_PATH)/cst
	cd $(BUILD_PATH)/cst && ../../cst/create_hdr_isbc input_spl_secure
	mv $(BUILD_PATH)/cst/hdr_spl.out $@

.PHONY: cst
cst:
	$(MAKE) -C $(CST_SRC_PATH)

