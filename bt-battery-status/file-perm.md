Great question 👍

When you want a script or binary to be **executable by anyone (globally)** on a Linux system, there are two parts to consider:

---

### 1. **File Permissions**

The script itself must be executable for **all users**:

```bash
chmod 755 myscript.sh
```

This sets:

* `7` (rwx) → owner can read/write/execute
* `5` (r-x) → group can read/execute
* `5` (r-x) → others can read/execute

If you want it executable but not editable by others (the normal case), `755` is the standard.
If you only want execution (no read), you could technically do `chmod 111 myscript.sh`, but that’s rarely useful because shells need to read the file.

---

### 2. **Install Location (PATH)**

To make it globally accessible without typing the full path, place it in a directory that’s part of everyone’s `$PATH`, for example:

* `/usr/local/bin/` → for locally installed scripts/programs (recommended)
* `/usr/bin/` → for system-wide binaries (managed by package managers)

Example:

```bash
sudo cp bt-battery.sh /usr/local/bin/bt-battery
sudo chmod 755 /usr/local/bin/bt-battery
```

Now any user can run it just by typing:

```bash
bt-battery
```

---

### 3. **Ownership**

Typically you’ll want the script to be **owned by root** so regular users can’t overwrite it:

```bash
sudo chown root:root /usr/local/bin/bt-battery
```

---

✅ **Summary:**

* Use `chmod 755` for global readability + executability.
* Place in `/usr/local/bin/` for local global commands.
* Set ownership to `root:root` for security.

