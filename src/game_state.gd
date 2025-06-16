class_name GameState extends Node

var current_run_data : RunData
var rng : RandomNumberGenerator

func prepare_rng() -> void:
	rng = RandomNumberGenerator.new()
	if current_run_data.rng_state != 0:
		rng.state = current_run_data.rng_state
	else:
		rng.seed  = _string_to_seed(current_run_data.rng_seed)

func _string_to_seed(str : String) -> int:
	var h : int = 0x811c9dc5              # 32-bit offset
	for b in str.to_utf8_buffer():
		h ^= b
		h = (h * 0x01000193) & 0xFFFFFFFF # 32-bit prime
	return h                              # 0 … 2^32-1  (well inside range)
