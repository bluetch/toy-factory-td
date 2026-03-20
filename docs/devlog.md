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

## 2026-03-17 · Day 5（Session 14）— 平衡調整 + QoL 全四維優化

### 數值平衡

| 項目 | 舊值 | 新值 | 原因 |
|---|---|---|---|
| 狙擊塔 `base_damage` | 65.0 | **45.0** | 65 dmg × 1.6 × 1.8 = 187 — 一炮秒殺大多數敵人，嚴重削弱遊戲性 |
| 狙擊塔 `build_cost` | 200 | **250** | 配合傷害下調，保持 cost/DPS 比合理 |
| 雷塔 `base_attack_speed` | 1.0 | **0.7** | 三鏈 × 1.0/秒 DPS 過高；0.7 保留強度但留給玩家反應空間 |
| Level 3 Boss `group_delay` | 15.0s | **25.0s** | 15s 內 Boss 與前波坦克同時壓線，無法應對；25s 給玩家喘息時間 |

### UX：格子路徑懸停反饋

`grid_manager.gd` — 放置模式懸停提示改進：

- **綠色**：可建造（不變）
- **橘色**（新）：懸停在路徑格（PATH），明確提示「這是敵人通道」
- **紅色**：懸停在已佔用格（OCCUPIED）
- **白色 ×**（新）：所有無效格都顯示白色叉叉（2條 3px 線段），原因一目了然
- 不再需要玩家靠「猜」和「試點」理解為何無法建造

### 視覺：工廠基地受擊爆閃

`game_world.gd` — 敵人抵達終點時，在 `factory_base.global_position` 觸發紅橙雙層光圈：

- 外層：紅色半透明擴散圓（8px → 72px，0.45 秒）
- 內層：橙色高亮核心（跟隨半徑 × 0.45 縮放）
- 與現有攝影機震動同步，強化「受傷」的感知

### QoL：鍵盤快捷鍵 1–5 選塔

`game_world.gd` — 遊戲中按數字鍵直接選取對應塔型：

| 按鍵 | 塔型 |
|---|---|
| `1` | 弩塔（Arrow Tower） |
| `2` | 砲台（Cannon Tower） |
| `3` | 冰塔（Ice Tower） |
| `4` | 雷塔（Lightning Tower） |
| `5` | 狙擊塔（Sniper Tower） |

`tower_panel.gd` — 每張卡片左上角新增小字數字徽章（1–5），提示快捷鍵存在。

---

## 2026-03-17 · Day 5（Session 15）— UX 全面提升（第二輪）

### 即時戰況資訊：敵人倒數顯示

- **EventBus** 新增 `enemy_count_changed(alive, total)` 信號
- **WaveManager** 追蹤 `_wave_total_enemies`，每波開始及每次敵人死亡/抵達終點時觸發信號
- **HUD** `wave_label` 波次活躍時顯示 `波次: X/Y  ⚔ A/B`（剩餘/總數），波次結束後恢復純波次顯示
- 玩家可隨時掌握當前波次存活敵人數，不再憑感覺判斷

### 放置模式射程預覽

- **GameWorld** 新增 `_range_preview: Node2D`，`begin_tower_placement()` 時建立
- 射程圓（綠色半透明）跟隨滑鼠吸附到 tile 中心（`tile_to_world()` 取中心點）
- 半徑 = `tower_data.get_range(0)`（基礎等級射程）
- `cancel_tower_placement()` 時自動銷毀；成功放置後重建新圓繼續顯示
- 玩家放塔前可精確預判射程覆蓋

### 出售確認：防誤觸兩步確認

- **UpgradePanel** 出售按鈕改為兩步確認：
  - 第一次按：按鈕文字改為「確認出售？ +X 💰」，字色改橘色，2.5 秒計時
  - 第二次按：執行出售
  - 2.5 秒無第二次按：自動回復為「出售 +X 💰」，不執行任何動作
  - 避免戰況緊張時誤點出售重要防禦塔

### 暫停選單新增「重新開始」

- **PauseMenu** `_ready()` 中動態注入「重新開始」按鈕（在「繼續」下方）
- 按下後 `GameManager.resume_game()` + `SceneManager.goto_level(current_id)`
- 不再需要返回主選單再手動選關

### 消費金幣視覺反饋

- **HUD** `_on_gold_changed()` 追蹤前一金幣值；金幣減少時金幣 Label 短暫 1.25× 縮放彈跳（0.08s 放大 → 0.12s 回原）
- 強化消費感知，減少「為何買不起塔」的疑惑

### 結算畫面完善

**勝利畫面**（victory.gd）：
- 動態注入「難度：簡單 / 普通 / 困難」標籤，顏色對應難度（綠/黃/紅）

**失敗畫面**（game_over.gd）：
- 新增「建造防禦塔：N」統計（從 AchievementManager 取值）
- 新增「難度：X」標籤（顏色同勝利畫面）

---

## 2026-03-17 · Day 5（Session 16）— 程式品質 + 遊戲性 + 劇情補完

### BUG 修復

**成就「全通關」描述錯誤**
- `achievement_manager.gd`：「完成所有五個關卡」→「完成全部八個關卡」

**成就「鋼鐵防線」可被利用**
- 舊邏輯：`GameManager.lives == _session_max_lives`，玩家在受傷後重新開始關卡即可洗掉生命損失
- 新邏輯：新增 `_session_lives_lost` 計數器，連接 `EventBus.enemy_reached_end`，判斷條件改為 `_session_lives_lost == 0`
- 效果：重新開始不再能繞過成就判定

### 數值平衡

**Level 6 資源危機修復（HIGH）**
- `starting_gold` 200 → **300**（低難度下只能建一座塔的問題徹底解決）
- `starting_lives` 12 → **15**（7波強度的關卡需要更多緩衝空間）

**Level 4 增加 Boss 高潮**
- 最終波（Wave 5）新增 Boss 敵人，`group_delay = 20s`（讓玩家先清理雜兵）
- Level 4 現在有完整的「雜兵 → 坦克 → Boss」敘事弧線

### 程式品質提升

**FloatingText PackedScene 靜態快取**（`base_enemy.gd`）
- 原本每次傷害 / 死亡都呼叫 `load("res://scenes/ui/FloatingText.tscn")`
- 改為 `static var _float_text_scene: PackedScene`，首次 `setup()` 時載入一次，之後所有實例共用
- 高戰況下（30+ 敵人同時受傷）減少大量重複 I/O

**RangeCircle 渲染最佳化**（`range_circle.gd`）
- 輪廓繪製從 128 次 `draw_line()` 改為 2 次 `draw_polyline()`
- 每個塔每幀從 128 draw call 降至 2 draw call（約 64 倍減少）

