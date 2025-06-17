# tabs for indentation
class_name Hand
extends Node2D

# ─────────────────────────────── constants ────────────────────────────────
const TILE_SIZE			: int = 32
const TILE_MAX_SEP		: int = 48
const MAX_HAND_WIDTH	: int = TILE_SIZE * 10		# visual cap (10 tiles wide)

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

	# live gap preview
	if _preview_tile and _tile_is_over_hand(_preview_tile):
		_preview_gap_for(_preview_tile)
	elif _preview_tile == null:
		_reorder_game_tiles()

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
	if tile.get_parent() == self:
		remove_child(tile)
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
	var tmp = game_tiles.duplicate()
	tmp.erase(tile)					# ignore dragged tile
	var idx = _index_from_mouse()
	tmp.insert(idx, null)			# placeholder gap
	_apply_layout(tmp)

func _apply_layout(layout : Array) -> void:
	if layout.is_empty():
		return

	var sep		= min(TILE_MAX_SEP, MAX_HAND_WIDTH / layout.size())
	var span	= (layout.size() - 1) * sep
	var start_x = -span * 0.5

	for i in layout.size():
		var t = layout[i]
		if t == null:
			continue				# the gap
		if t.state in [
			GameTile.TileState.IDLE,
			GameTile.TileState.RELEASED
		]:
			var pos  = Vector2(start_x + i * sep, 0)
			var tw   = create_tween()
			tw.tween_property(t, "position", pos, 0.18).set_ease(Tween.EASE_OUT)

# ────────────────────────── geometry helpers ──────────────────────────────
func _index_from_mouse() -> int:
	var local_x = to_local(get_global_mouse_position()).x
	var sep		= min(TILE_MAX_SEP, MAX_HAND_WIDTH / max(game_tiles.size(), 1))
	var span	= (game_tiles.size() - 1) * sep
	var start_x = -span * 0.5
	var idx		= int(round((local_x - start_x) / sep))
	return clamp(idx, 0, game_tiles.size() - 1)

func _tile_is_over_hand(tile : GameTile) -> bool:
	return $Area2D.get_overlapping_areas().has(tile.get_node("Area2D"))

# ─────────────────────── area overlap bookkeeping ─────────────────────────
func _on_area_entered(area : Area2D) -> void:
	var tile = area.get_parent()
	if tile is GameTile and not game_tiles.has(tile):
		game_tiles.append(tile)
		want_reindex = true

func _on_area_exited(area : Area2D) -> void:
	var tile = area.get_parent()
	if tile is GameTile:
		game_tiles.erase(tile)
		want_reindex = true
		if tile == _preview_tile:
			_preview_tile = null

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
