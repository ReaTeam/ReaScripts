# @noindex
"""reawarp beat detector backend, using Beat This! (CPJKU, ISMIR 2024).

Usage:
  python reawarp_beat_this.py INPUT.wav OUTPUT.txt [CHECKPOINT]
  python reawarp_beat_this.py --download [CHECKPOINT]

INPUT.wav is a mono or stereo 16-bit PCM file written by reawarp. OUTPUT.txt gets
two lines of times in seconds:
  beats <t1> <t2> ...
  downbeats <t1> <t2> ...
On failure, OUTPUT.txt gets a line "error <message>" and the exit code is 1.

The model is stored next to this file (models/), so removing the backend folder
removes everything.

Copyright (C) 2026 Gabriel Schuck. GPL-3.0-or-later (see LICENSE).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
os.environ.setdefault("TORCH_HOME", os.path.join(HERE, "models"))

DEFAULT_CHECKPOINT = "final0"


def read_wav(path):
    import wave

    import numpy as np

    with wave.open(path, "rb") as w:
        sr, nch, width, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(n)
    if width != 2:
        raise ValueError(f"expected 16-bit PCM, got {8 * width}-bit")
    y = np.frombuffer(raw, dtype="<i2").astype(np.float32) / 32768.0
    if nch > 1:
        y = y.reshape(-1, nch).mean(axis=1)
    return y, sr


def refine(times, logits, fps=50):
    """Sub-frame beat times: parabolic interpolation of the logit peak.

    The model works on 20 ms frames; at fast tempos that rounding alone makes
    consecutive beat intervals vary by several percent.
    """
    import numpy as np

    lg = logits.detach().float().cpu().numpy().ravel() if hasattr(logits, "detach") else np.ravel(logits)
    out = []
    for t in times:
        k = int(round(t * fps))
        if 0 < k < len(lg) - 1:
            a, b, c = lg[k - 1], lg[k], lg[k + 1]
            den = a - 2 * b + c
            if den < 0:
                t = (k + max(-0.5, min(0.5, 0.5 * (a - c) / den))) / fps
        out.append(float(t))
    return out


def cached_checkpoint(name):
    """Where torch.hub keeps a downloaded checkpoint (models/hub/checkpoints/)."""
    return os.path.join(os.environ["TORCH_HOME"], "hub", "checkpoints", f"beat_this-{name}.ckpt")


# A copy of the model on reawarp's GitHub, used when the authors' server
# fails (it has refused downloads at times), with its SHA-256
MIRRORS = {
    "final0": ("https://github.com/gabrielschuck/reawarp/releases/download/beat-this-model/beat_this-final0.ckpt",
               "8c328b45f59d8dd3dff219253ff6a8d6482be57d0133a29140e2febbf8eb8331"),
}


def download_mirror(name):
    """Download the model from the mirror into torch.hub's cache, checking its
    SHA-256. Returns False when there is no mirror for this model."""
    import hashlib
    import urllib.request

    if name not in MIRRORS:
        return False
    url, sha = MIRRORS[name]
    path = cached_checkpoint(name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    print(f"The authors' server did not answer; downloading the model from reawarp's copy:\n{url}")
    tmp = path + ".part"
    h = hashlib.sha256()
    with urllib.request.urlopen(url, timeout=60) as r, open(tmp, "wb") as f:
        while True:
            block = r.read(1 << 20)
            if not block:
                break
            h.update(block)
            f.write(block)
    if h.hexdigest() != sha:
        os.remove(tmp)
        raise RuntimeError("the copy of the model did not match its SHA-256")
    os.replace(tmp, path)
    return True


def download(name):
    """Download the model and check that it loads.

    torch.hub reuses a file already in the cache, so a download that arrived
    damaged (connection dropped, proxy, antivirus) would fail on every run:
    when the cached file does not load, it is deleted and downloaded again.
    When the authors' server fails, the copy on reawarp's GitHub is used.
    """
    from beat_this.inference import load_checkpoint

    mirrored = False
    for attempt in (1, 2, 3):
        try:
            load_checkpoint(name)
            return
        except Exception as e:
            path = cached_checkpoint(name)
            if os.path.exists(path):
                if attempt == 3:
                    raise
                print(f"The downloaded model is damaged ({type(e).__name__}); downloading it again...")
                os.remove(path)
            elif not mirrored and download_mirror(name):
                mirrored = True
            else:
                raise


def devices(torch):
    """Devices to try, best first: an NVIDIA GPU (CUDA build of PyTorch), Apple
    silicon (MPS), then the CPU. REAWARP_DEVICE=cpu|cuda|mps forces one."""
    forced = os.environ.get("REAWARP_DEVICE", "").strip().lower()
    if forced:
        return [forced] if forced == "cpu" else [forced, "cpu"]
    out = []
    if torch.cuda.is_available():
        out.append("cuda")
    mps = getattr(torch.backends, "mps", None)
    if mps is not None and mps.is_available():
        out.append("mps")
    return out + ["cpu"]


def main(argv):
    if len(argv) >= 1 and argv[0] == "--device":
        import torch

        print(devices(torch)[0])
        return 0
    if len(argv) >= 1 and argv[0] == "--download":
        download(argv[1] if len(argv) > 1 else DEFAULT_CHECKPOINT)
        print("model ready")
        return 0
    if len(argv) < 2:
        print(__doc__)
        return 2
    src, dst = argv[0], argv[1]
    checkpoint = argv[2] if len(argv) > 2 else DEFAULT_CHECKPOINT
    # tells reawarp (which runs this in the background, without a window) that
    # Python started; reawarp deletes it
    try:
        open(dst + ".run", "w").close()
    except OSError:
        pass
    try:
        import torch
        from beat_this.inference import Audio2Frames, Postprocessor

        torch.set_num_threads(max(1, os.cpu_count() or 1))
        y, sr = read_wav(src)
        beat_logits = down_logits = None
        for device in devices(torch):
            try:
                beat_logits, down_logits = Audio2Frames(checkpoint_path=checkpoint, device=device)(y, sr)
                break
            except Exception:
                if device == "cpu":
                    raise  # a GPU that fails (driver, memory) falls back to the CPU
        beats, downbeats = Postprocessor(type="minimal")(beat_logits, down_logits)
        beats = refine(beats, beat_logits)
        downbeats = [min(beats, key=lambda b: abs(b - d)) for d in downbeats] if len(beats) else []
        # written whole and then renamed: reawarp reads the file while this runs
        with open(dst + ".part", "w", encoding="utf-8") as f:
            f.write("beats " + " ".join(f"{t:.6f}" for t in beats) + "\n")
            f.write("downbeats " + " ".join(f"{t:.6f}" for t in downbeats) + "\n")
        os.replace(dst + ".part", dst)
        return 0
    except Exception as e:  # reported by reawarp
        with open(dst + ".part", "w", encoding="utf-8") as f:
            f.write("error " + f"{type(e).__name__}: {e}".replace("\n", " ") + "\n")
        os.replace(dst + ".part", dst)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
