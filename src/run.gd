class_name Run extends Node2D

var round_scene : PackedScene = preload("res://scenes/round.tscn")
var round : Round
@export var rune_manager : RuneManager
	
	
func start():
	G.current_run = self
	G.current_run_data.runes = [VowelPower.new(), TheVoid.new(), Singles.new()]
	rune_manager._load_visuals()
	rune_manager.position = Vector2(get_viewport_rect().size.x / 2, 32)
	round = round_scene.instantiate()
	self.add_child(round)
	var next_round_score = (G.current_run_data.last_round_won + 1) * 100
	round.initialize(G.current_run_data.tile_bag, next_round_score)

func round_score_updated(new_score : int):
	pass

func turn_mult_updated(new_mult : int):
	pass

func turn_points_updated(new_points : int):
	pass
	
func scoring_complete():
	pass
