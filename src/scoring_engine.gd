# tabs for indentation
##  ScoringEngine.gd  ────────────────────────────────────────────────────────
class_name ScoringEngine
extends Node          # Autoload

const TIME_BETWEEN_ANIMATIONS = 0.2

signal turn_score_updated(new_score : int)
signal turn_mult_updated(new_mult : int)
signal score_calculation_complete(points:int, mult:int)

func validate_turn(
		board_text  : Array,      # Array[Array[String]]
		placed_mask : Array,      # Array[Array[bool]]
		new_tiles   : Array       # Array[Vector2i]
) -> bool:

	# 1. positional rules --------------------------------------------------
	if not _tiles_form_single_line(board_text, new_tiles) \
	or	not _move_touches_board(placed_mask, board_text, new_tiles):
		return false

	# 2. dictionary rules --------------------------------------------------
	var dict_check = Evaluator.evaluate_board(board_text)
	if dict_check["illegal"].size() > 0:
		return false

	# 3. collect words -----------------------------------------------------
	var words = _collect_words(board_text, new_tiles)
	if words.is_empty():
		return false

	return true
	
# ───────────────────────  public entry  ─────────────────────────────────────
func score_turn(
		board_text   : Array,      # Array[Array[String]]
		board_tiles  : Array,      # Array[Array[GameTile]]
		placed_mask  : Array,      # Array[Array[bool]]
		new_tiles    : Array       # Array[Vector2i]
) -> void:

	var turn_pts : int = 0
	var turn_mul : int = 1

	var words = _collect_words(board_text, new_tiles)
	# 2. score each word (plays SFX & tweens inline) -------------------------
	var pitch : float = 0.0
	for w in words:
		var res := await _score_word(w, pitch, turn_pts, turn_mul, board_tiles)

		turn_pts = res.turn_pts
		turn_mul = res.turn_mul
		pitch   += w["text"].length() * 0.04
		
		var word_ctx = {
			"word" : w["text"],
			"words" : words
		}
		
		# --- word-level rune hooks ----------------------------------------
		for node : RuneNode in G.current_run.rune_manager.get_runes():
			for eff : RuneEffect in node.rune.after_word_scored(word_ctx):
				match eff.type:
					RuneEffect.RuneEffectType.ADD_MULTIPLIER:
						turn_mul += eff.value
						turn_mult_updated.emit(turn_mul)
					RuneEffect.RuneEffectType.MULT_MULTIPLIER:
						turn_mul *= eff.value
						turn_mult_updated.emit(turn_mul)

	score_calculation_complete.emit(turn_pts, turn_mul, true)

# ───────────────────────  word scoring  ────────────────────────────────────
func _score_word(
		word_info    : Dictionary,      # { text:String, tiles:Array[Vector2i] }
		start_pitch  : float,
		turn_in_pts  : int,
		turn_in_mul  : int,
		board_tiles  : Array            # GameTile grid
) -> Dictionary:

	var word_pts : int = 0
	var word_mul : int = 1
	var idx      : int = 0
	var pitch    : float = start_pitch
	const STEP   : float = 0.04

	for pos : Vector2i in word_info["tiles"]:
		var tile : GameTile = board_tiles[pos.y][pos.x]
		if tile == null:
			continue

		var tile_pts : int = tile.score
		var ctx := { "word":word_info["text"], "tile":tile, "letter_index":idx }

		# --- tile-level rune hooks ----------------------------------------
		for node : RuneNode in G.current_run.rune_manager.get_runes():
			for eff : RuneEffect in node.rune.before_tile_scored(ctx):
				match eff.type:
					RuneEffect.RuneEffectType.ZERO_TILE_SCORE:
						tile_pts = 0
					RuneEffect.RuneEffectType.ADD_TILE_SCORE:
						tile_pts += eff.value
					RuneEffect.RuneEffectType.MUL_TILE_SCORE:
						tile_pts *= eff.value

		if tile_pts > 0:
			word_pts += tile_pts
			turn_score_updated.emit(turn_in_pts + word_pts)
		
		add_child(DisappearingLabel.new("+%d" % tile_pts, tile.global_position))

		AudioStreamManager.play_good_sound(pitch)
		pitch += STEP

		tile.animate_score()			# tween runs, yields until finished
		await get_tree().create_timer(TIME_BETWEEN_ANIMATIONS).timeout
		# --- tile-level rune hooks ----------------------------------------
		for node : RuneNode in G.current_run.rune_manager.get_runes():
			for eff : RuneEffect in node.rune.after_tile_scored(ctx):
				var mult_changed : bool = false
				var score_changed : bool = false
				match eff.type:
					RuneEffect.RuneEffectType.ADD_SCORE:
						word_pts += eff.value
						score_changed = true
						
					RuneEffect.RuneEffectType.ADD_MULTIPLIER:
						mult_changed = true
						turn_in_mul += eff.value
						
					RuneEffect.RuneEffectType.MULT_MULTIPLIER:
						turn_in_mul *= eff.value
						mult_changed = true
						
				if score_changed:
					turn_score_updated.emit(turn_in_pts + eff.value)
				if mult_changed:
					turn_mult_updated.emit(turn_in_mul + eff.value)

					
				if eff.exclamation != "":
					node.add_child(DisappearingLabel.new(eff.exclamation, node.global_position, true))
				if score_changed or mult_changed:
					node.ding()
					AudioStreamManager.play_good_sound(pitch)
					pitch += STEP
					tile.animate_score()
				await get_tree().create_timer(TIME_BETWEEN_ANIMATIONS).timeout
				
		idx += 1

	# --- word-level rune hooks --------------------------------------------
	return {
		"turn_pts" : turn_in_pts + word_pts,
		"turn_mul" : turn_in_mul
	}

