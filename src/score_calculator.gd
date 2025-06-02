class_name ScoreCalculator extends Node

static var scrabble_points: Dictionary = {
	"A": 1,
	"B": 3,
	"C": 3,
	"D": 2,
	"E": 1,
	"F": 4,
	"G": 2,
	"H": 4,
	"I": 1,
	"J": 8,
	"K": 5,
	"L": 1,
	"M": 3,
	"N": 1,
	"O": 1,
	"P": 3,
	"Q": 10,
	"R": 1,
	"S": 1,
	"T": 1,
	"U": 1,
	"V": 4,
	"W": 4,
	"X": 8,
	"Y": 4,
	"Z": 10
}

static func get_word_scores(words : Array[String]) -> Dictionary:
	var score_dict : Dictionary = {}
	for word in words:
		score_dict[word] = calculate_word_score(word)
	return score_dict


static func calculate_word_score(word : String) -> int:
	var score : int = 0
	for letter in word: 
		score+=scrabble_points[letter.to_upper()]
	return score
