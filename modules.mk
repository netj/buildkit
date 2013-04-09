# buildkit/modules.mk -- Reusable makefile for handling multiple modules
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2010-07-25

BUILDKIT?=$(shell pwd)/buildkit
SHELL:=$(shell which bash)
PATH:=$(BUILDKIT):$(PATH)
CDPATH:=
export SHELL PATH CDPATH

STAGEDIR?=@prefix@
BUILDDIR?=.build

PREFIX?=/usr/local
PACKAGENAME?=$(shell basename $(PWD))
PACKAGEVERSION?=$(shell $(BUILDKIT)/determine-package-version)
MODULES?=
export PREFIX


.PHONY: all build index stage polish test clean package install

all: test

test: polish

polish: stage

stage: build

ifdef STAGING
stage: $(BUILDDIR)/staged
# staging rules
include $(BUILDDIR)/stage.mk
index \
$(BUILDDIR)/stage.mk: $(BUILDDIR)/modules \
                      $(BUILDKIT)/generate-staging-rules $(BUILDKIT)/modules.mk
	### BuildKit: generating staging rules
	@mkdir -p $(@D)
	@BUILDDIR=$(BUILDDIR) xargs generate-staging-rules <$< >$(BUILDDIR)/stage.mk
build:

else # !STAGING

stage index:
	@$(MAKE) STAGING=yes $@

# When watching filesystem isn't possible, invalidate some timestamps 
watch_files := $(shell \
    find $(BUILDDIR) -name '*.lastmodified' -exec rm -vf {} \;; \
)
# We won't touch $(BUILDDIR)/modules, so any change to .module.install or .module.build
# can be reflected by doing a "make clean".

build:
	### BuildKit: built all modules

endif # STAGING


# build rules
include $(BUILDDIR)/build.mk
$(BUILDDIR)/build.mk: $(BUILDDIR)/modules \
                      $(BUILDKIT)/generate-build-rules $(BUILDKIT)/modules.mk
	### BuildKit: generating build rules
	@mkdir -p $(@D)
	@xargs generate-build-rules <$< >$@
$(BUILDDIR)/%.lastmodified:
	@mkdir -p "$(@D)"
	@ln -sfn ../"$(shell sed 's:[^/]*/:../:g; s:[^/]*$$::' <<<"$*" \
	    )$(shell $(BUILDKIT)/most-recently-modified-files "$*" | head -1)" "$@"


# keep track of a list of modules
$(BUILDDIR)/modules:
	@mkdir -p $(@D)
ifneq ($(MODULES),)
	### BuildKit: MODULES="$(MODULES)"
	@printf '%s\n' $(MODULES) >$@
else
	@all-modules >$@
endif


ifdef PACKAGEEXECUTES
# use pojang for creating an executable package
PACKAGE := $(PACKAGENAME)-$(PACKAGEVERSION).sh
package: $(PACKAGE)
$(PACKAGE): polish
	@\
	    PACKAGENAME=$(PACKAGENAME) \
	    pojang $@ $(STAGEDIR) $(PACKAGEEXECUTES) . \
	    #
	### BuildKit: packaged as $(PACKAGE)

# we want to do create the package everytime
all: package

install: $(PACKAGE)
	### BuildKit: installing at $(PREFIX)/bin/$(PACKAGENAME)
	@mkdir -p $(PREFIX)/bin
	@install $< $(PREFIX)/bin/$(PACKAGENAME)
else
# otherwise, just create an ordinary tarball
PACKAGE := $(PACKAGENAME)-$(PACKAGEVERSION).tar.gz
package: $(PACKAGE)
$(PACKAGE): polish
	@tar czf $@ -C $(STAGEDIR) .
	### BuildKit: packaged as $(PACKAGE)

install: $(PACKAGE)
	### BuildKit: installing at $(PREFIX)
	@mkdir -p $(PREFIX)
	@tar xzf $< -C $(PREFIX)
endif


clean:
	@rm -rf $(STAGEDIR) $(BUILDDIR) $(PACKAGE)
	### BuildKit: cleaned

