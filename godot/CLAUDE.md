Please run these commands first:
git checkout main
git pull origin main
ls godot/*.md

Then proceed with the merge task.
Also, CLAUDE.md is missing from the repo. After the Bible merge, 
please recreate godot/CLAUDE.md with this content:

# CLAUDE.md — Read this before every task

## Codebase Rules
- No class_name except in Employee.gd and SaveSystem.gd
- All variables explicitly typed: var x: int = 0
- No := with untyped values
- No semicolons in .tscn files
- No unicode characters in .tscn files
- All @onready paths must exactly match .tscn scene tree
- Use proj.get("key", default) — never proj["key"]

## Autoload Order
SaveSystem → ClockManager → GameManager → EventManager → FacilityManager → DonorManager → CompetitorManager

## Modal Standard (BaseModal)
- CanvasLayer layer=8
- Dark dimmer background
- Centered Card panel (navy bg, blue border)
- Arrow nav [<][>] for multi-item screens
- Centered CLOSE button at bottom
- Title at top via set_title()
- Click outside to close

## Key File Paths
- Game Bible: godot/GAME_BIBLE_v1.4.md
- Economy Bible: godot/ECONOMY_BIBLE.md
- Humor Naming: godot/Humor naming bible.md
- BaseModal: godot/scenes/ui/BaseModal.tscn + godot/scripts/ui/BaseModal.gd

## Git Rules
- Never push to main directly
- Always create new branch
- Commit message format: "type: description"
