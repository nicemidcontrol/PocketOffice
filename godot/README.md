# 🏢 Pocket Office — Godot 4 Edition

> Kairosoft-inspired corporate simulation · GDScript · Godot 4.2+ · iOS & Android  
> **Ported from Unity/C# scaffold — all game logic preserved, syntax updated to GDScript**

---

## ⚡ Quick Start (No Install Required!)

1. Download **Godot 4.x** (single `.exe`, no install needed) from https://godotengine.org
2. Open Godot → **Import** → select this folder's `project.godot`
3. Go to **Project > Project Settings > Autoload**
4. Add `scripts/core/GameManager.gd` with name `GameManager`
5. Hit **F5** to run

---

## 📁 Folder Structure

```
PocketOffice_Godot/
├── project.godot                    ← Godot project config (portrait, 390×844)
├── scripts/
│   ├── core/
│   │   └── GameManager.gd          ← Autoload singleton. Central game loop + time
│   ├── employees/
│   │   ├── Employee.gd             ← Resource class: stats, personality, leveling
│   │   └── EmployeeManager.gd      ← Hire/fire, salary, motivation ticks
│   ├── economy/
│   │   └── EconomyManager.gd       ← Cash, revenue, monthly costs, loans
│   ├── projects/
│   │   └── ProjectManager.gd       ← Client projects, deadlines, assign/complete
│   ├── events/
│   │   └── EventManager.gd         ← 8 random corporate events with player choices
│   ├── office/
│   │   └── OfficeManager.gd        ← Grid-based floors, room types, buffs, rent
│   └── utils/
│       └── SaveSystem.gd           ← JSON save/load via FileAccess (user://)
├── scenes/                         ← (To build) .tscn scene files
│   ├── Main.tscn
│   ├── GameScene.tscn
│   └── UI/
├── assets/
│   ├── sprites/                    ← 16×16 / 32×32 pixel art (Aseprite → PNG)
│   └── audio/                      ← BGM + SFX (.ogg recommended for Godot)
└── data/
    └── projects_data.json          ← Static game data (project templates, tiers)
```

---

## 🏗️ Architecture

```
GameManager  [Autoload Singleton]
    ├── EmployeeManager   (child Node)
    ├── EconomyManager    (child Node)
    ├── ProjectManager    (child Node)
    ├── EventManager      (child Node)
    └── OfficeManager     (child Node)
```

**Key Godot patterns used:**
- `extends Resource` on `Employee` → can be serialised, inspected, duplicated
- Signals replace C# static `Action<T>` events — fully decoupled
- `Autoload` replaces Unity `DontDestroyOnLoad` singleton
- `user://` path for save files → works on all platforms including mobile
- No MonoBehaviour lifecycle — uses `_ready()` and `_process(delta)`

---

## 🔗 Signal Bus

| Signal | Owner | Payload |
|---|---|---|
| `day_passed(day)` | GameManager | int |
| `month_passed(month)` | GameManager | int |
| `tier_upgraded(tier)` | GameManager | CompanyTier |
| `game_message(msg)` | GameManager | String |
| `cash_changed(cash)` | EconomyManager | int |
| `went_bankrupt` | EconomyManager | — |
| `project_completed(proj)` | ProjectManager | Dictionary |
| `project_failed(proj)` | ProjectManager | Dictionary |
| `event_triggered(event)` | EventManager | Dictionary |
| `employee_hired(emp)` | EmployeeManager | Employee |
| `floor_unlocked(idx)` | OfficeManager | int |

**How to connect from UI:**
```gdscript
# In any UI script
func _ready():
    GameManager.game_message.connect(_on_game_message)
    GameManager.economy.cash_changed.connect(_update_cash_label)
    GameManager.events.event_triggered.connect(_show_event_popup)

func _on_game_message(msg: String) -> void:
    $NotificationLabel.text = msg
```

---

## 💾 Save File Location

| Platform | Path |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\Pocket Office\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Pocket Office/` |
| Android | `/data/data/com.yourcompany.pocketoffice/files/` |
| iOS | App sandbox `Documents/` |

---

## 🗺️ C# → GDScript Key Differences

| C# (Unity) | GDScript (Godot) |
|---|---|
| `MonoBehaviour` | `extends Node` |
| `Start()` | `_ready()` |
| `Update()` | `_process(delta)` |
| `static event Action<T>` | `signal name(param: Type)` |
| `Mathf.Clamp()` | `clampf()` / `clampi()` |
| `Debug.Log()` | `print()` |
| `JsonUtility.ToJson()` | `JSON.stringify()` |
| `DontDestroyOnLoad` | Autoload |
| `GetComponent<T>()` | `get_node("NodeName")` or typed child ref |
| `Instantiate()` | `load("res://...").instantiate()` |

---

## 🏁 Next Steps (UI to Build in Godot)

```
scenes/
├── UI/
│   ├── HUD.tscn              ← Top bar: cash label, reputation, date
│   ├── BottomNav.tscn        ← 4 tabs: Office | Staff | Finance | Events
│   ├── EventPopup.tscn       ← Modal with title, description, choice buttons
│   ├── StaffPanel.tscn       ← ScrollContainer of employee cards
│   ├── ProjectPanel.tscn     ← Available + active project list
│   └── OfficeGrid.tscn       ← TileMap or GridContainer for floor layout
```

**Recommended Godot nodes for pixel art:**
- `TileMapLayer` → office floor grid rendering
- `AnimatedSprite2D` → employee idle animations  
- `CanvasLayer` → HUD overlay (always on top)
- `Control` → all UI panels

---

## ⚠️ Important Notes

- `Employee` extends `Resource` not `Node` — don't add it to scene tree directly
- Always connect signals in `_ready()`, not in `_init()`
- GDScript arrays are reference types — use `.duplicate()` when returning copies
- Use `.ogg` audio files (not `.mp3`) — better Godot compression support
- Pixel art: set **Import > Filter** to `Nearest` on all sprite textures to keep crisp pixels
