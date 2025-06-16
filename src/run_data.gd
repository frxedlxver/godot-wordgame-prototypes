# tabs for indentation
class_name RunData extends Resource

@export var in_progress		: bool					= false
@export var money			: int					= 0
@export var tile_bag		: Array[GameTileData]	= []
@export var last_round_won	: int					= 0
@export var max_hand_size	: int					= 7
@export var runes			: Array[Rune]			= []
@export var rng_seed		: String				= ""
@export var rng_state		: int					= 0
@export var max_runes		: int					= 6

# ----------------------------------------------------------------
func start_new_run(seed : String = "") -> void:
	reinitialize()
	if seed == "":
		seed = _generate_random_seed()

	rng_seed  = seed          # ← FIX ① assign it
	rng_state = 0             # ← FIX ② clear state
	in_progress = true
	tile_bag  = GameTileFactory.create_default_bag()


func finish_run() -> void:
	in_progress = false        # won, lost, abandoned

func reinitialize() -> void:
	in_progress  = false
	money        = 0
	tile_bag.clear()
	last_round_won = 0
	max_hand_size  = 7
	rng_seed     = ""        # ← recommended so next run can see “unspecified”
	rng_state    = 0
	runes.clear()

func _generate_random_seed() -> String:
	var seed_length := 8
	var chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".split("")
	var result := ""
	for i in range(seed_length):         # ← FIX ③ range()
		result += chars[randi_range(0, chars.size() - 1)]
	return result

		
