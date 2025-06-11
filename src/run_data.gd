class_name RunData extends Resource

enum RunState {
	FRESH,
	ROUND
}
var money : int = 0
var tile_bag : Array[GameTileData] = []
var last_round_won : int = 0
var state : RunState = RunState.FRESH
