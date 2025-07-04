# tabs for indentation
class_name Evaluator extends Node2D

static var board_size : Vector2i = Board.BOARD_SIZE
const MIN_WORD_LEN := 2

static func evaluate_board(board : Array[Array]):
	# ── 1. scan both directions ───────────────────────────────────────
	var h_ret = _scan(board, true)
	var h_infos  = h_ret[0]		# [{word:String, coords:Array[Vector2i]}, …]
	var h_cover  = h_ret[1]		# bool grid: any ≥2-letter horiz run

	var v_ret = _scan(board, false)
	var v_infos = v_ret[0]
	var v_cover = v_ret[1]

	# ── 2. build cover grid for *valid* words only ────────────────────
	var legal_cover : Array = []
	for y in range(board_size.y):
		legal_cover.append([])
		for x in range(board_size.x):
			legal_cover[y].append(false)

	var add_to_legal_cover = func(coords : Array):
		for p in coords:
			legal_cover[p.y][p.x] = true

	for info in h_infos:
		if info["word"].length() >= MIN_WORD_LEN and WORD_CHECKER.check_for_word(info["word"]):
			add_to_legal_cover.call(info["coords"])
	for info in v_infos:
		if info["word"].length() >= MIN_WORD_LEN and WORD_CHECKER.check_for_word(info["word"]):
			add_to_legal_cover.call(info["coords"])

	# ── 3. collect *every* invalid word and all of its tiles ─────────
	var bad_words    : Array[String]   = []
	var illegal_tiles: Array[Vector2i] = []

	var push_if_invalid = func(info):
		if info["word"].length() >= MIN_WORD_LEN \
		   and not WORD_CHECKER.check_for_word(info["word"]):
			bad_words.append(info["word"])
			for p in info["coords"]:
				illegal_tiles.append(p)			# add all letters (shared or not)

	for info in h_infos:
		push_if_invalid.call(info)
	for info in v_infos:
		push_if_invalid.call(info)
	# ── 4. add orphan tiles (not in *any* ≥2-letter run) ──────────────
	for y in range(board_size.y):
		for x in range(board_size.x):
			if board[y][x] != "":
				if not (h_cover[y][x] or v_cover[y][x]):
					illegal_tiles.append(Vector2i(x, y))

	# ── 5. deduplicate tiles (Array.unique() isn’t available) ─────────
	var seen := {}
	var dedup : Array[Vector2i] = []
	for p in illegal_tiles:
		if not seen.has(p):
			seen[p] = true
			dedup.append(p)
	illegal_tiles = dedup
	
	# ── 6. collect legal tiles ────────────────────────────────────────
	var illegal_set : Dictionary = {}
	for p in illegal_tiles:
		illegal_set[p] = true

	var legal_tiles : Array[Vector2i] = []
	for y in range(board_size.y):
		for x in range(board_size.x):
			if board[y][x] != "":
				var pos := Vector2i(x, y)
				if not illegal_set.has(pos):
					legal_tiles.append(pos)

	# ── 6. report ─────────────────────────────────────────────────────
	if bad_words.is_empty() and illegal_tiles.is_empty():
		print("legal")
	else:
		if bad_words.size() > 0:
			print("illegal – bad words:", bad_words)
		if illegal_tiles.size() > 0:
			print("illegal – tiles at:", illegal_tiles)
			
	return { "illegal": illegal_tiles, "legal": legal_tiles }


# ───────────────── helpers ────────────────────────────────────────────
static func _scan(board : Array[Array], horizontal : bool):
	# returns [Array[Dictionary] infos, Array[Array[bool]] cover_grid]
	# each info = { "word": String, "coords": Array[Vector2i] }

	var infos : Array = []
	var cover : Array = []
	for _y in range(board_size.y):
		cover.append([])
		for _x in range(board_size.x):
			cover[_y].append(false)

	var outer = board_size.y if horizontal else board_size.x
	var inner = board_size.x if horizontal else board_size.y

	for i in range(outer):
		var current   := ""
		var start_pos := -1
		for j in range(inner):
			var y = i if horizontal else j
			var x = j if horizontal else i
			var ch = board[y][x]

			if ch != "":
				if current == "":
					start_pos = j
				current += ch
			if ch == "" or j == inner - 1:
				if current.length() > 0:
					var coords : Array[Vector2i] = []
					for k in range(current.length()):
						var yy = i if horizontal else start_pos + k
						var xx = start_pos + k if horizontal else i
						coords.append(Vector2i(xx, yy))
						if current.length() >= MIN_WORD_LEN:
							cover[yy][xx] = true
					infos.append({ "word": current, "coords": coords })
				current   = ""
				start_pos = -1
	# done
	return [infos, cover]
