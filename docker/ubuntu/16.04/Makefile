include $(FBDIR)/configs/$(CONFIGLIST)

VERSION=$(fbdockerimgversion)
REPO=$(fbdockerrepo)
USER=$(shell whoami)

build:
	docker build -t $(USER)/$(REPO):$(VERSION) .
