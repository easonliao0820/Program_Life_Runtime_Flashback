# 還缺的圖（2026-11-13 對過劇本與資料夾）

每一格灰框已經把「共同風格」接好了，**整格複製貼給生圖 AI 就好**。
生好之後照檔名放進指定資料夾，遊戲會自動換掉佔位圖，不用改程式。
詳細說明（尺寸、PixelLab 設定）見 [IMAGE_PROMPTS.md](IMAGE_PROMPTS.md)。

| 類別 | 資料夾 | 還缺 |
|---|---|---|
| 背景 | `assets/backgrounds/` | 4 張（`photo_room` ＋ 快轉用 `school`、`library`、`cafe`，後三張可改一支影片） |
| CG | `assets/cg/` | 12 張（資料夾目前是空的） |
| 立繪 | `assets/characters/` | 4 張：`倖芳_老年`、`媽媽_老年`、`爸爸_老年`、`翊丞_臉紅`（基本立繪 8 張＋面試官已放好） |

> ⚠️ 現有的 19 張背景全部是 **512×512 正方形**，遊戲會裁成 16:9，上下大約各切掉 22%。
> 不急，但之後有空可以用 Outpaint／擴展畫面往左右延伸成 16:9。新生的圖請直接用 16:9。

---

## 一、背景（4 張）— 放 `assets/backgrounds/`，16:9 橫向

### `photo_room.png`（5.4 整理舊照片）

```
Wide landscape image, 16:9 aspect ratio (1920x1080), full panoramic establishing shot,
camera pulled far back at standing eye level, the ENTIRE space visible from the left wall
to the right wall and from the ceiling down to the floor, the floor clearly visible and
filling the bottom third of the image, no close-up, no fisheye.
Pixel art, 16-bit retro game background, detailed hand-placed pixels, soft warm lighting,
gentle muted colors, nostalgic and cozy atmosphere, modern-day Taiwan setting,
no people, no text, no letters, no watermark, no UI, no border.
Full view of the whole small room, the open box and photo album on the wooden floor in the
lower middle of the image. A quiet room with an open cardboard box full of old photographs
and an open photo album on the floor, soft afternoon light, nostalgic mood.
```

### 3.2 快轉三張：`school.png`、`library.png`、`cafe.png`

> 三張構圖要一樣（同視角、桌子都在下方中間），快切才順。
> 或者改做一支 8～15 秒循環影片 `study_montage.ogv`，就不用生這三張（見 IMAGE_PROMPTS.md）。

```
Wide landscape image, 16:9 aspect ratio (1920x1080), full panoramic establishing shot,
camera at standing eye level, the whole room visible, the floor visible across the bottom
of the image, a study table in the lower middle. Pixel art, 16-bit retro game background,
detailed hand-placed pixels, gentle muted colors, nostalgic, modern-day Taiwan,
no people, no text, no watermark, no UI, no border.
A Taiwanese high school classroom after school, empty desks, chalkboard,
orange evening light, a single desk with open books in the foreground.
```

```
Wide landscape image, 16:9 aspect ratio (1920x1080), full panoramic establishing shot,
camera at standing eye level, the whole room visible, the floor visible across the bottom
of the image, a study table in the lower middle. Pixel art, 16-bit retro game background,
detailed hand-placed pixels, gentle muted colors, nostalgic, modern-day Taiwan,
no people, no text, no watermark, no UI, no border.
A quiet public library study area, long wooden tables, bookshelves,
soft lamps, a single desk with open books in the foreground.
```

```
Wide landscape image, 16:9 aspect ratio (1920x1080), full panoramic establishing shot,
camera at standing eye level, the whole room visible, the floor visible across the bottom
of the image, a study table in the lower middle. Pixel art, 16-bit retro game background,
detailed hand-placed pixels, gentle muted colors, nostalgic, modern-day Taiwan,
no people, no text, no watermark, no UI, no border.
A small cozy café corner, wooden table with open books and a latte in the
foreground, warm string lights.
```

---

## 二、CG（12 張）— 放 `assets/cg/`，16:9 橫向

> 每張開頭都先貼這段 **CG 共同風格**，再接下面那張的描述：

```
Wide landscape image, 16:9 aspect ratio (1920x1080), cinematic medium-wide shot.
Pixel art, 16-bit retro game style, detailed hand-placed pixels, soft warm lighting,
gentle muted colors, nostalgic and cozy atmosphere, modern-day Taiwan setting,
no text, no letters, no watermark, no UI, no border.
```

