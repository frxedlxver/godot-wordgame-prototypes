class_name Rune
extends Resource

@export var name        : String
@export var description : String
@export var icon        : Texture2D

func before_tile_scored(ctx : Dictionary) -> Array[RuneEffect]:
	return []
	
func after_tile_scored(ctx : Dictionary) -> Array[RuneEffect]:
	return []

func after_word_scored(ctx : Dictionary) -> Array[RuneEffect]:
	return []

func draw_effects(tile : GameTile) -> Array[RuneEffect]:
	return []

func round_start_effects(ctx : Dictionary) -> Array[RuneEffect]:
	return []

func round_end_effects(ctx : Dictionary) -> Array[RuneEffect]:
	return []
