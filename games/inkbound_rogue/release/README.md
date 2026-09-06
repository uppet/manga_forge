# Windows and Steam release staging

`host_game.py export` creates the runnable build in `build/windows/` and copies
the exact Steam payload into the isolated `build/steam-depot/` directory:

- `LastInkwarden.exe` — embedded-PCK Windows x86_64 game
- `THIRD_PARTY_NOTICES.txt` — redistributable engine notice
- `version.json` — product, build channel, and save-schema identity
- `PRIVACY_NOTICE.txt` — bilingual player-facing usage-statistics disclosure

The canonical people, tool, model, and platform roster lives in
`../design/credits.md`; its player-facing summary is compiled into the game and
the redistributable notices above.

`build/itch-windows/` is the isolated five-file free public-Beta payload: the
four files above plus `Start-Recorded-Playtest.cmd`. Upload the same complete
directory (or the same ZIP) to itch.io and the Quark Drive mirror so both
channels distribute an identical audited build. Players may run the EXE
normally or opt into local recording through the launcher without configuring
environment variables. The working `build/windows/` directory may retain
internal captures or historical executables and must not be uploaded.
The Steam depot intentionally excludes the launcher and remains restricted to
its four-file allowlist.

After the source and bundle audits pass, `host_game.py export` packages those
same five files as
`build/public-beta/LastInkwarden-<version>-windows-beta.zip`, writes its
`.sha256` companion, and records a `public-beta-build.json` manifest containing
only release identity, archive metadata, file names, and the non-secret
GameAnalytics configuration fingerprint. Upload that one ZIP unchanged to both
itch.io and Quark Drive.

Run `host_game.py recorded-launcher-test` after export. It drives the real CMD
launcher and exported EXE through the 120-frame boot handshake, then requires a
complete anonymous session and zero remaining game/Godot processes.

Historical captures and local diagnostic files may remain under other build
directories, but the Steam templates map only `build/steam-depot/` so they
cannot leak into an uploaded depot.

`p1-readiness.md` retains its historical filename but is the dated free-Beta
candidate snapshot and public-feedback checklist. Update it with each
candidate; never promote untested manual hardware rows or automated persona
simulations into human-playtest evidence.

Export always mirrors current source first, preserving only `.godot/` cache and
`build/` evidence while pruning stale source files. It then boots the exact
embedded-PCK executable with the Windows GL renderer for 120 frames and runs `release-audit` over
the source provenance plus depot allowlist.

The two `.vdf.example` files are intentionally inert. Copy them outside the
repository, replace both Steam IDs with values from Steamworks, and run
SteamCMD only with the partner account's approved publishing workflow. Never
commit credentials or a live Steam Guard session.

Before uploading a public Beta build or a later Steam playtest depot:

1. Run the serial `host_game.py p1-suite`, which covers `host_game.py test`,
   `host_game.py pause-test`, `host_game.py save-test`,
   `host_game.py session-test`, `host_game.py supply-test`, `host_game.py balance`,
   `host_game.py persona-test`, `host_game.py daily-test`,
   `host_game.py progression`, `host_game.py routes`, `host_game.py manual-test`,
   `host_game.py cast-test`, `host_game.py audio-test`, `host_game.py combat-feel-test`, `host_game.py accessibility-test`, `host_game.py restoration-test`,
   `host_game.py proof-test`, `host_game.py playtest-recorder-test`,
   `host_game.py gameanalytics-test`, `host_game.py privacy-test`,
   and `host_game.py soak` without overlapping Godot instances. Then run
   `host_game.py recorded-soak` and `host_game.py release-audit`. Preserve the
   timestamped `build/p1-suite/` summary and per-gate logs with the candidate's
   internal test evidence; they are excluded from the depot.
2. Run `host_game.py capture-session`, `host_game.py capture-upgrades`,
   `host_game.py capture-restoration`, `host_game.py capture-proof`,
   `host_game.py capture-daily`, and `host_game.py capture-manual`, then inspect
   the visual capture gallery. The session gallery includes the victory result
   and terminal thank-you pages in addition to the title and combat HUD states.
3. Export and launch the exact depot executable on Windows.
4. Verify clean-profile save creation, profile migration, current-draft backup
   recovery, Continue / Load, New Game confirmation, and checkpoint cleanup.
5. Check every default controller action, background-focus pause, Daily flow,
   ending, and achievement. Use `host_game.py process-status` before and after
   the session; `host_game.py run` refuses to open a second exported instance.
   Test commands hard-kill ten seconds after a normal timeout signal;
   `host_game.py cleanup-tests` is the scoped recovery command for a failed
   Last Inkwarden test and does not target editors or the exported game.
6. Run a pseudonymous recorded session with `host_game.py playtest --participant
   P-001`. Exercise at least one moment marker, finish the run survey, close the
   game normally, and confirm that `host_game.py playtest-report` sees one
   complete session. The launcher refuses to create a second game instance.
7. Replace all placeholder download, feedback, and video links in
   `itch-description.md`; upload one candidate ZIP to both public channels.
8. Complete the owner/publisher sign-offs in `ai-content-disclosure.md` and the real
   integrated/older-GPU row in `p1-compatibility-matrix.md`. Automated GL
   Compatibility success on the development GPU is not a low-end hardware pass.
