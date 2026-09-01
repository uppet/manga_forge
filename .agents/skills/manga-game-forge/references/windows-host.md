# Windows-host execution

The repository lives in WSL. GPU media production and the reference Godot runtime
live on the Windows host. `tools/windows/host_game.py` is the supported entrypoint.

## Invariants

- The delegate runner resolves `cwd` as a Windows path before launching Git Bash.
- Use `S:\\...` for runner working directories and the configured full Git Bash path.
- Sync only the game/runtime payload to `S:\\bld\\manga-forge-runtime`.
- Keep Godot engines, export templates, ComfyUI models, and generated caches out of Git.
- Probe paths before mutation and capture asynchronous task output to completion.

## Verification order

1. `python3 tools/windows/host_game.py probe`
2. `python3 tools/game/generate_validation_assets.py`
3. `python3 tools/windows/host_game.py sync`
4. `python3 tools/windows/host_game.py test`
5. `python3 tools/windows/host_game.py run`
6. `python3 tools/windows/host_game.py export` when templates are installed.

The host launcher must use an explicit Godot executable. Do not depend on PATH.
