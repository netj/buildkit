# buildkit/modules.mk -- Reusable makefile for handling multiple modules
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2010-07-25

SRCROOT:=$(shell pwd)
PROJECTNAME?=$(shell basename $(SRCROOT))
BUILDKIT?=$(SRCROOT)/buildkit
SHELL:=$(shell which bash)
PATH:=$(BUILDKIT):$(PATH)
CDPATH:=
export SHELL PATH SRCROOT BUILDKIT

STAGEDIR?=@prefix@
BUILDDIR?=.build
#DEPENDSDIR?=.depends
RUNTIMEDEPENDSDIR?=depends
export RUNTIMEDEPENDSDIR
STAGEIGNORE?=.stage.ignore

PREFIX?=/usr/local
PACKAGENAME?=$(PROJECTNAME)
PACKAGEVERSION_DEFAULT?=$(shell $(BUILDKIT)/determine-package-version)
PACKAGEVERSION?=$(PACKAGEVERSION_DEFAULT)
PACKAGEVERSIONSUFFIX?=
MODULES?=
export PREFIX

# shell template arguments
SHELL_MODULEPATH?=shell
SHELL_NAME?=$(PACKAGENAME)
SHELL_BINDIR?=bin
SHELL_RUNTIMEDIR?=bin/$(SHELL_NAME).d
SHELL_ENVVARPREFIX?=$(shell n=`echo $(SHELL_NAME) | tr a-z A-Z`; [ x"$$n" = x"$${n\#[^A-Za-z]}" ] || n="_$$n"; echo "$$n")

.PHONY: all depends build refresh stage polish test clean package install
DEPENDS := $(BUILDDIR)/depends.found-all
STAGED  := $(BUILDDIR)/staged
POLISHED := $(BUILDDIR)/polished
TESTED  := $(BUILDDIR)/tested

all: test

test: $(TESTED)
$(TESTED): $(POLISHED)
	### BuildKit: finished all tests
	@touch $@

polish: $(POLISHED)
$(POLISHED): stage
	### BuildKit: polished $(STAGEDIR)/
	@touch $@

stage: build

ifdef STAGING
stage: $(STAGED)
# staging rules
-include $(BUILDDIR)/stage.mk
$(BUILDDIR)/stage.mk: $(BUILDDIR)/modules \
                      $(BUILDKIT)/generate-staging-rules $(BUILDKIT)/modules.mk
	### BuildKit: generating staging rules
	@mkdir -p $(@D)
	@BUILDDIR=$(BUILDDIR) xargs generate-staging-rules <$< >$(BUILDDIR)/stage.mk
build:

else # !STAGING

refresh:
	### BuildKit: refreshing
	@rm -f $(BUILDDIR)/modules $(BUILDDIR)/stage.mk
	@$(MAKE) STAGING=yes
stage:
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
	### BuildKit: looking for all modules
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


ifdef APPEXECUTES
ifeq ($(shell uname),Darwin)
APPNAME ?= $(PACKAGENAME)
APPIDENT ?= $(PACKAGENAME)
APPCOPYRIGHT ?=
APPICON ?= /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns
APPPATHDIR ?= bin
APP := $(APPNAME).app
APPRSRCS := $(APP)/Contents/Resources
APPTEMPLATE := $(BUILDKIT)/template.os-x-app
define echo_APPPARAMS
{ \
    echo '@@dot@@=.'; \
    echo '@@APPNAME@@=$(APPNAME)'; \
    echo '@@APPIDENT@@=$(APPIDENT)'; \
    echo '@@APPCOPYRIGHT@@=$(APPCOPYRIGHT)'; \
    echo '@@PACKAGEVERSION@@=$(PACKAGEVERSION)'; \
    echo '@@BUNDLEVERSION@@=$(PACKAGEVERSION_DEFAULT)'; \
    echo '@@APPEXECUTES@@=$(APPEXECUTES)'; \
    echo '@@APPPATHDIR@@=$(APPPATHDIR)'; \
}
endef
app: $(APP)
$(APP): $(BUILDDIR)/os-x-app/main.applescript polish Makefile
	### BuildKit: compiling an OS X app
	@rm -rf "$@"
	@osacompile -o "$@" -x -s "$<"
	# customizing OS X app
	@cd "$@"/Contents && $(echo_APPPARAMS) | customize "$(APPTEMPLATE)"/Contents
	@for x in applet droplet; do \
	    [ -x "$@"/Contents/MacOS/$$x ] || continue; \
	    mv -f "$@"/Contents/MacOS/$$x          "$@"/Contents/MacOS/"$(APPNAME)"         ; \
	    mv -f "$@"/Contents/Resources/$$x.rsrc "$@"/Contents/Resources/"$(APPNAME)".rsrc; \
	    mv -f "$@"/Contents/Resources/$$x.icns "$@"/Contents/Resources/"$(APPNAME)".icns; \
	done
	@rsync -aH $(APPICON)                      "$@"/Contents/Resources/"$(APPNAME)".icns
	# bundling $(STAGEDIR) in OS X app
	@mkdir -p "$@"/Contents/Resources/Files
	@rsync -aH --delete "$(STAGEDIR)"/ "$@"/Contents/Resources/Files/
	@touch "$@"
	### BuildKit: compiled OS X app as $@
