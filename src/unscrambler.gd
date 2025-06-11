class_name Unscrambler extends Node

static var _dict_index : _DictIndex = _DictIndex.new()

const txt_dictionary_path = "res://EnableDictionary.txt"

class _DictIndex:
	var by_sig : Dictionary = {}			# PackedByteArray → [ "word", … ]
	var built : bool = false

	func _ensure_built() -> void:
		if built:
			return
		var f := FileAccess.open(txt_dictionary_path, FileAccess.READ)
		var freq : Array[int] = []
		freq.resize(26)
		while not f.eof_reached():
			var w := f.get_line().strip_edges()
			if w.length() == 0:				# skip blanks
				continue
			var sig := Unscrambler._sig(w)
			by_sig[sig] = by_sig.get(sig, []) + [w]
			for i in sig.size(): freq[i] += sig[i]
		var tot = 0
		for i in freq:
			tot += i
		for i in freq.size():
			print("%s: %f%%" % [char(i + 97), (float(freq[i]) / float(tot)) * 100])
		f.close()
		built = true

# Public ---------------------------------------------------------------------
static func unscramble(scrambled_text : String) -> Array[String]:
	# Build the index once (fast the second time)
	_dict_index._ensure_built()

	var pool_sig := _sig(scrambled_text)
	var results : Array[String] = []

	# Iterate over *signatures*, not permutations
	for sig_key in _dict_index.by_sig.keys():
		if _sig_is_subset(sig_key, pool_sig):
			results.append_array(_dict_index.by_sig[sig_key])
	
	print(results)

	print("found %d words for %s" % [results.size(), scrambled_text])
	return results


static func _sig(text : String) -> PackedByteArray:
	var v := PackedByteArray()
	v.resize(26)                          # 26 counters for a–z, all zero
	for c in text:
		var i := c.to_lower().to_ascii_buffer()[0] - 97   # 'a' → 0 … 'z' → 25
		if i >= 0 and i < 26:
			v[i] += 1
	return v

const ALPHABET : int = 26
static func _sig_is_subset(word_sig : PackedByteArray, pool_sig : PackedByteArray) -> bool:
	for i in ALPHABET:
		if word_sig[i] > pool_sig[i]:
			return false
	return true




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
