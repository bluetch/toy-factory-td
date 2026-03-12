# Assets Guide

## Kenney Tower Defense Kit (Recommended)

Download the **free** Tower Defense Kit from:
https://kenney.nl/assets/tower-defense-kit

### Suggested file naming after extraction

#### Towers — `assets/sprites/towers/`
```
tower_arrow_base.png       — Arrow tower base (square building)
tower_arrow_head.png       — Arrow tower rotating gun
tower_cannon_base.png      — Cannon tower base
tower_cannon_head.png      — Cannon tower rotating barrel
tower_ice_base.png         — Ice tower base
tower_ice_head.png         — Ice tower rotating emitter
```

#### Enemies — `assets/sprites/enemies/`
```
enemy_basic.png            — Grunt enemy
enemy_fast.png             — Scout enemy
enemy_tank.png             — Tank enemy
enemy_boss.png             — Boss enemy
```

#### Projectiles — `assets/sprites/projectiles/`
```
proj_arrow.png             — Arrow
proj_cannonball.png        — Cannon ball
proj_ice_shard.png         — Ice shard
```

#### UI — `assets/sprites/ui/`
```
icon.svg                   — App icon (replace default Godot icon)
btn_normal.png             — Button background
btn_hover.png              — Button hover state
panel_bg.png               — Panel background
```

## How to Swap in Sprites

For each tower scene (e.g., `scenes/towers/ArrowTower.tscn`):

1. Select the `Body` (ColorRect) node in the Godot editor
2. Change node type to `Sprite2D`
3. Set `Texture` to the appropriate sprite file
4. Adjust `offset` so the sprite is centered on the tile

The scripts do not reference node types directly — they only use the node
name (`Body`, `Gun`) for optional modulation, so swapping types is safe.

## Audio — `assets/audio/`

Recommended free sources:
- https://freesound.org (CC0 licensed sounds)
- https://opengameart.org

Suggested files:
```
music_menu.ogg             — Title screen background music
music_gameplay.ogg         — In-game background music
sfx_arrow_shoot.wav        — Arrow tower fire
sfx_cannon_shoot.wav       — Cannon fire
sfx_ice_shoot.wav          — Ice shard launch
sfx_enemy_die.wav          — Enemy death
sfx_tower_place.wav        — Tower placement
sfx_upgrade.wav            — Tower upgrade
sfx_game_over.wav          — Game over sting
sfx_victory.wav            — Victory fanfare
```