| 檔名 | 劇情 | 接在共同風格後面的描述 |
|---|---|---|
| `holding_hands.png` | 2.2 媽媽牽手走巷子 | `View from behind of a young mother holding a small child's hand, walking down a narrow Taiwanese alley in the morning, long soft shadows.` |
| `breakfast.png` | 2.2 吃培根蛋吐司 | `Close-up of a happy 5-year-old child holding a bacon-and-egg toast with both hands, cheeks full, warm breakfast-shop background.` |
| `mrt_gift.png` | 3.1 有送禮 | `Inside a crowded MRT car, surrounding passengers dissolve into soft blurred color shapes, only two high school students are in sharp focus, a girl with shoulder-length black hair and a pink hair clip smiling while holding a small handmade chocolate box.` |
| `mrt_alone.png` | 3.1 沒送禮 | `MRT train doors closing, the glass window reflects the faint back of a familiar girl in the next car, melancholic blue tones.` |
| `grandma_prayer.png` | 3.3 奶奶拜拜 | `View from behind of an elderly woman with short curly hair and a floral shirt kneeling on a red temple cushion, hands pressed together in prayer, incense smoke curling upward.` |
| `lake_promise.png` | 4.3 有送禮 | `Two young adults sitting side by side at a lakeside watching the sunrise, seen from behind, golden light on the water.` |
| `mrt_wave.png` | 4.3 沒送禮 | `In a busy MRT station crowd, a young woman turns back and waves goodbye with a gentle smile.` |
| `mom_breakfast.png` | 5.1 媽媽看到早餐 | `A middle-aged mother at the dining table looking at a bacon-and-egg toast and iced milk tea placed in front of her, surprised and teary-eyed.` |
| `claire_thumbs_up.png` | 5.2 偷偷比讚 | `Under an office desk, a hand of a woman with round glasses giving a secret thumbs-up, playful.` |
| `farewell_party.png` | 5.4 Cindy 退休 | `An office farewell party for a retiring female manager with short hair, colleagues holding flowers and a cake, warm light.` |
| `ending1.png` | 結局一 | `At a lakeside bench at sunset, a glowing figure in a blue hooded robe with blue hair fading to yellow dissolves into small points of blue and yellow light that flow into an elderly person's chest.` |
| `ending2.png` | 結局二 | `An elderly person embraces a glowing figure in a blue hooded robe with blue hair fading to yellow, their body turning into floating points of blue and yellow light absorbed into the glow, ethereal.` |

> `ending1`、`ending2` 生圖時把 `src/actors/npc/paisen_float_sparkle_sheet.png`（派森）一起丟給 AI 當參考圖。

---

## 三、角色立繪（還缺 4 張）— 放 `assets/characters/`，**去背 PNG**、直式 128×256

> ✅ 已放好的不用再生。剩下 4 張「老年／臉紅」版：**拿已經放好的那張當參考圖**，描述只改年齡或表情。
> ⚠️ 一定要開「Remove background／去背」，存成真的透明 PNG，不要是畫上去的灰白格子。尺寸跟現有的一樣 128×256 就好。

> 每張開頭都先貼這段 **立繪共同風格**：

```
Pixel art character portrait, 16-bit retro game style, clean outlines, soft shading,
half-body (knees up), facing the viewer slightly turned, full transparent background,
consistent proportions for a visual novel, no text, no watermark.
```

| 檔名 | 接在共同風格後面的描述 |
|---|---|
| ✅ `倖芳.png` | `A Taiwanese teenage girl, shoulder-length straight black hair, a pale pink hair clip, gentle smile with eyes curved like crescents, high school uniform (white shirt, navy skirt), cherry-blossom pink accents.` |
| `倖芳_老年.png` | 拿 `倖芳.png` 當參考圖：`Same girl as an elderly woman, white hair, gentle old lady, still wearing the pale pink hair clip, soft cardigan.` |
| ✅ `Cindy.png` | `A sharp professional woman in her 40s, neat short hair, dark blazer, holding a tablet, piercing confident eyes, wine-red accents, strict but trustworthy.` |
| ✅ `Claire.png` | `A cheerful young office woman, hair in a bun, round glasses, holding a snack, very expressive face, mint-green accents.` |
| ✅ `媽媽.png` | `A kind Taiwanese mother in her 30s, low ponytail, wearing an apron over a cardigan, warm gentle smile, warm orange accents.` |
| `媽媽_老年.png` | 拿 `媽媽.png` 當參考圖：`Same woman, now elderly, white hair, slimmer, still gentle and kind.` |
| ✅ `爸爸.png` | `A Taiwanese father in his 30s, glasses, looks a little stern but has a gentle smile, dark green accents.` |
| `爸爸_老年.png` | 拿 `爸爸.png` 當參考圖：`Same man, now elderly, mostly white hair, wrinkles, still wearing glasses.` |
| ✅ `奶奶.png` | `An elderly Taiwanese grandmother, short curly gray hair, floral print shirt, a cross-body bag, holding prayer beads, warm grandmotherly smile, magenta-purple accents.` |
| ✅ `翊丞.png` | `A university student, messy hair, wearing a hoodie, very exaggerated expressive face, energetic and goofy, orange-yellow accents.` |
| `翊丞_臉紅.png` | 拿 `翊丞.png` 當參考圖：`Same young man, tipsy with a bright red flushed face, goofy grin.` |
| ✅ `老闆娘.png` | `A friendly middle-aged woman running a breakfast shop, apron, headscarf, cheerful smile.` |
| ✅ `面試官.png` | 已複製 `Cindy.png` |

---

## 檢查清單

- [ ] `photo_room`
- [ ] `school`、`library`、`cafe`（或 `study_montage.ogv`）
- [ ] CG：holding_hands、breakfast、mrt_gift、mrt_alone、grandma_prayer、lake_promise、mrt_wave、mom_breakfast、claire_thumbs_up、farewell_party、ending1、ending2
- [x] 立繪：倖芳、Cindy、Claire、媽媽、爸爸、奶奶、翊丞、老闆娘、面試官（2026-11-13 放好）
- [ ] 立繪：倖芳_老年、媽媽_老年、爸爸_老年、翊丞_臉紅
