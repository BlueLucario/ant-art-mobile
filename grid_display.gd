extends Node2D

var grid_manager
var font
var dragging_queue_index = -1
var drag_position = Vector2.ZERO
var highlighted_cells = {}  # Vector2i -> Color tint
var highlight_color_id = -1
var pulse_time = 0.0
var highlight_mode = ""  # "available" or "all"

# Queue animation state
const QUEUE_START_Y_OFFSET = Config.ITEM_H + 15  # below slots
var queue_offsets = []  # current slide offset per queue
var queue_targets = []  # target offset per queue
var queue_widths = []
var queue_x_margin = (Config.SCREEN_WIDTH - (Config.QUEUE_COUNT*(Config.ITEM_W+Config.ITEM_GAP_X)))/2

func ini_board():
	queue_offsets.fill(0.0) 
	queue_targets.fill(0.0) 
	queue_widths.fill(1.0) 

func _ready():
	queue_offsets.resize(Config.QUEUE_COUNT)
	queue_targets.resize(Config.QUEUE_COUNT)
	queue_widths.resize(Config.QUEUE_COUNT)
	queue_offsets.fill(0.0) 
	queue_targets.fill(0.0) 
	queue_widths.fill(1.0) 
	
	grid_manager = get_parent()
	font = ThemeDB.fallback_font

func _process(delta):
	if highlighted_cells.size() > 0:
		pulse_time += delta
		queue_redraw()
	
	# Keep redrawing during slide animations
	for i in range(Config.SLOT_COUNT):
		if abs(queue_offsets[i]) > 0.01:
			queue_redraw()
			break

