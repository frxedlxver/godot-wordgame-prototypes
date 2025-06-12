class_name RoundUI extends Control


func animate_in():
	self.show()
	
func animate_out():
	self.hide()
	
func bag_count_updated(new_count : int):
	$BagUI.update_count(new_count)

func update_turn_score(new_score : int):
	$TurnScore.text = "Turn: %d" % new_score
	
func update_total_score(new_score : int):
	$TotalScore.text = "Total: %d" % new_score
	
