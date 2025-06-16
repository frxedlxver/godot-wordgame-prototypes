class_name Round extends Node2D

@export var bag : Bag
@export var board : Board
@export var hand : Hand
@export var round_ui : RoundUI

var turn_score : int
var total_score : int

var highlighted_board_slot : Slot

func initialize(bag_data : Array[GameTileData]):
	board.slot_highlighted.connect(func(slot): highlighted_board_slot = slot) 
	board.slot_unhighlighted.connect(func(_slot): highlighted_board_slot = null)
	board.tile_scored.connect(on_tile_scored)
	board.scoring_complete.connect(on_scoring_complete)
	hand.tile_placed.connect(on_tile_placed)
	bag.tile_count_changed.connect(round_ui.bag_count_updated)
	
	bag.initialize_from(bag_data)
	animate_in()

func animate_in():
	while hand.tile_count() < 7 and not bag.is_empty():
		await get_tree().create_timer(0.05).timeout
		hand.add_to_hand(bag.draw_tile())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("play"):
		play_tiles()

func on_tile_placed(tile : GameTile, slot : Slot):
	board.place_tile_at(tile, slot)

func play_tiles():
	var can_play = board.validate_board()
	if can_play:
		await board.play()
		while hand.tile_count() < G.current_run_data.max_hand_size:
			var tile = bag.draw_tile()
			
			
			hand.add_to_hand(tile, $Bag.global_position)
			await get_tree().create_timer(0.1).timeout
			

func on_tile_scored(new_score : int):
	turn_score = new_score
	round_ui.update_turn_score(turn_score)

func on_scoring_complete():
	total_score += turn_score
	round_ui.update_total_score(total_score)
	turn_score = 0
	round_ui.update_turn_score(turn_score)
