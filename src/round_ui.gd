class_name RoundUI
extends Control

@export var points_label	: Label
@export var turn_total_label	: Label
@export var required_score_label	: Label
@export var mult_tex_rect		: TextureRect
@export var points_tex_rect		: TextureRect
@export var mult_label			: Label
@export var total_score_label	: Label
@export var bag_ui				: BagUI
@export var plays_label			: Label
@export var muligans_label		: Label
@export var mulligan_button		: TextureButton
@export var play_button			: TextureButton
@export var round_score_bar		: ProgressBar

signal play_requested
signal mulligan_requested

func _ready():
	mulligan_button.pressed.connect(_mulligan_button_pressed)
	play_button.pressed.connect(_play_button_pressed)

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
	tween.tween_property(node, "scale", Vector2(1.25, 1.25), 0.02)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.08)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


# ────────────────────────────────────────────────────────────────
# Public update helpers that reuse the internal setter
# ────────────────────────────────────────────────────────────────
func update_points(new_score : int) -> void:
	_set_label_text(points_label, new_score)


func update_required_score(new_score : int) -> void:
	round_score_bar.max_value = new_score
	_set_label_text(required_score_label, new_score)


func update_total_score(new_score : int) -> void:
	round_score_bar.value = new_score
	_set_label_text(total_score_label, new_score)


func update_mult(new_mult : int) -> void:
	_set_label_text(mult_label, new_mult)


func update_turn_total(new_turn_total : int) -> void:
	_set_label_text(turn_total_label, new_turn_total)

func reset_turn_points_and_mult():
	points_label.text = str(0)
	mult_label.text = str(0)
func send_label_to_score(label : DisappearingLabel, amount : int):
	var target_pos = points_label.global_position
	label.disappear_to(target_pos)
	await  label.at_target_position
	update_points(amount)
	
func send_label_to_mult(label : DisappearingLabel, amount : int):
	var target_pos = mult_label.global_position
	label.disappear_to(target_pos)
	await  label.at_target_position
	update_mult(amount)
	
func update_plays(new_count : int):
	plays_label.text = str(new_count)
	
func update_mulligans(new_count : int):
	muligans_label.text = str(new_count)

func _mulligan_button_pressed():
	mulligan_requested.emit()

func _play_button_pressed():
	play_requested.emit()

func hide_buttons():
	play_button.set_process_input(false)
	mulligan_button.set_process_input(false)
	play_button.visible = false
	mulligan_button.visible = false
	
func show_buttons():
	play_button.set_process_input(true)
	mulligan_button.set_process_input(true)
	play_button.visible = true
	mulligan_button.visible = true

func disable_mulligan_button():
	mulligan_button.disabled = true
	
func enable_mulligan_button():
	mulligan_button.disabled = false
