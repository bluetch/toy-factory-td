# 開發日誌 — Coco & the Factory（發條工廠）

> 紀錄從零到 Steam Alpha 的每一步。
> 格式：日期 · 版本里程碑 · 完成項目 · 遇到的問題與解法

---

## 2026-03-12 · Day 1 · 專案建立 + Bug 修復

### Session 1 — 初始 Scaffold（commit `6e37e20`）

**目標**：從零建立一個可跑的塔防框架。

**完成項目**
- 建立 Godot 4.6 專案，設定 1728×960 視窗（Forward Plus renderer）
- 5 個 Autoload 單例：`EventBus`、`GameManager`、`SaveManager`、`SceneManager`、`AudioManager`
- 核心遊戲循環：
  - `GridManager`：64×64 tile 格子系統（23×13 格），路徑追蹤
  - `WaveManager`：波次計時、敵人生成
  - `BaseTower` + 3 種塔（弩塔、砲台、冰塔）
  - `BaseEnemy` + 3 種敵人（BasicEnemy、FastEnemy、TankEnemy）
  - `BaseProjectile` + 3 種投射物
- 5 個主線關卡資料（`LevelData.tres`），含路徑 waypoints 與波次組合
- 場景：`MainMenu`、`LevelSelect`、`GameWorld`、`HUD`、`PauseMenu`、`Victory`、`GameOver`
- 存檔系統（JSON → `user://save_data.json`）：解鎖關卡、最高分

**技術決策**
- 所有跨系統事件一律走 `EventBus` 信號，不直接呼叫 unrelated system 的方法
- TowerData / EnemyData / LevelData 全部資料驅動（`.tres` Resource 檔）
- GridManager 使用 `TILE_SIZE=64`, `GRID_OFFSET=Vector2(48,64)`，TowerPanel 固定在右側 160px

---

### Session 2 — 型別修正（commit `d9f4b4f`）

**問題**：Godot 4.6 對 Variant 型別推斷比預期嚴格，大量 warning 出現。
**解法**：為所有 signal 回呼、函式回傳值加上明確型別標注（`: Array[Vector2]` 等）。

---

### Session 3 — 場景修復（commit `75fc843`）

**問題清單與修法**
| 問題 | 原因 | 修法 |
|------|------|------|
| 場景切換閃退 | SceneManager 切換時 node 還在佇列 free | 改用 `call_deferred("_do_transition")` |
| 波次生成不觸發 | WaveManager `setup()` 在 EventBus connect 之前呼叫 | 調整 `_ready()` 中的初始化順序 |
| 倒數計時器速度雙倍 | `create_timer(delay / game_speed)` 在 time_scale 已調整的情況下造成 4× | 改為 `create_timer(delay)`（Engine.time_scale 已補償） |
| 節點路徑失效 | 場景重組後 `$UILayer/HUD` 路徑改變 | 統一用 `@onready` + unique name（`%NodeName`） |

---

## 2026-03-13 · Day 2 · 劇情系統

### Session 4 — 敘事層（commit `fe6c4d7`）

**完成項目**
- `StoryDatabase` autoload：10 段劇情資料（5 前置 + 4 後記 + 1 尾聲）
- `StoryScreen` 場景：打字機效果（38 字/秒）、角色立繪淡入淡出、進度標示
- `CharacterPortrait` 元件：交叉淡入（0.25s TRANS_QUART），支援 narrator/COCO/Longing 等角色
- `SceneManager` 擴充：`goto_story(id, callback)`、`goto_level_outro(level_id, on_complete)`
- 難度選擇系統（簡單/普通/困難），影響初始生命數與金幣
- `WorldBackground`：程式生成草地+道路格磚底圖

**技術決策**
- 劇情文字使用 `RichTextLabel.visible_characters` 實作打字機，無需額外 Timer
- 角色立繪 fade 透過 `ColorRect` overlay 的 alpha 實現，避免 shader 依賴

---

### Session 5 — 劇情系統完善（commit `48e1eca`）