**BaseTower 敵人列表就地清理**（`base_tower.gd`）
- 原本 `_enemies_in_range.filter(lambda)` 每個攻擊 tick 建立新 Array
- 改為倒序 `remove_at()` 就地清除失效引用，零 GC 分配

### 美術 / UX

**裝甲視覺指示器**（`base_enemy.gd`）
- 新增 `_setup_armor_indicator()`：armor > 0 的敵人（坦克、Boss）健康條背景改為藍灰色
- 在健康條右側顯示 🛡 徽章
- 玩家可立即辨識哪些敵人需要非穿甲攻擊

### 劇情

**新增 outro_8 過場劇情**（`story_database.gd`）
- 補完 Level 8 通關後、進入 epilogue 前的橋接劇情
- 內容：Coco 站在源點入口，思考即將到來的最終對決；齒輪爺爺最後叮囑
- 共 7 句，含旁白、COCO、齒輪爺爺三個發言人
- 故事弧線更完整：outro_7（機械迷宮思考）→ **outro_8（源點入口）** → epilogue（最終對決）

**劇情畫面 UX 改善**（`story_screen.gd`）
- `skip_label` 確保顯示「ESC 跳過 / 點擊繼續」
- 加入 portrait null-check 防崩潰

---

---

## 2026-03-17 · Session 17 · 測試腳本擴充

### 測試腳本 (`tests/run_tests.gd`)

**修復 Section 6 — Story Database**
- `required_ids` 補上 `"outro_8"`（Session 16 新增但測試未跟進）

**Section 9 — 難度修正值數學驗證**
- 鏡像 GameManager 的 `DIFFICULTY_GOLD_MULT` / `DIFFICULTY_LIVES_BONUS` 常量
- 驗證 EASY/NORMAL/HARD 三種難度的金幣乘數與生命加成數值
- 邊界測試：極低生命值 + HARD 難度的 `clampi(1, 1, 20)` 保底行為
- 關係驗證：HARD 金幣 < NORMAL 金幣 < EASY 金幣

**Section 10 — 關卡平衡護欄（全 8 關）**
- 每關 starting_gold ≥ 150、starting_lives 在 [5, 20] 範圍內
- 波次數量不得比前一關退步（防止設計回歸）
- 每波敵人總數在 [1, 500] 範圍內

**Section 11 — 成就定義完整性**
- 動態載入 `achievement_manager.gd` 取得 ACHIEVEMENTS 字典（無需 autoload）
- 驗證 10 個成就 ID 全部存在：`first_win`, `iron_defense`, `enemy_100`, `enemy_500`, `builder`, `completionist`, `speedrunner`, `minimalist`, `flawless_5`, `veteran`
- 每個成就須有 `name`、`desc`、`icon` 欄位且不為空

**Section 12 — 塔升級鏈完整性**
- 5 種塔各自的升級資料驗證：`upgrade_cost > 0`，`damage/range/speed_multiplier ≥ 1.0`
- 累積驗證：最高等級傷害與售價必須大於基礎值

測試檔從 427 行擴充至 612 行，共 12 個測試段。

### 其他修正

**`game_manager.gd` 文件註解**
- `start_level()` param 說明從「1–3」更正為「1–8」

---

## 2026-03-17 · Session 18 · 平衡、Bug 修復、難度深化

### 遊戲平衡

**Level 7 & 8 起始資源調整**（`data/levels/level_7.tres`, `level_8.tres`）
- 原問題：Level 7 HARD 模式下起始金 180×0.7=126（不足買第一座塔），Level 8 HARD 模式 8-5=3 條命
- Level 7: starting_lives 10→12, starting_gold 180→220
- Level 8: starting_lives 8→12, starting_gold 160→200
- HARD 下 Level 7 = 154 金（可買弩塔），Level 8 = 140 金，可行但仍具挑戰性

### 難度深化

**敵人生成速度依難度縮放**（`scripts/wave_manager.gd`）
- 新增 `SPAWN_INTERVAL_MULT: Array[float] = [1.25, 1.0, 0.75]`
- EASY：spawn_interval × 1.25（敵人間隔更大，更從容應對）
- HARD：spawn_interval × 0.75（敵人連串湧來，壓力感大增）
- 難度差異從「只是金/命數量不同」升級為「實際戰場節奏也不同」

### Bug 修復

**HUD：波次按鈕在自動開始後未隱藏**（`scripts/ui/hud.gd`）
- 問題：倒計時歸零自動呼叫 `start_next_wave()` 時，「開始波次」按鈕留在畫面上
- 修復：在 `_on_wave_started()` 中加入 `_stop_wave_btn_pulse()` + `next_wave_btn.hide()`
- 現在不管是手動點擊還是倒計時自動開始，按鈕都會正確消失

**金幣動畫 tween 衝突**（`scripts/ui/hud.gd`）
- 問題：快速連續消費金幣（如連放塔）時，多個 tween 同時操作 `gold_label.scale` 導致閃爍
- 修復：加入 `_gold_tween` 引用，每次建立前先 `.kill()` 並重置 scale

### UX 改善

**塔點選半徑擴大**（`scripts/game_world.gd`）
- `dist < 40.0` → `dist < 48.0`（從 0.625 tile 擴大到 0.75 tile）
- 降低誤點選空格的機率，特別是在緊湊佈局下

### 測試腳本

**Section 9 新增 spawn 間隔倍率驗證**（`tests/run_tests.gd`）
- 新增 `SPAWN_INTERVAL_MULT` 三種難度的數值驗證
- 確認 HARD 間隔 < NORMAL < EASY 的排序不變式

---

## 2026-03-17 · Session 19 · 塔平衡大改、冰塔升級系統、UX 優化

### 遊戲性 — 塔平衡

**狙擊塔成本調降**（`data/towers/sniper_tower.tres`）
- build_cost 250→220；升級1 150→120；升級2 280→250（總費用 680→590）
- 早期遊戲狙擊塔不再是天價，讓防止裝甲敵人的選項更易接觸

**Boss 護甲調降**（`data/enemies/boss_enemy.tres`）
- armor 0.35→0.20（35%→20% 傷害減免）
- 原設計迫使玩家必建狙擊塔才能有效對抗 Boss，破壞策略多樣性
- 現在弩塔、砲台、閃電塔也能有效輸出（80% 傷害通過 vs 65%）

### 程式品質 — 冰塔升級系統

**UpgradeData 新增 slow 縮放欄位**（`scripts/resources/upgrade_data.gd`）
- 新增 `slow_factor_mult: float = 1.0`（升級後乘以 slow_factor，使減速更強）
- 新增 `slow_duration_bonus: float = 0.0`（升級後加到 slow_duration）
- 預設值確保既有的其他塔升級資料不受影響

