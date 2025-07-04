class_name BagUI extends TextureRect

var anim_tween : Tween

func update_count(new_count : int, animate : bool = false):
	$Label.text = str(new_count)
	
	if animate:
		self.scale = Vector2(1.25, 1.25)
		if anim_tween:
			anim_tween.kill()
		
		anim_tween = create_tween()
		anim_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
		AudioStreamManager.play_bag_sound()
		