# ─────────────────── positional validation helpers ─────────────────────────
func _tiles_form_single_line(text:Array, new_tiles:Array) -> bool:
	if new_tiles.size() <= 1: return true
	var same_row := true
	var same_col := true
	var r0 = new_tiles[0].y
	var c0 = new_tiles[0].x
	for p : Vector2i in new_tiles:
		if p.y != r0: same_row = false
		if p.x != c0: same_col = false
	if not (same_row or same_col):
		return false
	if same_row:
		new_tiles.sort_custom(func(a,b): return a.x < b.x)
		for x in range(new_tiles[0].x, new_tiles[-1].x+1):
			if text[r0][x] == "": return false
	else:
		new_tiles.sort_custom(func(a,b): return a.y < b.y)
		for y in range(new_tiles[0].y, new_tiles[-1].y+1):
			if text[y][c0] == "": return false
	return true

func _move_touches_board(mask:Array, text:Array, new_tiles:Array) -> bool:
	var any_locked := false
	for row:Array in mask:
		if row.has(true):
			any_locked = true
			break
	if not any_locked:
		return true      # first move is always OK

	for p:Vector2i in new_tiles:
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q = p + dir
			if q.x<0 or q.x>=text[0].size() or q.y<0 or q.y>=text.size():
				continue
			if mask[q.y][q.x]:
				return true
	return false

# ───────────────── word collection helpers (pure) ──────────────────────────
func _collect_words(text:Array, new_tiles:Array) -> Array:
	var seen := {}
	var words := []
	for p:Vector2i in new_tiles:
		for dir in [Vector2i.RIGHT, Vector2i.DOWN]:
			var t = _scan(text, p, -dir) + text[p.y][p.x] + _scan(text, p, dir)
			if t.length() >= 2 and not seen.has(t):
				var coords := _tiles_of_word(text, p, dir)
				words.append({ "text":t, "tiles":coords })
				seen[t] = true
	return words

func _scan(text:Array, start:Vector2i, dir:Vector2i) -> String:
	var s := ""
	var cur := start + dir
	while cur.x>=0 and cur.x<text[0].size() and cur.y>=0 and cur.y<text.size():
		var ch = text[cur.y][cur.x]
		if ch == "": break
		s = ch + s if dir.x+dir.y<0 else s + ch
		cur += dir
	return s

func _tiles_of_word(text:Array, start:Vector2i, step:Vector2i) -> Array:
	var begin := start
	while true:
		var nxt := begin - step
		if nxt.x<0 or nxt.x>=text[0].size() or nxt.y<0 or nxt.y>=text.size(): break
		if text[nxt.y][nxt.x] == "": break
		begin = nxt
	var coords := []
	var cur := begin
	while cur.x<text[0].size() and cur.y<text.size() and text[cur.y][cur.x] != "":
		coords.append(cur)
		cur += step
	return coords
