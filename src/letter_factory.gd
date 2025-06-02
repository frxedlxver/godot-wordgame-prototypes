class_name GameTileFactory

const game_tile_scene_path : String = "res://scenes/game_tile.tscn"

static func create_tile(letter : String, score = -1, tile : GameTile = null):
	if tile != null:
		return tile.instantiate()
	if letter.length() != 1:
		return
	else:
		var tile_node = preload(game_tile_scene_path).instantiate()
		tile_node.letter = letter
		if score != -1:
			tile_node.score = score
		else:
			tile_node.score = LettersNumbers.LETTER_SCORES[letter]
		return tile_node
		
