extends Node2D

const CELL_SIZE = 20
#const MOVE_TIME = 0.1 # seconds per cell

enum Phase { OUTBOUND, RETURNING }

var home_box  # reference to the box that spawned this agent
var path = [] # array of Vector2i positions
var current_step = 0
var grid_manager
var color_id
var phase = Phase.OUTBOUND

func init(p: Array, gm: Node, c: int, box: Node):
	path = p
	grid_manager = gm
	color_id = c
	home_box = box

func start():
	if path.size() == 0:
		return
	position = Vector2(path[0].x * CELL_SIZE, path[0].y * CELL_SIZE)
	move_to_next()

func get_move_time() -> float:
	match SaveManager.get_agent_speed():
		0: return 0.2  # slow
		1: return 0.1  # normal
		2: return 0.05 # fast
		_: return 0.2

func move_to_next():
	current_step += 1
	if current_step >= path.size():
		if phase == Phase.OUTBOUND:
			arrive_at_pixel()
		else:
			arrive_at_box()
		return
	
	var next_pos = path[current_step]
	var tween = create_tween()
	tween.tween_property(
		self,
		"position",
		Vector2(next_pos.x * CELL_SIZE, next_pos.y * CELL_SIZE),
		get_move_time()
	)
	tween.tween_callback(move_to_next)

func arrive_at_pixel():
	var target = path[path.size() - 1]
	grid_manager.remove_pixel(target.x, target.y)
	
	# Switch to return phase
	phase = Phase.RETURNING
	path.reverse()
	current_step = 0
	queue_redraw()  # redraw as square
	move_to_next()

func arrive_at_box():
	home_box.on_agent_returned()
	queue_free()

func _draw():
	if phase == Phase.OUTBOUND:
		# Circle while hunting
		draw_circle(
			Vector2(CELL_SIZE / 2, CELL_SIZE / 2),
			CELL_SIZE * 0.35,
			grid_manager.COLORS[color_id]
		)
	else:
		# Square while returning (carrying the pixel)
		var size = CELL_SIZE * 0.6
		var offset = (CELL_SIZE - size) / 2
		draw_rect(
			Rect2(offset, offset, size, size),
			grid_manager.COLORS[color_id]
		)
