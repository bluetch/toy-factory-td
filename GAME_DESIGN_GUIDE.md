# 塔防遊戲設計師指南 (Game Design Guide)

> 本文件面向遊戲設計師，說明如何在不改動程式碼的情況下調整所有重要遊戲參數。
> 所有設定均以 Godot `.tres` 資源檔案儲存，可在 Godot 編輯器或文字編輯器中修改。

---

## 地圖與格子設定

> ⚠️ 此處需要修改程式碼 (`scripts/grid_manager.gd`)，改動後需要同步更新所有關卡路線。

| 常數 | 預設值 | 說明 |
|------|--------|------|
| `TILE_SIZE` | `64` | 每格像素大小（px） |
| `GRID_COLS` | `23` | 橫向格數（0 到 GRID_COLS-1） |
| `GRID_ROWS` | `13` | 縱向格數（0 到 GRID_ROWS-1） |
| `GRID_OFFSET` | `Vector2(64, 64)` | 格子左上角在螢幕上的位置（px） |

**視窗尺寸**（`project.godot`）：1728 × 960
**可用格子範圍**：col 0~22，row 0~12

---

## 關卡設定 (`data/levels/level_N.tres`)

每個關卡是一個 `LevelData` 資源，包含以下欄位：

```
level_id          : int     關卡編號（需與檔名一致，level_1.tres → id=1）
level_name        : String  關卡名稱（顯示在關卡選擇畫面）
description       : String  關卡簡介（顯示在關卡選擇畫面）
starting_lives    : int     初始生命值（敵人抵達終點扣 1）
starting_gold     : int     初始金幣（用於購買和升級炮台）
waypoints         : Vector2i[] 路線節點（格子座標，見下方說明）
waves             : WaveData[] 波次陣列（見波次設定）
```

### 現有關卡

| 關卡 | 名稱 | 生命 | 初始金 | 波次數 |
|------|------|------|--------|--------|
| 1 | The Valley | 20 | 300 | 4 |
| 2 | The Labyrinth | 15 | 175 | 5 |
| 3 | The Gauntlet | 10 | 150 | 6 |

### 路線（Waypoints）定義規則

路線由一組 **格子座標**（col, row）依序組成，系統自動連接相鄰兩點之間的直線路段（只支援水平或垂直線段，不支援斜線）。

```
waypoints = [Vector2i(0, 6), Vector2i(12, 6), Vector2i(12, 3), Vector2i(22, 3)]
```

視覺化（關卡1，23×13格）：
```
col:  0         12        22
row 3:           ←←←←←←←←● (出口)
                 ↑
row 6: ●→→→→→→→→● (入口在左, col=0)
```

**規則：**
- 第一個座標 = 敵人出生點（必須在 col=0，從左側進入）
- 最後一個座標 = 敵人目標點（通常在 col=22，從右側離開）
- 每段只能是水平（同 row）或垂直（同 col）移動
- 路線格子不能建造炮台
- 座標範圍：col 0~22，row 0~12

### 現有路線一覽

**關卡1 - The Valley**（簡單 L 形）
```
(0,6)→(12,6)→(12,3)→(22,3)
```

**關卡2 - The Labyrinth**（蜿蜒 S 形）
```
(0,2)→(6,2)→(6,10)→(15,10)→(15,4)→(22,4)
```

**關卡3 - The Gauntlet**（複雜折返路線）
```
(0,1)→(5,1)→(5,7)→(9,7)→(9,2)→(15,2)→(15,10)→(20,10)→(20,5)→(22,5)
```

### 新增關卡步驟

1. 複製 `data/levels/level_3.tres` → 改名為 `level_4.tres`
2. 修改 `level_id = 4`、`level_name`、路線、波次
3. 在 `scenes/ui/LevelSelect.tscn` 新增關卡卡片（參考現有卡片結構）

---

## 波次設定 (`WaveData`)

每個波次定義在 `level_N.tres` 內作為 sub_resource，包含：

