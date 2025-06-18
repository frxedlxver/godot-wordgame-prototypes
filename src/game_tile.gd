# tabs for indentation
class_name GameTile
extends Sprite2D

# ─────────────────────────────── enums ────────────────────────────────
enum TileState {
	IDLE,					# sitting in the hand
	GRABBED_FROM_HAND,		# being dragged (origin = hand)
	GRABBED_FROM_BOARD,		# being dragged (origin = board)
	PLACED_ON_BOARD,		# resting on a slot but not locked
	RELEASED,
	LOCKED_IN				# committed – cannot move
}

enum VisualState {
	NORMAL,
	HOVERED,
	LOCKED_IN
}

# ─────────────────────────────── signals ───────────────────────────────
signal grabbed		(GameTile)		# emitted on mouse-down
signal released		(GameTile)		# emitted on mouse-up
signal return_to_hand(GameTile)		# request from Board → Hand

# ────────────────────────────── public data ────────────────────────────
var state			: TileState		= TileState.IDLE
var visual_state	: VisualState	= VisualState.NORMAL
var coordinates		: Vector2i		= -Vector2i.ONE		# (-1,-1) = in hand
var data			: GameTileData		# reference to save-data struct

# ───────────────────────────── private refs ────────────────────────────
var _color_tw	: Tween
var _scale_tw	: Tween
var _shake_tw	: Tween
var _base_pos	: Vector2			# for shake

# ───────────────────────── letter / score props ───────────────────────
var _letter : String
var letter : String:
	get:	return _letter
	set(v):
		_letter = v.to_upper()
		$Letter.texture = LettersNumbers.get_letter_image(_letter)
		if data: data.letter = _letter

var _score : int
var score : int:
	get:	return _score
	set(v):
		_score = v
		if data: data.score = v
		var ones = v % 10
		$Letter/scoretab/NumberOnes.texture = LettersNumbers.get_small_number_image(ones)
		if v >= 10:
			var tens = v / 10
			$Letter/scoretab/NumberTens.texture = LettersNumbers.get_small_number_image(tens)
			$Letter/scoretab/NumberTens.offset = Vector2i(-2, 0)
			$Letter/scoretab/NumberOnes.offset = Vector2i( 2, 0)
		else:
			$Letter/scoretab/NumberTens.texture = null
			$Letter/scoretab/NumberOnes.offset  = Vector2i.ZERO

# ───────────────────────────── lifecycle ───────────────────────────────
func _ready() -> void:
	TILE_MANIPULATOR.register_tile(self)
	$Area2D.input_event .connect(_on_area2d_input_event)
	$Area2D.mouse_entered.connect(_on_area2d_mouse_enter)
	$Area2D.mouse_exited .connect(_on_area2d_mouse_exit)

# ───────────────────────────── state FSM ───────────────────────────────
func set_state(new_state : TileState) -> void:
	if state == new_state:
		return
	state = new_state

	match new_state:
		TileState.GRABBED_FROM_HAND:
			grabbed.emit(self)
			$TextEdit.text = "GBHN"

		TileState.GRABBED_FROM_BOARD:
			grabbed.emit(self)
			$TextEdit.text = "GBBD"
		TileState.IDLE:
			return_to_hand.emit(self)
			$TextEdit.text = "IDLE"
		TileState.PLACED_ON_BOARD:
			$TextEdit.text = "PLCD"
			
			pass								# nothing extra

		TileState.LOCKED_IN:
			$TextEdit.text = "LCKD"
			$Area2D.input_event.disconnect(_on_area2d_input_event)
			$Area2D.mouse_entered.disconnect(_on_area2d_mouse_enter)
			$Area2D.mouse_exited .disconnect(_on_area2d_mouse_exit)
			set_visual_state(VisualState.LOCKED_IN)

