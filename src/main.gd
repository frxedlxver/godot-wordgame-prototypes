class_name RoundManager extends Node2D

@export var hand : Hand
@export var bag : Bag
@export var board : Board

var highlighted_board_slot : Slot
var grabbed_tile : GameTile

func _ready() -> void:
	board.slot_highlighted.connect(func(slot): highlighted_board_slot = slot) 
	board.slot_unhighlighted.connect(func(_slot): highlighted_board_slot = null) 
	
	bag.initialize()
	for i in 7:
		hand.add_to_hand(bag.draw_tile());

func add_to_hand(letter : String):
	hand.add_to_hand(GameTileFactory.create_tile(letter))
