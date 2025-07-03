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

# 1) Move every tile that is on the BOARD back into the HAND
func return_board_to_hand() -> void:
	# Abort if either side isn’t registered
	if _board == null or _hand == null:
		return
	
	var copy : Array[GameTile] = []
	for child in _board.get_children():
		if child is GameTile:
			copy.append(child)

	for tile in copy:
		_board.remove_tile(tile)
		_hand.add_to_hand(tile)
		tile.set_state(GameTile.TileState.IDLE)	# reset state
		
		

func return_all_to_bag(bag : Bag, bag_ui : BagUI) -> void:
	if bag == null:
		return
	
	if bag_ui == null:
		push_warning("Bag UI icon missing; skipping fly animation")
		_perform_logical_return(bag)
		return


	var tiles : Array[GameTile] = []
	if _board:
		tiles.append_array(_board.get_non_locked_tiles())
	if _active_tile:
		tiles.append(_active_tile)
	if _hand:
		tiles.append_array(_hand.game_tiles)

	if tiles.is_empty():
		return
	
	var on_tw_finished = func(tile : GameTile):
		tile.scale = Vector2.ONE
		bag.add_to_bag(tile, true)
	var tweens : Array[Tween] = []
	for tile in tiles:
		if tile.get_parent() is Board:
			_board.remove_tile(tile)
		else:
			_hand.remove_from_hand(tile)
		var tw := create_tween()
		tw.tween_property(tile, "global_position", bag_ui.global_position, 0.15)
		tw.parallel().tween_property(tile, "scale", Vector2(0.05, 0.05), 0.15)

		tw.finished.connect(func(): on_tw_finished.call(tile))
		tweens.append(tw)
		await get_tree().create_timer(0.01).timeout

	await tweens[-1].finished


	_perform_logical_return(bag)


# Helper with your original logic, unchanged except for duplicate() safety
func _perform_logical_return(bag : Bag) -> void:
	# ----- Board -------------------------------------------------------
	if _board:
		for tile in _board.get_non_locked_tiles().duplicate():
			_board.remove_tile(tile)
			bag.add_to_bag(tile)

	# Active tile was never parented to the board/hand after grab
	if _active_tile:
		_hand.add_to_hand(_active_tile)
		bag.add_to_bag(_active_tile)
		_active_tile = null

	# ----- Hand --------------------------------------------------------
	if _hand:
		for tile in _hand.game_tiles.duplicate():
			_hand.remove_from_hand(tile)
			bag.add_to_bag(tile)

# ───────────────────────── signal callbacks ──────────────────────────
func _on_tile_grabbed(tile : GameTile) -> void:
	_active_tile = tile
	tile.z_index = 1000
	
	# 1. Detach from whatever parent (Hand or Board) immediately
	var tile_parent = tile.get_parent()
	if tile_parent is Hand:
		_hand.remove_from_hand(tile)
	elif tile_parent is Board:
		_board.remove_tile(tile)
	# 3. Tell the hand to start gap preview (it keeps tile in its list purely
	#    as a placeholder; being outside its node tree is fine)
	_hand.start_preview(tile)


func _on_tile_released(tile : GameTile) -> void:
	_active_tile = null
	tile.z_index = 1
	_hand.stop_preview()             # <<< remove gap preview

	var dst_slot : SlotNode = _hand.get_highlighted_slot()
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
	if tile.get_parent() is Board:
		_board.remove_tile(tile)
	_hand.stop_preview()
	_hand.add_to_hand(tile)

# optional helper if you instantiate many tiles at once
func connect_all_tiles_in(node : Node) -> void:
	for c in node.get_children():
		if c is GameTile:
			register_tile(c)