**TowerData 新增 get_slow_factor / get_slow_duration**（`scripts/resources/tower_data.gd`）
- `get_slow_factor(level)`: 累積乘以各升級的 slow_factor_mult
- `get_slow_duration(level)`: 累積加上各升級的 slow_duration_bonus

**冰塔升級資料**（`data/towers/ice_tower.tres`）
- 升級1 「深度冷凍」: slow_factor_mult=0.80（減速至 40% 速度），slow_duration_bonus=0.5（持續2.5秒）
- 升級2 「暴風雪」: slow_factor_mult=0.75（減速至 30% 速度），slow_duration_bonus=1.0（持續3.5秒）
- 修正升級描述：原描述「減速效果更強」但代碼完全沒有 slow 縮放，現在已實現

**冰塔腳本更新**（`scripts/towers/ice_tower.gd`）
- `_on_attack()` 改為 `tower_data.get_slow_factor(current_level)` 和 `get_slow_duration(current_level)`

### UX 優化

**塔面板：「差 N 💰」金幣不足提示**（`scripts/ui/tower_panel.gd`）
- 原設計：只有透明度降至 0.42，玩家難以察覺
- 新設計：費用標籤改顯示「差 N 💰」（紅色），opacity 提升至 0.55
- 玩家一眼可知還缺多少金就能建造

**關卡選擇難度按鈕改良**（`scripts/ui/level_select.gd`）
- 重構：9 個重複三元運算改為 1 個循環
- 選中難度：scale(1.08, 1.08) + 全亮（更明顯的視覺反饋）
- 未選難度：scale(1.0, 1.0) + 較暗（0.55 vs 之前的 0.60）

### 測試腳本

**Section 13 — 塔 DPS 平衡驗證**（`tests/run_tests.gd`）
- 狙擊塔基礎 DPS ≥ 弩塔（穿甲優勢應確保至少等效單體輸出）
- 砲台基礎 DPS > 弩塔（範圍傷害應有更高原始 DPS 補償）
- 冰塔滿升後 slow_factor < 基礎（升級真的使減速更強）
- 冰塔滿升後 slow_duration > 基礎（升級真的延長持續時間）
- Boss 護甲在 [0.10, 0.50] 範圍內（既有挑戰性，又不至於免疫）
- 所有塔對 Boss 的有效傷害 > 基礎傷害的 50%（確保無「廢塔」現象）

---

## 2026-03-17 · Session 20 · 波次預覽、WaveManager 清理、程式品質

### 遊戲性 / UX

**HUD 波次敵人組成預覽**（`scripts/ui/hud.gd`, `scripts/wave_manager.gd`）
- 新功能：「開始波次 N」按鈕顯示時，同步顯示下一波的敵人組成
- 例如：「下一波：👾×12  💨×8  🛡×4」（淡藍色，在波次橫幅下方）
- WaveManager 新增 `get_wave_preview_string(wave_index)` 方法
- WaveManager 新增 `ENEMY_ICONS` 字典：基礎→👾, 快速→💨, 坦克→🛡, BOSS→💀
- HUD 新增 `_wave_preview_label`（動態建立），在 `on_next_wave_ready` 填充，在 `_on_wave_started` 隱藏

### 程式品質 / Bug 修復

**WaveManager 遊戲結束清理**（`scripts/wave_manager.gd`）
- 原問題：遊戲結束後，已排程的 `create_timer` 回調仍會繼續生成敵人
- 修復：連接 `game_over_triggered` 和 `victory_triggered` 訊號到 `_on_game_ended()`
- `_on_game_ended()` 設定 `_game_ended = true`，`_spawn_enemy()` 和 `_check_wave_complete()` 均檢查此旗標

**SniperTower 目標搜索最佳化**（`scripts/towers/sniper_tower.gd`）
- 舊方式：`_enemies_in_range.filter(lambda)` — 每 tick 建立新陣列（GC 分配）
- 新方式：與 BaseTower 一致的向後就地清除（`remove_at()`）— 零 GC 分配
- 同時移除了 `has_method("get_path_progress")` 的多餘檢查（邏輯簡化）

**冰塔減速 SFX**（`scripts/enemies/base_enemy.gd`）
- `apply_slow()` 首次觸發時現在呼叫 `AudioManager.play_slow_applied()`
- 原本 `play_slow_applied()` 方法存在但從未被呼叫

**BaseEnemy 死亡動畫提取**（`scripts/enemies/base_enemy.gd`）
- 從 `_die()` 提取出 `_play_death_animation()` 方法
- `_die()` 從 23 行縮短至 11 行，可讀性更佳
- 分離「遊戲邏輯」（事件發射、金幣加算）和「視覺展示」（動畫）兩個職責

### 測試腳本

**Section 14 — 音效資源存在性驗證**（`tests/run_tests.gd`）
- 7 個必要 SFX 直接存在性檢查（ui_click, sfx_tower_upgrade/sell, sfx_enemy_die 等）
- 5 個備用鏈效果（sfx_enemy_hit/slow_applied/explosion/tower_select/invalid_placement）至少一個變體存在
- 3 個發射音效（shoot_arrow/cannon/ice.wav）存在性檢查
- 總計 767 行，14 個測試段

---

## 2026-03-17 · Session 21 · 難度 HP 縮放、升級預覽、測試擴充

### 難度深化 — 敵人 HP 依難度縮放

**WaveManager 新增 `DIFFICULTY_HP_MULT`**（`scripts/wave_manager.gd`）
- `DIFFICULTY_HP_MULT: Array[float] = [0.80, 1.0, 1.30]`
- EASY：敵人 HP × 0.80（較脆弱，讓新手有容錯空間）
- HARD：敵人 HP × 1.30（敵人更耐打，與更快生成速度形成雙重壓力）
- `_spawn_enemy()` 讀取難度乘數，傳遞給 `enemy.setup(data, waypoints, hp_mult)`

**BaseEnemy.setup() 新增 `health_mult` 參數**（`scripts/enemies/base_enemy.gd`）
- 簽名：`setup(data, waypoints, health_mult: float = 1.0)`
- `current_health = data.max_health * health_mult`
- 預設值 1.0 確保向後相容（任何直接呼叫 setup() 的程式碼不受影響）
- 難度效果：EASY 80HP → NORMAL 100HP → HARD 130HP（以 base_hp=100 為例）

### UX — UpgradePanel 升級後數值預覽

**升級面板顯示下一等級數值**（`scripts/ui/upgrade_panel.gd`）
- 新增動態標籤 `_next_stats_label`（綠色，字體 11px，插入 StatsLabel 下方）
- 升級可用時，顯示「升後：22傷  2.0/s  165射」
- 冰塔額外顯示「減速：50% 2.5s」→「升後：60% 3.0s」等慢效數值
- 最高等級（無法升級）時隱藏預覽標籤
- 現有 StatsLabel 同步補上冰塔當前減速/持續時間（原本只顯示傷害/速度/射程）

