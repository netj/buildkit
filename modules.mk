# buildkit/modules.mk -- Reusable makefile for handling multiple modules
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2010-07-25

BUILDKIT?=$(shell pwd)/buildkit
SHELL:=$(shell which bash)
PATH:=$(BUILDKIT):$(PATH)
CDPATH:=
export SHELL PATH CDPATH

STAGEDIR?=.stage
BUILDDIR?=.build
BUILD_TIMESTAMP_FMT:="$(BUILDDIR)/%s/build.timestamp"

PREFIX?=/usr/local
PACKAGENAME?=$(shell basename $(PWD))
PACKAGEVERSION?=$(shell $(BUILDKIT)/determine-package-version)
MODULES:=$(shell $(BUILDKIT)/all-modules | $(BUILDKIT)/order-by-depends)
export PREFIX


.PHONY: all build index stage clean package install

all: stage

stage: build

build:
	@\
	    buildable-modules $(MODULES) | \
	    xargs modified-modules $(BUILD_TIMESTAMP_FMT) | \
	    xargs build-modules $(BUILD_TIMESTAMP_FMT) \
	    # TODO we'll soon need to consider dependencies between modules :(
ifndef BUILD_BEFORE_STAGING
	### BuildKit: built all modules

include $(BUILDDIR)/stage.mk
index \
$(BUILDDIR)/stage.mk: $(BUILDKIT)/generate-staging-rules $(BUILDKIT)/modules.mk $(MODULES:%=%/.module.install)
	### BuildKit: generating staging rules
	@mkdir -p $(BUILDDIR)
	@# To determine correct staging rules, we need a prior build
	@$(MAKE) BUILD_BEFORE_STAGING=required build
	@\
	    STAGEDIR=$(STAGEDIR) BUILDDIR=$(BUILDDIR) \
	    generate-staging-rules >$(BUILDDIR)/stage.mk $(MODULES) \
	    #
endif


ifdef PACKAGEEXECUTES
# use pojang for creating an executable package
PACKAGE := $(PACKAGENAME)-$(PACKAGEVERSION).sh
package: $(PACKAGE)
$(PACKAGE): stage
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
$(PACKAGE): stage
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

