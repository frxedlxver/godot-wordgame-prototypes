class_name GameTile extends Sprite2D

enum TileState {
	IDLE,
	GRABBED,
	RELEASED,
	PLACED_ON_BOARD
}

enum VisualState {
	NORMAL,
	HOVERED
}

signal grabbed(GameTile)
signal released(GameTile)
signal return_to_hand(GameTile)

var state : TileState
var visual_state : VisualState
var coordinates : Vector2i

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
	if self.state == TileState.GRABBED:
		self.global_position = get_global_mouse_position()
	if self.state == TileState.RELEASED:
		set_state(TileState.IDLE)

func set_state(new_state : TileState):
	self.state = new_state
	match new_state:
		TileState.GRABBED:
			$TextEdit.text = "GRBD"
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

func _area2d_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("grab_tile"):
		set_state(TileState.GRABBED)
	elif event.is_action_released("grab_tile"):
		set_state(TileState.RELEASED)
	elif event.is_action_pressed("return_tile_to_hand"):
		set_state(TileState.IDLE)

func _area2d_mouse_entered():
	set_visual_state(VisualState.HOVERED)
	pass
	
func _area2d_mouse_exited():
	set_visual_state(VisualState.NORMAL)
	pass
func placed_on_board():
	print("placed on board")
	set_state(TileState.PLACED_ON_BOARD)
