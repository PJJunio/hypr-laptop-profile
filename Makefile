PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
TARGET := $(BINDIR)/notebook-profile

.PHONY: install uninstall

install:
	mkdir -p "$(BINDIR)"
	install -m 755 bin/notebook-profile "$(TARGET)"

uninstall:
	rm -f "$(TARGET)"
