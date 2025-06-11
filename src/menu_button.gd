class_name MainMenuButton extends TextureButton

var hover_tween : Tween
var pos_tween : Tween
const MAX_HOVER_SCALE : float = 1.05
const MIN_HOVER_SCALE : float = 0.95
const INITIAL_HOVER_SPEED : float = 0.4
const SECONDARY_HOVER_SPEED : float = 0.8

var in_hover_callback : bool = false
var hovered : bool = false
var clicked : bool = false

signal pressed_animation_finished

var default_pos : Vector2
func _ready():
	self.pressed.connect(_on_pressed)

func _on_pressed():
	clicked = true
	
func slide_out():
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	var cur_pos = global_position
	hover_tween.tween_property(self, "global_position", Vector2(cur_pos.x, 800), 0.3)
	await hover_tween.finished
	self.queue_free()
	
func spin_to_oblivion():
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE * 0.01, 0.6)
	hover_tween.set_ease(Tween.EASE_OUT)
	var tw2 = create_tween()
	tw2.tween_property(self, "rotation_degrees", 3600, 3.0)
	tw2.set_ease(Tween.EASE_IN)
	await hover_tween.finished
	pressed_animation_finished.emit()
	self.queue_free()

func disable():
	self.disabled = true
	$XTexture.show()
	
func enable():
	self.disabled = false
	$XTexture.hide()
	


# Called when the node enters the scene tree for the first time.
func _process(delta: float) -> void:
	if disabled or clicked: return
	if is_hovered():
		if not hovered:
			hovered = true
			on_hover()
	elif hovered:
		hovered = false
		on_hover_ended()
		
func on_hover():
	in_hover_callback = true
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE * MIN_HOVER_SCALE, SECONDARY_HOVER_SPEED)
	hover_tween.tween_property(self, "scale", Vector2.ONE * MAX_HOVER_SCALE, SECONDARY_HOVER_SPEED)
	hover_tween.set_ease(Tween.EASE_IN_OUT)
	hover_tween.set_loops()
	in_hover_callback = false

func on_hover_ended():
	hover_tween.kill()
	self.scale = Vector2.ONE
