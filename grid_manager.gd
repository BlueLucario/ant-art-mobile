extends Node

const GRID_WIDTH = 24
const GRID_HEIGHT = 36
const CELL_SIZE = 20  # pixels on screen per grid cell
const SLOT_X_POSITIONS = [2, 6, 11, 16, 20]  # grid x coords, y=35

enum CellState { PRESENT, REMOVED }
var COLORS = [
	Color(0.2, 0.7, 0.2), # green
	Color(0.802, 0.745, 0.0, 1.0), # light yellow
	Color(0.2, 0.4, 0.9), # blue
	Color(0.2, 0.8, 0.8), # cyan
	Color(0.829, 0.455, 0.067, 1.0), # orange
	Color(0.6, 0.2, 0.8), # purple
	Color(0.9, 0.4, 0.7), # pink
	Color(0.8, 0.2, 0.2), # red
	Color(0.9, 0.7, 0.1), # yellow
	Color(0.1, 0.5, 0.3), # dark green
	Color(0.1, 0.2, 0.6), # dark blue
	Color(0.9, 0.7, 0.6), # skin
	Color(0.5, 0.3, 0.1), # brown
	Color(0.9, 0.9, 0.9), # white
	Color(0.6, 0.6, 0.6), # light gray
	Color(0.3, 0.3, 0.3), # dark gray
]

var gameDificultyLvl = 3
var queue = []
var slots = [null, null, null, null, null]
var grid = []
var active_boxes = []  # all currently slotted boxes
var color_index = {}  # color -> array of {x, y} positions
var agent_scene = preload("res://agent.tscn")

func _ready():
	COLORS.shuffle()
	initialize_grid()
	color_index.clear()
	update_available_cells()
	generate_boxes()
	$GridDisplay.queue_redraw()
	$EndScreen.restart_requested.connect(_on_restart)

func indent(i: int):
	var ind = ""
	if i < 100:
		ind += " "
	if i < 10:
		ind += " "
	return ind+str(i)

func get_cell_color(color_id: int) -> Color:
	if color_id >= 0 and color_id < COLORS.size():
		return COLORS[color_id]
	return Color.WHITE

func initialize_grid(dificultyDelta: int = 0):
	grid.clear()
	gameDificultyLvl += dificultyDelta
	var dificultyLvl = gameDificultyLvl;
	if dificultyLvl > COLORS.size()-1: dificultyLvl = COLORS.size()-1
	if dificultyLvl < 0: dificultyLvl = 0
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if x > 0 and x < GRID_WIDTH-1 and y > 0 and y < GRID_WIDTH:#y<width is intentianal
				grid.append({
					"color": randi_range(0, dificultyLvl),#0,#randi_range(0, COLORS.size()-1),
					"state": CellState.PRESENT,
					"exposed": 0,
					"claimable": 1
				})
			else:
				grid.append({
					"color": 0,
					"state": CellState.REMOVED,
					"exposed": 0,
					"claimable": 0
				})

func get_cell(x: int, y: int):
	return grid[y * GRID_WIDTH + x]

func claim_cell(x: int, y: int):
	var cell = get_cell(x, y)
	cell.claimable = 0 
	$GridDisplay.queue_redraw()

func update_available_cells(x0: int = 0, y0: int = 0):
	var queue = []
	queue.append(Vector2i(x0, y0))

	while queue.size() > 0:
		var pos = queue.pop_front()
		
		var neighbors = [
			Vector2i(pos.x - 1, pos.y),
			Vector2i(pos.x + 1, pos.y),
			Vector2i(pos.x, pos.y - 1),
			Vector2i(pos.x, pos.y + 1),
		]
		
		for n in neighbors:
			if n.x < 0 or n.x >= GRID_WIDTH or n.y < 0 or n.y >= GRID_HEIGHT:
				continue
			var cell = get_cell(n.x, n.y)
			if cell.exposed == 1:
				continue
			cell.exposed = 1
			if cell.state == CellState.REMOVED:
				queue.append(n)
			elif cell.state == CellState.PRESENT and cell.claimable > 0:
				var c = cell.color
				if not color_index.has(c):
					color_index[c] = []
				if not color_index[c].has(n):
					color_index[c].append(n)

func remove_pixel(x: int, y: int):
	var cell = get_cell(x, y)
	
	if cell.exposed < 1:
		return # not accesable
	if cell.state == CellState.REMOVED:
		return # already gone
	
	# Remove it
	cell.state = CellState.REMOVED
	
	# Remove from color index if it was available
	var c = cell.color
	if color_index.has(c):
		color_index[c].erase(Vector2i(x, y))
	update_available_cells(x, y)
	
	# Notify any idle boxes that new pixels may be available
	notify_idle_boxes()
	$GridDisplay.queue_redraw()
	check_game_win()

func _is_traversable(n: Vector2i, goal: Vector2i) -> bool:
	if n == goal:
		return true
	if n.x < 0 or n.x >= GRID_WIDTH or n.y < 0 or n.y >= GRID_HEIGHT:
		return false
	var cell = get_cell(n.x, n.y)
	return cell.state == CellState.REMOVED

