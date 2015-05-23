# Includable piece of BuildKit's Makefile for running tests written in BATS.
# For BATS, see: https://github.com/sstephenson/bats
#
# Any BATS testcase placed at tests/*.bats either at the root of the source
# tree (`$SRCROOT`), or in each module will be run when you do `make test`.
# Each BATS test case will run in a freshly created, temporary working
# directory.  `PATH` environment will be set up to include `@prefix@/bin` (or
# more precisely, `$(STAGEDIR)/$(BINDIR)`), and `SRCROOT` will be set to the
# path to the root of the source tree, and `TESTROOT` to the containing
# directory of the BATS testcase.
#
# To add BATS to BuildKit's build dependency of your project, create the
# following symlinks under your .depends/:
#   ln -sfnv ../buildkit/depends/common/bats.commands .depends/
#   ln -sfnv ../buildkit/depends/common/bats.sh       .depends/

$(TESTED): $(patsubst %,$(BUILDDIR)/timestamp/%.tested,\
    $(wildcard test/*.bats $(MODULES:%=%/test/*.bats)))

# prefix command for running BATS
TEST_THROUGH ?=

BINDIR ?= bin
$(BUILDDIR)/timestamp/%.bats.tested: %.bats $(POLISHED)
	tmpdir=$$(mktemp -d "$${TMPDIR:-/tmp}"/buildkit-test.XXXXXX) && \
trap 'rm -rf "$$tmpdir"' EXIT && cd "$$tmpdir" && \
PATH='$(realpath $(STAGEDIR))/$(BINDIR)':"$$PATH" \
SRCROOT='$(SRCROOT)' \
TESTROOT='$(realpath $(<D))' \
$(TEST_THROUGH) \
bats $(realpath $<) \
# Running test: $*.bats
	@mkdir -p $(@D) && touch $@