### 測試腳本

**Section 15 — 難度 HP 縮放驗證**（`tests/run_tests.gd`）
- 鏡像 `DIFFICULTY_HP_MULT` 常量，驗證 EASY < NORMAL < HARD 排序不變式
- 數值邊界：EASY (0.5, 1.0)、HARD (1.0, 2.0)
- 具體值：EASY=80、NORMAL=100、HARD=130（以 base_hp=100 計算）
- 交叉驗證：HARD = 更多 HP（1.30×）+ 更快生成（0.75 間隔）雙重壓力

**Section 16 — 升級預覽數學驗證**（`tests/run_tests.gd`）
- 5 種塔全部測試：每級傷害 ≥ 前一級，速度 ≥ 前一級（確保升級真的有效）
- 冰塔：每級 slow_factor ≤ 前一級（減速更強），slow_duration ≥ 前一級（更長）
- 每種塔最高等級售價 > 基礎售價（確保 sell_value 正確累積投資金額）
- 總計 16 個測試段

---

## 2026-03-17 · Session 22 · 程式品質重構：重複代碼消除、音頻架構、防禦性保護

### 程式品質 — 難度常量統一

**GameManager 新增 `DIFFICULTY_NAMES` / `DIFFICULTY_COLORS`**（`scripts/autoloads/game_manager.gd`）
- 問題：`game_over.gd`、`victory.gd`、`hud.gd` 三個檔案各自定義相同的 `diff_names/diff_colors` 陣列
- 修復：在 `GameManager` 加入共享常量：
  - `DIFFICULTY_NAMES: Array[String] = ["簡單", "普通", "困難"]`
  - `DIFFICULTY_COLORS: Array[Color] = [綠色, 琥珀色, 紅橙色]`
- `game_over.gd`、`victory.gd`、`hud.gd` 全部改用 `GameManager.DIFFICULTY_NAMES[di]`
- 效益：只需修改一個地方即可調整難度顯示文字或顏色

### 程式品質 — 每關專屬音樂

**LevelData 新增 `music_track_id` 欄位**（`scripts/resources/level_data.gd`）
- 新增 `@export var music_track_id: String = "gameplay"`（預設值維持現有行為）
- `game_world.gd` 改為 `AudioManager.play_track(level_data.music_track_id)`（原為硬編碼 "gameplay"）
- 架構效益：未來添加 Boss 關卡音樂只需在 `.tres` 檔設定，無需修改程式碼
- 注意：`game_world._on_wave_started_music()` 仍在最終波次切換到 "boss" 軌道（原有行為保留）

### 程式品質 — AudioManager SFX 載入統一化

**5 個備用 SFX 從 15 行 if-chain 改為字典循環**（`scripts/autoloads/audio_manager.gd`）
- 原始：針對 enemy_hit/slow_applied/explosion/tower_select/invalid_placement 各自重複 3 次條件判斷
- 改為：`FALLBACK_SFX: Dictionary` 包含各 SFX 的候選路徑陣列，統一用 `_load_first()` 循環載入
- 與 `MUSIC_TRACKS` 使用相同模式，程式碼行數從 15 行降至 8 行（+字典定義）
- 新增候選路徑/格式只需修改字典，不需改邏輯

### Bug 修復 — LightningTower 防禦性保護

**傷害循環加入 `is_instance_valid()` 保護**（`scripts/towers/lightning_tower.gd`）
- 問題：`hit_chain` 中的節點可能在 Arc 建立後、傷害應用前已被釋放（被其他塔殺死）
- 修復：`if is_instance_valid(hit_node) and hit_node.has_method("take_damage")`
- 防止在高戰況下（多塔同時攻擊）出現 freed object 存取錯誤

### 測試腳本

**Section 17 — 難度常量 & 關卡音樂覆蓋率**（`tests/run_tests.gd`）
- 驗證 `GameManager.gd` 源碼包含 `DIFFICULTY_NAMES` 和 `DIFFICULTY_COLORS` 定義
- 驗證 `level_data.gd` 源碼包含 `music_track_id` 欄位定義
- 遍歷全 8 關，確認 `music_track_id` 不為空且為合法音軌 ID
- 驗證 `game_world.gd` 使用 `level_data.music_track_id`（不硬編碼 "gameplay"）
- 總計 17 個測試段

---

## 2026-03-17 · Session 23 · 效能修復、成就系統、程式品質

### 效能修復 — SaveManager 磁碟寫入批次化

**`set_stat_int()` 改為延遲批次寫入**（`scripts/autoloads/save_manager.gd`）
- 原問題：`set_stat_int()` 直接呼叫 `save()`，每次敵人被擊殺都觸發磁碟寫入
- 在高強度波次（100+ 敵人）中，一波可能觸發 100+ 次 `FileAccess.open/write/close`
- 修復：新增 `_save_pending: bool` 旗標 + `_schedule_save()` + `_do_deferred_save()`
- `call_deferred("_do_deferred_save")` 確保同一幀內的所有 stat 更新只觸發 **1 次磁碟寫入**
- 高分、成就解鎖、等級解鎖仍使用即時 `save()`（這些是罕見事件，需要立即持久化）

### 效能優化 — BaseTower `_process()` 跳過

**無砲塔的塔型停用 `_process()`**（`scripts/towers/base_tower.gd`）
- 原問題：Arrow/Cannon/Ice 三種塔每幀執行 `_process()` 只為了執行 `if _turret == null: return`
- 修復：在 `initialize()` 中加入 `set_process(_turret != null)`
- Arrow/Cannon/Ice 三塔：每幀省下一次函式呼叫（無 Turret 節點）
- Lightning/Sniper 兩塔：仍啟用 `_process()`（有 Turret 節點需要旋轉）
- 場景有 15 座塔時，減少 9 個塔的 `_process()` 呼叫

### 遊戲性 — 新成就：鋼鐵意志

**新增 `hard_victor` 成就**（`scripts/autoloads/achievement_manager.gd`）
- 成就：「🔥 鋼鐵意志」—— 在困難難度下完成任意關卡
- 總成就數：10 → **11**
- 觸發條件：`_on_victory()` 中檢查 `GameManager.current_difficulty == Difficulty.HARD`
- 設計意圖：鼓勵玩家嘗試 HARD 模式，提供明確的挑戰獎勵

### 測試腳本

**Section 11 更新**：total achievements == 10 → **11**，`EXPECTED_IDS` 加入 `"hard_victor"`

