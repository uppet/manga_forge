extends RefCounted

# Safe source-tree placeholder. tools/windows/host_game.py replaces only the
# Windows runtime copy during export when gameanalytics.local.json is present.
# Real credentials must never be written into this tracked file.
const EMBEDDED := false
const GAME_KEY := ""
const SECRET_KEY := ""
const ENVIRONMENT := "production"
const PROFILE := "none"
const CONFIG_FINGERPRINT := "none"
