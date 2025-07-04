# tabs for indentation
class_name SaveData
extends Resource

@export var version      : int      = 1

# --- RUN SNAPSHOT ----------------------------------------------------------
@export var run_data     : RunData  = RunData.new()
@export var run_pending  : bool     = false   # ← true ⇢ Continue available
# --------------------------------------------------------------------------

# put other long-term fields here (settings, unlocks, stats, …)
