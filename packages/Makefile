#####################################
#
# Copyright 2017 NXP
#
#####################################

include $(FBDIR)/configs/$(CONFIGLIST)

TGTDIRS := firmware linux apps rfs

all: $(TGTDIRS)

$(TGTDIRS): ECHO
	@$(MAKE) -C $(FBDIR)/packages/$@

ECHO:
	@echo Building $(TGTDIRS)
