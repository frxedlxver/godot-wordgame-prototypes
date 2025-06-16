# tabs for indentation
class_name RuneEffect
extends Resource

enum RuneEffectType {
	ZERO_TILE_SCORE,
	ADD_TILE_SCORE,        # +value           (tile only)
	MUL_TILE_SCORE,        # ×value
	SET_TILE_SCORE,        # =value
	ADD_SCORE,        # +value           (word only)
	ADD_MONEY,             # +value           (run_data.money)
	ADD_MULTIPLIER,        # +value           (board/run multiplier)
	MULT_MULTIPLIER,        # +value           (board/run multiplier)
	EXTRA_PLAY,            # +value plays
	NO_OP                  # placeholder / default
}

@export var type   : RuneEffectType  = RuneEffectType.NO_OP
@export var value  : int             = 0               # generic magnitude
@export var tag    : String          = ""              # optional, e.g. "vowel"
@export var exclamation : String	= ""
