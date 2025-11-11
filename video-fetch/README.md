Here’s a clean, concise README section for your updated `toast-debug` script:

---

# toast-debug

**toast-debug** is a robust, diagnostic video playback script for Linux. It automatically detects your available player (`mpv` or `Celluloid`) and provides normal or silent playback with hardware/software decoding fallback. It logs all actions to a file for easy debugging.

## Features

* Automatic detection of `mpv` or `Celluloid`
* Normal (visible) and silent (background) playback modes
* Hardware/software decoding fallback (mpv only)
* Debug mode (`--debug`) for verbose output
* Custom logfile support (`--logfile <path>`)
* Persistent last playback mode selection

## Installation

1. Ensure your video is in the default location (or adjust `VIDEO` in the script):

   ```text
   ~/Videos/StephenToast/toast.mp4
   ```
2. Make the script executable:

   ```bash
   chmod +x toast-debug
   ```
3. Optionally, place it in a folder in your PATH:

   ```bash
   sudo mv toast-debug /usr/local/bin/
   ```

## Usage

Run the script interactively:

```bash
toast-debug
```

Options:

* `--debug` or `-d` – Enable verbose debug mode
* `--logfile <path>` or `-l <path>` – Specify a custom log file location

Example:

```bash
toast-debug --debug --logfile ~/toast-debug.log
```

The script will prompt for:

1. Playback mode: Last playback, Normal, or Silent
2. Confirmation to run in debug mode or not (if specified via CLI)

Logs are saved by default to:

```text
~/.local/share/video-fetch/video-fetch-debug.log
```

and rotated automatically, keeping up to 5 previous logs.

---

## Notes

* **Preferred player:** `mpv` — full CLI support and hardware/software fallback
* **Fallback player:** `Celluloid` — GUI wrapper, no automatic decoding fallback
* **Silent mode** runs in the background without showing a window
* Works on Linux Mint and other Debian/Ubuntu-based distributions

---

_**Documentation Maintained By:** Raymond C. Turner_

_**November 11th, 2025**_