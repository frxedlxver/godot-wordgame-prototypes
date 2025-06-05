class_name DefinitionPanel extends PanelContainer

var definitions : Array[DefinitionBox] = []
var _def_box_scene : PackedScene = preload("res://scenes/definition_box.tscn")

func clear():
	for definition in self.definitions:
		definition.queue_free()
	self.definitions.clear()

func add_def(definition : Definition):
	var defbox : DefinitionBox = _def_box_scene.instantiate()
	defbox.set_def(definition)
	definitions.append(defbox)
	$Definitions.add_child(defbox)

func display():
	self.show()
