class_name WordChecker extends Node

const txt_dictionary_path : String = ".\\EnableDictionary.txt"
var dict : Dictionary = {}
@export var def_getter_scene : PackedScene
var debug_print : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var file : FileAccess = FileAccess.open(txt_dictionary_path, FileAccess.READ)
	var t : int = Time.get_ticks_usec()
	
	while not file.eof_reached():
		dict[file.get_line()] = ""
	var t2 : int = Time.get_ticks_usec()
	var final_time = t2 - t
	
	if debug_print:
		print("took %d usec to create dict of size %d" % [final_time, dict.keys().size()])

	check_for_word("hi")
	check_for_word("oops")
	check_for_word("plappa")
	
func check_for_word(word : String) -> bool:
	if debug_print:
		print("checking for word: %s" % word)
		
	if dict.has(word.to_lower()):
		if debug_print:
			print("found word %s!" % word)
		return true
	else:
		if debug_print:
			print("did not find word %s." % word)
		return false


func print_definition(word : String):
	var def_getter = def_getter_scene.instantiate()
	
	# def getter automatically makes request using this value in it's _ready() function
	def_getter.word_to_check = word
	
	# will automatically free self after printing definition
	self.add_child(def_getter)
