class_name GameTileFactory

const game_tile_scene_path : String = "res://scenes/game_tile.tscn"
static var game_tile_scene : PackedScene = preload(game_tile_scene_path)

static func create_tile_from_data(gtd : GameTileData):
	if gtd.letter.length() != 1:
		return
	else:
		var tile_node = game_tile_scene.instantiate()
		tile_node.data = gtd
		tile_node.letter = gtd.letter
		tile_node.score = gtd.score
		return tile_node

static func duplicate_tile(tile : GameTile):
	if tile != null:
		return tile.instantiate()


static func create_default_bag() -> Array[GameTileData]:
	var result : Array[GameTileData] =  []
	for letter in LettersNumbers.STARTING_LETTERS.keys():
		var score = LettersNumbers.LETTER_SCORES[letter]
		var count = LettersNumbers.STARTING_LETTERS[letter]
		for i in count:
			var gtd = GameTileData.new()
			gtd.letter = letter
			gtd.score = score
			result.append(gtd)
	return result
