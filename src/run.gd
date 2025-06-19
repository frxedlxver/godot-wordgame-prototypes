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
	self.add_child(round)
	var next_round_score = (G.current_run_data.last_round_won + 1) * 100
	round.initialize(G.current_run_data.tile_bag, next_round_score)
	
func _on_round_finished(won : bool):
	round.end()
	round = null
