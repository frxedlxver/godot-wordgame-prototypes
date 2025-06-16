class_name VowelPower extends Rune

func _init():
	name = "Vowel Power"
	description = "Gain 5 points when a vowel is scored"
	icon = load("res://sprites/runes/vowelpower.png")

func before_tile_played(ctx : Dictionary) -> Array[RuneEffect]:
	var tile : GameTile = ctx["tile"]
	
	if ['a','e','i','o','u'].has(tile.letter.to_lower()):
		var effect = RuneEffect.new()
		effect.type = RuneEffect.RuneEffectType.ADD_TILE_SCORE
		effect.exclamation = "+5"
		effect.value = 5
		return [effect]
	return []


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
