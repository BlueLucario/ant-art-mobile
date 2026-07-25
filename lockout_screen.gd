extends CanvasLayer

var countdown_timer: Timer

func _ready():
	#SaveManager.set_lockout_minutes(1) # Key
	update_display()
	countdown_timer = Timer.new()
	add_child(countdown_timer)
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_tick)
	countdown_timer.start()

func _on_tick():
	update_display()
	if SaveManager.get_seconds_remaining() <= 0:
		countdown_timer.stop()
		SaveManager.clear_lockout_timestamp()
		SaveManager.reset_session()
		get_tree().change_scene_to_file("res://main_menu.tscn")

func update_display():
	var remaining = SaveManager.get_seconds_remaining()
	var hours = remaining / 3600
	var minutes = (remaining % 3600) / 60
	var seconds = remaining % 60
	$VBox/CountdownLabel.text = "%02d:%02d:%02d" % [hours, minutes, seconds]

func _on_ok_exit():
	get_tree().quit()
