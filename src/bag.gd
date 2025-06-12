class_name Bag extends Node2D

var game_tiles : Array[GameTile]

signal tile_count_changed(int)

func initialize_from(bag_data : Array[GameTileData]):
	for gtd in bag_data:
		var tile = GameTileFactory.create_tile_from_data(gtd)
		if tile and tile is GameTile:
			add_to_bag(tile)
	shuffle()

func add_to_bag(game_tile : GameTile):
	self.game_tiles.append(game_tile)
	tile_count_changed.emit(game_tiles.size())
	
func shuffle():
	game_tiles.shuffle()

func draw_tile():
	if game_tiles.size() > 0:
		var drawn_tile = game_tiles.pop_back()
		tile_count_changed.emit(game_tiles.size())
		return drawn_tile
		
func is_empty():
	return game_tiles.size() == 0