**完成項目**
- 補完所有 10 段劇情文字（角色：COCO、齒輪爺爺、旁白、Longing）
- 過場動畫優化：進入故事場景時 slide-in 動畫
- `skip_label` 提示（ESC 跳過全部）、空格/滑鼠點擊加速打字
- Boss 敵人（渴望 Longing）：觸碰終點時觸發全螢幕震動 `trigger_shake(0.7, 20)`

---

## 2026-03-14 · Day 3 · 品質強化（Steam 標準）

### Session 6 — 全面品質升級（commit `690bdaf`）

**完成項目**
- **FactoryBase**：敵人進入時播放破裂特效、護盾動畫
- **Boss 敵人完整化**：`BossEnemy` 獨立場景、高血量、死亡時觸發 `trigger_shake`
- **FloatingText**：敵人死亡時 `+金幣` 標籤浮起並淡出
- **RangeCircle**：選中塔時顯示攻擊範圍圈（`_draw()` 繪製，無 shader）
- **健康條修正**：Fill ColorRect 改用 `modulate` 做紅→綠漸變（`Color(1-ratio, ratio, 0)`）
- **遊戲速度 2×**：HUD 加速按鈕，`Engine.time_scale = 2.0`
- **敵人護甲系統**：`take_damage()` 扣除護甲比例，`take_damage_piercing()` 無視護甲
- **全局本地化**：主選單/關卡選擇/暫停/勝利/失敗畫面全部繁體中文化

---

### Session 7 — Steam 等級品質強化（commit `3ed1e77`）

**完成項目**

**設定畫面 SettingsScreen**
- 音樂/音效音量滑桿（HSlider → AudioManager）
- 全螢幕 CheckButton（`DisplayServer.window_set_mode`）
- 重置教學按鈕
- `SceneManager.goto_settings(return_path)` / `settings_done()` 支援從主選單、暫停選單進入

**成就系統 AchievementManager**
- 10 個成就定義（首勝、無傷、百殺、建塔狂等）
- Session 追蹤（本局擊殺數、建塔數、最大生命值）
- **Toast 通知**：CanvasLayer(110) + TRANS_BACK slide-in，`process_mode=ALWAYS` 確保暫停時也顯示

**新防禦塔**
- **LightningTower（雷塔）**：鏈式閃電，最多跳 3 個敵人，每跳 40% 傷害衰減，Line2D 電弧特效
- **SniperTower（狙擊塔）**：超遠程，優先攻擊最低 HP 敵人，無視護甲，Line2D tracer 特效

**視覺波蘭**
- 塔建造動畫：scale 0.3 → 1.0 TRANS_BACK 彈跳（0.22s）
- 生命值危機 Vignette：生命 ≤ 3 時，螢幕四角紅色光暈 TRANS_SINE 脈動

**音樂架構完成**
- `AudioManager.play_track(name)` 懶載入系統，音樂檔不存在時靜默略過
- 5 個軌道（menu/gameplay/boss/victory/story）全部接入對應場景
- 最終波次自動切換 boss 音樂

---

### Session 8 — 教學系統 + 規劃文件（commit `f00c9fd`）

**完成項目**
- **TutorialManager autoload**：監聽 `SceneTree.node_added`，首次進入 Level 1 自動啟動
- **TutorialOverlay 場景**：高亮框 + 步驟說明 + 繼續按鈕，6 步引導（歡迎→放塔→波次→升級→加速→完成）
- **SaveManager 擴充**：`tutorial_done` flag、`achievements[]`、`stats{}` 記錄
- **README 轉型**：改為 Steam Alpha 路線的 Living Planning Document，含 checkboxes

---

## 2026-03-15 · Day 4 · 美術替換 + 音效補全

### Session 9 — A1 Art Overhaul + A2 SFX（當前）

**資產來源**
- Kenney Tower Defense Kit（CC0）：`assets/kenney_tower-defense-kit/`（3D 模型含 64×64 RGBA Preview PNG）
- Kenney Interface Sounds（CC0）：`assets/kenney_interface-sounds/`
- Kenney Impact Sounds（CC0）：`assets/kenney_impact-sounds/`

