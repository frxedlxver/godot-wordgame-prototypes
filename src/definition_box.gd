class_name DefinitionBox extends VBoxContainer

var definition : Definition

func set_def(def : Definition):
	self.definition = def
	$Title.text = self.definition.word
	$Body.text = self.definition.get_meanings_string()
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
