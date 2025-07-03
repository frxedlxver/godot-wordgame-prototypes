class_name WordHighlightBox extends Node2D

@export var border_colour : Color = Color.DODGER_BLUE
@export var thickness : float = 3.0

var _size : Vector2 = Vector2.ZERO


func _init(size : Vector2) -> void:
	_size = size

func _draw() -> void:
	if _size != Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, _size), border_colour, false, thickness)