**完成項目：精靈替換（ColorRect → Sprite2D）**

| 對象 | 之前 | 之後 |
|------|------|------|
| ArrowTower | 深綠色矩形 | `tower-round-base` + 旋轉 `weapon-ballista` |
| CannonTower | 棕色矩形 | `tower-square-bottom-a` + 旋轉 `weapon-cannon` |
| IceTower | 淡藍色矩形 | `tower-round-crystals` + 旋轉 `tower-round-top-a` |
| LightningTower | 深藍矩形 + 方塊 | `tower-round-top-b` + 旋轉 `tower-round-build-d`（**新增 Turret 旋轉**） |
| SniperTower | 灰色矩形 + 條形 | `tower-square-bottom-b` + 旋轉 `weapon-turret`（**新增 Turret 旋轉**） |
| FastEnemy | 橘色方塊 | `enemy-ufo-b.png`（scale 0.55×） |
| TankEnemy | 藍色大方塊 | `enemy-ufo-c.png`（scale 0.75×） |
| BossEnemy | 紫色方塊 + 發光邊框 | `enemy-ufo-d.png`（scale 1.2×，壓迫感增強） |
| ArrowProjectile | 棕色細長矩形 | `weapon-ammo-arrow.png`（rotation_degrees=-90） |
| CannonProjectile | 灰色圓形矩形 | `weapon-ammo-cannonball.png` |
| IceProjectile | 淡藍色矩形 | `weapon-ammo-bullet.png`（+ 藍色 modulate tint） |

**完成項目：SFX 音效系統**

AudioManager 新增 7 個 SFX 觸發方法，全部接入 EventBus 信號：

| 事件 | 音效來源 | 觸發位置 |
|------|------|------|
| 放置防禦塔 | `drop_002.ogg` | `game_world.gd` EventBus.tower_placed |
| 升級防禦塔 | `maximize_002.ogg` | `game_world.gd` EventBus.tower_upgraded |
| 出售防禦塔 | `minimize_002.ogg` | `game_world.gd` EventBus.tower_sold |
| 敵人死亡 | `glass_001.ogg` | `base_enemy.gd` `_die()` |
| 敵人到達終點 | `error_001.ogg` | `game_world.gd` `_on_enemy_reached_end()` |
| 遊戲失敗 | `error_006.ogg` | `game_over.gd` `_on_game_over()` |
| 關卡勝利 | `confirmation_004.ogg` | `victory.gd` `_on_victory()` |

**技術備註**
- Kenney Preview PNG 為 64×64 RGBA（調色盤模式含 tRNS 透明通道），恰好等於遊戲 tile 尺寸
- LightningTower/SniperTower 原本無 Turret 節點（靜態塔），本次補充後可自動旋轉面向目標
- 健康條 Fill 顏色統一改為白色（`Color(1,1,1,1)`），搭配 `modulate` 做正確紅→綠漸變

---

## 現況快照（2026-03-15）

### 完成度一覽
| 系統 | 狀態 | 備註 |
|------|------|------|
| 核心塔防循環 | ✅ | 放塔、波次、敵人路徑、傷害計算 |
| 5 種防禦塔 | ✅ | 弩/砲/冰/雷/狙，各 2 段升級 |
| 4 種敵人 | ✅ | 小兵/斥候/重甲/Boss（渴望） |
| 5 個主線關卡 | ✅ | 26 波，關 3/5 有 Boss |
| 劇情系統 | ✅ | 10 段故事 + 打字機 + 立繪淡入 |
| 存檔系統 | ✅ | JSON，高分/解鎖/設定/成就/統計 |
| 成就系統 | ✅ | 10 個成就 + Toast 通知 |
| 設定畫面 | ✅ | 音樂/音效/全螢幕/重置教學 |
| 難度選擇 | ✅ | 簡單/普通/困難 |
| 繁體中文 UI | ✅ | 全介面中文化 |
| 教學系統 | ✅ | 首次遊玩自動觸發，6 步引導 |
| 美術（精靈） | ✅ | Kenney 64×64 RGBA，全塔/敵人/投射物 |
| 音效 SFX | ✅ | 7 個遊戲事件音效 + 4 個射擊音效 |
| 音樂架構 | ✅ | 5 軌道系統，懶載入，缺檔靜默 |
| **背景音樂檔** | ⏳ | 需手動取得 5 個 .ogg 放入 `assets/audio/music/` |
| Steam 商店素材 | ❌ | 截圖/Trailer/文案，需遊戲完成後製作 |

