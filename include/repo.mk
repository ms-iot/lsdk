#####################################
#
# Copyright 2017 NXP
#
#####################################

SHELL=/bin/bash

define fetch-git-tree
	@if [ ! -d $1 ]; then \
		tree=`echo $1 | sed 's/-/_/g'` && \
		branch=`grep -E "^$${tree}_repo_branch" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2` && \
		tag=`grep -E "^$${tree}_repo_tag" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2` && \
		commit=`grep -E "^$${tree}_repo_commit" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2` && \
		repourl=`grep -E "^$${tree}_repo_url" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2` && \
		if [ -z "$$repourl" ]; then repourl=$(GIT_REPOSITORY_URL)/$1; fi && \
		if [ -n "$$tag" ]; then git clone --recurse-submodules $$repourl $1 && cd `realpath $(FBDIR)/packages/*/$1` && git checkout $$tag -b $$tag && cd -; \
		elif [ -n "$$commit" ]; then git clone --recurse-submodules $$repourl $1 && cd `realpath $(FBDIR)/packages/*/$1` && git checkout $$commit -b $$commit && cd -; \
		elif [ -n "$$branch" ]; then git clone --recurse-submodules $$repourl $1 -b $$branch; fi;\
	fi
endef


define repo-update
	@for tree in $2; do \
	    echo -e "\nrepo: $$tree"; tree2=`echo $$tree | sed 's/-/_/g'`; \
	    branch=`grep -E "^$${tree2}_repo_branch" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2` && if [ -n "$$branch" ]; then echo branch = $$branch; fi; \
	    commit=`grep -E "^$${tree2}_repo_commit" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2` && if [ -n "$$commit" ]; then echo commit = $$commit; fi; \
	    tag=`grep -E "^$${tree2}_repo_tag" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2` && if [ -n "$$tag" ]; then echo tag = $$tag; fi; \
	    repourl=`grep -E "^$${tree2}_repo_url" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2` && if [ -z "$$repourl" ]; then \
	    repourl=$(GIT_REPOSITORY_URL)/$$tree; fi; \
	    repo_en=`grep -iE "^CONFIG_BUILD_$${tree2}" $(FBDIR)/configs/$(CONFIGLIST) | cut -d= -f2`; \
	    if [ -d $$tree ]; then \
	        if [ $1 = update -a -n "$$branch" ]; then if [ "$${repo_en}" = "n" ]; then echo $$tree disabled!; \
		    else cd `realpath $(FBDIR)/packages/*/$$tree` && if [ "`cat .git/HEAD | cut -d/ -f3`" != "$$branch" ]; \
		    then if git show-ref --verify --quiet refs/heads/$$branch; \
		    then git checkout $$branch && git pull origin $$branch; \
		    else git checkout remotes/origin/$$branch -b $$branch;fi; else git pull origin $$branch; fi || exit 1; cd -; fi; \
		elif [ $1 = update -a -z "$$branch" -a -n "$$tag" ]; then if [ "$${repo_en}" = "n" ]; then echo $$tree disabled!; \
		    else cd `realpath $(FBDIR)/packages/*/$$tree` && if ! git show-ref --verify --quiet refs/tags/$$tag; then git pull||true;fi && \
		    if [ "`cat .git/HEAD | cut -d/ -f3`" != "$$tag" ]; then \
		    if git show-ref --verify --quiet refs/heads/$$tag; then git checkout $$tag; else git checkout $$tag -b $$tag;fi;fi || exit 1; cd -; fi; \
		elif [ $1 = tag -a -n "$$tag" ]; then if [ "$${repo_en}" = "n" ]; then echo $$tree disabled!; \
		    else cd `realpath $(FBDIR)/packages/*/$$tree` && if ! git show-ref --verify --quiet refs/tags/$$tag; then \
		    git fetch --tags || true;fi && if [ "`cat .git/HEAD | cut -d/ -f3`" != "$$tag" ]; then if git show-ref --verify --quiet refs/heads/$$tag; \
		    then git checkout $$tag; else git checkout $$tag -b $$tag;fi;fi || exit 1; cd -; fi; \
		elif [ $1 = commit -a -n "$$commit" ]; then cd `realpath $(FBDIR)/packages/*/$$tree` && git config advice.objectNameWarning false && \
		    if git show-ref --verify --quiet refs/heads/$$commit; then git checkout $$commit; else git checkout $$commit -b $$commit; fi || exit 1; cd -; \
                elif [ $1 = branch -a -n "$$branch" ]; then if [ "$${repo_en}" = "n" ]; then echo $$tree disabled!; \
                    else cd `realpath $(FBDIR)/packages/*/$$tree` && git checkout $$branch || exit 1; cd -; fi; \
		elif [ $1 = fetch ]; then echo $$tree exists!; \
		else echo unsupported as tag/branch/commit info is not specified in $(CONFIGLIST)!; fi;\
	    elif [ $1 = fetch ]; then \
	        if [ "$${repo_en}" = "n" ]; then echo $$tree disabled!; \
		elif [ -n "$$tag" ]; then git clone --recurse-submodules $$repourl $$tree && cd `realpath $(FBDIR)/packages/*/$$tree` && git checkout $$tag -b $$tag && cd -; \
		elif [ -n "$$commit" ]; then git clone --recurse-submodules $$repourl $$tree && cd `realpath $(FBDIR)/packages/*/$$tree` && git checkout $$commit -b $$commit && cd -; \
		elif [ -n "$$branch" ]; then git clone --recurse-submodules $$repourl $$tree -b $$branch; fi;\
	    fi; \
	done
endef


define build_dependent_rfs
	echo building dependent $(DESTARCH) rootfs && cd $(FBDIR) && flex-builder -i mkrfs -a $(DESTARCH) -f $(CONFIGLIST) && cd -
endef

define build_dependent_linux
        echo building dependent $(DESTARCH) linux && cd $(FBDIR) && flex-builder -c linux -a $(DESTARCH) -f $(CONFIGLIST) && cd -
endef

red=\e[0;41m
RED=\e[1;31m
green=\e[0;32m
GREEN=\e[1;32m
NC=\e[0m

define fbprint_b
        echo -e "$(green)\n Building $1 ... $(NC)"
endef
define fbprint_n
	echo -e "$(green) $1 $(NC)"
endef
define fbprint_d
	echo -e "$(GREEN) Build $1  [Done] $(NC)"
endef
define fbprint_e
        echo -e "$(red) $1 $(NC)"
endef
