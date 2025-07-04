class_name DefinitionGetter extends Node2D

var word_to_check : String
signal definition_ready(Definition)
signal no_definition_found()
var http_request : HTTPRequest
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	http_request = HTTPRequest.new()
	self.add_child(http_request)
	if self.word_to_check != null:
		http_request.request_completed.connect(_on_request_completed)
		http_request.request("https://api.dictionaryapi.dev/api/v2/entries/en/%s" % self.word_to_check)


func _on_request_completed(result, _response_code, _headers, body):
	var definition : Definition = Definition.new()
	definition.word = self.word_to_check
	
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json is Array:
			var word = json[0]["word"]
			definition.word = word
			for meaning in json[0]["meanings"]:
				var def = meaning["definitions"][0]["definition"]
				var part_of_speech = meaning["partOfSpeech"]
				definition.add_meaning(part_of_speech, def)
	definition_ready.emit(definition)
	self.queue_free()
