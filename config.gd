extends Node

# Screen
const SCREEN_WIDTH = 480
const SCREEN_HEIGHT = 854

# Grid
const GRID_WIDTH = 24
const GRID_HEIGHT = 30
const CELL_SIZE = 20
const IMAGE_WIDTH  = GRID_WIDTH - 2 # playable image area
const IMAGE_HEIGHT = IMAGE_WIDTH # playable image area

# Grid border lane width
const BORDER = 1

# Box generation
const BOX_MIN_AGENTS = 5
const BOX_MAX_AGENTS = GRID_WIDTH * 2

# Slot system
const SLOT_COUNT = 5
const SLOT_Y = GRID_HEIGHT - 1
var SLOT_X_POSITIONS = [] # Generated in _ready function
const SLOT_X_MARGIN = (SCREEN_WIDTH - (SLOT_COUNT*ITEM_W))/2


# Queue system
const QUEUE_COUNT = 5
const QUEUE_X_MARGIN = (SCREEN_WIDTH - (QUEUE_COUNT*(ITEM_W+ITEM_GAP_X)))/2
const QUEUE_START_Y_OFFSET = 55

# Display Boxes
const ITEM_W = 86
const ITEM_H = 40
const ITEM_GAP_X = 5 
const ITEM_GAP_Y = - 36
const MARGIN = 10

# Agent
const AGENT_SPEED_SLOW   = 0.2
const AGENT_SPEED_NORMAL = 0.1
const AGENT_SPEED_FAST   = 0.05

const SPAWN_INTERVAL_SLOW   = AGENT_SPEED_SLOW   * 2
const SPAWN_INTERVAL_NORMAL = AGENT_SPEED_NORMAL * 2
const SPAWN_INTERVAL_FAST   = AGENT_SPEED_FAST   * 2

# Difficulty
const MIN_DIFFICULTY = 1
const MAX_DIFFICULTY = 16
const DEFAULT_DIFFICULTY = 4

# Colors
const MAX_COLORS = 16

# Generate Data
func _ready():
	var step_size: float = float(GRID_WIDTH) / float(SLOT_COUNT)
	for i in range(1, SLOT_COUNT + 1):
		SLOT_X_POSITIONS.append(int(floor(i * step_size))-3)
