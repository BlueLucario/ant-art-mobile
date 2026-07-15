extends CanvasLayer

signal restart_requested(difficulty_delta: int)

var current_difficulty

func _ready():
	hide()

func show_result(win: bool, difficulty: int):
	var out_of_games = SaveManager.decrement_games()
	current_difficulty = difficulty
	
	if win:
		SaveManager.record_win(difficulty)
	else:
		SaveManager.record_loss(difficulty)
	
	if out_of_games and SaveManager.get_lives_enabled():
		show_games_out()
		return
	
	if win:
		var t = "You Win!"
		if not SaveManager.is_unlocked(difficulty + 1):
			t += "\nUnlocked: Level " + str(difficulty + 1)
		$Panel/Label.text = t
		$Panel/HBoxContainer/EasierGame.visible = false
		$Panel/HBoxContainer/SameGame.visible = true
		$Panel/HBoxContainer/HarderGame.visible = true
	else:
		var t = "Game Over"
		if not SaveManager.is_unlocked(difficulty - 1):
			t += "\nUnlocked: Level " + str(difficulty - 1)
		$Panel/Label.text = t
		$Panel/HBoxContainer/EasierGame.visible = true
		$Panel/HBoxContainer/SameGame.visible = true
		$Panel/HBoxContainer/HarderGame.visible = false
	
	$Panel/MainMenu.visible = true
	$Panel/OKExit.visible = false
	show()

func show_games_out():
	$Panel/Label.text = "This is an exit point.\nGo drink some Water!\n\nYou can change this in\nthe Settings menu."
	$Panel/HBoxContainer/EasierGame.visible = false
	$Panel/HBoxContainer/SameGame.visible = false
	$Panel/HBoxContainer/HarderGame.visible = false
	$Panel/MainMenu.visible = false
	$Panel/OKExit.visible = true
	show()

func _on_easier():
	hide()
	get_parent().restart(-1)

func _on_same():
	hide()
	get_parent().restart(0)

func _on_harder():
	hide()
	get_parent().restart(1)

func _on_main_menu():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_ok_exit():
	if SaveManager.get_hard_exit():
		get_tree().quit()
	else:
		get_tree().change_scene_to_file("res://main_menu.tscn")
