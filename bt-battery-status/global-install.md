Perfect ✅ — here’s a simple **`Makefile` + installer script** so you can install your `bt-battery.sh` globally into `/usr/local/bin/` with the correct permissions.

---

## 🔹 Makefile

```make
PREFIX=/usr/local
BINDIR=$(PREFIX)/bin
SCRIPT=bt-battery
SRC=bt-battery.sh

install:
	@echo "Installing $(SRC) to $(BINDIR)/$(SCRIPT)..."
	sudo install -m 755 $(SRC) $(BINDIR)/$(SCRIPT)
	sudo chown root:root $(BINDIR)/$(SCRIPT)
	@echo "Installed as $(BINDIR)/$(SCRIPT)"

uninstall:
	@echo "Removing $(BINDIR)/$(SCRIPT)..."
	sudo rm -f $(BINDIR)/$(SCRIPT)
	@echo "Uninstalled."
```

---

## 🔹 Usage

### Install globally

```bash
make install
```

This will:

* Copy `bt-battery.sh` → `/usr/local/bin/bt-battery`
* Set correct permissions (`755`)
* Set ownership (`root:root`)

### Uninstall

```bash
make uninstall
```

---

## 🔹 Alternative Installer Script

If you don’t want `make`, here’s a standalone script:

```bash
#!/bin/bash
# install-bt-battery-global.sh

PREFIX="/usr/local/bin"
SCRIPT_NAME="bt-battery"
SOURCE="bt-battery.sh"
TARGET="$PREFIX/$SCRIPT_NAME"

echo "Installing $SOURCE to $TARGET..."

sudo install -m 755 "$SOURCE" "$TARGET"
sudo chown root:root "$TARGET"

echo "Installed globally as: $SCRIPT_NAME"
echo "You can now run it with: $SCRIPT_NAME"
```

Run it with:

```bash
chmod +x install-bt-battery-global.sh
./install-bt-battery-global.sh
```

---

## 🔹 Result

After installation, you can run your script from anywhere:

```bash
bt-battery
```