func _draw():
	draw_grid()
	draw_slots()
	draw_queue()
	draw_drag_ghost()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_press(event)
			else:
				_handle_release(event)
	if event is InputEventMouseMotion and dragging_queue_index >= 0:
		drag_position = event.position
		queue_redraw()
	# Open Pause menu
	if not (event is InputEventMouseButton):
		return
	if not (event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local = to_local(event.position)
	# Grid click
	if local.y < Config.GRID_HEIGHT * Config.CELL_SIZE :
		if local.y < (Config.GRID_HEIGHT * Config.CELL_SIZE ) / 2:
			grid_manager.get_node("PausePopup").popup()
			return

func _handle_press(event):
	var local = to_local(event.position)
	var slots_y = Config.GRID_HEIGHT * Config.CELL_SIZE  + 5
	var queue_y_base = slots_y + QUEUE_START_Y_OFFSET
	var active = get_active_queue_indices()
	
	# Check queue tap
	if local.y >= queue_y_base:
		for q_index in range(Config.SLOT_COUNT):
			if (grid_manager.queues[q_index].size() == 0): continue
			var x = get_queue_x(q_index)
			const off = int(Config.ITEM_GAP_X/2)
			if local.x >= x-off and local.x <= x + Config.ITEM_W+off:
				if dragging_queue_index == q_index:
					# Second tap on same queue — place it
					grid_manager.place_box_from_queue(q_index)
					dragging_queue_index = -1
					clear_highlight()
				elif grid_manager.queues[q_index].size() > 0:
					# First tap — highlight
					dragging_queue_index = q_index
					drag_position = to_local(event.position)
					var color_id = grid_manager.queues[q_index][0].color
					highlight_color(color_id, "available")
				return
	
	# Check placed box tap
	if local.y >= slots_y and local.y <= slots_y + Config.ITEM_H:
		for i in range(Config.SLOT_COUNT):
			var x = get_item_x(i)
			const off = int(Config.ITEM_GAP_X/2)
			if local.x >= x - off and local.x <= x + Config.ITEM_W + off:
				var box = grid_manager.slots[i]
				if box != null:
					highlight_color(box.color_id, "all")
				return

func _handle_release(event):
	if dragging_queue_index < 0:
		clear_highlight()
		return
	
	var local = to_local(event.position)
	var slots_y = Config.GRID_HEIGHT * Config.CELL_SIZE  + 5
	
	# Check if dropped on a slot
	if local.y <= slots_y + Config.ITEM_H:
		for i in range(Config.SLOT_COUNT):
			var x = get_item_x(i)
			if local.x >= x and local.x <= x + Config.ITEM_W+Config.ITEM_GAP_X:
				if grid_manager.slots[i] == null:
					grid_manager.place_box_in_slot_from_queue(dragging_queue_index, i)
					dragging_queue_index = -1
					clear_highlight()
					return
	
	# Dropped outside — if it was just a tap (no real drag), place in first free slot
	dragging_queue_index = -1
	clear_highlight()

func animate_queue_slide(queue_index: int):
	# Start offset one box height down, animate to 0
	queue_offsets[queue_index] = 1.0#Config.ITEM_H #-(Config.ITEM_H + Config.ITEM_GAP_Y)
	var tween = create_tween()
	tween.tween_method(
		func(val): queue_offsets[queue_index] = val,
		1.0, #-(Config.ITEM_H + Config.ITEM_GAP_Y),
		0.0,
		0.25
	)
	tween.tween_callback(func(): queue_redraw())

func draw_drag_ghost():
	if dragging_queue_index < 0:
		return
	if dragging_queue_index >= grid_manager.queues.size():
		return
	var item = grid_manager.queues[dragging_queue_index][0]
	var color = grid_manager.COLORS[item.color][0]
	color.a = 0.7
	var local = to_local(drag_position)
	draw_rect(Rect2(local.x - Config.ITEM_W/2, local.y - Config.ITEM_H/2, Config.ITEM_W, Config.ITEM_H), color)
	draw_rect(Rect2(local.x - Config.ITEM_W/2, local.y - Config.ITEM_H/2, Config.ITEM_W, Config.ITEM_H), Color.WHITE, false)

func draw_grid():
	for y in range(Config.GRID_HEIGHT):
		for x in range(Config.GRID_WIDTH):
			var cell = grid_manager.grid[y * Config.GRID_WIDTH + x]
			var rect = Rect2(
				x * Config.CELL_SIZE ,
				y * Config.CELL_SIZE ,
				Config.CELL_SIZE  - 1,
				Config.CELL_SIZE  - 1
			)
			var color = grid_manager.get_cell_color(cell.color)
			if cell.state == grid_manager.CellState.REMOVED:
				color = Color(0.15, 0.15, 0.15)
			draw_rect(rect, color)
			
			# Highlight overlay
			var pos = Vector2i(x, y)
			if highlighted_cells.has(pos):
				var pulse = (sin(pulse_time * 4.0) + 1.0) / 2.0  # 0.0 to 1.0
				draw_rect(rect, Color(1, 1, 1, 0.2 + pulse * 0.3))  # white shimmer
				draw_rect(rect, Color(1, 1, 1, 0.8 + pulse * 0.2), false, 2.0)
			elif highlight_color_id != -1 and cell.state == grid_manager.CellState.PRESENT:
				draw_rect(rect, Color(0, 0, 0, 0.2))  # darken non-highlighted

func get_active_queue_count() -> int:
	var count = 0
	for q in grid_manager.queues:
		if q.size() > 0:
			count += 1
	return count

func get_active_queue_indices() -> Array:
	var indices = []
	for i in range(Config.QUEUE_COUNT):
		if grid_manager.queues[i].size() > 0 || queue_widths[i] > 0:
			indices.append(i)
	return indices

func get_item_x(col: int) -> float:
	return Config.MARGIN + col * (Config.ITEM_W + Config.ITEM_GAP_X)

func get_queue_x(display_index: int = -1) -> float:
	var total_width = 0
	var at_i_width = 0
	for q_index in range(Config.SLOT_COUNT):
		if (q_index == display_index): 
			at_i_width = total_width
		total_width += ((Config.ITEM_W+Config.ITEM_GAP_X) * queue_widths[q_index])
	
	var start_x = (Config.SCREEN_WIDTH - total_width) / 2.0
	return start_x + at_i_width

func draw_slots():
	var y = Config.GRID_HEIGHT * Config.CELL_SIZE  + 5
	for i in range(5):
		var x = get_item_x(i)
		var rect = Rect2(x, y, Config.ITEM_W, Config.ITEM_H)
		var slot_box = grid_manager.slots[i]
		if slot_box == null:
			draw_rect(rect, Color(0.2, 0.2, 0.2))
			draw_rect(rect, Color(0.5, 0.5, 0.5), false)
		else:
			var color_bg = grid_manager.COLORS[slot_box.color_id][0]
			var color_fg = grid_manager.COLORS[slot_box.color_id][1]
			draw_rect(rect, color_bg)
			draw_rect(rect, color_fg, false)
			var waiting = slot_box.agents_total - slot_box.agents_dispatched
			var out = slot_box.agents_dispatched - slot_box.agents_home
			var home = slot_box.agents_home
			draw_string(font, Vector2(x + 6, y + Config.ITEM_H - 20),
		  		str(waiting), HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, color_fg)
			draw_string(font, Vector2(x + (Config.ITEM_W/2)-6, y + Config.ITEM_H - 20),
		  		str(out), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, color_fg)
			draw_string(font, Vector2(x + Config.ITEM_W - 20, y + Config.ITEM_H - 20),
		  		str(home), HORIZONTAL_ALIGNMENT_RIGHT, -1, 14, color_fg)

func draw_queue():
	var slots_y = Config.GRID_HEIGHT * Config.CELL_SIZE  + 5
	var queue_y_base = slots_y + QUEUE_START_Y_OFFSET
	var active = get_active_queue_indices()
	for q_i in range(Config.SLOT_COUNT):
		if (grid_manager.queues[q_i].size() == 0 && queue_widths[q_i] > 0): 
			queue_widths[q_i] = max(queue_widths[q_i]-0.06, 0)
	
	for display_i in range(active.size()):
		var q_index = active[display_i]
		var q = grid_manager.queues[q_index]
		var draw_x = get_queue_x(q_index)
		var offset = queue_offsets[q_index]
		
		for i in range(q.size()):
			var box_i = q.size() - (i + 1)
			var item = q[box_i]
			var x = draw_x + pow(-1, display_i + i - 1)
			var y = queue_y_base + ((box_i+offset) * ((Config.ITEM_H * 3)/(2+(box_i+offset))) )
			
			var rect = Rect2(x, y, Config.ITEM_W, Config.ITEM_H)
			var color_bg = grid_manager.COLORS[item.color][0]
			var color_fg = grid_manager.COLORS[item.color][1]
			
			draw_rect(rect, color_bg)
			
			# Count label
			if box_i <= 3:
				draw_string(
					font,
					Vector2(x + 4, y + Config.ITEM_H - 20),
					str(item.count),
					HORIZONTAL_ALIGNMENT_LEFT,
					-1, 14, color_fg
				)
			
			# Highlight top box border if color matches highlighted
			if box_i == 0:# and item.color == grid_manager.get_node("GridDisplay").highlight_color_id:
				var c = 1-offset
				draw_rect(rect, Color(c, c, c), false, 1.0)
			elif box_i <= 10:
				draw_rect(rect, Color.BLACK, false, 1.0)
			else:
				draw_rect(rect, Color.BLACK, true, 1.0)

func highlight_color(color_id: int, mode: String):
	highlighted_cells.clear()
	highlight_color_id = color_id
	highlight_mode = mode
	
	if mode == "available":
		var available = grid_manager.color_index.get(color_id, [])
		for pos in available:
			highlighted_cells[pos] = true
	elif mode == "all":
		for y in range(Config.GRID_HEIGHT):
			for x in range(Config.GRID_WIDTH):
				var cell = grid_manager.grid[y * Config.GRID_WIDTH + x]
				if cell.state == grid_manager.CellState.PRESENT and cell.color == color_id:
					highlighted_cells[Vector2i(x, y)] = true
	
	queue_redraw()

func clear_highlight():
	highlighted_cells.clear()
	highlight_color_id = -1
	queue_redraw()
