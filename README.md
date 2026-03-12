# Tower Defense

A grid-based tower defense game built with **Godot 4.6**.

## Features

- **3 Levels** with escalating difficulty, unlock-on-completion
- **3 Tower types** — Arrow, Cannon, Ice — each with 2 upgrade tiers
- **4 Enemy types** — Grunt, Scout, Tank, Boss
- **Wave system** with manual or auto wave-start
- **Tower upgrade & sell** system
- **Game speed toggle** (1× / 2×)
- **Local high-score** persistence per level
- **Clean architecture** — EventBus, autoloads, Resource data files

---

## Getting Started

### Requirements
- [Godot 4.6](https://godotengine.org/download/) (standard, not Mono/C#)

### Running the game
1. Clone this repository
2. Open Godot 4.6 → "Import" → select `project.godot`
3. Press **F5** or click the Play button

---

## Visual Assets (Optional — Kenney Pack)

The game ships with **placeholder colored shapes**. To use the free Kenney Tower Defense Pack:

1. Download from https://kenney.nl/assets/tower-defense-kit (free)
2. Extract sprites into:
   - `assets/sprites/towers/`   — tower base/head sprites
   - `assets/sprites/enemies/`  — enemy sprites
   - `assets/sprites/projectiles/` — projectile sprites
   - `assets/sprites/ui/`       — UI icons
3. Replace `ColorRect` nodes in each scene with `Sprite2D` nodes pointing to the downloaded textures
4. See `assets/ASSETS_README.md` for naming conventions

---

## Project Structure

```
project.godot            — Godot project configuration
scripts/
  autoloads/             — Global singletons (EventBus, GameManager, SaveManager, SceneManager, AudioManager)
  resources/             — Resource class definitions (TowerData, EnemyData, WaveData, LevelData)
  towers/                — Tower behavior scripts (BaseTower + 3 types)
  enemies/               — Enemy behavior scripts (BaseEnemy + 3 types)
  projectiles/           — Projectile scripts (Arrow, Cannon, Ice)
  ui/                    — UI controller scripts
  grid_manager.gd        — Grid state + rendering
  wave_manager.gd        — Enemy wave spawning
  game_world.gd          — Main gameplay orchestrator
scenes/
  MainMenu.tscn          — Title screen
  LevelSelect.tscn       — Level selection with unlock state
  GameWorld.tscn         — Active gameplay scene
  levels/                — Level-specific scenes (Level1-3.tscn)
  towers/                — Tower scene prefabs
  enemies/               — Enemy scene prefabs
  projectiles/           — Projectile scene prefabs
  ui/                    — UI panel scenes
data/
  towers/                — TowerData .tres files (stats, upgrade costs)
  enemies/               — EnemyData .tres files
  levels/                — LevelData .tres files (waypoints, wave configs)
assets/                  — Sprites, fonts, audio (Kenney or placeholder)
```

---

## Architecture Overview

### Autoloads (Singletons)
| Autoload | Responsibility |
|---|---|
| `EventBus` | Global signal bus — all cross-system events |
| `GameManager` | Runtime state: lives, gold, score, game speed, game state |
| `SaveManager` | Persist/load progress (JSON → `user://save_data.json`) |
| `SceneManager` | Animated scene transitions (fade in/out) |
| `AudioManager` | Music & SFX volume control |

### Data Flow
```
LevelData.tres ──► GameWorld ──► GridManager (grid layout)
                            └──► WaveManager (spawns enemies)
TowerData.tres ──► TowerPanel ──► GameWorld ──► BaseTower instances
EnemyData.tres ──► WaveManager ──► BaseEnemy instances
```

### Signal Bus Pattern
All gameplay events flow through `EventBus` to avoid tight coupling:
```
BaseEnemy._die() ──► EventBus.enemy_died ──► HUD updates score/gold
                                         └──► WaveManager tracks alive count
```

---

## Adding a New Tower Type

1. Create `scripts/towers/my_tower.gd` extending `BaseTower`
2. Override `_on_attack(target)` to spawn your projectile
3. Create `scenes/towers/MyTower.tscn` with the standard node structure
4. Create `data/towers/my_tower.tres` with `TowerData` resource
5. Add the `.tres` path to `TowerPanel.TOWER_RESOURCES` array

## Adding a New Level

1. Create `data/levels/level_N.tres` with `LevelData` resource (waypoints + waves)
2. Update `LevelSelect.tscn` to show the new card
3. Update `SaveManager` max level constant if needed

---

## Development Roadmap

- [ ] Replace placeholder graphics with Kenney assets
- [ ] Add particle effects (enemy death, tower shoot, explosions)
- [ ] Add sound effects and background music
- [ ] Add more enemy types (flying, healing)
- [ ] Add more tower types (laser, freeze + kill combo)
- [ ] Add difficulty settings (Easy/Normal/Hard)
- [ ] Add in-game map editor

---

## License

Game code: MIT License
Kenney assets: CC0 1.0 Universal (public domain)
