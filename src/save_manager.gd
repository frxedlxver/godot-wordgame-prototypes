# tabs for indentation
class_name SaveManager
extends Node

const SAVE_PATH := "user://profile.tres"

var _cache : SaveData

# ─────────────────────────────────────────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────────────────────────────────────────
func load_data() -> void:
	# Call once on game start / main-menu init.
	_load_or_create()               # fills _cache but touches nothing else

func save_data() -> void:
	# Call whenever you want to persist the profile.
	if G.current_run_data.in_progress:
		_cache.run_data = G.current_run_data
		_cache.run_pending = true
	else:
		_cache.run_pending = false
		_cache.run_data.reinitialize()
	_serialize()

func has_saved_run() -> bool:
	return _cache.run_pending

func load_saved_run() -> bool:
	# Returns TRUE if a pending run was copied into RUN_DATA.
	if not _cache.run_pending:
		return false

	G.current_run_data.copy_from(_cache.run_data)

	# Consume the snapshot so it cannot be loaded twice.
	_cache.run_pending = false
	_cache.run_data.reinitialize()
	_serialize()
	return true

# ─────────────────────────────────────────────────────────────────────────────
#  INTERNAL
# ─────────────────────────────────────────────────────────────────────────────
func _load_or_create() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		_cache = ResourceLoader.load(SAVE_PATH) as SaveData
		if _cache == null:
			push_warning("Profile corrupted – starting fresh")
	if _cache == null:
		_cache = SaveData.new()
	G.current_run_data = _cache.run_data

func _serialize() -> void:
	var err := ResourceSaver.save(
		_cache, SAVE_PATH, ResourceSaver.FLAG_COMPRESS)
	if err != OK:
		push_error("Save write failed: %s" % error_string(err))
