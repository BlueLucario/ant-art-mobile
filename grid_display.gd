extends Node2D

const CELL_SIZE = 20
const ITEM_W = 86
const ITEM_H = 40
const ITEM_GAP = 5
const MARGIN = 10

var grid_manager
var font

func _ready():
	grid_manager = get_parent()
	font = ThemeDB.fallback_font

func _draw():
	draw_grid()
	draw_slots()
	draw_queue()

func draw_grid():
	for y in range(grid_manager.GRID_HEIGHT):
		for x in range(grid_manager.GRID_WIDTH):
			var cell = grid_manager.grid[y * grid_manager.GRID_WIDTH + x]
			var rect = Rect2(
				x * CELL_SIZE,
				y * CELL_SIZE,
				CELL_SIZE - 1,
				CELL_SIZE - 1
			)
			var color = grid_manager.get_cell_color(cell.color)
			if cell.state == grid_manager.CellState.REMOVED:
				color = Color(0.15, 0.15, 0.15)
			draw_rect(rect, color)

func get_item_x(col: int) -> float:
	return MARGIN + col * (ITEM_W + ITEM_GAP)

func draw_slots():
	var y = grid_manager.GRID_HEIGHT * CELL_SIZE + 5
	for i in range(5):
		var x = get_item_x(i)
		var rect = Rect2(x, y, ITEM_W, ITEM_H)
		var slot_box = grid_manager.slots[i]
		if slot_box == null:
			draw_rect(rect, Color(0.25, 0.25, 0.25))
			draw_rect(rect, Color(0.5, 0.5, 0.5), false)
		else:
			draw_rect(rect, grid_manager.COLORS[slot_box.color_id])
			draw_rect(rect, Color(0.5, 0.5, 0.5), false)
			var waiting = slot_box.agents_total - slot_box.agents_dispatched
			var out = slot_box.agents_dispatched - slot_box.agents_home
			var home = slot_box.agents_home
			draw_string(font, Vector2(x + 6, y + ITEM_H - 6),
		  		str(waiting), HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, Color.BLACK)
			draw_string(font, Vector2(x + (ITEM_W/2)-6, y + ITEM_H - 6),
		  		str(out), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.BLACK)
			draw_string(font, Vector2(x + ITEM_W - 20, y + ITEM_H - 6),
		  		str(home), HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, Color.BLACK)

func draw_queue():
	var y_base = grid_manager.GRID_HEIGHT * CELL_SIZE + ITEM_H + 10
	var show = min(10, grid_manager.queue.size())
	for i in range(show):
		var row = i / 5
		var col = i % 5
		var x = get_item_x(col)
		var y = y_base + row * (ITEM_H + ITEM_GAP)
		var rect = Rect2(x, y, ITEM_W, ITEM_H)
		var item = grid_manager.queue[i]
		var color = grid_manager.COLORS[item.color]
		if i >= 5:
			color = color.darkened(0.4)
		draw_rect(rect, color)
		draw_string(font, Vector2(x + 4, y + ITEM_H - 6),
			str(item.count), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)

func _input(event):
	if not (event is InputEventMouseButton):
		return
	if not (event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	
	var local = to_local(event.position)
	
	# Grid click
	if local.y < grid_manager.GRID_HEIGHT * CELL_SIZE:
		var x = int(local.x / CELL_SIZE)
		var y = int(local.y / CELL_SIZE)
		if x >= 0 and x < grid_manager.GRID_WIDTH:
			grid_manager.remove_pixel(x, y)
		return
	
	# Queue tap — top 5 only
	var queue_y_start = grid_manager.GRID_HEIGHT * CELL_SIZE + ITEM_H + 10
	var queue_y_end = queue_y_start + ITEM_H
	if local.y >= queue_y_start and local.y <= queue_y_end:
		for i in range(min(5, grid_manager.queue.size())):
			var x = get_item_x(i)
			if local.x >= x and local.x <= x + ITEM_W:
				grid_manager.place_box_from_queue(i)
				return
