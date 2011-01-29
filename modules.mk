# buildkit/modules.mk -- Reusable makefile for handling multiple modules
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2010-07-25

BUILDKIT?=$(shell pwd)/buildkit
SHELL:=$(shell which bash)
PATH:=$(BUILDKIT):$(PATH)
export BUILDKIT SHELL PATH

STAGEDIR ?= .stage
BUILDDIR ?= .build
BUILD_TIMESTAMP_FMT:="$(BUILDDIR)/%s/build.timestamp"
export STAGEDIR BUILDDIR

PREFIX ?= /usr/local
PACKAGENAME ?= $(shell basename $(PWD))
PACKAGEVERSION ?= $(shell git rev-parse HEAD 2>/dev/null | cut -b -6 || \
		  date +%Y%m%d)$(shell git status >/dev/null && echo +WIP)
MODULES:=$(shell $(BUILDKIT)/all-modules | $(BUILDKIT)/order-by-depends)
export PREFIX PACKAGENAME PACKAGEVERSION MODULES


.PHONY: all build stage clean package install

all: stage


build:
	@\
	    buildable-modules $(MODULES) | \
	    xargs modified-modules $(BUILD_TIMESTAMP_FMT) | \
	    xargs build-modules $(BUILD_TIMESTAMP_FMT)
# TODO we'll soon need to consider dependencies between modules :(


stage: build
ifndef BUILD_FOR_STAGING_RULES
include $(BUILDDIR)/stage.mk
$(BUILDDIR)/stage.mk: $(BUILDKIT)/generate-staging-rules $(MODULES:%=%/.module.install)
	mkdir -p $(@D)
	# we need to first build before we determine staging rules
	$(MAKE) BUILD_FOR_STAGING_RULES=1 build
	$< >$@ $(MODULES)
endif


ifdef PACKAGEEXECUTES
# use pojang for creating an executable package
PACKAGE := $(PACKAGENAME)-$(PACKAGEVERSION).sh
package: $(PACKAGE)
$(PACKAGE): stage
	( cd $(STAGEDIR) && pojang $(PACKAGEEXECUTES) . ) >$@
	chmod +x $@

# we want to do create the package everytime
all: package

install: $(PACKAGE)
	mkdir -p $(PREFIX)/bin
	install $< $(PREFIX)/bin/$(PACKAGENAME)
else
# otherwise, just create an ordinary tarball
PACKAGE := $(PACKAGENAME)-$(PACKAGEVERSION).tar.gz
package: $(PACKAGE)
$(PACKAGE): stage
	tar czvf $@ -C $(STAGEDIR) .

install: $(PACKAGE)
	mkdir -p $(PREFIX)
	tar xzvf $< -C $(PREFIX)
endif


clean:
	rm -rf $(STAGEDIR) $(BUILDDIR) $(PACKAGE)

