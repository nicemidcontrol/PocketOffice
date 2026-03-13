# Pocket Office — Claude Code Rules
## Repo
- Godot 4.5 GDScript, mobile 390x844px portrait
- Godot project root: `godot/` subdirectory
- Never push to main — always create a new branch
## Code Rules (strictly enforced)
- No `class_name` except `Employee.gd` and `SaveSystem.gd`
- All vars explicitly typed: `var x: int = 0`
- No `:=` with untyped values
- No unicode characters or semicolons in `.tscn` files (pure ASCII only)
- `@onready` paths must EXACTLY match the scene tree — read `.tscn` first
- Use `.get("key", default)` — never `dict["key"]` direct access
## Autoload Order
SaveSystem -> ClockManager -> GameManager -> EventManager ->
FacilityManager -> DonorManager -> CompetitorManager
## Modal Dialog Standard
All modals must follow this pattern:
- Root: CanvasLayer layer=8
- Dimmer: ColorRect fullscreen Color(0,0,0,0.55) mouse_filter=STOP
- Card: Panel centered +-170 horizontal, +-280 vertical mouse_filter=STOP
- StyleBoxFlat: bg Color(0.047,0.047,0.11,0.97)
  border 2px Color(0.18,0.42,0.78,1.0) corner_radius=10
- process_mode = PROCESS_MODE_ALWAYS in _ready()
- Click outside (Dimmer gui_input) -> queue_free()
- CLOSE button: text="CLOSE", calls queue_free()
- ArtworkPanel: 90px fixed height, placed above ContentArea
## Key Files
- godot/scripts/ui/Main.gd — main scene controller
- godot/Employee.gd — only file with class_name besides SaveSystem.gd
- godot/scenes/ui/BaseModal.tscn — reusable modal template
- godot/GAME_BIBLE_v1.3.md — design reference (read only if needed)
## Scope Rule
Each task touches minimum files possible.
If task says "BuildScreen only" — do NOT touch any other file.
