class_name Board extends Node2D

@onready var round_manager : RoundManager = get_parent()
const board_size : Vector2i = Vector2i(7, 7)
const slot_size : Vector2i = Vector2i(34, 34)
@export var slot_scene : PackedScene

signal slot_highlighted(Slot)
signal slot_unhighlighted(Slot)

class SlotTileStruct:
	var slot : Slot
	var tile : GameTile
	
	func _init(p_slot : Slot = null, p_tile : GameTile = null) -> void:
		self.slot = p_slot
		self.tile = p_tile

var board_state : Array[Array] = []
var board_state_text : Array[Array] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for y in board_size.y:
		board_state.append([])
		board_state_text.append([])
		for x in board_size.x:
			board_state[y].append('')
			board_state_text[y].append('')
			var slot_pos = Vector2i(x, y) * slot_size
			var slot : Node2D = slot_scene.instantiate()
			self.add_child(slot)
			slot.name = "slot_%d-%d" % [x, y]
			slot.position = slot_pos
			slot.coordinates = Vector2i(x, y)
			board_state[y][x] = SlotTileStruct.new(slot)
			slot.highlighted.connect(_slot_highlighted)

func _input(event):
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_0:
		var illegal_tiles = Evaluator.evaluate_board(board_state_text)
		for tile in illegal_tiles:
			board_state[tile.y][tile.x].tile.self_modulate = Color.RED
			
func place_tile_at(game_tile : GameTile, slot : Slot):
	var tw = create_tween()
	tw.tween_property(game_tile, "global_position", slot.global_position, 0.1)
	tw.set_ease(Tween.EASE_IN)
	board_state[slot.coordinates.y][slot.coordinates.x].tile = game_tile
	board_state_text[slot.coordinates.y][slot.coordinates.x] = game_tile.letter
	game_tile.coordinates = slot.coordinates
	game_tile.grabbed.connect(remove_tile)
	game_tile.return_to_hand.connect(remove_tile)
	debug_print_board()


func remove_tile(game_tile : GameTile):
	var slot_tile_struct : SlotTileStruct = board_state[game_tile.coordinates.y][game_tile.coordinates.x]
	board_state_text[game_tile.coordinates.y][game_tile.coordinates.x] = ''
	slot_tile_struct.tile.disconnect(&"grabbed", remove_tile)
	slot_tile_struct.tile.disconnect(&"return_to_hand", remove_tile)
	slot_tile_struct.tile = null
	debug_print_board()


func debug_print_board():
	var board_string = ''
	for row in board_state_text:
		for cell in row:
			board_string += cell if cell != '' else '-'
			board_string += ' '
		board_string += '\n'
	print(board_string)


func _slot_highlighted(slot : Slot):
	slot_highlighted.emit(slot)


func _slot_unhighlighted(slot : Slot):
	slot_unhighlighted.emit(slot)
