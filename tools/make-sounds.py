# Builds Sounds/*.ogg, the gimmicks' sound effects (Modules/Gimmicks.lua), from nothing but maths
# (so there is no sample to license). Needs numpy and ffmpeg:
#   python tools/make-sounds.py
# The game only finds new sound files after a full restart.
import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Sounds")
rng = np.random.default_rng(7)  # fixed seed: the same files every run


def silence(seconds):
    return np.zeros(int(RATE * seconds))


def add(track, sound, at, gain=1.0):
    start = int(RATE * at)
    end = min(len(track), start + len(sound))
    track[start:end] += gain * sound[: end - start]


def noise(seconds, low, high, decay):
    """White noise kept between two frequencies, dying away."""
    n = int(RATE * seconds)
    spectrum = np.fft.rfft(rng.standard_normal(n))
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    spectrum[(freqs < low) | (freqs > high)] = 0
    out = np.fft.irfft(spectrum, n)
    out /= np.abs(out).max() or 1
    return out * np.exp(-np.arange(n) / RATE / decay)


def ring(freq, seconds, decay, partials):
    """A struck piece of metal: partials that die faster the higher they are."""
    t = np.arange(int(RATE * seconds)) / RATE
    out = sum(amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t / (decay / ratio ** 0.7))
              for ratio, amp in partials)
    out[: int(RATE * 0.002)] *= np.linspace(0, 1, int(RATE * 0.002))  # no click at the start
    return out


BELL = [(1, 1), (2, 0.6), (2.76, 0.35), (4.07, 0.2), (5.4, 0.1)]
COIN = [(1, 1), (1.47, 0.7), (2.09, 0.45), (2.83, 0.25)]


def bell(freq, seconds=0.6, decay=0.25):
    return ring(freq, seconds, decay, BELL) + 0.3 * np.pad(noise(0.01, 3000, 9000, 0.002), (0, int(RATE * seconds) - int(RATE * 0.01)))


def coin():
    return ring(rng.uniform(3600, 5200), 0.15, 0.035, COIN)


def clunk():
    """A reel stopping: a thud, the click of the stop, a little rattle."""
    t = np.arange(int(RATE * 0.3)) / RATE
    thud = np.sin(2 * np.pi * (60 * t + 80 * 0.05 * (1 - np.exp(-t / 0.05)))) * np.exp(-t / 0.06)
    out = 0.9 * thud
    add(out, noise(0.03, 2000, 6000, 0.004), 0, 0.6)
    add(out, ring(900, 0.2, 0.05, [(1, 1), (1.59, 0.7), (2.46, 0.5)]), 0.004, 0.2)
    return out


def spin(seconds=4.5, rate=20):
    """Reels turning: the ticks of the symbols going by over a low whirr."""
    out = silence(seconds)
    whirr = noise(seconds, 150, 700, 1e9)
    t = np.arange(len(out)) / RATE
    out += 0.12 * whirr * (0.7 + 0.3 * np.sin(2 * np.pi * rate * t))
    at = 0.0
    while at < seconds - 0.05:
        add(out, noise(0.02, 1500, 5000, 0.004), at, rng.uniform(0.55, 1.0))
        add(out, ring(95, 0.04, 0.012, [(1, 1)]), at, 0.3)
        at += rng.uniform(0.95, 1.05) / rate
    fade = int(RATE * 0.03)
    out[:fade] *= np.linspace(0, 1, fade)
    out[-fade:] *= np.linspace(1, 0, fade)
    return out


def win():
    """One stack paid out: a ding and a few coins in the tray."""
    out = silence(0.7)
    add(out, bell(2093), 0)
    for at in (0.09, 0.17, 0.28):
        add(out, coin(), at, 0.35)
    return out


def crit():
    """A crit: two rising dings, brighter and longer."""
    out = silence(0.95)
    add(out, bell(2637, 0.8, 0.3), 0, 0.8)
    add(out, bell(3520, 0.8, 0.4), 0.09)
    for at in (0.2, 0.27, 0.36, 0.47):
        add(out, coin(), at, 0.3)
    return out


def payout(seconds, strikes, runs):
    """A jackpot: the bell hammering, a rising run of notes, coins pouring out."""
    out = silence(seconds)
    ringing = seconds - 0.5
    for i in range(int(ringing * strikes)):
        at = i / strikes
        add(out, ring(1760, 0.2, 0.09, BELL), at, 0.5 * min(1, (ringing - at) / 0.6))
    notes = [1047, 1319, 1568, 2093, 2637, 3136, 4186]  # C major, climbing
    for run in range(runs):
        for i, freq in enumerate(notes):
            add(out, bell(freq, 0.35, 0.12), 0.05 + run * 0.62 + i * 0.075, 0.55)
    for at in np.sort(rng.uniform(0.3, seconds - 0.35, int(seconds * 16))):
        add(out, coin(), at, rng.uniform(0.2, 0.4))
    fade = int(RATE * 0.4)
    out[-fade:] *= np.linspace(1, 0, fade)
    return out


def gust():
    """Windfury: a rush of wind rising in pitch, and the two strikes it carries."""
    seconds = 0.9
    out = silence(seconds)
    t = np.arange(len(out)) / RATE
    for i, (low, high) in enumerate([(200, 700), (500, 1500), (1200, 3500), (2500, 7000)]):
        swell = np.exp(-(((t - 0.1 - i * 0.1) / 0.12) ** 2))
        out += (1 - 0.15 * i) * noise(seconds, low, high, 1e9) * swell
    for at in (0.3, 0.4):
        t2 = np.arange(int(RATE * 0.15)) / RATE
        thud = np.sin(2 * np.pi * 90 * t2) * np.exp(-t2 / 0.04)
        add(out, thud + 0.5 * noise(0.15, 300, 3000, 0.02), at, 0.9)
    fade = int(RATE * 0.2)
    out[-fade:] *= np.linspace(1, 0, fade)
    return out


SOUNDS = {  # name: (samples, peak level); new ones go last, so the others keep their random draws
    "spin": (spin(), 0.3),
    "stop": (clunk(), 0.7),
    "win": (win(), 0.6),
    "crit": (crit(), 0.7),
    "jackpot": (payout(2.6, 14, 1), 0.75),
    "mega": (payout(3.8, 17, 3), 0.8),
    "windfury": (gust(), 0.7),
}

os.makedirs(OUT, exist_ok=True)
with tempfile.TemporaryDirectory() as tmp:
    for name, (samples, peak) in SOUNDS.items():
        samples = samples / np.abs(samples).max() * peak
        wav = os.path.join(tmp, name + ".wav")
        with wave.open(wav, "wb") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(RATE)
            f.writeframes((samples * 32767).astype("<i2").tobytes())
        ogg = os.path.join(OUT, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", ogg], check=True)
        print(f"{name}.ogg  {len(samples) / RATE:.2f}s  {os.path.getsize(ogg)} bytes")