**Section 18 — 存檔最佳化 & 成就邏輯驗證**（`tests/run_tests.gd`）
- 驗證 `_schedule_save` / `_do_deferred_save` 定義存在於 `save_manager.gd`
- 驗證 `set_stat_int` 呼叫 `_schedule_save()` 而非直接 `save()`
- 驗證 `_save_pending` 旗標已定義
- 驗證 `hard_victor` 成就欄位完整（name/desc/icon）
- 驗證 `_on_victory()` 包含 `hard_victor` 觸發及 `Difficulty.HARD` 條件
- 驗證 `BaseTower` 調用 `set_process(_turret != null)`
- 驗證 `project.godot` 包含 8 個 autoload 且 TutorialManager 已註冊
- 總計 **18 個測試段**

---

## 2026-03-17 · Session 24 · 描述與實作不符修復、鏈式縮放、濺射縮放

### Bug 修復 — 升級描述與實際效果不符

#### 問題一：LightningTower 升級1描述「鏈接跳數+1」但代碼用硬編碼常量

**根因**：`lightning_tower.gd` 使用 `const CHAIN_COUNT := 3`（永不變化），
而 `lightning_tower.tres` 升級1描述「鏈接跳數+1（最多4個）」但實際上 +0。

**修復**（`scripts/resources/upgrade_data.gd`）
- 新增 `@export var chain_bonus: int = 0`（升級時增加的跳數）

**修復**（`scripts/resources/tower_data.gd`）
- 新增 `@export var base_chain_count: int = 0`（基礎跳數，0=不使用）
- 新增 `get_chain_count(level) -> int`：累積各升級的 `chain_bonus`

**修復**（`scripts/towers/lightning_tower.gd`）
- 移除 `const CHAIN_COUNT := 3`
- `_on_attack()` 改為 `tower_data.get_chain_count(current_level)`（tower_data 為 null 時 fallback 3）

**修復**（`data/towers/lightning_tower.tres`）
- 主資源加入 `base_chain_count = 3`
- 升級1加入 `chain_bonus = 1`（升後跳3→4個敵人）

結果：Level 0=3跳，Level 1=4跳，Level 2=4跳（升級2無 chain_bonus）。

---

#### 問題二：CannonTower 升級描述「更大的爆炸範圍」但 splash_radius 永不縮放

**根因**：`cannon_tower.gd` 直接讀 `tower_data.splash_radius`（靜態），
升級後半徑完全不變，與描述矛盾。

**修復**（`scripts/resources/upgrade_data.gd`）
- 新增 `@export var splash_radius_bonus: float = 0.0`（升級時增加的像素半徑）

**修復**（`scripts/resources/tower_data.gd`）
- 新增 `get_splash_radius(level) -> float`：`splash_radius + Σ splash_radius_bonus`

**修復**（`scripts/towers/cannon_tower.gd`）
- `launch_aoe()` 的半徑參數從 `tower_data.splash_radius` → `tower_data.get_splash_radius(current_level)`

**修復**（`data/towers/cannon_tower.tres`）
- 升級1 `splash_radius_bonus = 30.0`（60→90px）；描述補上「(+30px)」
- 升級2 `splash_radius_bonus = 20.0`（90→110px）；描述補上「(+20px)」

### UX — UpgradePanel 顯示鏈式/濺射數值

**`scripts/ui/upgrade_panel.gd`**
- 當前數值欄（`stats_label`）：
  - `base_chain_count > 0` → 顯示「跳數：N」
  - `splash_radius > 0.0` → 顯示「爆炸：NNpx」
- 升後預覽欄（`_next_stats_label`）同樣延伸相同數值

### 測試腳本

**Section 19 — 鏈式跳躍縮放 & 濺射半徑縮放**（`tests/run_tests.gd`）
- 驗證 `UpgradeData` 源碼包含 `chain_bonus` / `splash_radius_bonus` 欄位
- 驗證 `TowerData` 源碼包含 `base_chain_count`、`get_chain_count()`、`get_splash_radius()`
- 驗證 `LightningTower` 使用 `get_chain_count()` 且不再有 `const CHAIN_COUNT`
- 驗證 `CannonTower` 使用 `get_splash_radius()`
- 資源數值驗證：
  - `lightning_tower.tres`：Level0=3跳，Level1=4跳，Level2=4跳
  - `cannon_tower.tres`：Level0=60px，Level1=90px，Level2=110px
- 總計 **19 個測試段**

---

## 2026-03-17 · Session 25 · Bug 修復、Boss HP 條、冰塔 AoE 縮放

### Bug 修復

#### IceTower splash_radius 未隨升級縮放（`scripts/towers/ice_tower.gd`）
- **問題**：`ice_tower.gd` 直接讀 `tower_data.splash_radius`（靜態欄位），
  而 Upgrade2「暴風雪」描述「範圍大幅擴大」但實際半徑永不增加
- **修復**：改用 `tower_data.get_splash_radius(current_level)`（與 CannonTower 一致）
- **`ice_tower.tres`**：
  - Upgrade1「深度冷凍」新增 `splash_radius_bonus = 20.0`（40→60px）
  - Upgrade2「暴風雪」新增 `splash_radius_bonus = 40.0`（60→100px）
  - 升級描述補上尺寸 (+20px / +40px)
- **結果**：IceTower 全升後 AoE 由 40px 擴大至 100px，實現「暴風雪」的命名承諾

#### HUD 波次標籤偏移（`scripts/ui/hud.gd`）
- **問題**：`on_next_wave_ready()` 中 `_wave_num = wave_number - 1`，
  導致等待第 1 波時標籤顯示「波次: 0/5」，玩家困惑
- **修復**：改為 `_wave_num = wave_number`，按鈕「開始波次 1 ▶」與標籤「波次: 1/5」同步一致

#### GameWorld 關卡資料型別驗證（`scripts/game_world.gd`）
- **問題**：`load(level_res_path)` 若載入了錯誤類型資源，只檢查 `== null`，會在後續屬性存取時崩潰
- **修復**：改為 `if level_data == null or not level_data is LevelData:`，附完整錯誤訊息

### 新功能 — Boss HP 條

**設計**：Boss 出現時，HUD 頂部中央顯示一個寬 440px、高 22px 的血量條，
隨 Boss 受擊實時更新，Boss 死亡 1.5 秒後自動隱藏。

**血條顏色語義**：
- > 60%：深紅色（正常）
- 30-60%：橘色（危險）
- < 30%：亮紅色（垂死）

**實作**：
- `event_bus.gd`：新增 `signal boss_spawned(boss: Node)` 和 `signal boss_health_changed(current_hp: float, max_hp: float)`
- `base_enemy.gd`：新增 `_max_health: float = 0.0`，在 `setup()` 中設定
- `boss_enemy_scene.gd`：
  - 新增 `func setup()` override → 呼叫 super 後 emit `boss_spawned(self)`
  - 新增 `func take_damage()` / `take_damage_piercing()` overrides → 呼叫 super 後 emit `boss_health_changed`