```
wave_number       : int     波次編號（從 1 開始）
auto_start_delay  : float   前一波結束後自動開始的秒數，-1 = 需玩家手動按開始
entries           : WaveEntry[]  此波包含的敵人組列表
```

### 敵人組設定 (`WaveEntry`)

每組敵人在波次中的子設定：

```
enemy_data        : EnemyData  使用哪種敵人（引用 data/enemies/*.tres）
count             : int        此組要派出的數量
group_delay       : float      此組在波次開始後延遲幾秒才出現（製造節奏感）
spawn_interval    : float      同組內每隻敵人之間的間隔秒數（越小越密集）
```

### 波次設計建議

| 難度感受 | spawn_interval | count | 組合 |
|---------|---------------|-------|------|
| 輕鬆開場 | 1.5s | 5~8 | 只有基礎敵人 |
| 中等壓力 | 1.0s | 8~12 | 基礎 + 快速 |
| 高壓挑戰 | 0.6~0.8s | 10~20 | 混合3種 |
| Boss 關卡 | 1.0s | 1 | Boss 前加 group_delay=15 |

---

## 敵人設定 (`data/enemies/*.tres`)

每種敵人是一個 `EnemyData` 資源：

```
enemy_id          : String  唯一識別碼（e.g. "basic_enemy"）
enemy_name        : String  顯示名稱
max_health        : float   最大血量
move_speed        : float   移動速度（像素/秒，TILE_SIZE=64，80px/s ≈ 1.25格/秒）
armor             : float   護甲（0.0 = 無護甲，0.5 = 吸收50%傷害，最高不建議超過 0.85）
gold_reward       : int     擊殺後獲得金幣
score_reward      : int     擊殺後獲得分數
scene_path        : String  對應的場景路徑（不要修改）
```

### 現有敵人數值

| 敵人 | 血量 | 速度 | 護甲 | 金幣 | 分數 |
|------|------|------|------|------|------|
| Grunt（基礎） | 100 | 80 | 0% | 20 | 10 |
| Fast（快速） | — | — | — | — | — |
| Tank（坦克） | — | — | — | — | — |
| Boss | — | — | — | — | — |

> 提示：格子大小 64px，速度 80px/s 約 1.25 格/秒。建議速度範圍：快速敵人 140~180，坦克 40~60。

### 平衡參考公式

```
有效血量 = max_health / (1 - armor)
基礎 DPS（弓箭塔 lv0）= 15 * 1.5 = 22.5
擊殺基礎敵人需要時間 ≈ 100 / 22.5 ≈ 4.4 秒
```

### 新增敵人步驟

1. 複製 `data/enemies/basic_enemy.tres` → 改名（e.g. `shielded_enemy.tres`）
2. 修改 `enemy_id`、數值欄位
3. 在 `scripts/enemies/` 新增腳本（繼承 `BaseEnemy`）
4. 建立場景並在 `scene_path` 填入路徑
5. 在波次設定中引用新 `.tres`

---

## 炮台設定 (`data/towers/*.tres`)

每種炮台是一個 `TowerData` 資源：

```
tower_id          : String  唯一識別碼
tower_name        : String  顯示名稱
description       : String  說明文字（顯示在炮台面板）
build_cost        : int     建造花費（金幣）
sell_ratio        : float   賣出退款比例（0.7 = 退還70%花費）
base_damage       : float   基礎傷害（每發）
base_attack_speed : float   攻擊頻率（次/秒）
base_range        : float   攻擊範圍（像素，1格=64px）
projectile_speed  : float   彈丸飛行速度（像素/秒）
splash_radius     : float   爆炸範圍（0 = 單體，>0 = 範圍傷害）
slow_factor       : float   減速係數（1.0 = 不減速，0.5 = 速度減為50%）
slow_duration     : float   減速持續時間（秒）
upgrades          : UpgradeData[]  升級層設定（最多2層，見下方）
scene_path        : String  場景路徑（不要修改）
```

### 現有炮台 - 弓箭塔

