class_name Run extends Node2D

var round_scene : PackedScene = preload("res://scenes/round.tscn")
var round : Round
	
	
func start():
	round = round_scene.instantiate()
	self.add_child(round)
	round.initialize(G.current_run_data.tile_bag)
