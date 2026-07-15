extends Node

signal box_cleared  # emitted when all agents home, slot can be freed

var color_id: int
var agents_total: int
var agents_dispatched: int = 0
var agents_home: int = 0
var slot_index: int = -1
var box_position: Vector2i  # grid position of this box's spawn point

var grid_manager
var agent_scene = preload("res://agent.tscn")
var spawn_timer: Timer
var is_idle: bool = false  # true when no pixels available, waiting for recheck

func init(c: int, count: int, slot: int, box_pos: Vector2i, gm: Node):
	color_id = c
	agents_total = count
	slot_index = slot
	box_position = box_pos
	grid_manager = gm

func start():
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = get_spawn_interval()
	spawn_timer.timeout.connect(_on_spawn_timer)
	spawn_timer.start()

func get_spawn_interval() -> float:
	match SaveManager.get_agent_speed():
		0: return 0.7  # slow
		1: return 0.5  # normal
		2: return 0.1  # fast
		_: return 0.3

func _on_spawn_timer():
	if agents_dispatched >= agents_total:
		spawn_timer.stop()
		return
	dispatch_next_agent()

func dispatch_next_agent():
	if not grid_manager.color_index.has(color_id):
		go_idle()
		return
	
	var available = grid_manager.color_index[color_id]
	if available.size() == 0:
		go_idle()
		return
	
	# Sort by slot comparator and take first
	var sorted = grid_manager.sort_pixels_for_slot(available, slot_index)
	var target = sorted[0]
	grid_manager.color_index[color_id].erase(target)
	
	var path = grid_manager.find_path(target, box_position)
	if path.size() == 0:
		go_idle()
		return
	path.reverse()
	# Claim the pixel
	grid_manager.claim_cell(target.x, target.y)
	var agent = agent_scene.instantiate()
	grid_manager.add_child(agent)
	agent.init(path, grid_manager, color_id, self)
	agent.start()
	agents_dispatched += 1

func go_idle():
	is_idle = true
	spawn_timer.stop()  # pause timer until woken by recheck
	grid_manager.check_game_loose()

# Called by agent when it arrives home
func on_agent_returned():
	agents_home += 1
	if agents_home >= agents_total:
		box_cleared.emit()
	grid_manager.get_node("GridDisplay").queue_redraw()
	grid_manager.check_game_loose()

# Called by GridManager recheck when new pixels of our color become available
func on_pixels_available():
	if is_idle and agents_dispatched < agents_total:
		is_idle = false
		dispatch_next_agent()
		if not spawn_timer.is_stopped():
			return
		spawn_timer.start()  # restart timer only after dispatch