- `hud.gd`：
  - 新增 `_build_boss_bar()` — 動態建立 Control + ColorRect + Label，預設隱藏
  - `_on_boss_spawned(boss)` — 顯示血條、重置至 100%
  - `_on_boss_health_changed(current, max)` — 平滑縮放 fill 寬度、更新顏色和百分比文字

### 視覺改善 — 減速浮動文字

**`scripts/enemies/base_enemy.gd`**：`apply_slow()` 中，敵人「第一次被減速」時，
除了音效外，新增產生 `❄` 藍色浮動文字，讓玩家清楚看到冰塔命中效果。

### 測試腳本

**Section 20 — Session 25 修復驗證**（`tests/run_tests.gd`）
- IceTower `get_splash_radius()` 各級數值（40→60→100px）
- IceTower 腳本不再直接存取靜態 `tower_data.splash_radius`
- HUD `on_next_wave_ready()` 不含 `wave_number - 1`
- HUD 包含 `_build_boss_bar`、`_on_boss_spawned`、`_on_boss_health_changed`
- EventBus 包含 `boss_spawned`、`boss_health_changed` 信號定義
- BossEnemy 含 setup/take_damage/take_damage_piercing override 及 emit 呼叫
- BaseEnemy 追蹤 `_max_health` 且 `apply_slow()` 包含 ❄ 文字
- GameWorld 含 `is LevelData` 型別驗證
- 總計 **20 個測試段**

---

## 2026-03-17 · Session 26 · 遊戲性改善、Bug 修復、程式碼品質

### 新遊戲性功能 — 波次完成金幣獎勵

**設計**：每完成一個非最終波次，玩家獲得 25 金幣獎勵（含 HUD 訊息提示）。
- 鼓勵積極進攻風格，讓塔的建造更流暢
- Level 8 共 8 個非最終波次 = 200 額外金幣，有效緩解後期資源壓力

**實作**：
- `event_bus.gd`：新增 `signal wave_bonus_awarded(amount: int)`
- `wave_manager.gd`：新增 `const WAVE_BONUS_GOLD := 25`；在 `_check_wave_complete()` 非最終波次分支呼叫 `GameManager.add_gold(WAVE_BONUS_GOLD)` + emit `wave_bonus_awarded`
- `hud.gd`：連接 `wave_bonus_awarded`，顯示「波次完成！ +25 💰」訊息

### Bug 修復

#### WaveManager `_on_game_ended()` 未重置 `_countdown`（`wave_manager.gd`）
- **問題**：遊戲結束時 `_counting_down` 設為 false，但 `_countdown` 仍保留正值。若有程式碼直接讀取 `_countdown`（例如 HUD 或未來功能），會得到過時數值
- **修復**：在 `_on_game_ended()` 末尾加入 `_countdown = -1.0`

#### Victory screen 冗餘 null 檢查（`scripts/ui/victory.gd`）
- **問題**：`if _diff_label != null:` — `_diff_label` 在 `_ready()` 中建立，永遠不為 null，此條件具有誤導性
- **修復**：移除冗餘 null guard，直接操作 `_diff_label`

#### game_manager.gd 文件錯誤（`scripts/autoloads/game_manager.gd`）
- **問題**：`current_level_id` 的文件說明「1–3」，但關卡已擴展至 8 個
- **修復**：更正為「1–8」

#### SceneManager 靜默略過缺失故事（`scripts/autoloads/scene_manager.gd`）
- **問題**：`goto_level()` 在沒有 story_N 時靜默跳過，無任何通知，調試困難
- **修復**：加入 `push_warning()` 告知開發者哪個關卡缺少劇情

### 程式碼品質

#### CannonProjectile 魔法數字（`scripts/projectiles/cannon_projectile.gd`）
- `collision_mask = 2` → 定義為 `const ENEMY_COLLISION_LAYER := 2` 並在查詢中引用
- 與 Physics Layers 設定的語意連結更清晰

#### WaveManager 狀態機文件（`scripts/wave_manager.gd`）
- 在檔案頂部加入 ASCII 狀態機圖示，說明 setup→countdown→wave→complete 的完整流程

### 平衡調整 — Level 8 終局波次縮減

**問題**：Wave 9（最終決戰）原有 50 基本 + 40 快速 + 28 坦克 + 10 Boss = 128 個敵人，
在 HARD 模式下 200 金 + 12 命的起始資源下幾乎無法通關。

**調整後**：
| 敵人 | 舊 | 新 |
|---|---|---|
| 基本 | 50 | 35 |
| 快速 | 40 | 28 |
| 坦克 | 28 | 18 |
| Boss | 10 | 6（間隔 4.5s，略變） |
| **合計** | **128** | **87** |

仍然是極具挑戰性的關卡，但不再接近「無解」。

### 測試腳本

**Section 21 — Session 26 修復驗證**（`tests/run_tests.gd`）
- WaveManager 含 WAVE_BONUS_GOLD、add_gold 呼叫、wave_bonus_awarded emit
- WaveManager `_on_game_ended()` 含 `_countdown = -1.0`
- EventBus `wave_bonus_awarded` 定義
- HUD 連接 `wave_bonus_awarded` + `_on_wave_bonus_awarded` 函式
- CannonProjectile 不含魔法數字 `collision_mask = 2`
- Level 8 Wave 9 總敵人數 ≤ 90
- SceneManager 含 `push_warning` for missing story
- Victory.gd 無冗餘 null guard
- 總計 **21 個測試段**

---

## 2026-03-17 · Session 27 · Bug 修復三連

### 問題修復

**Bug 1 — Boss HP 血條顏色反轉（`scripts/ui/hud.gd`）**

`_on_boss_health_changed()` 中的顏色邏輯被寫反了：
- **舊**：`pct > 0.6` → 顯示紅色 `Color(0.85, 0.15, 0.15)`（血量高時紅色！）
- **新**：`pct > 0.6` → 綠色 `Color(0.25, 0.80, 0.25)` → 琥珀色 → 紅色

玩家現在能直觀地看到 Boss 的危險程度。

---

**Bug 2 — Boss 衝刺後無視緩速效果（`scripts/enemies/boss_enemy_scene.gd`）**

Boss 衝刺結束後強制將 `_speed_multiplier` 歸回 `1.0`，忽略了正在生效的冰塔緩速：
- **修復**：新增 `_pre_charge_speed` 變數。衝刺前儲存，衝刺後還原。
- 效果：Boss 被冰塔減速後再衝刺，衝刺結束仍維持減速狀態。

