# tabs for indentation
class_name Board
extends Node2D

# ───────────────────────────── constants / exports ─────────────────────────
const BOARD_SIZE  : Vector2i = Vector2i(9, 9)
const SLOT_SIZE   : Vector2i = Vector2i(34, 34)
const HALF_IDX    : Vector2i = (BOARD_SIZE - Vector2i.ONE) / 2

@export var slot_scene : PackedScene

# ──────────────────────────── public signals (ui) ───────────────────────────
signal slot_highlighted(Slot)
signal slot_unhighlighted(Slot)

# ───────────────────────── internal state (visual) ──────────────────────────
var board_state      : Array[Array]               = []   # SlotTileStruct grid
var board_text       : Array[Array]               = []   # String grid ("" = empty)
var placed_mask      : Array[Array]               = []   # Bool grid (true = locked)
var word_coords_dict : Dictionary          = {}   # hover-panel cache

var show_defs_held : bool      = false
var _hover_coord   : Vector2i  = Vector2i(-1, -1)
var _word_defs     : Dictionary = {}             # "APPLE" → Definition

# ---------------------------------------------------------------------------
class SlotTileStruct:
	var slot : Slot
	var tile : GameTile
	func _init(p_slot : Slot = null, p_tile : GameTile = null) -> void:
		slot = p_slot
		tile = p_tile

# ─────────────────────────────── lifecycle ─────────────────────────────────
func _ready() -> void:
	for y in range(BOARD_SIZE.y):
		board_state.append([])
		board_text.append([])
		placed_mask.append([])

		for x in range(BOARD_SIZE.x):
			board_state[y].append(SlotTileStruct.new())
			board_text[y].append("")
			placed_mask[y].append(false)

			var slot = slot_scene.instantiate() as Slot
			add_child(slot)
			slot.position    = (Vector2i(x, y) - HALF_IDX) * SLOT_SIZE
			slot.coordinates = Vector2i(x, y)
			board_state[y][x].slot = slot

			slot.highlighted.connect(_slot_highlighted)
			slot.unhighlighted.connect(_slot_unhighlighted)

func _process(_dt : float) -> void:
	if show_defs_held:
		var coord = _get_coord_under_mouse()
		_update_definition_panel(coord)

func _input(event) -> void:
	if event.is_action_pressed("show_defs"):
		show_defs_held = true
		show_definition_panel()
	elif event.is_action_released("show_defs"):
		show_defs_held = false
		_hover_coord = Vector2i(-1, -1)
		hide_definition_panel()

# ─────────────────────── public interface for Game Flow ─────────────────────
func get_turn_snapshot() -> Dictionary:
	var new_tiles : Array[Vector2i] = _get_current_turn_tiles()

	# build a parallel grid of GameTile refs (or null)
	var tiles_grid : Array = []
	for y in range(BOARD_SIZE.y):
		tiles_grid.append([])
		for x in range(BOARD_SIZE.x):
			tiles_grid[y].append(board_state[y][x].tile)

	return {
		"board_text"  : board_text,
		"board_tiles" : tiles_grid,
		"placed_mask" : placed_mask,
		"new_tiles"   : new_tiles
	}

func commit_turn(new_tiles : Array[Vector2i]) -> void:
	var seen : Dictionary = {}          # Vector2i → bool
	for p in new_tiles:
		if seen.has(p):                 # already processed this cell
			continue
		seen[p] = true

		placed_mask[p.y][p.x] = true
		var tile = board_state[p.y][p.x].tile
		if tile:
			tile.lock_in()
			if tile.grabbed.is_connected(remove_tile):
				tile.grabbed.disconnect(remove_tile)
			if tile.return_to_hand.is_connected(remove_tile):
				tile.return_to_hand.disconnect(remove_tile)

# ─────────────────────────── tile manipulation ─────────────────────────────
func can_place_at(target_slot : Slot) -> bool:
	return not placed_mask[target_slot.coordinates.y][target_slot.coordinates.x]

func can_pick_up(tile : GameTile) -> bool:
	if tile.coordinates == -Vector2i.ONE:
		return true
	return not placed_mask[tile.coordinates.y][tile.coordinates.x]

