class_name AudioStreamManager extends Node

static var _instance : AudioStreamManager

@onready var sounds : Dictionary = {
	"good" : $Good,
	"oops" : $Bad,
}

func _ready() -> void:
	AudioStreamManager._instance = self
	
static func play_sound_effect(name : String, pitch_mod : float):
	var audio_stream : AudioStreamPlayer = _instance.sounds.get(name)
	print("playing sound")
	if audio_stream and audio_stream is AudioStreamPlayer:
		audio_stream.play()

static func play_good_sound(pitch_mod : float = 0.0):
	var stream : AudioStreamPlayer = _instance.get_node("Good")
	stream.pitch_scale = 1.0 + pitch_mod
	stream.play()

static func reset_good_pitch():
	var stream : AudioStreamPlayer = _instance.get_node("Good")
	if stream.playing:
		await stream.finished
	stream.pitch_scale = 1.0
	
static func play_bad_sound():
	_instance.get_node("Bad").play()
	
static func play_tick():
	_instance.get_node("Click").pitch_scale = 1.0 + randf_range(-0.1, 0.1)
	_instance.get_node("Click").play()

static func play_round_total():
	_instance.get_node("RoundTotal").play()
	
static func play_turn_total():
	_instance.get_node("TurnTotal").play()
