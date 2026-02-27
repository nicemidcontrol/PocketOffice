extends Node

# ─────────────────────────────────────────
#  ENUMS
# ─────────────────────────────────────────
enum RoomType {
	EMPTY,
	DESK,
	MEETING_ROOM,
	BREAK_ROOM,
	SERVER_ROOM,
	TRAINING_ROOM,
	HR_OFFICE,
	EXECUTIVE_SUITE
}

# ─────────────────────────────────────────
#  CONSTANTS
# ─────────────────────────────────────────
const FLOOR_WIDTH  := 10
const FLOOR_HEIGHT := 5
const BASE_RENT_PER_FLOOR := 1000

# Room buff table: { productivity, morale, skill }
const ROOM_BUFFS := {
	RoomType.EMPTY:          { "productivity": 0,  "morale": 0,  "skill": 0  },
	RoomType.DESK:           { "productivity": 5,  "morale": 0,  "skill": 0  },
	RoomType.MEETING_ROOM:   { "productivity": 8,  "morale": 3,  "skill": 0  },
	RoomType.BREAK_ROOM:     { "productivity": 0,  "morale": 15, "skill": 0  },
	RoomType.SERVER_ROOM:    { "productivity": 12, "morale": 0,  "skill": 0  },
	RoomType.TRAINING_ROOM:  { "productivity": 0,  "morale": 0,  "skill": 10 },
	RoomType.HR_OFFICE:      { "productivity": 0,  "morale": 8,  "skill": 0  },
	RoomType.EXECUTIVE_SUITE:{ "productivity": 5,  "morale": 5,  "skill": 0  },
}

# Room build costs
const ROOM_COSTS := {
	RoomType.DESK:            500,
	RoomType.MEETING_ROOM:    2000,
	RoomType.BREAK_ROOM:      1500,
	RoomType.SERVER_ROOM:     5000,
	RoomType.TRAINING_ROOM:   3000,
	RoomType.HR_OFFICE:       2500,
	RoomType.EXECUTIVE_SUITE: 10000,
}

# ─────────────────────────────────────────
#  STATE
#  _floors: { floor_index -> Array[Array[int]]  (RoomType grid) }
# ─────────────────────────────────────────
var _floors: Dictionary = {}
var unlocked_floors: int = 0

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
signal floor_unlocked(floor_index: int)
signal room_placed(floor: int, x: int, y: int, room_type: int)

# ─────────────────────────────────────────
#  INIT
# ─────────────────────────────────────────
func initialize() -> void:
	unlock_floor(0)

func unlock_floor(floor_index: int) -> void:
	if _floors.has(floor_index):
		return

	# Create empty grid
	var grid: Array[Array] = []
	for y in range(FLOOR_HEIGHT):
		var row: Array[int] = []
		for x in range(FLOOR_WIDTH):
			row.append(RoomType.EMPTY)
		grid.append(row)
	_floors[floor_index] = grid

	# Place starter desks
	_place_raw(floor_index, 0, 0, RoomType.DESK)
	_place_raw(floor_index, 1, 0, RoomType.DESK)
	_place_raw(floor_index, 2, 0, RoomType.DESK)

	unlocked_floors = maxi(unlocked_floors, floor_index + 1)
	floor_unlocked.emit(floor_index)
	print("[OfficeManager] Floor %d unlocked." % floor_index)

# ─────────────────────────────────────────
#  PLACE ROOMS
# ─────────────────────────────────────────
func place_room(floor_idx: int, x: int, y: int, room_type: RoomType, gm: Node) -> bool:
	var cost: int = ROOM_COSTS.get(room_type, 0)
	if not gm.economy.spend(cost, "Build " + RoomType.keys()[room_type]):
		return false
	return _place_raw(floor_idx, x, y, room_type)

func _place_raw(floor_idx: int, x: int, y: int, room_type: RoomType) -> bool:
	if not _floors.has(floor_idx):
		return false
	if x < 0 or x >= FLOOR_WIDTH or y < 0 or y >= FLOOR_HEIGHT:
		return false
	_floors[floor_idx][y][x] = room_type
	room_placed.emit(floor_idx, x, y, room_type)
	return true

func get_tile(floor_idx: int, x: int, y: int) -> RoomType:
	if not _floors.has(floor_idx):
		return RoomType.EMPTY
	return _floors[floor_idx][y][x]

# ─────────────────────────────────────────
#  FINANCIALS
# ─────────────────────────────────────────
func get_monthly_rent() -> int:
	return unlocked_floors * BASE_RENT_PER_FLOOR

# ─────────────────────────────────────────
#  BUFF TOTALS  (used by GameManager for scoring)
# ─────────────────────────────────────────
func get_total_buff(buff_key: String) -> int:
	var total := 0
	for grid in _floors.values():
		for row in grid:
			for tile in row:
				total += ROOM_BUFFS.get(tile, {}).get(buff_key, 0)
	return total

func get_productivity_buff() -> int: return get_total_buff("productivity")
func get_morale_buff()       -> int: return get_total_buff("morale")
func get_skill_buff()        -> int: return get_total_buff("skill")

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func to_save_dict() -> Dictionary:
	var out := {}
	for floor_idx in _floors:
		out[str(floor_idx)] = _floors[floor_idx]
	return { "floors": out, "unlocked_floors": unlocked_floors }

func from_save_dict(d: Dictionary) -> void:
	_floors.clear()
	unlocked_floors = d.get("unlocked_floors", 1)
	var floors_raw: Dictionary = d.get("floors", {})
	for key in floors_raw:
		_floors[int(key)] = floors_raw[key]
