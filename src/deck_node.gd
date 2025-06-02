class_name Bag extends Node2D

@onready var round_manager : RoundManager = get_parent()
var game_tiles : Array[GameTile]




func initialize():
	for letter in LettersNumbers.STARTING_LETTERS.keys():
		var amount = LettersNumbers.STARTING_LETTERS[letter]
		for i in amount:
			add_to_bag(GameTileFactory.create_tile(letter))
	game_tiles.shuffle()

func add_to_bag(game_tile : GameTile):
	self.game_tiles.append(game_tile)
	$TextEdit.text = str(game_tiles.size())
func shuffle():
	game_tiles.shuffle()

func draw_tile():
	if game_tiles.size() > 0:
		return game_tiles.pop_back()
