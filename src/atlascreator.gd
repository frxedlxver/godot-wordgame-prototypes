class_name SpritesheetToAtlas extends Node2D

@export var atlas_image : CompressedTexture2D

var pix_size : Vector2i = Vector2i(5, 7)
var size : Vector2i = Vector2i(10, 1)

var to_get = ["0","1","2","3","4","5","6","7","8","9"]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var i = 0
	for y in size.y:
		for x in size.x:
			if i < to_get.size():
				var next_letter = to_get[i]
				i += 1
				var atlas = AtlasTexture.new()
				atlas.atlas = atlas_image
				atlas.region = Rect2i(x * pix_size.x, y * pix_size.y, pix_size.x, pix_size.y)
				ResourceSaver.save(atlas, "res://sprites/small_numbers/%s.tres" % next_letter)
				print("letter %s at %d, %d. saved to %s" % [next_letter, x, y, atlas.resource_path])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