```gdscript
# 衝刺前：
_pre_charge_speed = _speed_multiplier
_speed_multiplier = CHARGE_MULTIPLIER
# 衝刺後：
_speed_multiplier = _pre_charge_speed  # 保留緩速效果
```

---

**Bug 3 — 塔板允許金幣不足時啟動放塔（`scripts/ui/tower_panel.gd`）**

玩家點擊負擔不起的塔時，仍進入放置模式（遊戲內邏輯雖不允許放塔，但 UX 不佳）：
- **修復**：在 `_on_tower_button_pressed()` 前置金幣檢查，若不足立即播放 `play_invalid_placement()` 並 return。

---

### 測試腳本

**Section 22 — Session 27 修復驗證**（`tests/run_tests.gd`）
- HUD boss 血條含 `Color(0.25, 0.80, 0.25)`（綠色）
- HUD boss 血條高血量段不含 `Color(0.85, 0.15, 0.15)`（舊紅色）
- BossEnemy 含 `_pre_charge_speed` 變數
- BossEnemy 儲存、還原 `_pre_charge_speed`
- BossEnemy 衝刺後不再硬寫 `_speed_multiplier = 1.0`
- TowerPanel 含 `can_afford` 檢查
- TowerPanel 含 `play_invalid_placement` 呼叫
- 總計 **22 個測試段**

---

## 2026-03-17 · Session 28 · 四項 Bug 修復

### 問題修復

**Bug 1 — 血條在 HARD 難度顯示錯誤（`scripts/enemies/base_enemy.gd`）**

`_update_health_bar()` 用 `enemy_data.max_health`（原始數值）計算比率，而非
`_max_health`（套用難度倍率後的實際最大血量）：

- **HARD 難度**：敵人血量 × 1.30，但血條仍以原始值校準 → 血條初始顯示超過 100%
- **修復**：改為 `current_health / maxf(_max_health, 1.0)`

---

**Bug 2 — 波次 2 之後無法「提前開始」下一波（`scripts/wave_manager.gd`）**

`next_wave_ready` 信號只在 `setup()` 時發射一次（波次 1）。波次 2+ 完成後
`_check_wave_complete()` 啟動倒數計時，但不發射 `next_wave_ready`，導致
「開始波次 N」按鈕永遠不會再出現：

- **症狀**：玩家波次 1 後必須等完整的 15 秒倒數，無法手動跳過
- **修復**：在 `_check_wave_complete()` 的非最後一波分支末尾加上：
  ```gdscript
  next_wave_ready.emit(_current_wave_index + 2, _waves.size())
  ```

---

**Bug 3 — 出售確認超時無視覺回饋（`scripts/ui/upgrade_panel.gd`）**

確認出售按鈕的 2.5 秒窗口關閉時，按鈕靜默重設，玩家不清楚需要多快再按：

- **修復**：在 `_process()` 中於確認期間更新按鈕文字，顯示倒數秒數：
  ```
  確認出售？(2)
  +150 💰
  ```

---

**Bug 4 — 升級按鈕不隨金幣更新（`scripts/ui/upgrade_panel.gd`）**

選中一座塔後，如果金幣增加（敵人被殺）到足夠升級的金額，升級按鈕仍保持灰色，
需要重新點擊塔才能刷新：

- **修復**：`_ready()` 連接 `EventBus.gold_changed` → `_on_gold_changed()`，
  即時更新升級按鈕的可用/不可用狀態及顏色

---

### 測試腳本

**Section 23 — Session 28 修復驗證**（`tests/run_tests.gd`）
- BaseEnemy `_update_health_bar` 使用 `_max_health`（非 `enemy_data.max_health`）
- WaveManager 在 `_check_wave_complete` 中為後續波次發射 `next_wave_ready`
- UpgradePanel `_process` 在確認期間顯示倒數秒數
- UpgradePanel 連接 `gold_changed` 且有 `_on_gold_changed` 處理器
- 總計 **23 個測試段**

---

## 2026-03-17 · Session 29 · 雙重死亡修復 + 瞄準修正

### 問題修復

**Bug 1 — 雙重死亡（`scripts/enemies/base_enemy.gd`）**

狙擊塔（瞬間命中）在敵人進入死亡動畫期間仍可再次命中，觸發 `_die()` 第二次：
- **症狀**：玩家獲得雙倍金幣、雙倍分數、重複音效、重複浮動文字
- **修復**：新增 `_is_dead: bool = false` 旗標
  - `take_damage()` / `take_damage_piercing()` 開頭檢查並提前 return
  - `_die()` 最開頭檢查並提前 return，然後立刻設 `_is_dead = true`

```gdscript
func _die() -> void:
    if _is_dead:
        return
    _is_dead = true
    ...
```

---

**Bug 2 — 各塔對死亡中的敵人仍繼續瞄準（`scripts/towers/base_tower.gd`、`sniper_tower.gd`）**

`remove_from_group("enemies")` 只移除群組成員；敵人仍留在 `_enemies_in_range` 直到 `queue_free()`。各塔在每次攻擊時清除 `is_instance_valid() == false` 的條目，但死亡動畫期間節點仍然有效：
- **修復**：`BaseTower._get_best_target()` 和 `SniperTower._get_best_target()` 中增加 `if enemy.get("_is_dead") == true: continue`

---

**改進：瞄準效率（`scripts/towers/sniper_tower.gd`）**

舊版 `enemy.get("current_health")` 在同一行呼叫兩次（null check + 取值）：
- **修復**：快取 Variant，再轉型 float，單次呼叫

---

**改進：缺少 SFX 時改為 `push_warning`（`sniper_tower.gd`、`lightning_tower.gd`）**

原本靜默忽略缺失的音效檔，開發時難以偵錯：
- **修復**：`else: push_warning("SniperTower: SFX not found at '%s'")`

---

### 測試腳本

**Section 24 — Session 29 修復驗證**（`tests/run_tests.gd`）
- BaseEnemy 含 `_is_dead` 旗標 + `_die()` / `take_damage()` 正確防守
- BaseTower `_get_best_target` 跳過 `_is_dead` 敵人
- SniperTower 跳過 `_is_dead` 敵人、單次 HP get、含 `push_warning`
- LightningTower 含 `push_warning`
- 總計 **24 個測試段**

---

## 2026-03-17 · Session 30 · 穩定性與平衡調整

### 問題修復

**Bug 1 — StoryScreen 缺少空值防護（`scripts/ui/story_screen.gd`）**

`_show_entry()` 和 `_process()` 直接訪問 `dialogue_text`、`continue_label`、`speaker_label`，若節點缺失（場景重命名或誤刪）會立即崩潰：
- **修復 1**：`_show_entry()` 開頭加入 `dialogue_text == null` 聯合檢查；缺失時呼叫 `SceneManager.story_complete()` 並記錄 `push_error()`
- **修復 2**：`_process()` 開頭加入相同防護，避免每幀崩潰
- **修復 3**：`progress_label.text` 加入 `if progress_label != null:` 包裝

