# tabs for indentation
class_name TileManipulator
extends Node2D



var _hand  : Hand
var _board : Board
var _active_tile : GameTile = null

func register_hand_board(hand : Hand, board: Board):
	self._hand = hand
	self._board = board

func clear_registrations():
	self._hand = null
	self._board = null
	
func _process(delta: float) -> void:
	if _active_tile:
		_active_tile.global_position = get_global_mouse_position()

# call for every tile you spawn
func register_tile(tile : GameTile) -> void:
	if not tile.grabbed.is_connected(_on_tile_grabbed):
		tile.grabbed.connect(_on_tile_grabbed)
	if not tile.released.is_connected(_on_tile_released):
		tile.released.connect(_on_tile_released)
	if not tile.return_to_hand.is_connected(_on_tile_return):
		tile.return_to_hand.connect(_on_tile_return)

# ───────────────────────── signal callbacks ──────────────────────────
func _on_tile_grabbed(tile : GameTile) -> void:
	_active_tile = tile
	tile.z_index = 1000

	# 1. Detach from whatever parent (Hand or Board) immediately
	var gpos := tile.global_position
	var tile_parent = tile.get_parent()
	if tile_parent is Hand:
		_hand.remove_from_hand(tile)
	elif tile_parent is Board:
		_board.remove_tile(tile)
	get_tree().current_scene.add_child(tile)   # temporary root-level owner
	tile.global_position = gpos                # restore visual position

	# 2. If it came from the board, update board state
	if tile.coordinates != -Vector2i.ONE:
		_board.remove_tile(tile)               # clears board grids
		tile.coordinates = -Vector2i.ONE       # mark “no slot yet”

	# 3. Tell the hand to start gap preview (it keeps tile in its list purely
	#    as a placeholder; being outside its node tree is fine)
	_hand.start_preview(tile)


func _on_tile_released(tile : GameTile) -> void:
	_active_tile = null
	tile.z_index = 1
	_hand.stop_preview()             # <<< remove gap preview

	var dst_slot : Slot = _hand.get_highlighted_slot()
	# TileManipulator.gd  (inside _on_tile_released)
	if dst_slot and _board.can_place_at(dst_slot):
		_hand.remove_from_hand(tile)            #    (unparents from Hand)
		_board.place_tile_at(tile, dst_slot)    # 4) slide into slot
		tile.placed_on_board()
		_active_tile = null
	else:
		_hand.add_to_hand(tile)
		tile.set_state(GameTile.TileState.IDLE)



func _on_tile_return(tile : GameTile) -> void:
	_hand.stop_preview()
	_hand.add_to_hand(tile)

# optional helper if you instantiate many tiles at once
func connect_all_tiles_in(node : Node) -> void:
	for c in node.get_children():
		if c is GameTile:
			register_tile(c)
