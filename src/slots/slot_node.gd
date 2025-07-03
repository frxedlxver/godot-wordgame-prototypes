class_name SlotNode extends Sprite2D

signal highlighted(SlotNode)
signal unhighlighted(SlotNode)

var coordinates : Vector2i
var has_tile : bool = false
var slot_info : SlotInfo

func _ready() -> void:
	$Area2D.mouse_entered.connect(_area2d_mouse_entered)
	$Area2D.mouse_exited.connect(_area2d_mouse_exited)
	self.texture = slot_info.tex
func _area2d_mouse_entered():
	self_modulate = Color8(200, 200, 200, 255);
	highlighted.emit(self)
	
func _area2d_mouse_exited():
	self_modulate = Color.WHITE
	unhighlighted.emit(self)

func empty():
	return !has_tile
	
func effect():
	if slot_info:
		return slot_info.get_slot_effect()
