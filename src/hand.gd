# tabs for indentation
class_name Hand
extends Node2D

# ─────────────────────────────── constants ────────────────────────────────
const TILE_SIZE			: int = 32
const TILE_MAX_SEP		: int = 48
const MAX_HAND_WIDTH	: int = TILE_SIZE * 10		# visual cap (10 tiles wide)
const PREVIEW_GAP_FACTOR  : float = 1.00                # 0 = no gap, 1 = full gap

# ────────────────────────────── data members ──────────────────────────────
var game_tiles		: Array[GameTile] = []		# canonical order
var want_reindex	: bool = false

var _preview_tile	: GameTile = null			# tile currently hovered over hand

# ─────────────────────────────── signals ────────────────────────────────
# (hand no longer emits tile_grabbed / tile_released – manipulator handles that)
signal tile_placed(GameTile, Slot)				# still useful for other systems

# ─────────────────────────────── lifecycle ────────────────────────────────
func _ready() -> void:
	$Area2D.area_entered.connect(_on_area_entered)
	$Area2D.area_exited .connect(_on_area_exited)

func _process(_delta : float) -> void:
	if want_reindex:
		want_reindex = false
		reindex_tiles()
		_reorder_game_tiles()
		

	# live gap preview
	if _preview_tile and _tile_is_over_hand(_preview_tile):
		_preview_gap_for(_preview_tile)


# ───────────────────────────── public API ────────────────────────────────
## Called by TileManipulator on drag-start
func start_preview(tile : GameTile) -> void:
	# Remember which tile is hovering, but do NOT add it as a child.
	_preview_tile = tile

	# Ensure the tile is *not* counted in game_tiles.  (If it was in the
	# list because we grabbed it from inside the hand, remove it now.)
	game_tiles.erase(tile)

	want_reindex = true			# triggers gap-generation in _process()

func stop_preview() -> void:
	_preview_tile = null
	want_reindex = true

func add_to_hand(tile : GameTile, global_pos = null) -> void:
	tile.coordinates = Vector2.ONE * -1
	if game_tiles.has(tile):
		return
	
	if tile.get_parent():
		tile.reparent(self)
	else:
		add_child(tile)
	
	if global_pos != null:
		tile.global_position = global_pos
	game_tiles.append(tile)
	want_reindex = true

func remove_from_hand(tile : GameTile) -> void:
	game_tiles.erase(tile)
	want_reindex = true

func tile_count() -> int:
	return game_tiles.size()

# ───────────────────── internal layout & sorting helpers ───────────────────
func reindex_tiles() -> void:
	# stable left-to-right sort (dragged tile keeps its place)
	game_tiles.sort_custom(func(a : GameTile, b : GameTile) -> bool:
		return a.position.x < b.position.x)

func _reorder_game_tiles() -> void:
	_dedupe_and_prune_tiles()
	_apply_layout(game_tiles)

func _preview_gap_for(tile : GameTile) -> void:
	# 1. Work on a copy (game_tiles never contains the dragged tile)
	var sorted := game_tiles.duplicate()
	# Sort by global x so we always compare apples to apples
	sorted.sort_custom(func(a : GameTile, b : GameTile) -> bool:
		return a.global_position.x < b.global_position.x)

	# 2. Determine insertion index based on current cursor position
	var idx := _index_from_neighbour_positions(tile.global_position.x, sorted)

	# 3. Insert placeholder gap and lay out the row
	sorted.insert(idx, null)
	_apply_layout(sorted)

# ---------------------------------------------------------------
func _index_from_neighbour_positions(cursor_x : float, sorted_tiles : Array) -> int:
	for i in sorted_tiles.size():
		if cursor_x < sorted_tiles[i].global_position.x:
			return i                      # slot is to the left of this tile
	return sorted_tiles.size()           # cursor is past all tiles → append

func _apply_layout(layout : Array) -> void:
	if layout.is_empty():
		return

	var sep      = min(TILE_MAX_SEP, MAX_HAND_WIDTH / layout.size())
	var span     = (layout.size() - 1) * sep
	var start_x  = -span * 0.5
	var gap_idx  = layout.find(null)          # where the placeholder sits

	for i in layout.size():
		var t = layout[i]
		if t == null:
			continue                          # skip the placeholder

		# Compute slot index with compressed gap
		var eff_i := float(i)
		if gap_idx != -1 and i > gap_idx:
			eff_i -= (1.0 - PREVIEW_GAP_FACTOR)

		var pos = Vector2(start_x + eff_i * sep, 0)

		if t.state in [
			GameTile.TileState.IDLE,
			GameTile.TileState.RELEASED
		]:
			var tw = create_tween()
			tw.tween_property(t, "position", pos, 0.18)\
			  .set_ease(Tween.EASE_OUT)


# ────────────────────────── geometry helpers ──────────────────────────────
func _index_from_global_position(object_global_pos : Vector2) -> int:
	var count = max(
		game_tiles.size() + (0 if _preview_tile == null else 0),  # ← add 1 for gap
		1
	)

	var local_x = to_local(object_global_pos).x
	var sep     = min(TILE_MAX_SEP, MAX_HAND_WIDTH / count)
	var span    = (count - 1) * sep
	var start_x = -span * 0.5
	var idx     = int(round((local_x - start_x) / sep))

	return clamp(idx, 0, count - 1)



func _tile_is_over_hand(tile : GameTile) -> bool:
	return $Area2D.get_overlapping_areas().has(tile.get_node("Area2D"))

func _on_area_entered(area : Area2D) -> void:
	var tile := area.get_parent()
	if tile is GameTile and tile.state == GameTile.TileState.GRABBED:
		start_preview(tile)              # show live gap

func _on_area_exited(area : Area2D) -> void:
	var tile := area.get_parent()
	if tile == _preview_tile:
		stop_preview()                   # collapse gap



# ───────────────────────────── utilities ──────────────────────────────────
func _dedupe_and_prune_tiles() -> void:
	var cleaned : Array[GameTile] = []
	for t in game_tiles:
		if t == null:
			continue
		if not is_instance_valid(t):
			continue
		if t.get_parent() != self:
			continue
		if not cleaned.has(t):
			cleaned.append(t)
	game_tiles = cleaned

# ───────────────────── slot query (used by manipulator) ────────────────────
func get_highlighted_slot() -> Slot:
	var params = PhysicsPointQueryParameters2D.new()
	params.position		   = get_global_mouse_position()
	params.collide_with_areas = true

	var hits = get_world_2d().direct_space_state.intersect_point(params)
	for h in hits:
		var owner = h.collider.get_parent()
		if owner is Slot:
			return owner if owner.empty() else null
	return null
