# tabs for indentation
class_name ScoreRoller
extends Node

## Public ------------------------------------------------------------------
func roll(turn_delta : int,              # points earned this play
		total_label : Label,           # cumulative-score label
		turn_label  : Label,           # this-turn label
		score_bar	: ProgressBar,
		duration    : float = 0.5):

	_base_total   = int(total_label.text)	# current total shown
	_turn_delta   = turn_delta
	_total_label  = total_label
	_turn_label   = turn_label
	_score_bar = score_bar

	# start at 0 progress, tween up to full delta
	progress = 0.0
	var tw = create_tween()
	tw.tween_property(self, "progress", turn_delta, duration)\
	  .set_trans(Tween.TRANS_QUAD)\
	  .set_ease(Tween.EASE_IN_OUT)\
	  .finished.connect(_on_roll_finished)

## Private -----------------------------------------------------------------
var progress     : float:
	set(v):
		_set_progress(v)
	get: return _progress
		
var _progress : float = 0.0

var _base_total		: int
var _turn_delta		: int
var _total_label	: Label
var _turn_label		: Label
var _score_bar		: ProgressBar

func _set_progress(v : float):
	_progress = v
	
	# update both labels on every tween step
	var total  = _base_total + int(round(v))
	var turn_total = _turn_delta - int(round(v))

	_total_label.text = "%d" % (total)
	_turn_label.text  = "%d" % max(0, turn_total)
	
	_score_bar.value = total

func _on_roll_finished():
	_turn_label.text = "0"   # ensure clean landing
