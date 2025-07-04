class_name Bag extends Node2D

var game_tiles : Array[GameTile]

signal tile_count_changed(int, bool)

func initialize_from(bag_data : Array[GameTileData]):
	for gtd in bag_data:
		var tile = GameTileFactory.create_tile_from_data(gtd)
		if tile and tile is GameTile:
			add_to_bag(tile)
	shuffle()

func add_to_bag(game_tile : GameTile, animate : bool = false):
	game_tile.set_state(GameTile.TileState.IDLE)
	self.game_tiles.append(game_tile)
	if game_tile.get_parent():
		game_tile.get_parent().remove_child(game_tile)
	
	tile_count_changed.emit(game_tiles.size(), animate)
	
func shuffle() -> void:
	var n := game_tiles.size()
	for i in range(n - 1, 0, -1):          # i = n-1 … 1
		var j := G.rng.randi_range(0, i)     # 0 ≤ j ≤ i
		if i == j:
			continue
		var tmp := game_tiles[i]
		game_tiles[i] = game_tiles[j]
		game_tiles[j] = tmp


func draw_tile():
	if game_tiles.size() > 0:
		var drawn_tile = game_tiles.pop_back()
		tile_count_changed.emit(game_tiles.size())
		return drawn_tile
		
func is_empty():
	return game_tiles.size() == 0
	
	
func ensure_balanced_draw():
	var balanced_draw_available = false
	while !balanced_draw_available:
		var vowel_count = 0
		for i in range(1, G.current_run_data.max_hand_size + 1):
			if LettersNumbers.is_vowel(game_tiles[-i].letter):
				vowel_count += 1
		print("vowel_count: ", vowel_count)
		if vowel_count >= 2 and vowel_count <= 4:
			balanced_draw_available = true
		else:
			shuffle()
