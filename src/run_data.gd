# tabs for indentation
class_name RunData extends Resource

@export var in_progress    : bool                 = false
@export var money          : int                  = 0
@export var tile_bag       : Array[GameTileData]  = []
@export var last_round_won : int                  = 0
@export var max_hand_size  : int                  = 7

# ----------------------------------------------------------------
func start_new_run() -> void:
	reinitialize()
	in_progress = true
	tile_bag = GameTileFactory.create_default_bag()

func finish_run() -> void:
	in_progress = false        # won, lost, abandoned

func reinitialize() -> void:
	in_progress     = false
	money           = 0
	tile_bag.clear()
	last_round_won  = 0
	max_hand_size   = 7
