class_name Main extends Node2D


var run_scene : PackedScene = preload("res://scenes/run.tscn")
var round_scene : PackedScene = preload("res://scenes/round.tscn")
var main_menu_scene : PackedScene = preload("res://scenes/main_menu.tscn")
var current_run : Run

var main_menu_node : MainMenu

var has_saved_run : bool = false

func _ready() -> void:
	SAVE_MANAGER.load_data()
	show_main_menu()
	pass

func show_main_menu():
	main_menu_node = main_menu_scene.instantiate()
	$UI.add_child(main_menu_node)
	main_menu_node.new_game_pressed.connect(start_new_run)
	if SAVE_MANAGER.has_saved_run():
		main_menu_node.enable_continue()
	else:
		main_menu_node.disable_continue()
	
func start_new_run():
	if main_menu_node:
		await get_tree().create_timer(0.5).timeout
		main_menu_node.queue_free()

	# reset and flag as in-progress
	G.current_run_data.start_new_run()          # or RUN_DATA.reinitialize() + set fields

	SAVE_MANAGER.save_data()          # ← RUN_DATA is valid now
	
	current_run = run_scene.instantiate()
	add_child(current_run)
	current_run.initialize_fresh()