### 遊戲內容量
- **關卡**：5 關 / **波次**：26 波 / **塔**：5 種 × 3 級 / **敵人**：4 種
- **劇情**：10 段 / **成就**：10 個 / **預估首通**：2–3 小時

---

## 下一步規劃（Next Steps）

### 優先級 1 — 遊戲體驗核心（本週）

**① 背景音樂補全（A2）**
- 需要 5 個 .ogg 音樂檔：`music_menu`, `music_gameplay`, `music_boss`, `music_victory`, `music_story`
- 推薦免費來源：OpenGameArt.org（CC0/CC-BY），搜尋關鍵字 "tower defense bgm"、"factory theme"
- 放入 `assets/audio/music/` 即可自動接入，架構已完成

**② TowerPanel 縮圖（A1 剩餘）**
- 在 TowerPanel 的每個塔按鈕旁加入 64×64 縮圖
- 使用 Kenney 精靈的 TextureRect 即可，不需要大量程式碼
- 預計工時：2–3 小時

**③ 地形美化（A1 剩餘）**
- WorldBackground 目前為程式繪製的純色格子
- 用 Kenney 的 `tile.png`（草地）和 `tile-straight.png`（道路）替換
- 預計工時：4–6 小時（需理解 WorldBackground 的繪製邏輯）

---

### 優先級 2 — 遊戲深度提升（下週）

**④ 粒子效果**
- 敵人死亡：`CPUParticles2D` 爆炸碎片
- 砲台命中：爆炸閃光
- 冰塔命中：冰晶粒子
- 技術上簡單，視覺衝擊大

**⑤ 元素反應系統（設計文件中評分最高）**
- 詳見 `docs/GAME_DESIGN_PROPOSALS.md`
- 冰塔凍結 + 砲台轟炸 → 碎裂傷害加成
- 複雜度中等，可大幅提升策略深度
- 建議在 Steam Early Access 後加入

**⑥ 關卡 6–8（內容擴充）**
- 新路徑形狀：U 形、螺旋形
- 新敵人：護盾兵（需打破護盾才能傷害）、加速 Aura 敵人
- 配合更多劇情段落

---

### 優先級 3 — Steam 上架準備（2 週後）

**⑦ 英文本地化**
- 所有 UI 文字加入英文版本
- Godot 4.6 使用 `.po` + `TranslationServer`
- 可機器翻譯後人工校訂，節省時間

**⑧ Steam 商店素材（C5）**
- Capsule 主圖：231×87, 460×215, 1128×492
- 遊戲截圖：至少 5 張 1920×1080
- 30–90 秒 Trailer：開場劇情 → 遊玩展示 → Boss 戰高潮
- 商店文案（中英雙語）

**⑨ 系統需求 + 測試**
- 目標：macOS + Windows 原生執行
- Godot export 設定：PCK 嵌入、圖示、可執行檔簽名

---

### 技術債清單（待機時處理）

| 項目 | 說明 | 優先度 |
|------|------|--------|
| ArrowTower/CannonTower/IceTower 無 RangeCircle 腳本 | 這三個塔的 RangeCircle 節點缺少 `range_circle.gd`，圓圈不會繪製 | 中 |
| BasicEnemy 健康條 Fill 顏色 | 目前仍用綠色 `color` 而非白色，modulate 效果不純 | 低 |
| SFX 音量不受 SFX 滑桿控制 | `_sfx_tower_place` 等新 SFX 在 `_load_volumes_from_save()` 後載入，需確認 pool 音量已套用 | 中 |
| 敵人死亡無淡出動畫 | FastEnemy/TankEnemy/BossEnemy 使用靜態 Sprite2D，`_anim` 為 null，死亡時直接 `queue_free` | 低 |
| BossEnemy 無特殊技能 | Boss 目前只是大型慢速敵人，無特殊行為 | 中（趣味性） |

