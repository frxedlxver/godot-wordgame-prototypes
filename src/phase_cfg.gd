# tabs for indentation
# res://data/PhaseCfg.gd
class_name PhaseCfg
extends RefCounted

var required_score	: int
var is_boss			: bool
var money_reward	: int
var upgrade_id		: String

func _init(
	required_score : int,
	is_boss : bool = false,
	money_reward : int = 0,
	upgrade_id : String = ""
) -> void:
	self.required_score = required_score
	self.is_boss        = is_boss
	self.money_reward   = money_reward
	self.upgrade_id     = upgrade_id
