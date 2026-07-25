extends Node

# Grid
const GRID_WIDTH = 24
const GRID_HEIGHT = 32
const IMAGE_WIDTH  = GRID_WIDTH - 2 # playable image area
const IMAGE_HEIGHT = IMAGE_WIDTH # playable image area
const CELL_SIZE = 20

# Grid border lane width
const BORDER = 1

# Box generation
const BOX_MIN_AGENTS = 5
const BOX_MAX_AGENTS = GRID_WIDTH * 2

# Slot system
const SLOT_COUNT = 5
const SLOT_Y = GRID_HEIGHT - 1
const SLOT_X_POSITIONS = [2, 6, 11, 16, 20]

# Queue system
const QUEUE_COUNT = 5
const QUEUE_VISIBLE = 2.5

# Display
const ITEM_W = 86
const ITEM_H = 40
const ITEM_GAP = 5
const MARGIN = 10
const QUEUE_START_Y_OFFSET = 55

# Agent
const AGENT_SPEED_SLOW   = 0.4
const AGENT_SPEED_NORMAL = 0.2
const AGENT_SPEED_FAST   = 0.05

const SPAWN_INTERVAL_SLOW   = 0.7
const SPAWN_INTERVAL_NORMAL = 0.5
const SPAWN_INTERVAL_FAST   = 0.1

# Difficulty
const MIN_DIFFICULTY = 1
const MAX_DIFFICULTY = 16
const DEFAULT_DIFFICULTY = 4

# Colors
const MAX_COLORS = 16
