class_name Definition

class Meaning:
	var part_of_speech : String
	var definition : String

var word : String
var meanings : Array[Meaning]

func _init(p_word : String ="", p_meanings : Array[Meaning] = []):
	self.word = p_word
	self.meanings = p_meanings

func add_meaning(part_of_speech : String, definition : String):
	var meaning = Meaning.new()
	meaning.part_of_speech = part_of_speech
	meaning.definition = definition
	meanings.append(meaning)
	
func get_meanings_string():
	if meanings.size() == 0:
		return "No Meanings found"
	
	var meanings_str = ""
	for meaning in meanings:
		meanings_str += "[%s]: %s\n" % [meaning.part_of_speech, meaning.definition]
	return meanings_str
