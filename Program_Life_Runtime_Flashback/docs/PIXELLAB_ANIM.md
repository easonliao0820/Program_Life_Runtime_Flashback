# PixelLab 生圖指南：動態背景、角色立繪

這份文件說明怎麼在 PixelLab 生**會動的東西**和**還缺的立繪**。
靜態背景、CG 的 prompt 在 [IMAGE_TODO.md](IMAGE_TODO.md)、[CG_PROMPTS.md](CG_PROMPTS.md)，PixelLab 的基本欄位設定在 [IMAGE_PROMPTS.md](IMAGE_PROMPTS.md) 的「用 PixelLab 生圖」一節。

> **檔名照下面的表放進指定資料夾，遊戲就會自動播放，不用改程式。** 沒放的就維持靜態圖。

---

## 0. 遊戲支援的三種「會動」

| 種類 | 檔名、位置 | 格式 | 適合 |
|---|---|---|---|
| **A. 背景小動畫**（最推薦） | `assets/backgrounds/fx/<名稱>.png` | 一列橫排、每格**正方形**、**去背** | 蒸氣、香煙、窗簾、灰塵、落葉。背景本身不動，只疊一個小動畫上去 |
| **B. 整張背景動畫** | `assets/backgrounds/<背景>_anim.png` | 一列橫排、每格 **16:9**（例如 640×360 一格） | 捷運車廂窗外隧道燈閃過、湖面波光這類「整張畫面都在變」的 |
| **C. 角色眨眼** | `assets/characters/<角色>_blink.png`<br>（有表情：`<角色>_<表情>_blink.png`） | 一列橫排、每格 **1:2**（跟現在的立繪一樣 128×256） | 只做眨眼，不做整身擺動 |

- **一列橫排**的意思是：第 1 格、第 2 格、第 3 格……從左排到右，排成一張長條圖。
- 三種都可以只放一部分，沒放的就是靜態圖，不會壞。
- 優先順序：背景有 `.ogv` 影片就播影片 → 沒有影片但有 `_anim.png` 就播動畫 → 都沒有才用靜態 `.png`。
- 夜晚、傍晚這類「調色變出來」的背景（例如 `dorm_night`）會自動沿用白天那張的動畫和小動畫，也會一起調色。

### PixelLab 匯出的格式不對怎麼辦

PixelLab 可能匯出成 GIF、一張張分開的 PNG，或是好幾列的 sheet。用專案裡的小工具轉成一列就好（需要 Pillow：`pip3 install pillow`）：

```bash
# GIF → 一列
python3 tools/make_sheet.py steam.gif -o assets/backgrounds/fx/steam.png

# 分開的 PNG（照播放順序）→ 一列；--pingpong 會自動接上倒著播（1 2 3 4 3 2），來回擺動的東西很好用
python3 tools/make_sheet.py c1.png c2.png c3.png c4.png --pingpong -o assets/backgrounds/fx/curtain.png

# 多列 sheet（例如 4 欄 2 列）→ 一列
python3 tools/make_sheet.py export.png --grid 4x2 -o assets/backgrounds/fx/birds.png

# 每格大小不一樣時，統一縮放（最近鄰，不會糊）
python3 tools/make_sheet.py a.png b.png --size 128x256 -o assets/characters/倖芳_blink.png
```

---

## 1. PixelLab 怎麼做動畫

PixelLab 的動畫工具（例如 *Animate with text*、*Animate with skeleton*）比較擅長**小尺寸的物件**，可用的尺寸和工具名稱會隨方案與版本不同，以 PixelLab 介面上看到的為準。所以：

- **小動畫（A）**：直接用動畫工具生，畫布設 **64×64**（大一點的東西用 128×128，如果你的方案允許）。
- **整張背景（B）、角色眨眼（C）**：畫面太大，動畫工具通常做不好。改用 **「Inpaint（局部重畫）」做幾張不同的格子**，再用 `tools/make_sheet.py` 拼起來。3～6 格就很夠了，像素風的動畫本來就是少少幾格。

### 小動畫共同設定（A）

| 欄位 | 填什麼 |
|---|---|
| 工具 | Animate with text（或你方案裡的文字生動畫工具） |
| 畫布 | 64×64（正方形） |
| 格數 | 4～8 格 |
| Remove background／透明背景 | **打開**（一定要真的透明，不能是灰白格子） |
| View | `side` |
| Style image | 上傳要疊上去的那張背景，顏色才會一致 |

每個小動畫的 Description 開頭先貼這行：

```
seamless looping animation, transparent background, isolated effect only, no ground, no frame, soft pixel art,
```

### Inpaint 做格子的流程（B、C）

1. 把原圖（背景或立繪）載入 PixelLab 編輯器。
2. 複製成第 2 張，用 Inpaint 只框要變的地方（例如窗戶、眼睛），描述寫「變成什麼樣」。
3. 重複做出第 3、4 張。**其他地方一個像素都不要動**，不然播起來會整張閃。
4. 照播放順序用 `tools/make_sheet.py` 拼成一列。

---

## 2. 背景小動畫清單（A）— 放 `assets/backgrounds/fx/`

位置已經在 `src/game/core/chapter_registry.gd` 的 `BG_FX` 設好，**放對檔名就會出現在正確位置**。
同一張小動畫可以用在好幾個場景（例如 `steam` 早餐店、便利商店、熱炒店都會用）。

