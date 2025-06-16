class_name LettersNumbers

enum Letter {
	A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z
}

const STARTING_LETTERS: Dictionary = {
	"a": 9,	"b": 2,	"c": 2,	"d": 4,	"e": 12,
	"f": 2,	"g": 3,	"h": 2,	"i": 9,	"j": 1,
	"k": 1,	"l": 4,	"m": 2,	"n": 6,	"o": 8,
	"p": 2,	"q": 1,	"r": 6,	"s": 4,	"t": 6,
	"u": 4,	"v": 2, "w": 2, "x": 1, "y": 2, "z": 1
}

const LETTER_SCORES: Dictionary = {
	"a": 1,	"b": 3,	"c": 3,	"d": 2,	"e": 1,
	"f": 4,	"g": 2,	"h": 4,	"i": 1,	"j": 8,
	"k": 5,	"l": 1,	"m": 3,	"n": 1,	"o": 1,
	"p": 3,	"q": 10,"r": 1,	"s": 1,	"t": 1,
	"u": 4,	"v": 4, "w": 4, "x": 8, "y": 4, "z": 10
}

const VOWELS : Array[String] = ['a','e','i','o','u',]

static func is_vowel(to_check : String):
	return VOWELS.has(to_check.to_lower())

static func get_letter_image(letter: String):
	var path = "res://sprites/letters/%s.tres" % letter.to_upper()
	return load(path)
	
static func get_small_number_image(number : int):
	if number < 0 or number > 9:
		print("number %d not in range" % number)
	var path = "res://sprites/small_numbers/%d.tres" % number
	return load(path)