---

## 設計哲學備忘

> 這款遊戲的核心價值不在「最硬核的塔防」，而在**「情感共鳴 + 策略滿足感」**的平衡。
> - 每個關卡的劇情段落必須和該關的遊玩難度情緒相呼應
> - 防禦塔的組合應該讓玩家感到「發現了正確答案」的快樂，而非無解的挫折
> - Coco 是個修繕者，遊戲的節奏也應反映「搭建→守護→成長」的敘事弧線

---

---

## 2026-03-15 · Day 4 補充 — TowerPanel 縮圖 + 地形美化

### Session 10 — A1 剩餘項目完成

**TowerPanel 縮圖**
- 從純文字 Button 改為 PanelContainer 卡片（TextureRect 縮圖 48×48 + 塔名 + 費用）
- 使用 `data.scene_path.get_file().get_basename()` 從 TowerData 提取塔型對應 Kenney 精靈
- 透明 Button overlay 覆蓋整個卡片處理點擊/hover
- 不可購買時卡片整體 `modulate.a = 0.45`（之前只有文字看不清）

**WorldBackground 地形美化**
- 完整重寫，從 tileset atlas 改為 Kenney 個別 tile PNG
- 路徑感知邏輯：
  - 偵測每個 path 格子的四方連通方向
  - 直路（純 EW）→ `tile-straight.png`（0°）
  - 直路（純 NS）→ `tile-straight.png`（90°）
  - 轉角 SE/SW/NE/NW → `tile-corner-round.png`（0°/90°/180°/270°）
  - 起點 → `tile-spawn.png`、終點 → `tile-end.png`
- 草地隨機混合（種子 7777）：65% 基礎/15% 凸起/10% 岩石/10% 樹木
- 繪製方式：先 `draw_rect` 填底色（草綠/土棕），再疊 Kenney tile（透明邊緣不穿幫）
- 旋轉支援：`draw_set_transform` + `draw_texture(tex, Vector2(-32,-32))`

**技術備註**
- ArrowTower/CannonTower/IceTower 的 RangeCircle 補上 `range_circle.gd` 腳本（之前技術債）
- 開發日誌建立：`docs/devlog.md`（完整 Day 1–4 紀錄 + 下一步規劃）

---

## 2026-03-15 · Day 4 補充（Session 11）— Bug 修復 + 視覺效果

### 修復 CRITICAL：BossEnemy 閃退

**問題**：`boss_enemy_scene.gd` 的 `@onready` 仍參考被刪除的 `ColorRect` 節點（`$Visual/Body`、`$Visual/Core`），
Boss 出現時立即 crash。

**修法**：
- 移除兩個壞掉的 `@onready var`
- 改為對 `$Visual`（Node2D）施加 scale tween → `Vector2(1.08, 1.08)` ↔ `Vector2(1.0, 1.0)` 循環
  保留「呼吸感」視覺，且無需找 ColorRect

### 新增：Boss 衝刺技能

每 8 秒觸發一次：
- 速度乘以 2.8，持續 1.5 秒
- 觸發時顯示「⚡ 衝刺！」浮動文字 + 紅色閃爍警示
- `_physics_process` override：不影響 `super()` 的物理計算

### UpgradePanel 中文化

| 原文（英文） | 修改後（繁中） |
|---|---|
| `"Level: %d / %d"` | `"等級：%d / %d"` |
| `"DMG: %.0f  SPD: %.1f/s  RNG: %.0f"` | `"傷害：%.0f  速度：%.1f/s  射程：%.0f"` |
| `"Upgrade\n%d 💰"` | `"升級\n%d 💰"` |
| `"Sell\n+%d 💰"` | `"出售\n+%d 💰"` |