| 檔名 | 用在 | 格數 | 接在共同開頭後面的 Description |
|---|---|---|---|
| `steam.png` | 早餐店煎台、便利商店茶葉蛋、熱炒店火鍋 | 6～8 | `thin wisps of white steam rising and curling upward from a hot pan, semi-transparent, fading out at the top` |
| `incense_smoke.png` | 文昌帝君廟香爐（白天、夜晚都會用） | 6～8 | `thin grey incense smoke rising in a slow wavy line, curling and fading at the top, calm and sacred mood` |
| `crt_flicker.png` | 客廳的舊電視螢幕 | 4 | `the glowing screen of an old CRT television, faint scanlines, subtle brightness flicker, bluish light` |
| `curtain.png` | 高中房間、大學宿舍的窗簾（宿舍那邊會左右翻轉） | 4（用 `--pingpong`） | `a light teal fabric curtain hanging from a rod, gently swaying in a soft breeze, side view` |
| `iv_drip.png` | 病房點滴 | 4 | `a hospital IV drip bag with a small clear drop falling into the drip chamber, simple, clinical` |
| `falling_leaves.png` | 畢業典禮的大樹 | 8 | `a few green and yellow leaves slowly falling and fluttering down from a tree, sparse, gentle` |
| `water_shimmer.png` | 湖邊夕陽的水面反光 | 4 | 畫布改 **128×32**（橫長）：`sparkling golden sunset reflections on calm lake water, horizontal glints twinkling` |
| `birds.png` | 湖邊夕陽的天空 | 6 | `two small dark birds silhouettes flapping wings, flying together in the evening sky` |

> 生好放進去之後，如果位置或大小跟背景對不上，改 `BG_FX` 裡的 `pos`（中心點，0～1）和 `h`（高度佔背景的比例）就好。
> ⚠️ 背景之後重生成 16:9 時，裡面的煎台、香爐位置會變，`BG_FX` 也要跟著重對。

---

## 3. 整張背景動畫（B）— 放 `assets/backgrounds/`

只挑「真的整張都會動」的場景做，其他用小動畫就夠了。**每格一定要 16:9**（建議 640×360），不然遊戲會切錯格。
先照 [IMAGE_PROMPTS.md](IMAGE_PROMPTS.md) 生出 16:9 的靜態圖，再用 Inpaint 做出其他格。

| 檔名 | 格數 | Inpaint 框哪裡 | 每一格的描述 |
|---|---|---|---|
| `mrt_car_anim.png` | 4 | 車門窗戶、車窗 | 第 1 格原圖（窗外黑色隧道）；第 2～4 格：`a bright white tunnel light streak passing outside the train window, motion blur lines`，光帶的位置從右往左移 |
| `lake_sunset_anim.png` | 4 | 湖面 | `calm lake water with golden sunset sparkles`，每格的波光位置不一樣；**天空、樹、長椅都不要框** |
| `star_sky_anim.png` | 4 | 只框幾顆星星 | `twinkling stars, some brighter, some dimmer`（沒有這張的話遊戲本來就會畫星星，可以最後再做） |

> 有 `lake_sunset_anim.png` 的話，`lake_dawn`（清晨）也會自動用它調色播放。
> 想要更流暢可以改做影片 `<背景>.ogv`（Godot 只吃 .ogv），但檔案會大很多。

---

## 4. 角色立繪 — 放 `assets/characters/`

規格：**128×256、去背 PNG、腰上半身**。PixelLab 設定：畫布 128×256、Remove background **打開**。

### 4.1 還可以補的立繪（選做）

| 檔名 | 用在 | Init image | Description |
|---|---|---|---|
| `老闆娘_老年.png` | 5.1「阿姨老了許多」（沒有這張時先用一般版） | `老闆娘.png`（強度中等偏高） | `the same breakfast shop owner, now in her 60s, greying hair under the same green floral headscarf, more wrinkles, same apron and spatula, same warm smile, crisp clean pixels, transparent background` |

### 4.2 角色眨眼（選做）

> ⚠️ 只做**眼睛**的眨眼。不要做整個人的呼吸／擺動循環：AI 生的每一格整個人會偏移 1～3 像素，播起來像在抖。

做法：拿現有立繪，用 Inpaint **只框眼睛**，做出「半閉」和「閉眼」兩張，再拼起來：

```bash
python3 tools/make_sheet.py 倖芳.png 倖芳_半閉.png 倖芳_閉.png 倖芳_半閉.png -o assets/characters/倖芳_blink.png
```

| Inpaint 描述 | 用途 |
|---|---|
| `same face, eyes half closed, same eyelashes and eye color` | 第 2、4 格 |
| `same face, eyes fully closed, relaxed eyelids` | 第 3 格 |

- 存成 `<角色>_blink.png`。**第 1 格一定要是睜眼**：遊戲大部分時間停在第 1 格，每 2.5～5 秒才播一輪。
- 有表情的版本也可以做，例如 `翊丞_臉紅_blink.png`。

---

## 5. 檢查清單（都是選做）

**小動畫**（`assets/backgrounds/fx/`）
- [ ] `steam` — 早餐店、便利商店、熱炒店都會用，最划算，先做這張
- [ ] `incense_smoke`
- [ ] `crt_flicker`
- [ ] `curtain`
- [ ] `iv_drip`
- [ ] `falling_leaves`
- [ ] `water_shimmer`
- [ ] `birds`

**整張背景動畫**（`assets/backgrounds/`）
- [ ] `mrt_car_anim`
- [ ] `lake_sunset_anim`
- [ ] `star_sky_anim`

**立繪**（`assets/characters/`）
- [ ] `老闆娘_老年`
- [ ] 眨眼：`倖芳`、`翊丞`……出場最多的先做
