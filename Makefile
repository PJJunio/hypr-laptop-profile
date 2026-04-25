PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
TARGET := $(BINDIR)/laptop-profile

.PHONY: install uninstall

install:
	mkdir -p "$(BINDIR)"
	install -m 755 bin/laptop-profile "$(TARGET)"

uninstall:
	rm -f "$(TARGET)"
