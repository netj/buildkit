# Makefile for pojang
# Author: Jaeho Shin <netj@sparcs.org>
# Created: 2009-01-28

NAME=pojang
VERSION=1.0

PRODUCT=$(NAME)-$(VERSION).sh
DEST=~/bin

dist/$(PRODUCT): pojang
	mkdir -p dist
	cp "$<" "$@"
	chmod +x "$@"

.PHONY: install clean

install: dist/$(PRODUCT)
	mkdir -p $(DEST)
	install "$<" $(DEST)/$(NAME)

clean:
	rm -f dist/$(PRODUCT)
	rmdir -p dist

