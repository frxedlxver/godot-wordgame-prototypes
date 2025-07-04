# tabs for indentation
class_name Round
extends Node2D

@export var bag      : Bag
@export var board    : Board
@export var hand     : Hand
@export var round_ui : RoundUI

# ──────────────────────────── round-state (auto-updates UI) ────────────────
var _points		: int = 0
var points		: int:
	set(v):
		_points = v
		if round_ui:
			round_ui.update_points(_points)
	get:
		return _points

var _total_score	: int = 0
var total_score		: int:
	set(v):
		_total_score = v
	get:
		return _total_score

var _required_score	: int = 0
var required_score	: int:
	set(v):
		_required_score = v
		if round_ui:
			round_ui.update_required_score(_required_score)
	get:
		return _required_score

var _mult			: int = 1
var mult			: int:
	set(v):
		_mult = v
		if round_ui:
			round_ui.update_mult(_mult)
	get:
		return _mult

var _plays			: int = 0
var plays			: int:
	set(v):
		_plays = v
		if round_ui:
			round_ui.update_plays(_plays)
	get:
		return _plays

var _mulligans		: int = 0
var mulligans		: int:
	set(v):
		_mulligans = v
		if round_ui:
			round_ui.update_mulligans(_mulligans)
	get:
		return _mulligans

# ─────────────────────────── internal flags/data ───────────────────────────
var highlighted_board_slot : SlotNode
var _scoring_in_progress   : bool = false
var current_phase : PhaseCfg
var round_cfg : RunTable.RoundCfg

signal finished(bool)
signal phase_finished(bool)

# ─────────────────────────────── lifecycle ────────────────────────────────
func initialize(bag_data : Array[GameTileData], round_config : RunTable.RoundCfg) -> void:
	TILE_MANIPULATOR.register_hand_board(hand, board)
	
	round_cfg = round_config
	start_next_phase()
	
	# board → round connections
	board.slot_highlighted.connect(func(slot): highlighted_board_slot = slot)
	board.slot_unhighlighted.connect(func(_slot): highlighted_board_slot = null)
	
	# scoring engine hooks
	SCORING_ENGINE.points_updated.connect(on_points_updated)
	SCORING_ENGINE.turn_mult_updated.connect(on_mult_changed)
	
	# hand / bag ui
	hand.tile_placed.connect(on_tile_placed)
	bag.tile_count_changed.connect(round_ui.bag_count_updated)
	
	bag.initialize_from(bag_data)
	animate_in()
	

	
	plays      = G.current_run_data.plays_per_round
	mulligans  = G.current_run_data.mulls_per_round
	
	round_ui.mulligan_requested.connect(_on_mulligan_requested)
	round_ui.play_requested.connect(_on_play_requested)

func animate_in() -> void:
	await board.animate_in()
	round_ui.animate_in()
	_refill_hand(current_phase == round_cfg.phase1)

func end() -> void:
	await animate_out()

func animate_out():
	TILE_MANIPULATOR.return_all_to_bag(bag, round_ui.bag_ui)
	await get_tree().create_timer(0.4).timeout
	await board.animate_out()
	round_ui.animate_out()
	

# ───────────────────────────── input handler ──────────────────────────────
func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("play") and not _scoring_in_progress:
		play_tiles()

# ───────────────────────────── drag placement ─────────────────────────────
func on_tile_placed(tile : GameTile, slot : SlotNode) -> void:
	board.place_tile_at(tile, slot)

# ───────────────────────────── play action ────────────────────────────────
func play_tiles() -> void:
	# don't play if user has a grabbed tile
	if TILE_MANIPULATOR._active_tile:
		return
	
	_scoring_in_progress = true
	var snap := board.get_turn_snapshot()
	var legal = SCORING_ENGINE.validate_turn(
		snap.board_text,
		snap.placed_mask,
		snap.new_tiles
	)
	
	if not legal:
		board.buzz_tiles()
		_scoring_in_progress = false
		return
	
	# board is legal: subtract a play and commit
	plays -= 1
	board.commit_turn(snap.new_tiles)
	round_ui.hide_buttons()
	
	# start scoring (async inside ScoringEngine)
	SCORING_ENGINE.score_turn(
		snap.board_text,
		snap.board_tiles,
		snap.placed_mask,
		snap.new_tiles,
		snap.slots
	)
	print("awaiting scoring")
	var result = await SCORING_ENGINE.score_calculation_complete
	print("done scoring")
	var points		: int = result[0]
	var mult_val	: int = result[1]
	
	points = points
	mult       = mult_val
	await on_scoring_complete()

func start_next_phase():
	animate_in()
	if current_phase == null:
		current_phase = round_cfg.phase1
	elif current_phase == round_cfg.phase1:
		current_phase = round_cfg.phase2
	elif current_phase == round_cfg.phase2:
		current_phase = round_cfg.boss
		
	total_score     = 0
	round_ui.update_total_score(total_score)
	
	required_score  = current_phase.required_score
	plays           = G.current_run_data.plays_per_round
	mulligans       = G.current_run_data.mulls_per_round
	
	start_new_turn()

func _refill_hand(require_balanced_hand : bool = false) -> void:
	if require_balanced_hand:
		bag.ensure_balanced_draw()

	
	while hand.tile_count() < G.current_run_data.max_hand_size and not bag.is_empty():
		var tile = bag.draw_tile()
		hand.add_to_hand(tile, round_ui.bag_ui.global_position)
		await get_tree().create_timer(0.1).timeout

# ───────────────────────────── board → ui hooks ───────────────────────────
func on_points_updated(new_score : int) -> void:
	points = new_score
	round_ui.update_points(new_score)

func on_mult_changed(new_mult : int) -> void:
	mult = new_mult
	round_ui.update_mult(new_mult)

func on_scoring_complete() -> void:
	await get_tree().create_timer(SCORING_ENGINE.TIME_BETWEEN_ANIMATIONS * 2).timeout
	var turn_total = points * mult
	reset_points_and_mult()
	round_ui.update_turn_total(turn_total)
	AudioStreamManager.play_turn_total()
	await get_tree().create_timer(SCORING_ENGINE.TIME_BETWEEN_ANIMATIONS * 2).timeout
	
	await round_ui.roll_score(turn_total)
	total_score += turn_total
	turn_total = 0
	
	await get_tree().create_timer(SCORING_ENGINE.TIME_BETWEEN_ANIMATIONS * 2).timeout
	
	# determine win / lose
	if total_score >= current_phase.required_score:
		print("beat req score")
		if current_phase == round_cfg.boss:
			finished.emit(true)
		else:
			phase_finished.emit(true)
	elif plays <= 0:
		print("plays 0")
		finished.emit(false)
	else:
		print("starting new turn")
		start_new_turn()

func start_new_turn():
	_refill_hand()
	_scoring_in_progress = false
	round_ui.show_buttons()
	print("new turn started")
	

func reset_points_and_mult():
	points = 0
	round_ui.update_points(points)
	mult = 1
	round_ui.update_mult(mult)

func _on_mulligan_requested():
	if mulligans > 0:
		mulligans -= 1
		await TILE_MANIPULATOR.return_all_to_bag(bag, round_ui.bag_ui)
		await get_tree().create_timer(0.5).timeout
		bag.shuffle()
		await _refill_hand()
		print("m req")

func _on_play_requested():
	play_tiles()
