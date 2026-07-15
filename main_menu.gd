extends CanvasLayer

func _ready():
	#SaveManager.unlock(4)
	if not SaveManager.any_unlocked():
		GameState.current_difficulty = 4
		get_tree().change_scene_to_file("res://grid_manager.tscn")
		return
	build_level_buttons()

func build_level_buttons():
	for i in range(1, 17):
		var btn = Button.new()
		btn.text = "Level " + str(i)
		btn.custom_minimum_size = Vector2(100, 35)
		btn.custom_maximum_size = Vector2(100, 35)
		if SaveManager.is_unlocked(i):
			btn.disabled = false
			btn.pressed.connect(func(): _on_level_pressed(i))
		else:
			btn.disabled = false
			btn.text += " 🔒"
			btn.pressed.connect(func(): _on_locked_pressed())
		$MainVBox/HBoxContainer/RightColumn/ScrollContainer/LevelList.add_child(btn)

func _on_level_pressed(difficulty: int):
	GameState.current_difficulty = difficulty
	get_tree().change_scene_to_file("res://grid_manager.tscn")

func _on_locked_pressed():
	$LockedPopup.popup()

func _on_game_mode_pressed():
	$ComingSoonPopup.popup()

func _on_options_pressed():
	get_tree().change_scene_to_file("res://options_menu.tscn")
