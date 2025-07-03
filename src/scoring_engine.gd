# tabs for indentation
##  ScoringEngine.gd  ────────────────────────────────────────────────────────
class_name ScoringEngine
extends Node          # Autoload

const TIME_BETWEEN_ANIMATIONS = 0.3

signal points_updated(new_score : int)
signal turn_mult_updated(new_mult : int)
signal score_calculation_complete(mult:int)

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
		board_text	: Array,	# Array[Array[String]]
		board_tiles	: Array,	# Array[Array[GameTile]]
		placed_mask	: Array,	# Array[Array[bool]]
		new_tiles	: Array,	# Array[Vector2i]
		slots		: Array		# Array[SlotNode]
) -> void:

	var turn_pts : int = 0
	var turn_mul : int = 1

	var words = _collect_words(board_text, new_tiles)
	# 2. score each word (plays SFX & tweens inline) -------------------------
	var pitch : float = 0.0
	for w in words:
		
		var hi_box = _spawn_word_box(w, slots)
		
		var res := await _score_word(w, pitch, turn_pts, turn_mul, board_tiles, slots)
		turn_pts = res.turn_pts
		turn_mul = res.turn_mul

		
		var word_ctx = {
			"word" : w["text"],
			"words" : words
		}
		
		turn_mul += w["text"].length()
		var first_tile_pos = w["tiles"][0]
		var first_tile = board_tiles[first_tile_pos.y][first_tile_pos.x]
		var label = DisappearingLabel.new("+%d MULT" % w["text"].length(), first_tile.global_position)
		self.add_child(label)
		turn_mult_updated.emit(turn_mul)
		
		pitch += 0.04 * (w["text"].length() + 1)
		for pos in w["tiles"]:
			var tile : GameTile = board_tiles[pos.y][pos.x]
			tile.animate_score()
			AudioStreamManager.play_good_sound(pitch)
		await get_tree().create_timer(TIME_BETWEEN_ANIMATIONS).timeout
		
			
		for pos in w["tiles"]:
			var slot = slots[pos.y][pos.x]
			var slot_effect : SlotEffect = slot.effect()
			if slot_effect:
				match slot_effect.type:
					SlotEffect.SlotEffectType.MULT_MULT:
						turn_mul *= slot_effect.value
						label = DisappearingLabel.new("MULT x%d" % slot_effect.value, slot.global_position)
						self.add_child(label)
						turn_mult_updated.emit(turn_mul)
						AudioStreamManager.play_good_sound(pitch)
						pitch += 0.04
						await get_tree().create_timer(TIME_BETWEEN_ANIMATIONS).timeout
		
		
		# --- word-level rune hooks ----------------------------------------
		for node : RuneNode in G.current_run.rune_manager.get_runes():
			for eff : RuneEffect in node.rune.after_word_scored(word_ctx):
				match eff.type:
					RuneEffect.RuneEffectType.ADD_MULTIPLIER:
						turn_mul += eff.value
					RuneEffect.RuneEffectType.MULT_MULTIPLIER:
						turn_mul *= eff.value
		
		hi_box.queue_free()
	
	print("score engine done scoring")
	score_calculation_complete.emit(turn_pts, turn_mul, true)


func _spawn_word_box(word : Dictionary, slots : Array) -> WordHighlightBox:
	# Find the outer bounds of all tiles in the word (in global space)
	var min_v := Vector2(INF, INF)
	var max_v := Vector2(-INF, -INF)
	for p : Vector2i in word["tiles"]:
		var slot : SlotNode = slots[p.y][p.x]
		var slot_size = slot.get_rect().size
		var tl  = slot.global_position - slot_size * 0.5	# tile's top-left
		min_v.x = min(min_v.x, tl.x)
		min_v.y = min(min_v.y, tl.y)
		max_v.x = max(max_v.x, tl.x + slot_size.x)
		max_v.y = max(max_v.y, tl.y + slot_size.y)

	var box := WordHighlightBox.new(max_v - min_v)
	box.top_level = true					# keep it in screen space
	box.position  = min_v
	add_child(box)
	return box

# ───────────────────────  word scoring  ────────────────────────────────────
func _score_word(
		word_info		: Dictionary,      # { text:String, tiles:Array[Vector2i] }
		start_pitch		: float,
		turn_in_pts		: int,
		turn_in_mul		: int,
		board_tiles		: Array,            # GameTile grid
		slots			: Array
) -> Dictionary:

	var word_pts : int = 0
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

		var label = _spawn_score_label(str(tile_pts), tile.global_position)
		points_updated.emit(turn_in_pts + word_pts)
		AudioStreamManager.play_good_sound(pitch)
		pitch += STEP

		tile.animate_score()			# tween runs, yields until finished
		await get_tree().create_timer(TIME_BETWEEN_ANIMATIONS).timeout
		
		var slot : SlotNode = slots[pos.y][pos.x]
		var slot_effect : SlotEffect = slot.slot_info.get_slot_effect()
		
		
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
					var new_label = DisappearingLabel.new(eff.exclamation, node.global_position, true)
					node.add_child(label)
					points_updated.emit(turn_in_pts)
				if mult_changed:
					node.add_child(label)
					var new_label = DisappearingLabel.new(eff.exclamation, node.global_position, true)
					turn_mult_updated.emit(label)
					
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

func _spawn_score_label(text : String, pos : Vector2, parent : Node = self) -> DisappearingLabel:
	var lbl = DisappearingLabel.new(text, pos)
	parent.add_child(lbl)
	return lbl

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