---

**Bug 2 — FactoryBase 煙霧相位無限累積（`scripts/factory_base.gd`）**

`_smoke_phase` 每幀不斷增加，長時間遊戲後浮點精度下降，煙霧動畫可能抖動：
- **修復**：改為 `fmod(_smoke_phase + delta * 0.8, 63.0)`（63 = 2.1 × 3 × 10，30 個完整週期後重置，視覺上無縫）

---

**改進：存檔備份與恢復（`scripts/autoloads/save_manager.gd`）**

原本若 `save()` 寫入途中中斷（磁碟滿、程式崩潰），`save_data.json` 可能損壞，玩家失去所有進度：
- **新增**：`save()` 每次先將現有 `save_data.json` 複製為 `save_data.json.bak`
- **新增**：`load_data()` 在主存檔損壞時嘗試從 `.bak` 恢復，記錄 `push_warning()`

---

**改進：關卡 3 難度曲線（`data/levels/level_3.tres`）**

關卡 2→3 從 15 命 / 175 金跌至 10 命 / 150 金，同時敵人數增加 47%（含首個 Boss），難度躍升過大：
- **調整**：`starting_lives` 10 → **12**，`starting_gold` 150 → **165**
- 仍比關卡 2 更難（12 vs 15 命，更多波次和 Boss），但不再讓新玩家遭遇「資源懸崖」

---

### 測試腳本

**Section 25 — Session 30 修復驗證**（`tests/run_tests.gd`）
- StoryScreen `_show_entry` / `_process` 含 null 防護
- FactoryBase smoke phase 使用 `fmod`
- SaveManager `save()` 建立 `.bak`，`load_data()` 含備份恢復邏輯
- Level 3 starting_lives ≥ 12，starting_gold ≥ 160
- 總計 **25 個測試段**

---

## 2026-03-17 · Session 31 · 四個潛在 Bug 修復

### 問題修復（程式碼審查發現）

**Bug 1 — WaveManager 重複發送 next_wave_ready 信號（scripts/wave_manager.gd）**

Session 28 補充「波次間 Start Wave 按鈕」功能時，複製貼上錯誤導致 next_wave_ready.emit() 在同一 _check_wave_complete() 分支中被呼叫兩次：
- 影響：HUD 收到兩次信號，next_wave_btn 的脈衝 Tween 被重啟，按鈕閃爍兩次
- 修復：刪除重複的第二行 next_wave_ready.emit()

---

**Bug 2 — BaseTower 放置後立即攻擊（scripts/towers/base_tower.gd）**

_ready() 呼叫 attack_timer.start() 不帶參數，導致塔放置後第一個冷卻周期未滿就攻擊（免費第一擊）：
- 影響：玩家剛放好塔就立刻射出一發，與後續節奏不一致
- 修復：改為 attack_timer.start(attack_timer.wait_time) 明確指定第一次等待時間

---

**Bug 3 — HUD 波次標籤在第一波開始前顯示空白（scripts/ui/hud.gd）**

_ready() 初始化其他 HUD 標籤但遺漏了 wave_label，直到 Wave 1 開始才顯示波次資訊：
- 修復：在 _ready() 載入 LevelData 時同時讀取 waves.size() 設定 _wave_total，初始化為「波次: 0 / N」

---

### 測試腳本

**Section 26 — Session 31 修復驗證**（tests/run_tests.gd）
- WaveManager next_wave_ready inter-wave emit 恰好出現一次（無重複）
- BaseTower attack_timer.start 帶 wait_time 參數，不存在裸 .start()
- HUD _ready 包含波次標籤初始化
- 總計 **26 個測試段**

---

## 2026-03-18 · Session 32 · UX 打磨 + 程式碼品質

### 改進：範圍預覽圓圈視覺反饋（scripts/game_world.gd）

放置塔時，範圍圓圈懸停在無法建造的格子上仍顯示綠色，給玩家錯誤資訊：
- **新增**：`_range_preview_valid: bool` 成員變數，每幀根據 `can_build(tile)` 更新
- **改進**：draw lambda 根據 `_range_preview_valid` 選擇顏色：綠色（可建造）vs 紅橙色（封鎖）
- **效果**：玩家可立即知道是否能在當前位置建塔，無需等到點擊後才收到錯誤提示

### 改進：塔選擇半徑常數化（scripts/game_world.gd）

硬編碼的 `48.0` 散落在程式碼中，不易維護：
- **新增**：`const TOWER_SELECT_RADIUS := 48.0`
- `_try_select_tower()` 改用常數替代裸數字

### 修復：HUD 訊息被覆蓋問題（scripts/ui/hud.gd）

波次完成 `+25 💰` 訊息、「金幣不足！」等可能互相覆蓋：
- **新增**：`_message_queue: Array[String]`（上限 3 筆）
- `show_message()` 在有訊息顯示時改為入隊而非直接覆蓋
- `_process()` 在計時器歸零後自動播放下一則佇列訊息

### 修復：UpgradePanel 使用 is_instance_valid（scripts/ui/upgrade_panel.gd）

`_process()` 的出售確認計時器使用 `!= null` 而非 `is_instance_valid()`，若塔在確認視窗期間被外部刪除可能存取無效物件：
- `_process()` sell confirm 改用 `is_instance_valid(_current_tower)`
- `_on_upgrade_pressed()` 同步改用 `not is_instance_valid(_current_tower)`
- `_on_sell_pressed()` 第一次按下時也同步更新

### 新功能：waves_cleared 統計（save_manager.gd + game_world.gd）

`wave_completed` 信號存在但從未被使用（死信號）：
- **SaveManager** `_default_data()` 新增 `"waves_cleared": 0` 統計
- **GameWorld** 連接 `EventBus.wave_completed` → 每次波次完成後呼叫 `SaveManager.set_stat_int("waves_cleared", ...)`
- 舊存檔透過 `_migrate_data()` 自動補 0 初始值

### 測試腳本

**Section 27 — Session 32 修復驗證**（tests/run_tests.gd）
- GameWorld TOWER_SELECT_RADIUS 常數 + dist < TOWER_SELECT_RADIUS 使用
- GameWorld _range_preview_valid 旗標 + 顏色分支
- GameWorld wave_completed 連接到 waves_cleared
- UpgradePanel is_instance_valid 使用（_process + _on_upgrade_pressed）
- HUD _message_queue 陣列 + append + pop_front + 上限 3
- SaveManager waves_cleared 在預設統計中
- 總計 **27 個測試段，1309 項全通過**

*最後更新：2026-03-18*
*維護：開發者 + Claude Code*