### 敵人死亡動畫

`base_enemy.gd` `_die()` 新增 else 分支（Sprite2D 敵人無 `_anim` 時）：
- 平行 tween：`scale × 1.6`（放大）+ `modulate.a → 0`（淡出）
- 持續 0.25 秒後 `queue_free()`
- 效果：砰一下炸開消失，比直接消失有衝擊感

### 砲台爆炸環 + 冰塔凍結環

`cannon_projectile.gd` 命中後呼叫 `_spawn_explosion_ring()`：
- 動態產生 Node2D，draw callback 繪製橙色弧線
- `tween_method` 控制半徑從 4px 擴張至 `_splash_radius`，alpha 同步淡出
- 0.32 秒後 `queue_free()`

`ice_projectile.gd` 命中後呼叫 `_spawn_freeze_ring()`：
- 藍白色雙層效果（外環弧線 + 內圓填色）
- 持續 0.42 秒

---

---

## 2026-03-15 · Day 4 補充（Session 12）— 關卡擴充 6–8

### 新增 3 個關卡（共 8 關）

| 關卡 | 名稱 | 路徑形狀 | 波次數 | 特色 |
|---|---|---|---|---|
| Level 6 | 廢墟之間 | 雙 U 迴廊 | 7 波 | Boss ×3 最終波 |
| Level 7 | 機械迷宮 | 螺旋（4 折） | 8 波 | Boss 從第 3 波起出現 |
| Level 8 | 最終決戰 | 蛇形（4 折） | 9 波 | 10 Boss 最終波，8 生命 |

**路徑 waypoints**
- Level 6: `(0,3)→(20,3)→(20,6)→(3,6)→(3,10)→(22,10)` — 雙 U
- Level 7: `(0,1)→(21,1)→(21,11)→(2,11)→(2,4)→(18,4)→(18,8)→(22,8)` — 螺旋
- Level 8: `(0,6)→(5,6)→(5,1)→(17,1)→(17,11)→(9,11)→(9,4)→(22,4)` — 蛇形

**SaveManager** `LEVEL_IDS` / `MAX_LEVEL` 更新至 8。

**LevelSelect.tscn** 更新：
- `HBoxContainer` → `GridContainer`（columns=4），anchor 改為頂部置中
- 卡片 4 列 × 2 排，所有 8 關在同一畫面顯示
- Level 4 / 5 標題統一改為「第N關：xxx」格式
- 3 張新關卡卡片加入（彩色預覽 ColorRect 配合關卡氛圍）

---

---

## 2026-03-15 · Day 4 補充（Session 13）— 劇情 Act 2 + 成就修正

### 第二幕劇情全部補完

新增 story_database.gd 條目：

| ID | 類型 | 內容 |
|---|---|---|
| `story_6` | 前置劇情 | Coco 踏入地下廢墟，面對 50 年的等待 |
| `story_7` | 前置劇情 | 機械迷宮深處，Longing 質問 Coco 的選擇 |
| `story_8` | 前置劇情 | 抵達「源點」，Longing 的真實形態現身 |
| `outro_5` | 第一幕結局 | Coco 理解自己保護的不是工廠而是可能性 |
| `outro_6` | 過場 | 廢墟中的音樂盒故事；齒輪爺爺動情 |
| `outro_7` | 過場 | Coco 思考 Longing 與自己的共同起點 |
| `epilogue` | **第二幕大結局** | Coco 握住 Longing 之手；它被第一次「聽見」；工廠重生 |

**敘事核心**：Longing 不是怪物，而是五十年無人回應的願望積累。最終以「接納」而非「消滅」解決衝突。

### 成就系統修正

- `completionist`：從硬編碼 `level_id == 5` 改為 `SaveManager.MAX_LEVEL`
- `flawless_5`（全命通過最終關）：同樣改為 `MAX_LEVEL`

---

*最後更新：2026-03-15*
*維護：開發者 + Claude Code*
