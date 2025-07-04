class_name RuneNode
extends TextureRect

@export var rune : Rune
signal drag_finished(old_index:int, new_index:int)

var scale_tween : Tween
var color_tween : Tween


func ding():
	if scale_tween:
		scale_tween.kill()
	if color_tween:
		color_tween.kill()
	color_tween = create_tween()
	scale_tween = create_tween()
	self.scale = Vector2(1.2, 0.9)
	self.self_modulate = Color.YELLOW
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	color_tween.tween_property(self, "self_modulate", Color.WHITE, 0.2)

func _ready():
	texture = rune.icon
	tooltip_text = rune.description
	mouse_filter = MOUSE_FILTER_PASS          # don’t block parent

# 1. start drag ----------------------------------------------------
func _get_drag_data(_pos):
	var preview := TextureRect.new()
	preview.texture = texture
	preview.size    = size
	set_drag_preview(preview)
	return { "rune_node": self }

# 2. allow drop ----------------------------------------------------
func _can_drop_data(_pos, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("rune_node")

# 3. accept drop ---------------------------------------------------
func _drop_data(_pos, data):
	var src := data["rune_node"] as RuneNode
	if src and src != self:
		var parent := get_parent()
		var old_idx = src.get_index()
		var new_idx = self.get_index()
		parent.move_child(src, new_idx)
		drag_finished.emit(old_idx, new_idx)
