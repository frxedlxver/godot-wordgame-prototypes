
class_name RunTable 

class RoundCfg:
	var phase1 : PhaseCfg
	var phase2 : PhaseCfg
	var boss : PhaseCfg
	
	func _init(p1 : PhaseCfg, p2 : PhaseCfg, p3 : PhaseCfg):
		phase1 = p1
		phase2 = p2
		boss = p3
	

##  RunTable.RUNS[round][phase] → PhaseCfg
static var default_run : Array = [
	# ROUND 1
	RoundCfg.new(
		PhaseCfg.new(100, false, 3, ""),
		PhaseCfg.new(200, false, 5, ""),
		PhaseCfg.new(350, true, 10, "")
	),
	# ROUND 2
	RoundCfg.new(
		PhaseCfg.new(300, false, 3, ""),
		PhaseCfg.new(500, false, 5, ""),
		PhaseCfg.new(1000, true, 10, "")
	)
	# … add six more rounds …
]
