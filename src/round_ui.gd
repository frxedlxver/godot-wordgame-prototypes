class_name RoundUI extends Control

@export var turn_score_label : Label
@export var mult_label : Label
@export var total_score_label : Label
@export var bag_ui : BagUI

func animate_in():
	self.show()
	
func animate_out():
	self.hide()
	
func bag_count_updated(new_count : int):
	bag_ui.update_count(new_count)

func update_turn_score(new_score : int):
	turn_score_label.text = "%d" % new_score
	
func update_total_score(new_score : int):
	total_score_label.text = "%d" % new_score

func update_mult(new_mult : int):
	mult_label.text = "%d" % new_mult
