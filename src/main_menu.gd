class_name MainMenu extends Control

@export var new_game_button : MainMenuButton
@export var continue_button : MainMenuButton
@export var settings_button : MainMenuButton

signal new_game_pressed
signal settings_pressed
signal continue_pressed

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func enable_continue():
	continue_button.enable()

func disable_continue():
	continue_button.disable()

func _on_new_game_pressed():
	settings_button.slide_out()
	continue_button.slide_out()
	new_game_button.spin_to_oblivion()
	new_game_pressed.emit()
	
func _on_continue_pressed():
	pass
	
func _on_settings_pressed():
	pass
