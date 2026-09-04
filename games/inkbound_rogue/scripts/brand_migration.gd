extends Node

# Godot derives user:// from application/config/name. Copy the previous
# development profile once so the public rename does not strand tester saves.
const LEGACY_USER_DIR_NAMES := [
	"Inkbound- Blade of the Blank Page",
]
const MIGRATION_MARKER := ".last_inkwarden_brand_migration_v1"
const SKIPPED_DIRECTORIES := ["logs", "playtest"]


func _enter_tree() -> void:
	_migrate_legacy_user_data()


func _migrate_legacy_user_data() -> void:
	var destination_root := OS.get_user_data_dir()
	var marker_path := destination_root.path_join(MIGRATION_MARKER)
	if FileAccess.file_exists(marker_path):
		return
	var migrated_from := "none"
	var completed := true
	for legacy_name in LEGACY_USER_DIR_NAMES:
		var source_root := destination_root.get_base_dir().path_join(legacy_name)
		if source_root == destination_root or not DirAccess.dir_exists_absolute(source_root):
			continue
		if not _copy_missing_tree(source_root, destination_root):
			completed = false
			break
		migrated_from = legacy_name
	if not completed:
		push_warning("Last Inkwarden could not finish legacy profile migration; it will retry next launch.")
		return
	var marker := FileAccess.open(marker_path, FileAccess.WRITE)
	if marker != null:
		marker.store_line("migration=1")
		marker.store_line("source=%s" % migrated_from)


func _copy_missing_tree(source_root: String, destination_root: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(destination_root) != OK and not DirAccess.dir_exists_absolute(destination_root):
		return false
	var source := DirAccess.open(source_root)
	if source == null or source.list_dir_begin() != OK:
		return false
	var succeeded := true
	var entry := source.get_next()
	while not entry.is_empty():
		if entry not in [".", "..", ".recovery_mode_lock", MIGRATION_MARKER]:
			var source_path := source_root.path_join(entry)
			var destination_path := destination_root.path_join(entry)
			if source.current_is_dir():
				if entry not in SKIPPED_DIRECTORIES and not _copy_missing_tree(source_path, destination_path):
					succeeded = false
			elif not FileAccess.file_exists(destination_path):
				if DirAccess.copy_absolute(source_path, destination_path) != OK:
					succeeded = false
		entry = source.get_next()
	source.list_dir_end()
	return succeeded
