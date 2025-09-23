# Makefile for installing all shell scripts in this repo

SCRIPTS=$(wildcard *.sh)
TARGET_DIR=/usr/local/bin

.PHONY: all install uninstall clean list

all:
	@echo "Available targets:"
	@echo "  make list      - Show scripts that will be installed"
	@echo "  make install   - Install all scripts to $(TARGET_DIR)"
	@echo "  make uninstall - Remove installed scripts from $(TARGET_DIR)"
	@echo "  make clean     - Cleanup (no-op here)"

list:
	@echo "Scripts available for installation:"
	@for s in $(SCRIPTS); do echo "  $$s"; done

install:
	@echo "Installing scripts to $(TARGET_DIR)..."
	@for s in $(SCRIPTS); do \
	    echo "  Installing $$s..."; \
	    sudo install -m 755 $$s $(TARGET_DIR)/$$s; \
	done
	@echo "✅ Installation complete."

uninstall:
	@echo "Removing installed scripts from $(TARGET_DIR)..."
	@for s in $(SCRIPTS); do \
	    echo "  Removing $$s..."; \
	    sudo rm -f $(TARGET_DIR)/$$s; \
	done
	@echo "✅ Uninstallation complete."

clean:
	@echo "Nothing to clean."