func set_visual_state(vs : VisualState) -> void:
	if vs == visual_state:
		return
	visual_state = vs

	match visual_state:
		VisualState.NORMAL:
			scale = Vector2.ONE
			self_modulate = Color.WHITE

		VisualState.HOVERED:
			scale = Vector2(1.1, 1.1)
			self_modulate = Color8(255, 230, 230, 255)

		VisualState.LOCKED_IN:
			scale = Vector2.ONE
			self_modulate = Color.GRAY
			_kill_tweens()

# ─────────────────────────── mouse handlers ────────────────────────────
func _on_area2d_input_event(_viewport, event, _shape_idx) -> void:
	if event.is_action_pressed("grab_tile"):
		if state == TileState.PLACED_ON_BOARD:
			# ask the Board owner if we may pick up
			set_state(TileState.GRABBED_FROM_BOARD)
		elif state == TileState.IDLE:
			set_state(TileState.GRABBED_FROM_HAND)

	elif event.is_action_released("grab_tile"):
		if state in [TileState.GRABBED_FROM_HAND, TileState.GRABBED_FROM_BOARD]:
			released.emit(self)

	elif event.is_action_pressed("return_tile_to_hand"):
		if state == TileState.PLACED_ON_BOARD:
			# Board will hear return_to_hand and call remove_tile()
			set_state(TileState.IDLE)

func _on_area2d_mouse_enter() -> void:
	if state != TileState.LOCKED_IN:
		set_visual_state(VisualState.HOVERED)

func _on_area2d_mouse_exit() -> void:
	if state != TileState.LOCKED_IN:
		set_visual_state(VisualState.NORMAL)

# ───────────────────────────── board hooks ─────────────────────────────
func placed_on_board() -> void:
	set_state(TileState.PLACED_ON_BOARD)

func release_from_board() -> void:
	set_state(TileState.IDLE)

func lock_in() -> void:
	set_state(TileState.LOCKED_IN)

# ─────────────────────────── feedback helpers ──────────────────────────
func ding() -> void:
	self_modulate = Color.GREEN
	_run_color_tween(0.4, Color.WHITE, false)

func animate_score() -> void:
	_run_scale_tween(0.1, Vector2.ONE, Vector2.ONE * 1.1, false)
	_run_color_tween(0.1, Color.GRAY, true)

func bzzt() -> void:
	_kill_tweens()
	self_modulate = Color.RED
	_run_color_tween(0.25, Color.WHITE, false)
	_run_scale_tween(0.1, Vector2.ONE, Vector2.ONE * 1.2, false)
	_run_shake_tween(0.18, 12.0, false)

# ─────────────────────── generic tween helpers ────────────────────────
func _run_color_tween(length : float, end_color : Color, wait : bool) -> void:
	if _color_tw: _color_tw.kill()
	_color_tw = create_tween()
	_color_tw.tween_property(self, "self_modulate", end_color, length).set_ease(Tween.EASE_IN)
	if wait: await _color_tw.finished

func _run_scale_tween(length : float, start_scale : Vector2, end_scale : Vector2, wait : bool) -> void:
	if _scale_tw: _scale_tw.kill()
	_scale_tw = create_tween()
	scale = start_scale
	_scale_tw.tween_property(self, "scale", end_scale, length).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tw.tween_property(self, "scale", start_scale, length).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if wait: await _scale_tw.finished

func _run_shake_tween(duration : float, amplitude : float, wait : bool) -> void:
	if _shake_tw: _shake_tw.kill()
	_base_pos = position
	_shake_tw = create_tween()
	_shake_tw.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_shake_tw.tween_method(Callable(self, "_apply_shake"), amplitude, 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_shake_tw.tween_callback(Callable(self, "_reset_position"))
	if wait: await _shake_tw.finished

func _apply_shake(strength : float) -> void:
	var offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * strength
	position = _base_pos + offset

func _reset_position() -> void:
	position = _base_pos

# ───────────────────────────── maintenance ────────────────────────────
func _kill_tweens() -> void:
	if _color_tw: _color_tw.kill()
	if _scale_tw: _scale_tw.kill()
	if _shake_tw: _shake_tw.kill()
