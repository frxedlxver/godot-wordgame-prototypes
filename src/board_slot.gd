class_name Slot extends Sprite2D

signal highlighted(Slot)
signal unhighlighted(Slot)

var coordinates : Vector2i
var has_tile : bool = false

func _ready() -> void:
	$Area2D.mouse_entered.connect(_area2d_mouse_entered)
	$Area2D.mouse_exited.connect(_area2d_mouse_exited)
	
func _area2d_mouse_entered():
	self_modulate = Color8(200, 200, 200, 255);
	highlighted.emit(self)
	
func _area2d_mouse_exited():
	self_modulate = Color.WHITE
	unhighlighted.emit(self)

func empty():
	return !has_tile
