class_name UnscramblerTester extends Node

class kvp:
	var key = ""
	var value = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var word = "flagsol"
	log_all_permutations(word)
	find_highest_scoring(word)
	
	
func find_highest_scoring(scrambled_text : String):
	var words = Unscrambler.unscramble(scrambled_text)
	var scored_words = ScoreCalculator.get_word_scores(words)
	
	var max : kvp = kvp.new()
	
	for word in scored_words.keys():
		if scored_words[word] > max.value:
			max.key = word
			max.value = scored_words[word]
	
	print("highest scoring word is %s, for %d points" % [max.key, max.value])

func log_all_permutations(scrambled_text : String):
	var t = Time.get_ticks_usec()
	var words = Unscrambler.unscramble(scrambled_text)
	var t2 = Time.get_ticks_usec()
	print("took %d usec to check permuations" % (t2-t))
	var file = FileAccess.open("%s_unscrambled.txt" % scrambled_text,FileAccess.WRITE)
	for word in words:
		file.store_string("%s\n" % word)
	file.close()
	t2 = Time.get_ticks_usec()
	print("took %d usec to check permuations" % (t2-t))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
