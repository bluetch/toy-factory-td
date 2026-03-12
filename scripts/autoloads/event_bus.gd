## ============================================================
## EventBus — 全局信号总线 (Global Signal Bus)
## ============================================================
## Purpose: Decoupled communication hub for all game systems.
## Every cross-system event is emitted here so that emitters and
## listeners never need a direct reference to each other.
##
## Usage:
##   Emit:   EventBus.enemy_died.emit(gold, score)
##   Listen: EventBus.enemy_died.connect(_on_enemy_died)
## ============================================================

extends Node


# ── 敌人事件 (Enemy Events) ─────────────────────────────────

## Emitted when an enemy reaches the end of the path and costs
## the player a life. No payload — GameManager handles lives.
signal enemy_reached_end

## Emitted when an enemy is killed by a tower or other damage source.
## [param gold_reward]  Gold to add to the player's pool.
## [param score_reward] Score to add to the player's total.
signal enemy_died(gold_reward: int, score_reward: int)


# ── 波次事件 (Wave Events) ───────────────────────────────────

## Emitted at the moment a new wave begins spawning.
## [param wave_number]  1-based index of the wave that just started.
## [param total_waves]  Total number of waves in this level.
signal wave_started(wave_number: int, total_waves: int)

## Emitted when every enemy in a wave has either died or reached the end.
## [param wave_number] The wave that just finished.
signal wave_completed(wave_number: int)

## Emitted after the final wave is completed, before the victory screen.
signal all_waves_completed


# ── 塔防事件 (Tower Events) ──────────────────────────────────

## Emitted after a tower is successfully placed on the map.
## [param tower]    The Tower node that was just added to the scene.
## [param tile_pos] Grid coordinates of the tile it occupies.
signal tower_placed(tower: Node, tile_pos: Vector2i)

## Emitted after a tower is sold and removed from the map.
## [param tile_pos]      Grid coordinates that are now free.
## [param refund_amount] Gold returned to the player.
signal tower_sold(tile_pos: Vector2i, refund_amount: int)

## Emitted whenever a tower's level increases.
## [param tower]     The Tower node that was upgraded.
## [param new_level] The level the tower just reached.
signal tower_upgraded(tower: Node, new_level: int)

## Emitted when the player clicks/taps a tower to inspect it.
## [param tower] The Tower node that is now selected.
signal tower_selected(tower: Node)

## Emitted when the player deselects a tower (click away, sell, etc.).
signal tower_deselected


# ── 游戏状态事件 (Game State Events) ────────────────────────

## Emitted whenever the player's remaining lives change.
## [param new_lives] The updated life count (may be 0 on game over).
signal lives_changed(new_lives: int)

## Emitted whenever the player's gold total changes (earned or spent).
## [param new_gold] The updated gold amount.
signal gold_changed(new_gold: int)

## Emitted whenever the player's score changes.
## [param new_score] The updated score total.
signal score_changed(new_score: int)

## Emitted when the game speed multiplier is toggled.
## [param new_speed] The new Engine.time_scale-compatible multiplier.
signal game_speed_changed(new_speed: float)

## Emitted when the game is paused (e.g., player opens the pause menu).
signal game_paused

## Emitted when the game resumes from a paused state.
signal game_resumed

## Emitted when the player loses all lives — show the Game Over screen.
signal game_over_triggered

## Emitted when the player survives all waves — show the Victory screen.
signal victory_triggered
