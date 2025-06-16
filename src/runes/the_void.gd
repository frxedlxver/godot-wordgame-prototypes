class_name TheVoid extends Rune

func _init():
	name = "The Void"
	description = "Vowels are worth 0, but consonants are worth double"
	icon = load("res://sprites/runes/void.png")

func before_tile_scored(ctx : Dictionary) -> Array[RuneEffect]:
	var effect = RuneEffect.new()
	effect.type = RuneEffect.RuneEffectType.NO_OP
	if LettersNumbers.is_vowel(ctx["tile"].letter):
		effect.type = RuneEffect.RuneEffectType.ZERO_TILE_SCORE
	else:
		effect.type = RuneEffect.RuneEffectType.MUL_TILE_SCORE
		effect.value = 2
	return [effect]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
