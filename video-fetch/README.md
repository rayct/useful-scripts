# video-fetch (Linux-Friendly)

`video-fetch` lets you play a local video with **one command**. You can name the script anything (e.g., `Toast`, `MovieNight`) and choose between **last playback**, **normal**, or **silent/background** modes. On Linux, it prefers **mpv** for reliability and uses VLC as a fallback.

---

## Features

* Plays a designated local video file.
* Auto-closes the player when finished.
* Works with `mpv` (preferred) or VLC (`vlc`/`cvlc`) in Linux.
* Prompts for playback mode: last, normal, or silent.
* Strict input validation.
* Supports multiple scripts for different videos.

---

## Installation

1. **Create the script** in `~/bin`:

```bash
nano ~/bin/Toast
```

Paste the Linux-friendly template:

```bash
#!/usr/bin/env bash
VIDEO="$HOME/Videos/favorite.mp4"
CONFIG="$HOME/.toast_mode"

if [ ! -f "$VIDEO" ]; then
  echo "Error: video not found at $VIDEO"
  exit 1
fi

# Determine player (prefer mpv)
if command -v mpv >/dev/null 2>&1; then
  PLAYER="mpv"
elif command -v vlc >/dev/null 2>&1; then
  PLAYER="vlc"
else
  echo "Error: install mpv or vlc"
  exit 1
fi

# Prompt user for playback mode
MODE=""
while [ -z "$MODE" ]; do
  if [ -f "$CONFIG" ]; then
    LAST_MODE=$(cat "$CONFIG")
    echo "Select playback mode:"
    echo "1) Last playback ($LAST_MODE)"
    echo "2) Normal (visible)"
    echo "3) Silent (background)"
    read -p "Enter choice [1/2/3]: " CHOICE
    case "$CHOICE" in
      1) MODE="$LAST_MODE" ;;
      2) MODE="n" ;;
      3) MODE="s" ;;
      *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
    esac
  else
    read -p "Play normally (visible) or silent (background)? [n/s]: " USER_MODE
    if [[ "$USER_MODE" == "n" || "$USER_MODE" == "s" ]]; then
      MODE="$USER_MODE"
    else
      echo "Invalid input. Please enter 'n' or 's'."
    fi
  fi
done

# Save chosen mode
echo "$MODE" > "$CONFIG"

# Play video based on mode
if [[ "$MODE" == "s" ]]; then
  if [[ "$PLAYER" == "mpv" ]]; then
    mpv --really-quiet --no-terminal --force-window=no --idle=no "$VIDEO" &
  else
    cvlc --play-and-exit --no-video "$VIDEO" >/dev/null 2>&1 &
  fi
else
  if [[ "$PLAYER" == "mpv" ]]; then
    mpv "$VIDEO"
  else
    vlc --play-and-exit "$VIDEO"
  fi
fi
```

2. Make it executable:

```bash
chmod +x ~/bin/Toast
```

3. Ensure `~/bin` is in your PATH:

```bash
export PATH="$HOME/bin:$PATH"
```

Add this line to `~/.bashrc` or `~/.zshrc` for persistence.

---

## Usage

```bash
Toast
```

* Choose playback mode:

  1. Last playback
  2. Normal (visible)
  3. Silent (background)

* Choice is saved for next run.

---

## Multiple Video Scripts

You can create multiple scripts for different videos:

```bash
nano ~/bin/MovieNight
nano ~/bin/PartyTime
chmod +x ~/bin/MovieNight ~/bin/PartyTime
```

Run each:

```bash
Toast
MovieNight
PartyTime
```

---

## Tips

* **Silent/background playback:**

  * mpv: `mpv --really-quiet --no-terminal --force-window=no "$VIDEO" &`
  * VLC: `cvlc --play-and-exit --no-video "$VIDEO" >/dev/null 2>&1 &`

* **Keyboard shortcuts:**

  * mpv: Space=Pause, ←/→=Seek, ↑/↓=Seek by 1 min, m=Mute, q=Quit
  * VLC GUI: Space=Pause, ←/→=Seek 10 sec, ↑/↓=Volume, m=Mute, q/Esc=Quit

---

## Notes

* Works with local video files only.
* Auto-closes the player when finished.
* Prompts for last/normal/silent mode with strict validation.
* Prefers mpv on Linux for reliable playback.

---

_**Documentation Maintained By:** Raymond C. Turner_

_**November 11th, 2025**_