# tabs for indentation, per your style note
class_name Evaluator extends Node2D

static var board_size : Vector2i = Board.board_size
const MIN_WORD_LEN := 2

static func evaluate_board(board : Array[Array]) -> void:
	# 1) find all horizontal words and mark the tiles they cover
	var h_return = _scan(board, true)
	var horiz_words = h_return[0]
	var horiz_cover = h_return[1]
	# 2) find all vertical words and mark the tiles they cover
	var v_return = _scan(board, false)
	var vert_words = v_return[0]
	var vert_cover = v_return[1]
	
	# 3) validate every ≥2-letter word
	var bad_words : Array[String] = []
	for w in horiz_words + vert_words:
		if not WORD_CHECKER.check_for_word(w):
			bad_words.append(w)

	# 4) verify every tile is in at least one covered set
	var orphans : Array[Vector2i] = []
	for y in range(board_size.y):
		for x in range(board_size.x):
			if board[y][x] != "":
				if not (horiz_cover[y][x] or vert_cover[y][x]):
					orphans.append(Vector2i(x, y))

	# 5) report
	if bad_words.is_empty() and orphans.is_empty():
		print("legal")
	else:
		if bad_words.size() > 0:
			print("illegal – bad words:", bad_words)
		if orphans.size() > 0:
			print("illegal – orphan tiles at:", orphans)


# ───────────────── helpers ─────────────────
static func _scan(board : Array[Array], horizontal : bool):
	# returns [Array[String] words, Array[Array[bool]] cover_grid]
	var words  : Array[String] = []
	var cover  : Array = []
	for _i in range(board_size.y):
		cover.append([])						# bool grid same size as board
		for _j in range(board_size.x):
			cover[_i].append(false)

	var outer := board_size.y if horizontal else board_size.x
	var inner := board_size.x if horizontal else board_size.y

	for i in range(outer):
		var current := ""
		var start_pos := -1
		for j in range(inner):
			var y := i
			var x := j
			if not horizontal:
				y = j
				x = i
			var ch = board[y][x]

			if ch != "":
				if current == "":
					start_pos = j			# first letter in this run
				current += ch
			if ch == "" or j == inner - 1:
				if current.length() >= MIN_WORD_LEN:
					words.append(current)
					# mark covered tiles for this word
					for k in range(current.length()):
						var yy := y
						var xx := x
						if horizontal:
							yy = i
							xx = start_pos + k
						else:
							yy = start_pos + k
							xx = i
						cover[yy][xx] = true
				# reset for next run
				current = ""
	# done
	return [words, cover]
