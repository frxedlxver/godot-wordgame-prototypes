class_name RoundUI
extends Control

@export var turn_score_label	: Label
@export var turn_total_label	: Label
@export var required_score_label	: Label
@export var mult_tex_rect		: TextureRect
@export var points_tex_rect		: TextureRect
@export var mult_label			: Label
@export var total_score_label	: Label
@export var bag_ui				: BagUI


func animate_in() -> void:
	self.show()


func animate_out() -> void:
	self.hide()


func bag_count_updated(new_count : int) -> void:
	bag_ui.update_count(new_count)


# ────────────────────────────────────────────────────────────────
# Internal helpers
# ────────────────────────────────────────────────────────────────
func _set_label_text(label : Label, value : int) -> void:
	if !label:
		return
	label.text = "%d" % value
	_pop_tween(label)	# visual feedback


func _pop_tween(node : Node) -> void:
	# Reset any previous scaling so pops don’t accumulate.
	node.scale = Vector2.ONE
	
	var tween := create_tween()
	# “Out” overshoot, then back to normal – quick and subtle.
	tween.tween_property(node, "scale", Vector2(1.25, 1.25), 0.07)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.08)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


# ────────────────────────────────────────────────────────────────
# Public update helpers that reuse the internal setter
# ────────────────────────────────────────────────────────────────
func update_turn_score(new_score : int) -> void:
	_set_label_text(turn_score_label, new_score)


func update_required_score(new_score : int) -> void:
	_set_label_text(required_score_label, new_score)


func update_total_score(new_score : int) -> void:
	_set_label_text(total_score_label, new_score)


func update_mult(new_mult : int) -> void:
	_set_label_text(mult_label, new_mult)


func update_turn_total(new_turn_total : int) -> void:
	_set_label_text(turn_total_label, new_turn_total)
