# Windows and Steam release staging

`host_game.py export` creates the runnable build in `build/windows/` and copies
the exact Steam payload into the isolated `build/steam-depot/` directory:

- `InkboundRogue.exe` — embedded-PCK Windows x86_64 game
- `THIRD_PARTY_NOTICES.txt` — redistributable engine notice
- `version.json` — product, build channel, and save-schema identity

Historical captures and local diagnostic files may remain under other build
directories, but the Steam templates map only `build/steam-depot/` so they
cannot leak into an uploaded depot.

The two `.vdf.example` files are intentionally inert. Copy them outside the
repository, replace both Steam IDs with values from Steamworks, and run
SteamCMD only with the partner account's approved publishing workflow. Never
commit credentials or a live Steam Guard session.

Before uploading a playtest depot:

1. Run `host_game.py test`, `host_game.py pause-test`, `host_game.py save-test`,
   `host_game.py session-test`, `host_game.py supply-test`, `host_game.py balance`,
   `host_game.py persona-test`, `host_game.py daily-test`,
   `host_game.py progression`, `host_game.py routes`, `host_game.py manual-test`,
   `host_game.py cast-test`, `host_game.py audio-test`, `host_game.py combat-feel-test`, `host_game.py restoration-test`,
   `host_game.py proof-test`, `host_game.py playtest-recorder-test`, and
   `host_game.py soak`.
2. Run `host_game.py capture-session`, `host_game.py capture-upgrades`,
   `host_game.py capture-restoration`, `host_game.py capture-proof`,
   `host_game.py capture-daily`, and `host_game.py capture-manual`, then inspect
   the visual capture gallery.
3. Export and launch the exact depot executable on Windows.
4. Verify clean-profile save creation, profile migration, current-draft backup
   recovery, Continue / Load, New Game confirmation, and checkpoint cleanup.
5. Check every default controller action, background-focus pause, Daily flow,
   ending, and achievement. Use `host_game.py process-status` before and after
   the session; `host_game.py run` refuses to open a second exported instance.
6. Run a pseudonymous recorded session with `host_game.py playtest --participant
   P-001`. Exercise at least one moment marker, finish the run survey, close the
   game normally, and confirm that `host_game.py playtest-report` sees one
   complete session. The launcher refuses to create a second game instance.
7. Replace draft capsule/store art and localize store copy before public launch.
