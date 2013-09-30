# buildkit/modules.mk -- Reusable makefile for handling multiple modules
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2010-07-25

SRCROOT:=$(shell pwd)
BUILDKIT?=$(SRCROOT)/buildkit
SHELL:=$(shell which bash)
PATH:=$(BUILDKIT):$(PATH)
CDPATH:=
export SHELL PATH

STAGEDIR?=@prefix@
BUILDDIR?=.build
#DEPENDSDIR?=.depends

PREFIX?=/usr/local
PACKAGENAME?=$(shell basename $(SRCROOT))
PACKAGEVERSION?=$(shell $(BUILDKIT)/determine-package-version)
PACKAGEVERSIONSUFFIX?=
MODULES?=
export PREFIX


.PHONY: all depends build index stage polish test clean package install
DEPENDS := $(BUILDDIR)/depends.found-all
STAGED  := $(BUILDDIR)/staged

all: test

test: polish

polish: stage

stage: build

ifdef STAGING
stage: $(STAGED)
# staging rules
-include $(BUILDDIR)/stage.mk
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

# Watch module modifications, or simply invalidate previous timestamps
watch_files := $(shell \
    mkdir -p $(BUILDDIR) $(STAGEDIR); \
    PATH=$(PATH) \
    BUILDKIT=$(realpath $(BUILDKIT)) \
    BUILDDIR=$(realpath $(BUILDDIR)) \
    STAGEDIR=$(realpath $(STAGEDIR)) \
    $(BUILDKIT)/watch-modifications \
)

build:
	### BuildKit: built all modules

endif # STAGING


# build rules
-include $(BUILDDIR)/build.mk
$(BUILDDIR)/build.mk: $(BUILDDIR)/modules \
                      $(BUILDKIT)/generate-build-rules $(BUILDKIT)/modules.mk
	### BuildKit: generating build rules
	@mkdir -p $(@D)
	@xargs generate-build-rules <$< >$@


# keep track of a list of modules
$(BUILDDIR)/modules:
	@mkdir -p $(@D)
ifneq ($(MODULES),)
	### BuildKit: MODULES="$(MODULES)"
	@printf '%s\n' $(MODULES) >$@
else
	@all-modules >$@
endif


# prepare build dependencies if necessary
ifndef DEPENDSDIR
$(DEPENDS):
	@touch $@
else
PATH:=$(shell cd $(DEPENDSDIR) && pwd)/.all/bin:$(PATH)
build: $(DEPENDS)
depends:
	@rm -f $(DEPENDS)
	@$(MAKE) $(DEPENDS)
$(DEPENDS): $(BUILDKIT)/check-depends $(BUILDKIT)/generate-depends-checker \
    $(wildcard $(DEPENDSDIR)/*.commands $(DEPENDSDIR)/*.paths $(DEPENDSDIR)/*.test.sh)
	@BUILDDIR=$(BUILDDIR)  $< $(DEPENDSDIR) $(DEPENDSDIR)/.all
	@touch $@
# XXX To add more "depends" tasks, so they run before all the tasks "build"
# depends on, you need to add the dependency edge to yours from $(DEPENDS),
# instead of "depends", e.g.,
#
# 	$(DEPENDS): your-task
# 	your-task:
# 		...
endif


PACKAGE = $(PACKAGENAME)-$(PACKAGEVERSION)$(PACKAGEVERSIONSUFFIX)$(PACKAGEEXTENSION)
PACKAGE_LATEST = $(PACKAGENAME)-LATEST$(PACKAGEVERSIONSUFFIX)$(PACKAGEEXTENSION)
define DO_SYMLINK_PACKAGE_LATEST
	[ ! -L $(PACKAGE_LATEST) -a -e $(PACKAGE_LATEST) ] || ln -sfn $@ $(PACKAGE_LATEST)
endef

ifdef PACKAGEEXECUTES
PACKAGEEXTENSION := .sh
# use pojang for creating an executable package
package: $(PACKAGE)
$(PACKAGE): polish
	@\
	    PACKAGENAME=$(PACKAGENAME) \
	    pojang $@ $(STAGEDIR) $(PACKAGEEXECUTES) . \
	    #
	@$(DO_SYMLINK_PACKAGE_LATEST)
	### BuildKit: packaged as $(PACKAGE)

# we want to do create the package everytime
all: package

install: $(PACKAGE)
	### BuildKit: installing at $(PREFIX)/bin/$(PACKAGENAME)
	@mkdir -p $(PREFIX)/bin
	@install $< $(PREFIX)/bin/$(PACKAGENAME)
else
# otherwise, just create an ordinary tarball
PACKAGEEXTENSION := .tar.gz
package: $(PACKAGE)
$(PACKAGE): polish
	@tar czf $@ -C $(STAGEDIR) .
	@$(DO_SYMLINK_PACKAGE_LATEST)
	### BuildKit: packaged as $(PACKAGE)

install: $(PACKAGE)
	### BuildKit: installing at $(PREFIX)
	@mkdir -p $(PREFIX)
	@tar xzf $< -C $(PREFIX)
endif


clean:
	@-! [ -s $(BUILDDIR)/watch.pid ] || kill -TERM -$$(cat $(BUILDDIR)/watch.pid)
	rm -rf -- $(STAGEDIR) $(BUILDDIR) $(PACKAGE)
	### BuildKit: cleaned

cleaner:
	@find $(shell cat $(BUILDDIR)/modules 2>/dev/null || echo .) \
	    -type d -name .build | xargs -t rm -rf --
	@$(MAKE) clean
	### BuildKit: cleaned all build artifacts

clean-depends:
	@git clean -xdf $(DEPENDSDIR)
	@rm -f $(DEPENDS)
	### BuildKit: cleaned dependencies

clean-packages:
	rm -f $(PACKAGENAME)-*.{sh,tar.gz}

gitclean:
	@git clean -xdf
	### BuildKit: cleaned with git

.PHONY: cleaner clean-depends clean-packages gitclean

# generate some useful files to be used with BuildKit
.gitignore .lvimrc:
	cd $(shell $(BUILDKIT)/relpath $(SRCROOT) $(BUILDKIT)/template) && { \
	    echo @@dot@@=.; \
	    echo @@PACKAGENAME@@=$(PACKAGENAME); \
	    echo @@DEPENDSDIR@@=$(DEPENDSDIR); \
	    echo @@BUILDDIR@@=$(BUILDDIR); \
	    echo @@STAGEDIR@@=$(STAGEDIR); \
	} | customize $(shell $(BUILDKIT)/relpath $(BUILDKIT)/template $(SRCROOT)) $(@:.%=@@dot@@%)
