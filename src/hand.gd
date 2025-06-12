class_name Hand extends Node2D

var game_tiles : Array[GameTile]
var grabbed_tile : GameTile
var game_tile_target_positions : Array[Vector2]

const TILE_SIZE = 32;
const TILE_MAX_SEP = 48;
const MAX_HAND_WIDTH = TILE_SIZE * 10;
const HAND_CENTER = MAX_HAND_WIDTH / 2;

var want_reindex : bool = false

var grabbed_tile_prev_index = 0

signal tile_grabbed(GameTile)
signal tile_released(GameTile)
signal tile_placed(GameTile, Slot)

func _ready() -> void:
	$Area2D.area_exited.connect(_area2d_area_exited)
	$Area2D.area_entered.connect(_area2d_area_entered)
	
func _process(delta: float) -> void:
	if grabbed_tile != null or want_reindex:
		want_reindex = false
		reindex_tiles()
		reorder_game_tiles()


func add_to_hand(game_tile : GameTile, starting_position = null):
	self.add_child(game_tile)
	if starting_position and starting_position is Vector2:
		game_tile.global_position = starting_position
	self.game_tiles.append(game_tile)
	reorder_game_tiles()
	game_tile.grabbed.connect(_tile_grabbed)
	game_tile.return_to_hand.connect(_tile_return_to_hand_requested)
	game_tile.released.connect(_tile_released)

func remove_from_hand(game_tile : GameTile):
	if game_tile.get_parent() == self:
		self.remove_child(game_tile)
	self.game_tiles.erase(game_tile)
	reorder_game_tiles()

func reindex_tiles():
	# reorganize array, sort left to right
	game_tiles.sort_custom(
		func(a: GameTile, b: GameTile) -> bool:
			return a.position.x < b.position.x
	)

func reorder_game_tiles() -> void:
	_dedupe_and_prune_tiles()          # <- add this line

	var count = game_tiles.size()
	game_tile_target_positions = []
	if count == 0:
		return

	var sep = min(TILE_MAX_SEP, MAX_HAND_WIDTH / count)
	var span = (count - 1) * sep
	var start_x = -span * 0.5

	for i in count:
		var pos = Vector2(start_x + i * sep, 0)
		game_tile_target_positions.append(pos)

	tween_tiles()


func tween_tiles():
	for i in game_tiles.size():
		var tile = game_tiles[i]
		if tile.state in [GameTile.TileState.IDLE, GameTile.TileState.RELEASED]:
			var pos = game_tile_target_positions[i]
			var tw = create_tween()
			tw.tween_property(tile, "position", pos, 0.2)
			tw.set_ease(Tween.EASE_OUT)

func _area2d_area_entered(area):
	var tile = area.get_parent()
	if tile is GameTile and not game_tiles.has(tile):
		game_tiles.append(tile)
		want_reindex = true

func _area2d_area_exited(area):
	var tile = area.get_parent()
	if tile is GameTile:
		game_tiles.erase(tile)
		want_reindex = true
		
func _tile_grabbed(gametile : GameTile):
	grabbed_tile = gametile
	gametile.z_index = 1000
	tile_grabbed.emit(gametile)


	
func _tile_released(gametile : GameTile):
	grabbed_tile = null
	
	gametile.z_index = 1
	
	want_reindex = true
	tile_released.emit(gametile)
	
	
	var current_slot = get_highlighted_slot()
	if current_slot:
		tile_placed.emit(gametile, current_slot)
		gametile.placed_on_board()
	else:
		_tile_return_to_hand_requested(gametile)

func _tile_return_to_hand_requested(game_tile : GameTile):
	if !game_tiles.has(game_tile):
		game_tiles.append(game_tile)
	want_reindex = true
	
func get_highlighted_slot():
	var query_params = PhysicsPointQueryParameters2D.new()
	query_params.position = get_global_mouse_position()
	query_params.collide_with_areas = true
	var contacts = get_world_2d().direct_space_state.intersect_point(query_params)

	for col in contacts:
		var area_owner = col.collider.get_parent()
		if area_owner is Slot:
			return area_owner if area_owner.empty() else null
			
	return null
		
func tile_count():
	return game_tiles.size()

func _dedupe_and_prune_tiles() -> void:
	var unique : Array[GameTile] = []
	for t in game_tiles:
		if t == null:
			continue
		if not unique.has(t):
			unique.append(t)
	game_tiles = unique
