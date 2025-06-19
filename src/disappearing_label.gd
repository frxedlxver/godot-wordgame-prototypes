class_name DisappearingLabel extends Label

var starting_position : Vector2
var _down : bool

signal at_target_position
func _init(text_to_show : String, starting_pos : Vector2, down : bool = false) -> void:
	self.text = text_to_show
	self.starting_position = starting_pos
	_down = down
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.z_index = 1000
	self_modulate = Color.WHITE
	label_settings = load("res://styles/disappearing_label_settings.tres")
	self.global_position = starting_position
	self.scale = Vector2(0.1, 0.1)
	var end_pos = starting_position + Vector2(0, 50 if _down else -50)
	
	# Tween motion and fade
	var tw_scale = create_tween()
	tw_scale.tween_property(self, "scale", Vector2.ONE, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "global_position", end_pos, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func disappear_to(new_position : Vector2):
	var tw = create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(self, "global_position", new_position, 0.2)
	await tw.finished
	self.at_target_position.emit()
	queue_free()
