# tabs for indentation
class_name Round
extends Node2D

@export var bag      : Bag
@export var board    : Board
@export var hand     : Hand
@export var round_ui : RoundUI

var turn_score : int = 0
var total_score : int = 0
var _required_score : int = 0
var mult : int = 1

var highlighted_board_slot : Slot

signal finished

# ─────────────────────────────── lifecycle ────────────────────────────────
func initialize(bag_data : Array[GameTileData], required_score : int = 0) -> void:
	TILE_MANIPULATOR.register_hand_board(hand, board) 
	_required_score = required_score
	round_ui.update_required_score(required_score)
	# board → round connections
	board.slot_highlighted.connect(func(slot): highlighted_board_slot = slot)
	board.slot_unhighlighted.connect(func(_slot): highlighted_board_slot = null)

	SCORING_ENGINE.turn_score_updated.connect(on_turn_score_updated)
	SCORING_ENGINE.turn_mult_updated.connect(on_mult_changed)
	# hand / bag ui
	hand.tile_placed.connect(on_tile_placed)
	bag.tile_count_changed.connect(round_ui.bag_count_updated)

	bag.initialize_from(bag_data)
	animate_in()

func animate_in() -> void:
	var board_tween = create_tween()
	board_tween.tween_property(board, "position", Vector2.ZERO, 0.5)
	var ui_tween = create_tween()
	ui_tween.tween_property(round_ui, "position", Vector2.ZERO, 0.5)
	while hand.tile_count() < G.current_run_data.max_hand_size and not bag.is_empty():
		await get_tree().create_timer(0.05).timeout
		hand.add_to_hand(bag.draw_tile())
		
func end() -> void:
	await animate_out()
	self.queue_free()

func animate_out():
	var board_tween = create_tween()
	board_tween.tween_property(board, "position", Vector2(0, -500), 0.5)
	await get_tree().create_timer(0.2).timeout
	var ui_tween = create_tween()
	ui_tween.tween_property(round_ui, "position", Vector2(-500, 0), 0.5)
	await ui_tween.finished
	

# ───────────────────────────── input handler ──────────────────────────────
func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("play"):
		play_tiles()

# ───────────────────────────── drag placement ─────────────────────────────
func on_tile_placed(tile : GameTile, slot : Slot) -> void:
	board.place_tile_at(tile, slot)

# ───────────────────────────── play action ────────────────────────────────
func play_tiles() -> void:
	var snap := board.get_turn_snapshot()
	var legal = SCORING_ENGINE.validate_turn(
		snap.board_text,
		snap.placed_mask,
		snap.new_tiles
	)
	if not legal:
		board.buzz_tiles()
		return
	
	# start scoring (runs async inside ScoringEngine)
	SCORING_ENGINE.score_turn(
		snap.board_text,
		snap.board_tiles,
		snap.placed_mask,
		snap.new_tiles)
	
	var result = await  SCORING_ENGINE.score_calculation_complete
	# wait for engine to finish and give us the result tuple
	var points : int = result[0]
	var mult   : int = result[1]

	if legal:
		turn_score += points
		mult        = mult				# update running mult if you track it
		board.commit_turn(snap.new_tiles)
		on_scoring_complete()
		await _refill_hand()
	else:
		board.buzz_tiles()


func _refill_hand() -> void:
	while hand.tile_count() < G.current_run_data.max_hand_size and not bag.is_empty():
		var tile = bag.draw_tile()
		hand.add_to_hand(tile, bag.global_position)
		await get_tree().create_timer(0.1).timeout

# ───────────────────────────── board → ui hooks ───────────────────────────
func on_turn_score_updated(new_score : int) -> void:
	turn_score = new_score
	round_ui.update_turn_score(turn_score)

func on_mult_changed(new_mult : int) -> void:
	mult = new_mult
	round_ui.update_mult(mult)

func on_scoring_complete() -> void:
	var turn_total = turn_score * mult
	round_ui.update_turn_total(turn_total)
	await get_tree().create_timer(SCORING_ENGINE.TIME_BETWEEN_ANIMATIONS).timeout
	total_score += turn_total
	round_ui.update_total_score(total_score)
	if total_score > _required_score:
		finished.emit()
	else:
		start_new_turn()

func start_new_turn():
	round_ui.update_turn_total(0)
	turn_score = 0
	round_ui.update_turn_score(0)

	mult = 1
	round_ui.update_mult(mult)
	
	_refill_hand()
