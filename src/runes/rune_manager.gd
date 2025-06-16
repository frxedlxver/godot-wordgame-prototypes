# tabs for indentation
class_name RuneManager
extends HBoxContainer

func get_runes():
	var result : Array[RuneNode]
	for child in get_children():
		result.append(child as RuneNode)
	return result

func _load_visuals():
	for r in G.current_run_data.runes:
		_spawn_node(r)

func _spawn_node(rune:Rune, idx:int=-1):
	var n := RuneNode.new()
	n.rune = rune
	n.drag_finished.connect(_on_node_reordered)
	add_child(n)
	if idx >= 0:
		move_child(n, idx)

# --------------------------------------------------------------------------
func _on_node_reordered(old_idx:int, new_idx:int):
	var r = G.run_data.runes.pop_at(old_idx)
	G.run_data.runes.insert(new_idx, r)
	SAVE_MANAGER.save_data()
