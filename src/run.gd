class_name Run extends Node2D

var round_scene : PackedScene = preload("res://scenes/round.tscn")
var round : Round
@export var rune_manager : RuneManager
	
func start():
	G.current_run = self
	G.current_run_data.runes = []
	rune_manager._load_visuals()
	rune_manager.position = Vector2(get_viewport_rect().size.x / 2, 32)
	start_next_round()
	
func start_next_round():
	round = round_scene.instantiate()
	round.finished.connect(_on_round_finished)
	round.phase_finished.connect(_on_phase_finished)
	self.add_child(round)
	var next_round_score = (G.current_run_data.last_round_won + 1) * 100
	var next_round = RunTable.default_run[G.current_run_data.last_round_won]
	round.initialize(G.current_run_data.tile_bag, next_round)
	
func _on_round_finished(won : bool):
	G.current_run_data.last_round_won += 1
	round.end()
	round = null
	if won:
		start_next_round()
	else:
		game_over()
		
func _on_phase_finished(won : bool):
	if won:
		round.animate_out()
		await get_tree().create_timer(2.0).timeout
		round.animate_in()
	else:
		round.end()
		game_over()
		
func game_over():
	# put more in here later
	# show a game over screen with run stats. Button to restart, button to return to main menu
	pass
