extends Node

const SAVE_PATH = "user://save.cfg"
const DEFAULT_DIFFICULTY = 4
const DEFAULT_MAX_GAMES_ENABLED = true
const DEFAULT_MAX_GAMES = 10
const DEFAULT_HARD_EXIT_ENABLED = false
const DEFAULT_LOCKOUT_MINUTES = 0
const DEFAULT_AGENT_SPEED = 1 # 0=slow, 1=normal, 2=fast

var config = ConfigFile.new()
# Runtime state (not saved)
var games_remaining = DEFAULT_MAX_GAMES

func _ready():
	load_data()
	reset_max_games()

func reset_session():
	config.set_value("session", "games_remaining", get_max_games())
	
func load_data():
	config.load(SAVE_PATH)

func save_data():
	config.save(SAVE_PATH)
	
func reset_max_games():
	games_remaining = get_max_games()

func get_games_remaining() -> int:
	return config.get_value("session", "games_remaining", get_max_games())

func decrement_games() -> bool:
	var remaining = get_games_remaining() - 1
	config.set_value("session", "games_remaining", remaining)
	# No save — session data resets on relaunch
	return remaining <= 0

# Difficulty unlock/lock
func is_unlocked(difficulty: int) -> bool:
	return config.get_value("unlocks", str(difficulty), false)
func unlock(difficulty: int):
	if difficulty < 1 or difficulty > 16:
		return
	config.set_value("unlocks", str(difficulty), true)
	save_data()
func any_unlocked() -> bool:
	for i in range(1, 17):
		if is_unlocked(i):
			return true
	return false

# Win/loss tracking
func get_wins(difficulty: int) -> int:
	return config.get_value("stats", str(difficulty) + "_wins", 0)
func get_losses(difficulty: int) -> int:
	return config.get_value("stats", str(difficulty) + "_losses", 0)
func record_win(difficulty: int):
	var wins = config.get_value("stats", str(difficulty) + "_wins", 0)
	config.set_value("stats", str(difficulty) + "_wins", wins + 1)
	unlock(difficulty)
	unlock(difficulty + 1)
	save_data()
func record_loss(difficulty: int):
	var losses = config.get_value("stats", str(difficulty) + "_losses", 0)
	config.set_value("stats", str(difficulty) + "_losses", losses + 1)
	unlock(difficulty)
	unlock(difficulty - 1)
	save_data()

# Options
func get_lives_enabled() -> bool:
	return config.get_value("options", "lives_enabled", DEFAULT_MAX_GAMES_ENABLED)
func set_lives_enabled(val: bool):
	config.set_value("options", "lives_enabled", val)
	save_data()

func get_max_games() -> int:
	return config.get_value("options", "max_games", DEFAULT_MAX_GAMES)
func set_max_games(val: int):
	config.set_value("options", "max_games", val)
	save_data()

func get_hard_exit() -> bool:
	return config.get_value("options", "hard_exit", DEFAULT_HARD_EXIT_ENABLED)
func set_hard_exit(val: bool):
	config.set_value("options", "hard_exit", val)
	save_data()

func get_agent_speed() -> int:
	return config.get_value("options", "agent_speed", DEFAULT_AGENT_SPEED)
func set_agent_speed(val: int):
	config.set_value("options", "agent_speed", val)
	save_data()

func get_lockout_minutes() -> int:
	return config.get_value("options", "lockout_minutes", DEFAULT_LOCKOUT_MINUTES)
func set_lockout_minutes(val: int):
	config.set_value("options", "lockout_minutes", val)
	save_data()

# Lock out system
func save_lockout_timestamp():
	config.set_value("session", "lockout_timestamp", Time.get_unix_time_from_system())
	save_data()
func clear_lockout_timestamp():
	config.erase_section_key("session", "lockout_timestamp")
	save_data()

func get_seconds_remaining() -> int:
	var timestamp = config.get_value("session", "lockout_timestamp", -1)
	if timestamp == -1:
		return 0
	var lockout_seconds = get_lockout_minutes() * 60
	var unlock_time = timestamp + lockout_seconds
	var remaining = int(unlock_time - Time.get_unix_time_from_system())
	return max(0, remaining)
	
func is_locked_out() -> bool:
	if get_lockout_minutes() == 0:
		return false
	return get_seconds_remaining() > 0

func clear_save_data():
	config.clear()
	save_data()
	reset_session()
