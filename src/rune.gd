class_name Rune
extends Resource

@export var name        : String
@export var description : String
@export var icon        : Texture2D

func tile_effects(ctx : Dictionary) -> Array[RuneEffect]:
	return []				# default: no change

func word_effects(ctx : Dictionary) -> Array[RuneEffect]:
	return []

func draw_effects(tile : GameTile) -> Array[RuneEffect]:
	return []

func round_start_effects(ctx : Dictionary) -> Array[RuneEffect]:
	return []

func round_end_effects(ctx : Dictionary) -> Array[RuneEffect]:
	return []