```
build_cost = 100     base_damage = 15     base_attack_speed = 1.5
base_range = 150     splash_radius = 0    (單體快速)

升級1: +75金，傷害×1.5，射程×1.1
升級2: +150金，傷害×1.6，速度×1.3
```

### 升級層設定 (`UpgradeData`)

```
upgrade_name      : String  升級名稱（顯示在升級面板）
description       : String  升級說明
upgrade_cost      : int     升級花費（金幣）
damage_multiplier : float   傷害乘數（1.0 = 不變，1.5 = 增加50%）
range_multiplier  : float   射程乘數
speed_multiplier  : float   攻擊速度乘數
```

### 範圍與像素對應

| 像素範圍 | 約等於幾格 | 視覺感受 |
|---------|-----------|---------|
| 96px | 1.5格 | 非常近 |
| 128px | 2格 | 近距離 |
| 192px | 3格 | 中距離（推薦基礎） |
| 256px | 4格 | 遠距離 |
| 320px | 5格 | 狙擊 |

### 平衡參考：DPS 計算

```
DPS = base_damage * base_attack_speed
弓箭塔 lv0 DPS = 15 * 1.5 = 22.5
大砲塔 lv0 DPS = （見 cannon_tower.tres）
冰塔（含減速效果）：actual_DPS = DPS / slow_factor（等效提高其他塔的效率）
```

### 新增炮台步驟

1. 複製 `data/towers/arrow_tower.tres` → 改名
2. 修改所有數值欄位
3. 在 `scripts/towers/` 新增腳本（繼承 `BaseTower`）
4. 建立場景，填入 `scene_path`
5. 在 `scripts/ui/tower_panel.gd` 的 `TOWER_RESOURCES` 陣列加入 `.tres` 路徑

---

## 遊戲整體參數速查

### 時間常數（`scripts/wave_manager.gd`）

```gdscript
PREP_TIME = 20.0          # 第一波開始前的準備時間（秒）
BETWEEN_WAVE_TIME = 15.0  # 波次之間的預設倒數（秒，當 auto_start_delay = -1 時使用）
```

### GameManager 狀態

```
lives    = 起始生命（由 LevelData.starting_lives 設定）
gold     = 起始金幣（由 LevelData.starting_gold 設定）
score    = 0（擊殺敵人累積）
game_speed = 1.0 / 2.0（玩家可切換）
```

---

## 快速設計流程

```
新關卡：
  1. 在紙上畫出 23×13 的格子
  2. 規劃路線（只能直線轉彎，避免單格寬的 U 型迴廊）
  3. 決定生命值/金幣/波次數
  4. 複製 level_N.tres，修改 waypoints 和 waves
  5. 在 LevelSelect 新增入口

調整難度：
  敵人更強 → 提高 max_health 或 armor（armor 不超過 0.8）
  節奏更快 → 降低 spawn_interval 或 auto_start_delay
  更有策略 → 設計迫使玩家建不同種炮台的混合波次

調整炮台：
  過強 → 降低 damage_multiplier 或提高 build_cost
  過弱 → 提高 base_damage 或降低 upgrade_cost
  建議：炮台的基礎 DPS × 射程 / 100 ≈ build_cost / 10（粗略平衡基準）
```

---

## 檔案位置速查

```
data/
  levels/       ← 關卡設定（生命、金幣、路線、波次）
    level_1.tres
    level_2.tres
    level_3.tres
  towers/       ← 炮台設定（傷害、速度、範圍、費用、升級）
    arrow_tower.tres
    cannon_tower.tres
    ice_tower.tres
  enemies/      ← 敵人設定（血量、速度、護甲、獎勵）
    basic_enemy.tres
    fast_enemy.tres
    tank_enemy.tres
    boss_enemy.tres

scripts/
  grid_manager.gd   ← 格子尺寸常數（GRID_COLS、GRID_ROWS、TILE_SIZE）
  wave_manager.gd   ← PREP_TIME、BETWEEN_WAVE_TIME
```
