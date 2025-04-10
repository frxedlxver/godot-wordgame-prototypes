class_name Unscrambler extends Node


# Public ---------------------------------------------------------------------
static func unscramble(scrambled_text: String) -> Array[String]:
	var result: Array[String] = []
	var all_permutations : Array[String] = get_all_permutations(scrambled_text)
	for permutation in all_permutations:
		if WORD_CHECKER.check_for_word(permutation):
			result.append(permutation)
			
	print("found %d permutations, %d of which are words" % [all_permutations.size(), result.size()])
	return result


static func get_all_permutations(scrambled_text: String) -> Array[String]:
	# Split the string into a PackedStringArray of single‑character substrings
	var chars: PackedStringArray = scrambled_text.split("")
	var out: Array[String] = []
	_build_permutations("", chars, out)
	return out


# Private --------------------------------------------------------------------

static func _build_permutations(prefix: String, remaining: PackedStringArray, out: Array[String]) -> void:
	# Any non‑empty prefix is already a valid permutation
	if prefix.length() > 0:
		out.append(prefix)
	
	# Try each still‑unused character in the next position
	for i in remaining.size():
		var next_prefix := prefix + remaining[i]
		var next_remaining: PackedStringArray = remaining.duplicate()
		next_remaining.remove_at(i)
		_build_permutations(next_prefix, next_remaining, out)
