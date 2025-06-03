class_name Board extends Node2D

@onready var round_manager : RoundManager = get_parent()
const board_size : Vector2i = Vector2i(7, 7)
const slot_size : Vector2i = Vector2i(34, 34)
@export var slot_scene : PackedScene

signal tile_scored(int)
signal scoring_complete

signal slot_highlighted(Slot)
signal slot_unhighlighted(Slot)

class SlotTileStruct:
	var slot : Slot
	var tile : GameTile
	
	func _init(p_slot : Slot = null, p_tile : GameTile = null) -> void:
		self.slot = p_slot
		self.tile = p_tile

var board_state : Array[Array] = []
var board_state_text : Array[Array] = []

#tracks whether tile is a part of a previous play, or just placed
var board_state_placed_status : Array[Array] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for y in board_size.y:
		board_state.append([])
		board_state_text.append([])
		board_state_placed_status.append([])
		for x in board_size.x:
			board_state_placed_status[y].append(false)
			board_state[y].append('')
			board_state_text[y].append('')
			var slot_pos = Vector2i(x, y) * slot_size
			var slot : Node2D = slot_scene.instantiate()
			self.add_child(slot)
			slot.name = "slot_%d-%d" % [x, y]
			slot.position = slot_pos
			slot.coordinates = Vector2i(x, y)
			board_state[y][x] = SlotTileStruct.new(slot)
			slot.highlighted.connect(_slot_highlighted)

func _input(event):
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_0:
		validate_board()

func validate_board() -> bool:
	var tiles = Evaluator.evaluate_board(board_state_text)
	var illegal_tiles = tiles["illegal"]
	var legal_tiles   = tiles["legal"]

	# ---------- dictionary errors ----------
	if illegal_tiles.size() > 0:
		for p in illegal_tiles:
			if !board_state_placed_status[p.y][p.x]:
				board_state[p.y][p.x].tile.bzzt()
		for p in legal_tiles:
			if !board_state_placed_status[p.y][p.x]:
				board_state[p.y][p.x].tile.ding()
		return false

	# ---------- positional rules ----------
	var new_tiles = get_non_locked_tile_positions()

	if !_tiles_form_single_line(new_tiles):
		for p in new_tiles: board_state[p.y][p.x].tile.bzzt()
		return false

	if !_move_touches_board(new_tiles):
		for p in new_tiles: board_state[p.y][p.x].tile.bzzt()
		return false

	return true

		
func play():
	await score_current_turn()
	update_board_state_placed_status()
	
	scoring_complete.emit()

func update_board_state_placed_status():
	if board_state_placed_status.size() != board_state_text.size():
		var row : Array[bool]
		row.resize(board_size.x)
		row.fill(false)
		board_state_placed_status.resize(board_size.y)
		board_state_placed_status.fill(row)
		print(str(board_state_placed_status))
	for y in board_state_text.size():
		for x in board_state_text[y].size():
			if board_state_text[y][x].length() > 0:
				board_state_placed_status[y][x] = true
				board_state[y][x].tile.lock_in()
				board_state[y][x].slot.has_tile = true
			else:
				board_state_placed_status[y][x] = false
			

func place_tile_at(game_tile : GameTile, target_slot : Slot):
	var target_cell : SlotTileStruct = board_state[target_slot.coordinates.y][target_slot.coordinates.x]
	var displaced_tile : GameTile      = target_cell.tile                 # tile currently in the slot
	
	game_tile.grabbed.connect(remove_tile)
	game_tile.return_to_hand.connect(remove_tile)
	# -------- locate origin slot if the dragged tile was on the board --------
	var origin_slot : Slot = null
	if game_tile.coordinates != -Vector2i.ONE:
		var origin_cell : SlotTileStruct = board_state[game_tile.coordinates.y][game_tile.coordinates.x]
		origin_slot = origin_cell.slot

	# --- handle displaced tile first ---
	if displaced_tile and displaced_tile != game_tile:
		if origin_slot:                                # swap path
			_snap_tile_to_slot(displaced_tile, origin_slot)
			displaced_tile.coordinates = origin_slot.coordinates
			board_state[origin_slot.coordinates.y][origin_slot.coordinates.x].tile = displaced_tile
			board_state_text[origin_slot.coordinates.y][origin_slot.coordinates.x] = displaced_tile.letter
		else:                                          # came from hand → bump tile out
			print("returning tile to hand")
			displaced_tile.release_from_board()

	# --- now claim the destination slot ---
	game_tile.coordinates = target_slot.coordinates
	target_cell.tile      = game_tile
	board_state_text[target_slot.coordinates.y][target_slot.coordinates.x] = game_tile.letter
	_snap_tile_to_slot(game_tile, target_slot)


func _snap_tile_to_slot(game_tile : GameTile, slot : Slot):
	var tw = create_tween()
	tw.tween_property(game_tile, "global_position", slot.global_position, 0.1)
	tw.set_ease(Tween.EASE_IN)
	game_tile.placed_on_board()   # NEW

func remove_tile(tile : GameTile):
	# ── stop listening first ───────────────────────────────
	if tile.grabbed.is_connected(remove_tile):
		tile.grabbed.disconnect(remove_tile)
	if tile.return_to_hand.is_connected(remove_tile):
		tile.return_to_hand.disconnect(remove_tile)

	# ── clear arrays while coordinates are still valid ────
	var y := tile.coordinates.y
	var x := tile.coordinates.x
	if y >= 0 and x >= 0:
		board_state_text[y][x] = ''
		board_state[y][x].tile = null

	# ── if the tile was actually returned to hand, clear coords ──
	if tile.state == GameTile.TileState.IDLE:
		tile.coordinates = -Vector2.ONE

	debug_print_board()




