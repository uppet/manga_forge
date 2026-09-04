# P1 Windows compatibility matrix

The P1 target is a private, small-scale Windows playtest, not a claim of final
minimum specifications. Automated evidence and manual hardware evidence remain
separate so a pass on the development PC cannot masquerade as low-end coverage.

## Fixed technical baseline

- Windows x86_64 export, Godot 4.2, GL Compatibility renderer (OpenGL 3.3).
- 480×270 logical canvas, nearest-neighbour pixel textures, default 960×540
  window, runtime windowed/fullscreen switch.
- 60 Hz physics; no network, online account, Steam client, microphone, camera,
  or live AI dependency.
- Provisional P1 floor: Windows 10/11 64-bit, OpenGL 3.3-capable GPU, 4 GB RAM,
  200 MB free storage, keyboard/mouse or compatible XInput/SDL gamepad.

## Automated on every P1 candidate

| Gate | Pass condition |
| --- | --- |
| Source/release audit | 108/108 runtime assets hashed; 44 pre-generated AI, 64 procedural, zero live AI; inert Steam IDs |
| Stress soak | 1,200 accelerated frames, final act reached, ≤1,000 nodes, ≤256 MiB static memory, ≥90 processing fps |
| Recorded stress soak | Same budget with the opt-in local recorder writing event/performance streams |
| Serial regression | 29 gameplay/save/UI/balance/persona/recorder/stress gates in one non-overlapping delegate session, with timestamped per-gate evidence |
| Export boot | Exact embedded-PCK `LastInkwarden.exe` opens with the Windows GL renderer for 120 frames and exits cleanly |
| Depot isolation | Exactly EXE, notices, and version JSON; no logs, captures, save data, source, tests, or credentials |
| UI renderer | English/Chinese title, settings, upgrades, story, credits, and combat HUD render through Windows GL Compatibility |

## Manual hardware passes

Record date, Windows build, CPU, GPU/driver, RAM, display scale, controller,
locale, result, and session ID. A blank row is **not tested**, not a pass.

| Tier | Target | Hardware/date/session | Status |
| --- | --- | --- | --- |
| Development baseline | Windows 11, discrete GPU, Xbox-layout pad, 100%/150% display scaling | Radeon RX 9070 XT renderer confirmed 2026-09-01; controller hardware still to record | Partial |
| Provisional minimum | Windows 10, integrated/older OpenGL 3.3 GPU, 4 GB available RAM, 720p/1080p | — | Not tested |
| PlayStation layout | DualShock 4 or DualSense over USB/Bluetooth | — | Not tested |
| Nintendo layout | Switch Pro-compatible SDL controller | — | Not tested |
| Keyboard-only | No controller attached, English and Chinese | — | Not tested |

The private P1 invite should state the provisional requirements and ask testers
to attach the anonymous session ID plus hardware summary to any performance or
controller report. Final store minimum specifications require at least one real
pass on the provisional-minimum row; renderer selection alone is not evidence.