$(BUILDDIR)/os-x-app/main.applescript: $(APPTEMPLATE).applescript
	@mkdir -p "$(@D)"
	@cd "$(<D)" && { \
	    echo "./$(<F)=./$(@F)"; \
	    $(echo_APPPARAMS); \
	} | customize "$(realpath $(@D))" ./"$(<F)"
clean: clean-app
clean-app:
	rm -rf -- $(APP)
.PHONY: app clean-app

DMG := $(PACKAGENAME)-$(PACKAGEVERSION)$(PACKAGEVERSIONSUFFIX).dmg
DMGTEMPLATE ?= $(BUILDKIT)/template.os-x-app.dmg
dmg: $(DMG)
$(DMG): $(APP) app
	@package-os-x-app-dmg "$<" "$(DMGTEMPLATE)" "$@"
	### BuildKit: packaged disk image for $< as $@
clean-packages: clean-dmgs
clean-dmgs:
	rm -f $(PACKAGENAME)-*.dmg
.PHONY: dmg clean-dmgs
endif
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
APPNAME ?= *
.gitignore .lvimrc:
	cd "$(BUILDKIT)"/template && { \
	    echo '@@dot@@=.'; \
	    echo '@@APPNAME@@=$(APPNAME)'; \
	    echo '@@PACKAGENAME@@=$(PACKAGENAME)'; \
	    echo '@@DEPENDSDIR@@=$(DEPENDSDIR)'; \
	    echo '@@BUILDDIR@@=$(BUILDDIR)'; \
	    echo '@@STAGEDIR@@=$(STAGEDIR)'; \
	} | customize "$(realpath $(SRCROOT))" $(@:.%=@@dot@@%)

depends/.module.install:
	@mkdir -p $(@D)/{bundled,runtime}
	@relsymlink $(BUILDKIT)/depends/module.install              $@
	@relsymlink $(BUILDKIT)/depends/module.build                $(@D)/.module.build
	@relsymlink $(BUILDKIT)/depends/check-runtime-depends-once  $(@D)/
	@cp -f      $(BUILDKIT)/depends/bundle.conf                 $(@D)/
	
	# Created `depends' module that can bundle and/or check runtime dependencies.
	# Add dependency definitions under depends/bundled/ and depends/runtime/, and
	# define a RUNTIMEDEPENDSDIR variable in your Makefile for specifying the path
	# within @prefix@ for your dependencies.
	#
	# Bundled dependencies will be installed at @prefix@/$$RUNTIMEDEPENDSDIR/bundled/
	# so add @prefix@/$$RUNTIMEDEPENDSDIR/bundled/.all/bin to your PATH at runtime to
	# use bundled commands.
	#
	# Runtime dependencies can be easily checked by calling:
	#     @prefix@/$$RUNTIMEDEPENDSDIR/check-runtime-depends-once
	# Add @prefix@/$$RUNTIMEDEPENDSDIR/runtime/.all/bin to your PATH at runtime if
	# you install anything on the fly.


shell/$(SHELL_NAME):
	@mkdir -p $(SHELL_MODULEPATH)
	cd "$(SHELL_MODULEPATH)" && { \
	    echo '@@dot@@=.'; \
	    echo '@@APPNAME@@=$(APPNAME)'; \
	    echo '@@PACKAGENAME@@=$(PACKAGENAME)'; \
	    echo '@@RUNTIMEDEPENDSDIR@@=$(RUNTIMEDEPENDSDIR)'; \
	    echo '@@GENERATED_TIMESTAMP@@=$(shell date +%F)'; \
	    echo '@@SHELL_NAME@@=$(SHELL_NAME)'; \
	    echo '@@SHELL_BINDIR@@=$(SHELL_BINDIR)'; \
	    echo '@@SHELL_RUNTIMEDIR@@=$(SHELL_RUNTIMEDIR)'; \
	    echo '@@SHELL_ENVVARPREFIX@@=$(SHELL_ENVVARPREFIX)'; \
	} | customize "$(realpath $(BUILDKIT)/template.shell)"