func debug_print_board():
	var board_string = ''
	for row in board_state_text:
		for cell in row:
			board_string += cell if cell != '' else '-'
			board_string += ' '
		board_string += '\n'
	print(board_string)


func _slot_highlighted(slot : Slot):
	slot_highlighted.emit(slot)


func _slot_unhighlighted(slot : Slot):
	slot_unhighlighted.emit(slot)

func get_non_locked_tile_positions():
	var result : Array[Vector2i] = []
	for y in board_state_text.size():
		for x in board_state_text[y].size():
			if board_state_text[y][x] and !board_state_placed_status[y][x]:
				result.append(Vector2i(x, y))
				
	return result
	
# ------------------------------------------------------------------

func score_current_turn() -> int:
	var new_tiles : Array[Vector2i] = get_non_locked_tile_positions()
	if new_tiles.is_empty():
		return 0

	# -------- gather all words formed this turn --------
	var words : Array = _collect_words(new_tiles)
	if words.is_empty():
		return 0
		
	# -------- lock tiles after successful move --------
	for p in new_tiles:
		board_state_placed_status[p.y][p.x] = true
		board_state[p.y][p.x].tile.lock_in()

	var turn_points := 0
	for word in words:
		turn_points += await _score_word(word)



	return turn_points


# ===== helpers ====================================================

func _collect_words(new_tiles : Array[Vector2i]) -> Array:
	var seen := {}           # avoid duplicates
	var words : Array = []

	for p in new_tiles:
		# horizontal (scan left + right)
		var w = _scan_from(p, Vector2i(-1,0)) \
			   + board_state_text[p.y][p.x] \
			   + _scan_from(p, Vector2i(1,0))
		if w.length() >= 2 and not seen.has(w):
			words.append({ "text": w, "tiles": _tiles_of_word(p, Vector2i(1,0)) })
			seen[w] = true

		# vertical (scan up + down)
		w = _scan_from(p, Vector2i(0,-1)) \
			+ board_state_text[p.y][p.x] \
			+ _scan_from(p, Vector2i(0,1))
		if w.length() >= 2 and not seen.has(w):
			words.append({ "text": w, "tiles": _tiles_of_word(p, Vector2i(0,1)) })
			seen[w] = true

	return words


func _scan_from(start : Vector2i, dir : Vector2i) -> String:
	var s := ""
	var cur := start + dir
	while cur.x >= 0 and cur.x < board_size.x and cur.y >= 0 and cur.y < board_size.y:
		var ch = board_state_text[cur.y][cur.x]
		if ch == "":
			break
		s     =  ch + s if dir.x + dir.y < 0 else s + ch   # prepend if scanning left/up
		cur  += dir
	return s


func _tiles_of_word(start : Vector2i, step : Vector2i) -> Array[Vector2i]:
	# assumes word is contiguous; walk left/up to find beginning
	var begin := start
	while true:
		var nxt := begin - step
		if nxt.x < 0 or nxt.x >= board_size.x or nxt.y < 0 or nxt.y >= board_size.y:
			break
		if board_state_text[nxt.y][nxt.x] == "":
			break
		begin = nxt

	var coords : Array[Vector2i] = []
	var cur := begin
	while cur.x < board_size.x and cur.y < board_size.y \
		  and board_state_text[cur.y][cur.x] != "":
		coords.append(cur)
		cur += step
	return coords


func _score_word(info : Dictionary) -> int:
	var tiles : Array = info["tiles"]
	var word_mult := 1
	var letter_pts := 0

	for pos in tiles:
		var tile = board_state[pos.y][pos.x].tile
		var letter_score = tile.score
		
		letter_pts += letter_score
		tile_scored.emit(letter_pts)
		await tile.animate_score()
		

	return letter_pts * word_mult
	
	
	# ───────── helper: does at least one new tile touch an old tile? ─────────
func _move_touches_board(new_tiles : Array[Vector2i]) -> bool:
	# if nothing is locked yet, it's the first move – allow it
	var board_empty = true
	for row in board_state_placed_status:
		if row.has(true):
			board_empty = false
			break
	if board_empty:
		return true   # board empty ⇒ first turn

	for p in new_tiles:
		for dir in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
			var q  = p + dir
			if q.x < 0 or q.x >= board_size.x or q.y < 0 or q.y >= board_size.y:
				continue
			if board_state_placed_status[q.y][q.x]:
				return true   # touches an existing locked tile
	return false
	
func _tiles_form_single_line(tiles : Array[Vector2i]) -> bool:
	# 0-or-1 tile → trivially OK (single-letter play or first move)
	if tiles.size() <= 1:
		return true

	var same_row := true
	var same_col := true
	var y0 := tiles[0].y
	var x0 := tiles[0].x

	for p in tiles:
		if p.y != y0:
			same_row = false
		if p.x != x0:
			same_col = false

	if not (same_row or same_col):
		return false			# not all in one row or one column

	# -------- ensure no gaps --------
	if same_row:
		tiles.sort_custom(func(a,b): return a.x < b.x)
		for i in range(tiles.size() - 1):
			if tiles[i+1].x != tiles[i].x + 1:
				return false
	else: # same_col
		tiles.sort_custom(func(a,b): return a.y < b.y)
		for i in range(tiles.size() - 1):
			if tiles[i+1].y != tiles[i].y + 1:
				return false

	return true
