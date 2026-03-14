# 音樂檔案放置說明

將授權音樂檔案（`.ogg` 格式）放在此資料夾即可自動載入。

## 需要的檔案

| 檔名 | 場景 | 風格建議 |
|------|------|----------|
| `music_menu.ogg` | 主選單 | 輕鬆、神秘、帶齒輪機械感 |
| `music_gameplay.ogg` | 遊玩中（一般波次） | 緊張、節奏穩定 |
| `music_boss.ogg` | 最終波次（Boss 戰） | 強烈、史詩、情緒化 |
| `music_victory.ogg` | 勝利畫面 | 溫暖、充滿希望 |
| `music_story.ogg` | 劇情對話畫面 | 柔和、鋼琴或環境音 |

## 推薦免費音樂來源（CC0 / CC BY）

- **OpenGameArt**: https://opengameart.org
  - 搜尋 "tower defense music"、"strategy game bgm"
- **Free Music Archive**: https://freemusicarchive.org
- **Zapsplat**: https://www.zapsplat.com（需免費帳號）
- **Incompetech (Kevin MacLeod)**: https://incompetech.com（CC BY 4.0）

## 轉檔指令（mp3 → ogg，需安裝 ffmpeg）

```bash
ffmpeg -i input.mp3 -c:a libvorbis -q:a 4 music_menu.ogg
```

## 注意事項

- 檔案不存在時 AudioManager 會靜默忽略，不影響遊戲運作
- 建議 bitrate 128kbps，檔案大小控制在 5MB 以內
- 音樂需設定為循環播放（Godot 會自動循環 AudioStreamPlayer）
