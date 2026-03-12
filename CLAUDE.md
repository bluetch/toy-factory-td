# CLAUDE.md — Project Notes for Claude Code

## Project
Tower Defense game in Godot 4.6. Long-term development project.

## Key Conventions

### GDScript Style
- Use `@export`, `@onready` (Godot 4 syntax)
- `class_name` on Resource subclasses and scene scripts
- Constants in `SCREAMING_SNAKE_CASE`
- Private variables prefix with `_underscore`
- Signal callbacks prefix with `_on_`
- No C# — pure GDScript

### Architecture Rules
- **All cross-system events** go through `EventBus` signals — never call methods on unrelated systems directly
- **GameManager** is the only source of truth for lives/gold/score/game_state
- **SaveManager** handles all file I/O — no other script should access `FileAccess` directly
- **SceneManager** handles all scene changes — no other script should call `get_tree().change_scene_to_*`
- Tower stats are always read from `TowerData` resources (`.tres` files) — no hardcoded values in scripts

### File Locations
- Scripts: `scripts/` (autoloads, resources, towers, enemies, projectiles, ui)
- Scenes: `scenes/` (matching subdirectory structure)
- Data: `data/` (`.tres` resource files for towers, enemies, levels)
- Assets: `assets/` (sprites, audio, fonts)

### Adding Content (summary)
- **New tower**: script in `scripts/towers/`, scene in `scenes/towers/`, data in `data/towers/`, add path to `TowerPanel.TOWER_RESOURCES`
- **New enemy**: script in `scripts/enemies/`, scene in `scenes/enemies/`, data in `data/enemies/`
- **New level**: data in `data/levels/level_N.tres`, add card to `LevelSelect.tscn`

## Godot Version
4.6 — Forward Plus renderer. Do NOT use deprecated Godot 3 APIs.
