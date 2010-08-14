# buildkit/modules.mk -- Reusable makefile for handling multiple modules
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2010-07-25

BUILDKIT?=$(PWD)/buildkit
SHELL:=$(shell which bash)
PATH:=$(BUILDKIT):$(PATH)
export SHELL PATH


PREFIX ?= /usr/local
PACKAGENAME ?= $(shell basename $(PWD))
PACKAGEVERSION ?= $(shell git rev-parse HEAD | cut -b -6 || \
		  date +%Y%m%d)$(shell git status >/dev/null && echo +WIP)
STAGEDIR ?= .stage
BUILDDIR ?= .build
BUILD_TIMESTAMP_FMT:="$(BUILDDIR)/%s/build.timestamp"

MODULES=$(shell $(BUILDKIT)/all-modules)


.PHONY: all build stage clean package install

all: stage


build:
	@\
	    buildable-modules $(MODULES) | \
	    xargs modified-modules $(BUILD_TIMESTAMP_FMT) | \
	    xargs build-modules $(BUILD_TIMESTAMP_FMT)
# TODO we'll soon need to consider dependencies between modules :(


stage: build
include $(BUILDDIR)/stage.mk
$(BUILDDIR)/stage.mk: $(BUILDKIT)/generate-staging-rules $(MODULES:%=%/.module.install)
	mkdir -p $(@D)
	$< >$@ $(MODULES)


PACKAGE := $(PACKAGENAME)-$(PACKAGEVERSION).tar.gz
package: $(PACKAGE)
$(PACKAGE): stage
	tar czvf $@ -C .stage .


install: $(PACKAGE)
	mkdir -p $(PREFIX)
	tar xzvf $< -C $(PREFIX)


clean:
	rm -rf $(STAGEDIR) $(BUILDDIR) $(PACKAGE)