func find_path(start: Vector2i, goal: Vector2i) -> Array:
	# A* from pixel position to box position
	#print("Pathfinding from ", start, " to ", goal)
	var open_set = []
	var came_from = {}
	var g_score = {}
	var f_score = {}
	
	g_score[start] = 0
	f_score[start] = heuristic(start, goal)
	open_set.append(start)
	
	while open_set.size() > 0:
		# Find lowest f_score in open set
		var current = open_set[0]
		for pos in open_set:
			if f_score.get(pos, INF) < f_score.get(current, INF):
				current = pos
		
		if current == goal:
			return reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		var neighbors = [
			Vector2i(current.x + 1, current.y),
			Vector2i(current.x - 1, current.y),
			Vector2i(current.x, current.y + 1),
			Vector2i(current.x, current.y - 1),
		]
		for n in neighbors:
			# Allow movement through removed cells and one step outside grid (the border lane)
			if n.x < -1 or n.x > GRID_WIDTH or n.y < -1 or n.y > GRID_HEIGHT+3:
				continue
			
			# Check if traversable
			if not _is_traversable(n, goal):
				continue
			
			var tentative_g = g_score.get(current, INF) + 1
			if tentative_g < g_score.get(n, INF):
				came_from[n] = current
				g_score[n] = tentative_g
				f_score[n] = tentative_g + heuristic(n, goal)
				if not open_set.has(n):
					open_set.append(n)
	
	return []  # no path found

func heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path

func launch_agent(pixel: Vector2i, box_position: Vector2i, color: int):
	var path = find_path(pixel, box_position)
	if path.size() == 0:
		print("Error: No path found!")
		return
	path.reverse()  # path goes pixel→box, we want box→pixel for travel
	var agent = agent_scene.instantiate()
	add_child(agent)
	agent.init(path, self, color)
	agent.start()

func generate_boxes():
	var maxBoxSize = 42 + (gameDificultyLvl*2)
	if maxBoxSize < 1: maxBoxSize
	var color_counts = {}
	for y in range(1, GRID_WIDTH):
		for x in range(1, GRID_WIDTH):
			var cell = get_cell(x, y)
			if cell.state == CellState.PRESENT:
				color_counts[cell.color] = color_counts.get(cell.color, 0) + 1
	
	queue.clear()
	for color in color_counts:
		var remaining = color_counts[color]
		while remaining > 0:
			var box_size = min(randi_range(5, maxBoxSize), remaining)
			queue.append({"color": color, "count": box_size})
			remaining -= box_size
	
	queue.shuffle()
	print("Generated ", queue.size(), " boxes")

func get_first_free_slot() -> int:
	for i in range(slots.size()):
		if slots[i] == null:
			return i
	return -1

func place_box_from_queue(queue_index: int):
	if queue_index < 0 or queue_index >= min(5, queue.size()):
		return
	var slot = get_first_free_slot()
	if slot == -1:
		print("No free slots!")
		return
	
	var box_data = queue[queue_index]
	queue.remove_at(queue_index)
	
	var box = preload("res://box.tscn").instantiate()
	add_child(box)
	var box_pos = Vector2i(SLOT_X_POSITIONS[slot], 35)
	box.init(box_data.color, box_data.count, slot, box_pos, self)
	
	# Capture for lambda
	var s = slot
	slots[s] = box
	active_boxes.append(box)
	
	box.box_cleared.connect(func():
		slots[s] = null
		active_boxes.erase(box)
		$GridDisplay.queue_redraw()
	)
	box.start()
	$GridDisplay.queue_redraw()

func sort_pixels_for_slot(pixels: Array, slot: int) -> Array:
	var sorted = pixels.duplicate()
	var max_x = GRID_WIDTH - 1
	var max_y = GRID_HEIGHT - 1
	
	match slot:
		0: sorted.sort_custom(func(a, b): 
			if a.x != b.x: return a.x < b.x
			return a.y > b.y)
		1: sorted.sort_custom(func(a, b): 
			return (a.x + (max_y - a.y)) < (b.x + (max_y - b.y)))
		2: sorted.sort_custom(func(a, b): 
			if a.y != b.y: return a.y > b.y
			return a.x < b.x)
		3: sorted.sort_custom(func(a, b): 
			return ((max_x - a.x) + (max_y - a.y)) < ((max_x - b.x) + (max_y - b.y)))
		4: sorted.sort_custom(func(a, b): 
			if a.x != b.x: return a.x > b.x
			return a.y > b.y)
	
	return sorted

func notify_idle_boxes():
	for box in active_boxes:
		if box.is_idle and color_index.has(box.color_id) and color_index[box.color_id].size() > 0:
			box.on_pixels_available()

func check_game_win():
	# Win check
	var game_win = 1;
	for cell in grid:
		if cell.state == CellState.PRESENT:
			game_win = 0
			break
	if (game_win == 1):
		# loop completed without break = all removed
		show_end_screen(true)

func check_game_loose():
	# If any agents are still out, not lost yet
	var agents_out = 0
	for box in active_boxes:
		agents_out += box.agents_dispatched - box.agents_home
	if agents_out > 0:
		return
	
	# No agents moving, check if anything can still be done
	if queue.size() > 0 and get_first_free_slot() != -1:
		return
	for box in active_boxes:
		if color_index.get(box.color_id, []).size() > 0:
			return
	
	show_end_screen(false)

func show_end_screen(win: bool):
	get_node("EndScreen").show_result(win)

func _on_restart(delta: int):
	# Clear all active boxes
	for box in active_boxes:
		box.queue_free()
	active_boxes.clear()
	slots = [null, null, null, null, null]
	
	# Clear all agents
	for child in get_children():
		if child.has_method("move_to_next"):
			child.queue_free()
	
	# Reinitialize
	grid.clear()
	color_index.clear()
	initialize_grid(delta)
	update_available_cells()
	generate_boxes()
	
	$EndScreen.hide()
	$GridDisplay.queue_redraw()
