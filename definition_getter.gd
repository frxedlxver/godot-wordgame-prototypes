class_name DefinitionGetter extends Node2D

var word_to_check : String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if self.word_to_check != null:
		$HTTPRequest.request_completed.connect(_on_request_completed)
		$HTTPRequest.request("https://api.dictionaryapi.dev/api/v2/entries/en/%s" % self.word_to_check)


func _on_request_completed(result, _response_code, _headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var word = json[0]["word"]
		print("")
		print("%s:" % word.to_upper())
		for meaning in json[0]["meanings"]:
			var def = meaning["definitions"][0]["definition"]
			var part_of_speech = meaning["partOfSpeech"]
			print("[%s]: %s" % [part_of_speech, def])
		self.queue_free()
