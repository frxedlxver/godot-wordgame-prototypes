class_name Singles extends Rune


# Called when the node enters the scene tree for the first time.
func _init() -> void:
	name = "Singles"
	description = "Multiplier +5 for each letter when no letters are repeated in a word"
	icon = load("res://sprites/runes/singles.png")


func after_tile_scored(ctx : Dictionary) -> Array[RuneEffect]:
	# Guard: ctx may not contain "word"
	var word : String = ctx.get("word", "")
	if word.is_empty():
		return []

	# Case-insensitive duplicate check (optional)
	word = word.to_upper()

	var seen := {}
	for ch in word:
		if seen.has(ch):
			return []		# duplicate letter → no bonus
		seen[ch] = true

	# All letters unique → grant multiplier bonus
	var eff := RuneEffect.new()
	eff.type  = RuneEffect.RuneEffectType.ADD_MULTIPLIER
	eff.value = 5
	eff.exclamation = "+5 MULT"
	print("Singles value : %d" % eff.value)
	return [eff]			# <-- ALWAYS wrap in an array
