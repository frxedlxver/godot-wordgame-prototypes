class_name GameTile extends Sprite2D

enum TileState {
	IDLE,
	GRABBED_FROM_HAND,
	RELEASED,
	PLACED_ON_BOARD,
	GRABBED_FROM_BOARD,
	LOCKED_IN
}

enum VisualState {
	NORMAL,
	HOVERED,
	LOCKED_IN
}

signal grabbed(GameTile)
signal released(GameTile)
signal return_to_hand(GameTile)

var state : TileState
var visual_state : VisualState
var coordinates : Vector2i = -Vector2i.ONE

var color_tween : Tween
var scale_tween : Tween
var shake_tween : Tween			# NEW
var _base_pos   : Vector2		# NEW

var mouse_inside : bool
var _letter : String
var letter : String:
	get: return _letter
	set(new_letter): 
		if new_letter.length() != 1:
			return
		else:
			_letter = new_letter.to_upper()
			$Letter.texture = LettersNumbers.get_letter_image(letter)
			
var _score : int
var score : int:
	get: return _score
	set(v):
		_score = v
		var ones = score % 10
		$Letter/scoretab/NumberOnes.texture = LettersNumbers.get_small_number_image(ones)
		if score >= 10:
			var tens = score / 10
			$Letter/scoretab/NumberTens.texture = LettersNumbers.get_small_number_image(tens)
			$Letter/scoretab/NumberTens.offset = Vector2i(-2, 0)
			$Letter/scoretab/NumberOnes.offset = Vector2i(2, 0)
		else:
			$Letter/scoretab/NumberOnes.offset = Vector2i.ZERO
			$Letter/scoretab/NumberTens.texture = null

func _ready():
	$Area2D.input_event.connect(_area2d_input_event)
	$Area2D.mouse_entered.connect(_area2d_mouse_entered)
	$Area2D.mouse_exited.connect(_area2d_mouse_exited)

func _process(delta: float) -> void:
	if self.state == TileState.GRABBED_FROM_HAND or self.state == TileState.GRABBED_FROM_BOARD:
		self.global_position = get_global_mouse_position()
	if self.state == TileState.RELEASED:
		set_state(TileState.IDLE)

func set_state(new_state : TileState):
	if self.state == new_state:
		return
	self.state = new_state
	match new_state:
		TileState.GRABBED_FROM_HAND:
			$TextEdit.text = "GRBH"
			grabbed.emit(self)
			print("grabbed")
		TileState.RELEASED:
			$TextEdit.text = "RLSD"
			released.emit(self)
			print("released")
		TileState.IDLE:
			$TextEdit.text = "IDLE"
			return_to_hand.emit(self)
			print("return requested")

		TileState.PLACED_ON_BOARD:
			$TextEdit.text = "PLCD"
		TileState.GRABBED_FROM_BOARD:
			$TextEdit.text = "GRBB"
			grabbed.emit(self)
			print("grabbed_from_board")
		TileState.LOCKED_IN:
			$Area2D.input_event.disconnect(_area2d_input_event)
			$Area2D.mouse_entered.disconnect(_area2d_mouse_entered)
			$Area2D.mouse_exited.disconnect(_area2d_mouse_exited)
			self.set_visual_state(VisualState.LOCKED_IN)

func set_visual_state(new_state : VisualState):
	if new_state == self.visual_state: return
	self.visual_state = new_state
	match visual_state:
		VisualState.NORMAL:
			self.scale = Vector2.ONE
			self.self_modulate = Color.WHITE
			pass
		VisualState.HOVERED:
			self.scale = Vector2(1.1, 1.1)
			self.self_modulate = Color8(255,230,230,255)
			pass
		VisualState.LOCKED_IN:
			self.scale = Vector2.ONE
			self.self_modulate = Color.GRAY
			kill_tweens()

func _area2d_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("grab_tile"):
		if self.state == TileState.PLACED_ON_BOARD:
			set_state(TileState.GRABBED_FROM_BOARD)
		else:
			set_state(TileState.GRABBED_FROM_HAND)
	elif event.is_action_released("grab_tile"):
		if state == TileState.GRABBED_FROM_HAND or state == TileState.GRABBED_FROM_BOARD:
			set_state(TileState.RELEASED)
	elif event.is_action_pressed("return_tile_to_hand"):
		set_state(TileState.IDLE)

func _area2d_mouse_entered():
	set_visual_state(VisualState.HOVERED)
	pass
	
func _area2d_mouse_exited():
	set_visual_state(VisualState.NORMAL)
	pass
	
func release_from_board():
	set_state(TileState.IDLE)

func placed_on_board():
	print("placed on board")
	set_state(TileState.PLACED_ON_BOARD)


func ding():
	self_modulate = Color.GREEN
	run_color_tween()
	
func lock_in():
	set_state(TileState.LOCKED_IN)
	
		
func animate_score():
	self.self_modulate = Color.GREEN
	run_scale_tween(0.1, Vector2.ONE, Vector2.ONE * 1.1, false)
	await run_color_tween(0.1, Color.GRAY, true)
	
# ───────────────────────────── bzzt effect ─────────────────────────────
func bzzt() -> void:
	kill_tweens()						# stop any previous animations

	self_modulate = Color.RED			# start with red flash
	run_color_tween(0.25, Color.WHITE, false)	# fade back to white
	run_scale_tween(0.1, Vector2.ONE, Vector2.ONE * 1.2, false)	# pop scale
	run_shake_tween(0.18, 12.0, false)		# brief jitter
# ───────────────────────────────────────────────────────────────────────

# ─────────────────────── generic tween helpers ────────────────────────
func run_color_tween(length : float = 0.7, end_color : Color = Color.WHITE, wait : bool = false) -> void:
	if color_tween: color_tween.kill()
	color_tween = create_tween()
	color_tween.tween_property(self, "self_modulate", end_color, length) \
		.set_ease(Tween.EASE_IN)
	if wait: await color_tween.finished

func run_scale_tween(length : float = 0.7, start_scale : Vector2 = Vector2.ONE, end_scale : Vector2 = Vector2.ONE, wait : bool = false) -> void:
	if scale_tween: scale_tween.kill()
	scale_tween = create_tween()
	self.scale = start_scale
	scale_tween.tween_property(self, "scale", end_scale, length) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", start_scale, length) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if wait: await scale_tween.finished

# NEW: random positional shake
func run_shake_tween(duration : float = 0.18, amplitude : float = 12.0, wait : bool = false) -> void:
	if shake_tween: shake_tween.kill()
	_base_pos = position
	shake_tween = create_tween()
	shake_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)

	# drive _apply_shake each frame while amplitude → 0
	shake_tween.tween_method(Callable(self, "_apply_shake"), amplitude, 0.0, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# restore exact start position when done
	shake_tween.tween_callback(Callable(self, "_reset_position"))
	if wait: await shake_tween.finished

func _apply_shake(strength : float) -> void:
	var offset := Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized() * strength
	position = _base_pos + offset

func _reset_position() -> void:
	position = _base_pos

# ───────────────────────── misc maintenance ───────────────────────────
func kill_tweens() -> void:
	if color_tween: color_tween.kill()
	if scale_tween: scale_tween.kill()
	if shake_tween: shake_tween.kill()
# ───────────────────────────────────────────────────────────────────────
