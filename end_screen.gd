extends CanvasLayer

signal restart_requested(difficulty_delta: int)

func _ready():
	hide()

func show_result(win: bool):
	$Panel/VBoxContainer/Label.text = "You Win!" if win else "Game Over"
	show()

func _on_easier():
	restart_requested.emit(-1)

func _on_same():
	restart_requested.emit(0)

func _on_harder():
	restart_requested.emit(1)
