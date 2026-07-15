extends CanvasLayer

func _ready():
	update_max_games_label()
	update_speed_label()
	$VBox/LivesToggle.button_pressed = SaveManager.get_lives_enabled()
	$VBox/HardExitToggle.button_pressed = SaveManager.get_hard_exit()
	$VBox/HardExitToggle.visible = SaveManager.get_lives_enabled()
	
	var speed = SaveManager.get_agent_speed()
	$VBox/HBoxContainer/SpeedSlow.button_pressed = speed == 0
	$VBox/HBoxContainer/SpeedNormal.button_pressed = speed == 1
	$VBox/HBoxContainer/SpeedFast.button_pressed = speed == 2

func _on_lives_toggled(val: bool):
	SaveManager.set_lives_enabled(val)
	$VBox/HardExitToggle.visible = val

func update_max_games_label():
	$VBox/MaxGamesRow/MaxGamesValue.text = "Max Games: " + str(SaveManager.get_max_games())

func _on_max_games_minus():
	var val = max(1, SaveManager.get_max_games() - 1)
	SaveManager.set_max_games(val)
	update_max_games_label()

func _on_max_games_plus():
	var val = min(999, SaveManager.get_max_games() + 1)
	SaveManager.set_max_games(val)
	update_max_games_label()

func _on_hard_exit_toggled(val: bool):
	SaveManager.set_hard_exit(val)

func update_speed_label():
	var speed_names = ["Slow", "Normal", "Fast"]
	$VBox/SpeedLabel.text = "Agent Speed (" + speed_names[SaveManager.get_agent_speed()] + ")"

func _on_speed_slow():
	SaveManager.set_agent_speed(0)
	update_speed_label()

func _on_speed_normal():
	SaveManager.set_agent_speed(1)
	update_speed_label()

func _on_speed_fast():
	SaveManager.set_agent_speed(2)
	update_speed_label()

func _on_back():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_clear_save() -> void:
	$ConfirmDialog.popup()

func _on_confirm_clear():
	SaveManager.clear_save_data()
	$VBox/MaxGamesRow/MaxGamesValue.text = str(SaveManager.get_max_games())
	$VBox/LivesToggle.button_pressed = SaveManager.get_lives_enabled()
	$VBox/HardExitToggle.button_pressed = SaveManager.get_hard_exit()
	update_speed_label()
	update_max_games_label()
	_on_back()
