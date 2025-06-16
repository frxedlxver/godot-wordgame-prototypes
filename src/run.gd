class_name Run extends Node2D

var round_scene : PackedScene = preload("res://scenes/round.tscn")
var round : Round
var rune_manager : RuneManager
	
	
func start():
	G.current_run = self
	rune_manager = RuneManager.new()
	G.current_run_data.runes = [VowelPower.new(), TheVoid.new(), Singles.new()]
	get_node("/root/Node2D/UI").add_child(rune_manager)
	rune_manager._load_visuals()
	rune_manager.position = Vector2(get_viewport_rect().size.x / 2, 32)
	round = round_scene.instantiate()
	self.add_child(round)
	round.initialize(G.current_run_data.tile_bag)
