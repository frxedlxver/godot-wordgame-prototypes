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
var score_roller : ScoreRoller

signal play_requested
signal mulligan_requested

func _ready():
	mulligan_button.pressed.connect(_mulligan_button_pressed)
	play_button.pressed.connect(_play_button_pressed)
	score_roller = ScoreRoller.new()
	self.add_child(score_roller)

func animate_in() -> void:
	self.show()


func animate_out() -> void:
	self.hide()

func roll_score(turn_delta : float):
	var score_time = 0.5
	score_roller.roll(
		turn_delta,
		total_score_label,
		turn_total_label,
		round_score_bar,
		score_time
	)
	await get_tree().create_timer(score_time).timeout
	

func bag_count_updated(new_count : int, animate : bool = false) -> void:
	bag_ui.update_count(new_count, animate)


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
	tween.tween_property(node, "scale", Vector2(1.5, 1.5), 0.02)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


# ────────────────────────────────────────────────────────────────
# Public update helpers that reuse the internal setter
# ────────────────────────────────────────────────────────────────
func update_points(new_score : int) -> void:
	_set_label_text(points_label, new_score)


func update_required_score(new_req_score : int) -> void:
	round_score_bar.max_value = new_req_score
	required_score_label.text = str(new_req_score)

func update_total_score(new_total_score : int) -> void:
	round_score_bar.value = new_total_score
	total_score_label.text = str(new_total_score)

func update_mult(new_mult : int) -> void:
	_set_label_text(mult_label, new_mult)


func update_turn_total(new_turn_total : int) -> void:
	turn_total_label.text = str(new_turn_total)

func reset_turn_points_and_mult():
	points_label.text = str(0)
	mult_label.text = str(0)
	
func update_plays(new_count : int):
	plays_label.text = str(new_count)
	
func update_mulligans(new_count : int):
	muligans_label.text = str(new_count)

func _mulligan_button_pressed():
	mulligan_requested.emit()

func _play_button_pressed():
	play_requested.emit()

func hide_buttons():
	print("UI HIDE at ", Time.get_ticks_msec())
	play_button.set_process_input(false)
	mulligan_button.set_process_input(false)
	play_button.visible = false
	mulligan_button.visible = false
	
func show_buttons():
	print("UI SHOW at ", Time.get_ticks_msec())
	play_button.set_process_input(true)
	mulligan_button.set_process_input(true)
	play_button.visible = true
	mulligan_button.visible = true

func disable_mulligan_button():
	mulligan_button.disabled = true
	
func enable_mulligan_button():
	mulligan_button.disabled = false
