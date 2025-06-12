class_name Run extends Node2D

var round_scene : PackedScene = preload("res://scenes/round.tscn")
var round : Round

# Called when the node enters the scene tree for the first time.
func initialize_fresh():
	round = round_scene.instantiate()
	self.add_child(round)
	G.current_run_data.tile_bag = GameTileFactory.create_default_bag()
	round.initialize(G.current_run_data.tile_bag)
	
	
