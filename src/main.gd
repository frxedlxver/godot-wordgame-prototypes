class_name Main extends Node2D

var current_run_data : RunData = null
var hand : Hand
var bag : Bag
var board : Board

var board_scene : PackedScene = preload("res://scenes/board.tscn")
var hand_scene : PackedScene = preload("res://scenes/hand.tscn")
var bag_scene : PackedScene = preload("res://scenes/bag.tscn")

@export var new_game_button : MainMenuButton
@export var continue_button : MainMenuButton
@export var settings_button : MainMenuButton

var total_score : int
var turn_score : int
var max_hand_size : int = 7

var highlighted_board_slot : Slot
var grabbed_tile : GameTile
var has_saved_run : bool = false

func _ready() -> void:
	# later, first check for save data
	# load save data if exists, create if not
	# if save data has an active run, activate continue button
	show_main_menu()
	pass

func show_main_menu():
	if has_saved_run:
		continue_button.enable()
		continue_button.pressed.connect(_on_continue_pressed())
	else:
		continue_button.disable()
	settings_button.pressed.connect(_on_settings_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
		

func _on_new_game_pressed():
	settings_button.slide_out()
	continue_button.slide_out()
	new_game_button.spin_to_oblivion()
	await new_game_button.pressed_animation_finished
	start_new_run();
	
func start_new_run():
	current_run_data = RunData.new()
	hand = hand_scene.instantiate()
	board = board_scene.instantiate()
	bag = bag_scene.instantiate()
	
	self.add_child(hand)
	self.add_child(board)
	self.add_child(bag)
	
	var vp_size = get_viewport_rect().size
	
	var board_target_pos = Vector2(vp_size.x / 2, vp_size.y / 2)
	board.global_position = Vector2(vp_size.x / 2, vp_size.y * -2)
	var tw = create_tween()
	tw.tween_property(board, "global_position", board_target_pos, 0.4)
	
	bag.tile_count_changed.connect($"UI/Round UI".bag_count_updated)
	bag.initialize()
func _on_continue_pressed():
	pass
	
func _on_settings_pressed():
	pass
	
func initialize_round():
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
			var tile = bag.draw_tile()
			
			hand.add_to_hand(tile, $Bag.global_position)
			await get_tree().create_timer(0.1).timeout
			

func on_tile_scored(new_score : int):
	turn_score = new_score
	$TurnScore.text = "Turn: %d" % turn_score

func on_scoring_complete():
	total_score += turn_score
	$TotalScore.text = "Total: %d" % total_score
	turn_score = 0
	$TurnScore.text = "Turn: %d" % turn_score
