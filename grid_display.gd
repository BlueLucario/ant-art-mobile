extends Node2D

const CELL_SIZE = 20
const ITEM_W = 86
const ITEM_H = 40
const ITEM_GAP = 5
const MARGIN = 10

var grid_manager
var font
var dragging_queue_index = -1
var drag_position = Vector2.ZERO
var highlighted_cells = {}  # Vector2i -> Color tint
var highlight_color_id = -1
var pulse_time = 0.0
var highlight_mode = ""  # "available" or "all"

# Queue animation state
const QUEUE_VISIBLE = 2.5  # boxes visible per queue
const QUEUE_START_Y_OFFSET = ITEM_H + 15  # below slots
var queue_offsets = [0.0, 0.0, 0.0, 0.0, 0.0]  # current slide offset per queue
var queue_targets = [0.0, 0.0, 0.0, 0.0, 0.0]   # target offset per queue

func _ready():
	grid_manager = get_parent()
	font = ThemeDB.fallback_font

func _process(delta):
	if highlighted_cells.size() > 0:
		pulse_time += delta
		queue_redraw()
	
	# Keep redrawing during slide animations
	for i in range(5):
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
	if local.y < grid_manager.GRID_HEIGHT * CELL_SIZE:
		if local.y < (grid_manager.GRID_HEIGHT * CELL_SIZE) / 2:
			grid_manager.get_node("PausePopup").popup()
			return

func _handle_press(event):
	var local = to_local(event.position)
	var slots_y = grid_manager.GRID_HEIGHT * CELL_SIZE + 5
	var queue_y_base = slots_y + QUEUE_START_Y_OFFSET
	var active = get_active_queue_indices()
	
	# Check queue tap
	if local.y >= queue_y_base and local.y <= queue_y_base + ITEM_H:
		for display_i in range(active.size()):
			var q_index = active[display_i]
			var x = get_queue_x(display_i, active.size())
			if local.x >= x and local.x <= x + ITEM_W:
				if dragging_queue_index == q_index:
					# Second tap on same queue — place it
					grid_manager.place_box_from_queue(q_index)
					dragging_queue_index = -1
					clear_highlight()
				else:
					# First tap — highlight
					dragging_queue_index = q_index
					drag_position = to_local(event.position)
					var color_id = grid_manager.queues[q_index][0].color
					highlight_color(color_id, "available")
				return
	
	# Check placed box tap
	if local.y >= slots_y and local.y <= slots_y + ITEM_H:
		for i in range(5):
			var x = get_item_x(i)
			if local.x >= x and local.x <= x + ITEM_W:
				var box = grid_manager.slots[i]
				if box != null:
					highlight_color(box.color_id, "all")
				return

func _handle_release(event):
	if dragging_queue_index < 0:
		clear_highlight()
		return
	
	var local = to_local(event.position)
	var slots_y = grid_manager.GRID_HEIGHT * CELL_SIZE + 5
	
	# Check if dropped on a slot
	if local.y >= slots_y and local.y <= slots_y + ITEM_H:
		for i in range(5):
			var x = get_item_x(i)
			if local.x >= x and local.x <= x + ITEM_W:
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
	queue_offsets[queue_index] = -(ITEM_H + ITEM_GAP)
	var tween = create_tween()
	tween.tween_method(
		func(val): queue_offsets[queue_index] = val,
		-(ITEM_H + ITEM_GAP),
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
	var color = grid_manager.COLORS[item.color]
	color.a = 0.7
	var local = to_local(drag_position)
	draw_rect(Rect2(local.x - ITEM_W/2, local.y - ITEM_H/2, ITEM_W, ITEM_H), color)

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
	for i in range(5):
		if grid_manager.queues[i].size() > 0:
			indices.append(i)
	return indices

func get_item_x(col: int) -> float:
	return MARGIN + col * (ITEM_W + ITEM_GAP)

func get_queue_x(display_index: int, total_queues: int) -> float:
	# Center the active queues
	var total_width = total_queues * (ITEM_W + ITEM_GAP) - ITEM_GAP
	var start_x = (480 - total_width) / 2.0
	return start_x + display_index * (ITEM_W + ITEM_GAP)

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
	var slots_y = grid_manager.GRID_HEIGHT * CELL_SIZE + 5
	var queue_y_base = slots_y + QUEUE_START_Y_OFFSET
	var active = get_active_queue_indices()
	
	for display_i in range(active.size()):
		var q_index = active[display_i]
		var q = grid_manager.queues[q_index]
		var x = get_queue_x(display_i, active.size())
		var offset = queue_offsets[q_index]
		
		for box_i in range(min(q.size(), 4)):  # draw up to 4, clip to 2.5
			var item = q[box_i]
			var y = queue_y_base + box_i * (ITEM_H + ITEM_GAP) - offset
			
			# Clip — only draw if within visible area
			var max_y = queue_y_base + QUEUE_VISIBLE * (ITEM_H + ITEM_GAP)
			if y > max_y:
				break
			
			var rect = Rect2(x, y, ITEM_W, ITEM_H)
			var color = grid_manager.COLORS[item.color]
	
			# Half visible box effect — fade out beyond 2 boxes
			var fade_start = queue_y_base + 2 * (ITEM_H + ITEM_GAP)
			if y > fade_start:
				var fade = 1.0 - (y - fade_start) / (ITEM_H + ITEM_GAP)
				color.a = clamp(fade, 0.0, 1.0)
				# Only show color, no count text for half-visible box
				draw_rect(rect, color)
				continue
			
			draw_rect(rect, color)
			
			# Count label
			if box_i <= 1:
				draw_string(
					font,
					Vector2(x + 4, y + ITEM_H - 6),
					str(item.count),
					HORIZONTAL_ALIGNMENT_LEFT,
					-1, 14, Color.BLACK
				)
			
			# Highlight top box border if color matches highlighted
			if box_i == 0:# and item.color == grid_manager.get_node("GridDisplay").highlight_color_id:
				draw_rect(rect, Color.WHITE, false, 1.0)
			else:
				draw_rect(rect, Color.BLACK, false, 1.0)

func highlight_color(color_id: int, mode: String):
	highlighted_cells.clear()
	highlight_color_id = color_id
	highlight_mode = mode
	
	if mode == "available":
		var available = grid_manager.color_index.get(color_id, [])
		for pos in available:
			highlighted_cells[pos] = true
	elif mode == "all":
		for y in range(grid_manager.GRID_HEIGHT):
			for x in range(grid_manager.GRID_WIDTH):
				var cell = grid_manager.grid[y * grid_manager.GRID_WIDTH + x]
				if cell.state == grid_manager.CellState.PRESENT and cell.color == color_id:
					highlighted_cells[Vector2i(x, y)] = true
	
	queue_redraw()

func clear_highlight():
	highlighted_cells.clear()
	highlight_color_id = -1
	queue_redraw()