func place_tile_at(tile : GameTile, target_slot : Slot) -> void:

	var dest      = board_state[target_slot.coordinates.y][target_slot.coordinates.x]
	var displaced = dest.tile
	
	if tile.get_parent():
		tile.reparent(self)
	else:
		add_child(tile)

	if not tile.grabbed.is_connected(remove_tile):
		tile.grabbed.connect(remove_tile)
	if not tile.return_to_hand.is_connected(remove_tile):
		tile.return_to_hand.connect(remove_tile)

	var origin_slot : Slot = null
	if tile.coordinates != -Vector2i.ONE:
		origin_slot = board_state[tile.coordinates.y][tile.coordinates.x].slot

	# handle displaced tile
	if displaced and displaced != tile:
		if origin_slot:
			_snap_tile_to_slot(displaced, origin_slot)
			displaced.coordinates = origin_slot.coordinates
			board_state[origin_slot.coordinates.y][origin_slot.coordinates.x].tile  = displaced
			board_text [origin_slot.coordinates.y][origin_slot.coordinates.x] = displaced.letter
		else:
			displaced.release_from_board()

	# claim destination
	tile.coordinates = target_slot.coordinates
	dest.tile        = tile
	board_text[target_slot.coordinates.y][target_slot.coordinates.x] = tile.letter
	_snap_tile_to_slot(tile, target_slot)

func remove_tile(tile : GameTile) -> void:
	if tile.coordinates == -Vector2i.ONE:
		return

	var y = tile.coordinates.y
	var x = tile.coordinates.x
	if y < 0 or x < 0:
		return
	if placed_mask[y][x]:
		return

	if tile.grabbed.is_connected(remove_tile):
		tile.grabbed.disconnect(remove_tile)
	if tile.return_to_hand.is_connected(remove_tile):
		tile.return_to_hand.disconnect(remove_tile)

	board_text[y][x]       = ""
	board_state[y][x].tile = null
	if tile.state == GameTile.TileState.IDLE:
		tile.coordinates = -Vector2i.ONE

func _snap_tile_to_slot(tile : GameTile, slot : Slot) -> void:
	var tw = create_tween()
	tw.tween_property(tile, "global_position", slot.global_position, 0.1)
	tw.set_ease(Tween.EASE_IN)

# ───────────────────── hover-definition panel helpers ──────────────────────
func _get_coord_under_mouse() -> Variant:
	var local = to_local(get_viewport().get_mouse_position())
	var rel   = (local / Vector2(SLOT_SIZE)) + Vector2(HALF_IDX)
	var cell  = Vector2i(int(round(rel.x)), int(round(rel.y)))
	if	cell.x < 0 or cell.x >= BOARD_SIZE.x \
	or	cell.y < 0 or cell.y >= BOARD_SIZE.y:
		return null
	return cell

func _update_definition_panel(coord : Variant) -> void:
	if coord == _hover_coord:
		return
	if coord == null:
		_hover_coord = Vector2i(-1, -1)
	clear_definitions()
	if coord == null:
		return

	var words = word_coords_dict.get(coord, [])
	var seen  : Dictionary = {}
	for w in words:
		if seen.has(w):
			continue
		seen[w] = true
		if _word_defs.has(w):
			$DefinitionPanel.add_def(_word_defs[w])

func clear_definitions() -> void:			$DefinitionPanel.clear()
func show_definition_panel() -> void:		$DefinitionPanel.show()
func hide_definition_panel() -> void:		$DefinitionPanel.hide()

func _cache_definition(word : String) -> void:
	if _word_defs.has(word):
		return
	var getter = DefinitionGetter.new()
	getter.word_to_check = word
	add_child(getter)
	var def = await getter.definition_ready
	_word_defs[word] = def
	getter.queue_free()

# ───────────────────────────── utility helpers ─────────────────────────────
func _get_current_turn_tiles() -> Array[Vector2i]:
	var tiles : Array[Vector2i] = []
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			if board_text[y][x] != "" and not placed_mask[y][x]:
				tiles.append(Vector2i(x, y))
	return tiles

func buzz_tiles() -> void:
	for p in _get_current_turn_tiles():
		board_state[p.y][p.x].tile.bzzt()
	AudioStreamManager.play_bad_sound()

func debug_print_board() -> void:
	var s = ""
	for row in board_text:
		for ch in row:
			s += ch if ch != "" else "-"
			s += " "
		s += "\n"
	print(s)

# ───────────────────────── slot highlight relays ───────────────────────────
func _slot_highlighted(s : Slot) -> void:	slot_highlighted.emit(s)
func _slot_unhighlighted(s : Slot) -> void:	slot_unhighlighted.emit(s)
