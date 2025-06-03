class_name RoundManager extends Node2D

@export var hand : Hand
@export var bag : Bag
@export var board : Board

var total_score : int
var turn_score : int
var max_hand_size : int = 7

var highlighted_board_slot : Slot
var grabbed_tile : GameTile

func _ready() -> void:
	board.slot_highlighted.connect(func(slot): highlighted_board_slot = slot) 
	board.slot_unhighlighted.connect(func(_slot): highlighted_board_slot = null)
	board.tile_scored.connect(on_tile_scored)
	board.scoring_complete.connect(on_scoring_complete)
	
	bag.initialize()
	for i in max_hand_size:
		hand.add_to_hand(bag.draw_tile());

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("play"):
		play_tiles()
		
func play_tiles():
	var can_play = board.validate_board()
	if can_play:
		await board.play()
		while hand.tile_count() < max_hand_size:
			hand.add_to_hand(bag.draw_tile())
			

func on_tile_scored(new_score : int):
	turn_score = new_score
	$TurnScore.text = "Turn: %d" % turn_score

func on_scoring_complete():
	total_score += turn_score
	$TotalScore.text = "Total: %d" % total_score
	turn_score = 0
	$TurnScore.text = "Turn: %d" % turn_score
