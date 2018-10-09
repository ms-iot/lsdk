#####################################
#
# Copyright 2017 NXP
#
#####################################

ifndef FBDIR
  FBDIR = $(shell cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)
endif

include $(FBDIR)/configs/$(CONFIGLIST)

all:
	@$(MAKE) -C $(FBDIR)/packages

ifeq ($(CONFIGLIST), build_lsdk.cfg)
uboot uefi ppa ppa-optee ppa-fuse bin-firmware $(FIRMWARE_REPO_LIST):
else
uboot uefi rcw ppa ppa-optee ppa-fuse bin-firmware $(FIRMWARE_REPO_LIST):
endif
	@$(MAKE) -C $(FBDIR)/packages/firmware $@

firmware linux apps:
	@$(MAKE) -C $(FBDIR)/packages/$@

cryptodev-linux perf lttng-modules:
	@$(MAKE) -C $(FBDIR)/packages/linux $@

$(APPS_REPO_LIST) edgescale:
	@$(MAKE) -C $(FBDIR)/packages/apps $@

ramdiskrfs initrds:
	@$(MAKE) -C $(FBDIR)/packages/rfs $@
