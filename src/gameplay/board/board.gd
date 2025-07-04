# tabs for indentation
class_name Board
extends Node2D

# constants / exports ──────────────────────────────────────────────────────────
const BOARD_SIZE  : Vector2i = Vector2i(11, 11)
const SLOT_SIZE   : Vector2i = Vector2i(34, 34)
const HALF_IDX    : Vector2i = (BOARD_SIZE - Vector2i.ONE) / 2

@export var slot_scene : PackedScene

# slot highlight relays ────────────────────────────────────────────────────────
signal slot_highlighted(SlotNode)
signal slot_unhighlighted(SlotNode)
func _slot_highlighted(s : SlotNode) -> void:	slot_highlighted.emit(s)
func _slot_unhighlighted(s : SlotNode) -> void:	slot_unhighlighted.emit(s)

# board state ──────────────────────────────────────────────────────────────────
var board_state		: Array[Array] = []		# SlotTileStruct grid
var board_text		: Array[Array] = []		# board text rep ("" = empty)
var placed_mask		: Array[Array] = []		# Bool grid (true = locked in)


# ignore for now, will be used by definition getter later when that is made into its own class
var word_coords_dict : Dictionary= {}   # V2i board coordinates : array of words

# ---------------------------------------------------------------------------
class SlotTileStruct:
	var slot : SlotNode
	var tile : GameTile
	func _init(p_slot : SlotNode = null, p_tile : GameTile = null) -> void:
		slot = p_slot
		tile = p_tile


func _ready() -> void:
	var center_slot_coords : Vector2i = Vector2i(BOARD_SIZE / 2)
	for y in range(BOARD_SIZE.y):
		board_state.append([])
		board_text.append([])
		placed_mask.append([])

		for x in range(BOARD_SIZE.x):
			board_state[y].append(SlotTileStruct.new())
			board_text[y].append("")
			placed_mask[y].append(false)
			
			var slot = slot_scene.instantiate() as SlotNode
			
			# set slot type here
			if Vector2i(x, y) == center_slot_coords:
				slot.slot_info = CenterSlot.new()
			else:
				slot.slot_info = NormalSlot.new()
				
				
			add_child(slot)
			slot.position    = (Vector2i(x, y) - HALF_IDX) * SLOT_SIZE
			slot.coordinates = Vector2i(x, y)
			board_state[y][x].slot = slot

			slot.highlighted.connect(_slot_highlighted)
			slot.unhighlighted.connect(_slot_unhighlighted)
			slot.hide()

func animate_in():
	self.show()
	var slots : Array = []
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			var s : SlotNode = board_state[y][x].slot
			if s:
				slots.append(s)
				s.scale = Vector2.ZERO # start hidden
	slots.shuffle()

	var delay := 0.0
	const DELAY_STEP := 0.012
	const DURATION   := 0.15
	for s in slots:
		s.show()
		
		var tw := create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw.set_trans(Tween.TRANS_BACK)
		tw.tween_property(s, "scale", Vector2.ONE, DURATION).set_delay(delay)
		tw.finished.connect(func(): AudioStreamManager.play_pop_sound())
		
		var tile : GameTile = board_state[s.coordinates.y][s.coordinates.x].tile
		if tile:
			tile.scale = Vector2.ZERO  # start hidden
			tw.parallel().tween_property(
				tile, "scale",
				Vector2.ONE, DURATION) \
				.set_delay(delay) \
				.set_trans(Tween.TRANS_ELASTIC)
				
		delay += DELAY_STEP
		
		# if this is the last slot, let's wait
		if s == slots.back():
			await tw.finished


func animate_out():
	var slots : Array = []
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			var s : SlotNode = board_state[y][x].slot
			if s:
				slots.append(s)
	slots.shuffle()
	
	var delay := 0.0
	const DELAY_STEP := 0.012
	const DURATION   := 0.15
	for s : SlotNode in slots:
		var tw := create_tween()
		
		tw.tween_property(s, "scale", Vector2.ZERO, DURATION) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_IN) \
			.set_delay(delay)
		var tile : GameTile = board_state[s.coordinates.y][s.coordinates.x].tile
		if tile: 
			tw.parallel().tween_property(tile, "scale", Vector2.ZERO, DURATION) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_IN) \
			.set_delay(delay)
		
		delay += DELAY_STEP
		# if this is the last slot, let's wait
		if s == slots.back():
			await tw.finished
		self.hide()

# public interface for Game Flow ────────────────────────────────────────────────
func get_turn_snapshot() -> Dictionary:
	var new_tiles : Array[Vector2i] = _get_current_turn_tiles()

	# build a parallel grid of GameTile refs (or null)
	var tiles_grid : Array = []
	var slots : Array = []
	for y in range(BOARD_SIZE.y):
		tiles_grid.append([])
		slots.append([])
		for x in range(BOARD_SIZE.x):
			tiles_grid[y].append(board_state[y][x].tile)
			slots[y].append(board_state[y][x].slot)
	return {
		"board_text"	: board_text,
		"board_tiles"	: tiles_grid,
		"placed_mask"	: placed_mask,
		"new_tiles"		: new_tiles,
		"slots"			: slots
	}


func commit_turn(new_tiles : Array[Vector2i]) -> void:
	var seen : Dictionary = {}
	for p in new_tiles:
		if seen.has(p):
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

# tile manipulation ────────────────────────────────────────────────────────
func can_place_at(target_slot : SlotNode) -> bool:
	return not placed_mask[target_slot.coordinates.y][target_slot.coordinates.x]

func can_pick_up(tile : GameTile) -> bool:
	if tile.coordinates == -Vector2i.ONE:
		return true
	return not placed_mask[tile.coordinates.y][tile.coordinates.x]

func place_tile_at(tile : GameTile, target_slot : SlotNode) -> void:
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

	var origin_slot : SlotNode = null
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


func _snap_tile_to_slot(tile : GameTile, slot : SlotNode) -> void:
	var tw = create_tween()
	tw.tween_property(tile, "global_position", slot.global_position, 0.1)
	tw.set_ease(Tween.EASE_IN)


func get_non_locked_tiles() -> Array[GameTile]:
	# Collect every tile that is present on the board and **not** locked in
	var result : Array[GameTile] = []
	for y in range(BOARD_SIZE.y):
		for x in range(BOARD_SIZE.x):
			if not placed_mask[y][x]:
				var tile : GameTile = board_state[y][x].tile
				if tile:
					result.append(tile)
	return result


# utility helpers ────────────────────────────────────────────────────────
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
