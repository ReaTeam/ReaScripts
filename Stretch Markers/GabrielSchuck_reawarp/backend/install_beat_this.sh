#!/bin/sh
# reawarp - installs the Beat This! beat detector in this folder.
# No Python installation is needed: uv downloads a private Python here.
# Copyright (C) 2026 Gabriel Schuck. GPL-3.0-or-later (see LICENSE).
# Arguments: [gpu|cpu] [auto]
#   gpu: PyTorch for NVIDIA graphics cards (Linux, about 2.5 GB); cpu: about 300 MB.
#   Without one it keeps the kind already installed (cpu on a new install).
#   On macOS the standard build is used: it also runs on the GPU of Apple silicon.
#   auto: started by reawarp. The window closes at the end and reawarp shows the
#   result (install_status.txt: "ok <device>" or "fail"). The details of every
#   step go to install.log.
cd "$(dirname "$0")" || exit 1
HERE=$(pwd)
# macOS Terminal cannot pass arguments to a script: reawarp leaves them here
if [ $# -eq 0 ] && [ -f "$HERE/install_args.txt" ]; then
  # shellcheck disable=SC2046
  set -- $(cat "$HERE/install_args.txt")
  rm -f "$HERE/install_args.txt"
fi
KIND="${1:-}"
AUTO="${2:-}"
if [ "$KIND" = auto ]; then KIND=""; AUTO=auto; fi
LOG="$HERE/install.log"
STATUS="$HERE/install_status.txt"
rm -f "$STATUS"
echo "reawarp: Beat This! installation" > "$LOG"

say() { # a progress line, on the screen and in the log
  echo "$*"
  echo "$*" >> "$LOG"
}

finish() {
  # nothing here writable by everyone (folders synced to the cloud, as with
  # MEGA, refuse 777): 775 for folders, 664 for files
  chmod -R o-w "$HERE" 2>/dev/null
  if [ "$AUTO" != auto ]; then
    if [ "$1" != 0 ]; then echo; echo "Details:"; cat "$LOG"; fi
    echo
    printf 'Press Enter to close. '
    read -r _
  fi
  exit "$1"
}

say "reawarp: installing the Beat This! beat detector."
say "This downloads about 350 MB and needs about 1 GB of disk space"
say "(the version for NVIDIA graphics cards: about 2.5 GB, and 3 GB of disk)."
say "Everything goes inside this folder; no Python installation is needed."
if [ "$AUTO" = auto ]; then say "This window closes by itself when the installation ends."; fi
echo

UV_VERSION=0.12.20
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) TARGET=aarch64-apple-darwin ;;
  Darwin-x86_64) TARGET=x86_64-apple-darwin ;;
  Linux-x86_64) TARGET=x86_64-unknown-linux-gnu ;;
  Linux-aarch64 | Linux-arm64) TARGET=aarch64-unknown-linux-gnu ;;
  *) say "Unsupported system: $(uname -s) $(uname -m)"; echo fail > "$STATUS"; finish 1 ;;
esac
# keep uv's Python, cache and tools inside this folder, and never use a system Python
export UV_PYTHON_INSTALL_DIR="$HERE/python"
export UV_CACHE_DIR="$HERE/uvcache"
export UV_PYTHON_PREFERENCE=only-managed
export UV_NO_CONFIG=1
UV="$HERE/uv/uv"

set -e
# (the download cache stays after a failure, so a retry does not download everything again)
trap 'say "The installation failed. It needs an internet connection; you can run it again to retry."; echo fail > "$STATUS"; finish 1' EXIT
if [ ! -x "$UV" ]; then
  say "Downloading uv $UV_VERSION..."
  mkdir -p uv
  URL="https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-$TARGET.tar.gz"
  if command -v curl >/dev/null 2>&1; then curl -L --fail -sS -o uv/uv.tar.gz "$URL" >> "$LOG" 2>&1
  else wget -q -O uv/uv.tar.gz "$URL" >> "$LOG" 2>&1; fi
  tar -xzf uv/uv.tar.gz -C uv --strip-components=1 >> "$LOG" 2>&1
  rm uv/uv.tar.gz
fi
# --allow-existing keeps the installed packages and repairs an env whose folder was moved
say "Installing Python..."
"$UV" venv env --python 3.12 --allow-existing >> "$LOG" 2>&1
if [ "$(uname -s)" = "Darwin" ]; then
  say "Installing PyTorch..."
  "$UV" pip install --python env/bin/python torch torchaudio >> "$LOG" 2>&1
else
  CUR=$(env/bin/python -c "import torch; print(torch.version.cuda or 'cpu')" 2>/dev/null || true)
  if [ -z "$KIND" ]; then
    if [ -n "$CUR" ] && [ "$CUR" != cpu ]; then KIND=keep; else KIND=cpu; fi
  fi
  INDEX=cpu
  if [ "$KIND" = gpu ]; then
    # the newest CUDA build that the NVIDIA driver supports
    DRV=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n 1 | cut -d. -f1 || true)
    case "$DRV" in
      '' | *[!0-9]*) say "No NVIDIA graphics card found: installing the CPU version." ;;
      *) if [ "$DRV" -ge 580 ]; then INDEX=cu130
         elif [ "$DRV" -ge 570 ]; then INDEX=cu128
         elif [ "$DRV" -ge 560 ]; then INDEX=cu126
         else say "The NVIDIA driver is too old for the GPU version: installing the CPU version."
         fi ;;
    esac
  fi
  if [ "$KIND" = keep ]; then
    say "PyTorch for the GPU is already installed."
  else
    REINSTALL=""
    if [ "$INDEX" = cpu ] && [ -n "$CUR" ] && [ "$CUR" != cpu ]; then REINSTALL="--reinstall-package torch --reinstall-package torchaudio"; fi
    if [ "$INDEX" != cpu ] && [ "$CUR" = cpu ]; then REINSTALL="--reinstall-package torch --reinstall-package torchaudio"; fi
    if [ "$INDEX" = cpu ]; then say "Installing PyTorch for the CPU..."
    else say "Installing PyTorch for the NVIDIA GPU ($INDEX), about 2.5 GB. This takes a while..."; fi
    # shellcheck disable=SC2086
    "$UV" pip install --python env/bin/python torch torchaudio --index-url "https://download.pytorch.org/whl/$INDEX" $REINSTALL >> "$LOG" 2>&1
  fi
fi
say "Installing Beat This!..."
"$UV" pip install --python env/bin/python beat-this==1.1.0 >> "$LOG" 2>&1
say "Downloading the model..."
env/bin/python reawarp_beat_this.py --download >> "$LOG" 2>&1
DEVICE=$(env/bin/python reawarp_beat_this.py --device 2>/dev/null || echo cpu)
rm -rf uvcache
trap - EXIT
say "Done. Beat This! runs on: $DEVICE."
echo "ok $DEVICE" > "$STATUS"
finish 0
