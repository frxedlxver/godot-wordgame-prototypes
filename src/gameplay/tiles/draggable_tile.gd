# tabs for indentation
class_name DraggableTile
extends Sprite2D                 # works for Sprite2D, TextureRect, etc.

# ─────────────────────────── shared enums ────────────────────────────
enum DragState  { IDLE, GRABBED, PLACED, LOCKED, RELEASED }
enum VisualState { NORMAL, HOVER, LOCKED }

# ───────────────────────────── signals ───────────────────────────────
signal grabbed(DraggableTile)
signal released(DraggableTile)
signal hover_entered(DraggableTile)
signal hover_exited(DraggableTile)

# ───────────────────────── configurable UX ────────────────────────────
@export var hover_scale  : float = 1.10
@export var hover_tint   : Color = Color8(255,230,230)
@export var locked_tint  : Color = Color.GRAY
@export var hover_sfx    : Resource       = null   # optional AudioStream

# ───────────────────────── runtime state ─────────────────────────────
var drag_state   : int = DragState.IDLE
var visual_state : int = VisualState.NORMAL

# ───────────────────────────── setup  ────────────────────────────────
func _ready() -> void:
	# assume each tile scene contains an Area2D named "Area2D"
	var a := get_node("Area2D") as Area2D
	a.input_event .connect(_on_area2d_input)
	a.mouse_entered.connect(_on_area2d_enter)
	a.mouse_exited .connect(_on_area2d_exit)

# ─────────────────────── public helpers  ─────────────────────────────
func set_drag_state(s : int) -> void:
	if drag_state == s: return
	drag_state = s
	match s:
		DragState.GRABBED:
			grabbed.emit(self)
		DragState.IDLE, DragState.PLACED:
			released.emit(self)
	_update_visual()

func lock_in() -> void:
	drag_state   = DragState.LOCKED
	visual_state = VisualState.LOCKED
	_update_visual()

# ───────────────────── Area2D callbacks  ─────────────────────────────
func _on_area2d_input(_vp, ev, _shape) -> void:
	if ev.is_action_pressed("grab_tile") and drag_state == DragState.IDLE:
		set_drag_state(DragState.GRABBED)
	elif ev.is_action_released("grab_tile") and drag_state == DragState.GRABBED:
		set_drag_state(DragState.IDLE)

func _on_area2d_enter() -> void:
	hover_entered.emit(self)
	if drag_state == DragState.IDLE:
		visual_state = VisualState.HOVER
		_update_visual()

func _on_area2d_exit() -> void:
	hover_exited.emit(self)
	if drag_state == DragState.IDLE:
		visual_state = VisualState.NORMAL
		_update_visual()

# ─────────────────────── visual handling  ────────────────────────────
func _update_visual() -> void:
	match visual_state:
		VisualState.NORMAL:
			_apply_visual_state(Vector2.ONE, Color.WHITE)
		VisualState.HOVER:
			_apply_visual_state(Vector2.ONE * hover_scale, hover_tint)
			if hover_sfx: AudioStreamManager.play_tick()
		VisualState.LOCKED:
			_apply_visual_state(Vector2.ONE, locked_tint)

# Override in derived classes if they need extra bling
func _apply_visual_state(scale_vec : Vector2, tint : Color) -> void:
	scale         = scale_vec
	self_modulate = tint
