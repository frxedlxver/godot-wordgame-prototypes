class_name CenterSlot extends SlotInfo

func _init() -> void:
	self.tex = load("res://sprites/slots/slot_center.tres")

func get_slot_effect():
	var effect : SlotEffect = SlotEffect.new()
	effect.type = SlotEffect.SlotEffectType.MULT_MULT
	effect.value = 2
	return effect
