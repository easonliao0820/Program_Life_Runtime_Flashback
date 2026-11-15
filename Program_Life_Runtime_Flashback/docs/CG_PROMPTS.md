# CG 生圖清單

CG 是劇情裡「定格的一幕」，劇本寫 `@cg 名稱 說明` 就會顯示。
同一張 CG 之後還會出現在**回憶相簿**和**結局**，縮成小圖時也要看得懂。

- 放到：`assets/cg/<檔名>.png`（資料夾還沒有的話自己建一個）
- 檔名照下面寫，放進去遊戲就會自動換掉佔位畫面，不用改程式
- 狀態：**12 張都還沒有**（`birth` 已經有了，用的是 `assets/images/parentsfull.png`）

其他圖（背景、立繪）見 [IMAGE_TODO.md](IMAGE_TODO.md)；工具設定（PixelLab 尺寸等）見 [IMAGE_PROMPTS.md](IMAGE_PROMPTS.md)。

---

## 遊戲怎麼顯示 CG（構圖要注意）

| 規則 | 所以生圖時要 |
|---|---|
| 圖片**完整顯示、置中、不裁切**，比例不是 16:9 的話，兩旁會補米色底 | 用 **16:9 橫向**，畫面才會滿版 |
| 畫面**上方**會疊一條深藍色的說明字（就是劇本裡 `@cg` 後面那句） | 上方約 15% 不要放重要的東西（臉、手） |
| 畫面**下方三分之一**會被對話框擋住 | **主角放在畫面中間** |
| 用最近鄰放大，像素保持清楚 | 像素風可以直接生小圖：PixelLab 用 **480×270** 或 **640×360** |

> 「你」（主角）在一般劇情裡沒有立繪，在 CG 裡可以入鏡，但**盡量只拍背影或側面**，不要畫清楚的正臉，讓玩家比較好代入。

---

## 共同風格（每張都先貼這段）

```
Wide landscape image, 16:9 aspect ratio (1920x1080), cinematic medium-wide shot,
main subject centered in the middle of the frame, keep the top 15% and the bottom third
free of important details. Pixel art, 16-bit retro game style, detailed hand-placed pixels,
soft warm lighting, gentle muted colors, nostalgic and cozy atmosphere,
modern-day Taiwan setting, no text, no letters, no watermark, no UI, no border.
```

**角色參考圖**：CG 裡有出現的角色，把 `assets/characters/` 裡那張立繪一起丟給生圖 AI，長相才會一致。

| CG 裡的人 | 參考圖 |
|---|---|
| 媽媽 | `assets/characters/媽媽.png` |
| 倖芳 | `assets/characters/倖芳.png` |
| 奶奶 | `assets/characters/奶奶.png` |
| Cindy | `assets/characters/Cindy.png` |
| Claire | `assets/characters/Claire.png` |
| 派森 | 新設計 A「光之精靈」，見 [PAISEN_DESIGN.md](PAISEN_DESIGN.md)。等新派森的設定圖生好，再拿它當參考圖生 `ending1`、`ending2` |

---

## 第二章：童年

### 1. `holding_hands.png`｜2.2 第一次去買早餐

- **劇情**：媽媽說「你就快要上學了，今天練習自己去買早餐」，牽著你出門。你跟在高大的背影後面，覺得長大好像也不錯。
- **畫面**：從背後看，媽媽牽著小小的你，走在早晨的巷子裡。
- **參考圖**：`媽媽.png`
- **色調**：童年（暖、柔焦、晨光）

```
View from behind of a young mother with a low ponytail and an apron over a cardigan,
holding a small 5-year-old child's hand, walking together down a narrow Taiwanese alley
in the early morning, scooters parked along the walls, potted plants, long soft shadows,
warm golden morning light, the mother looks tall next to the tiny child.
```

### 2. `breakfast.png`｜2.2 買到早餐

- **劇情**：你自己算好錢、買到早餐，捧著培根蛋吐司一口一口吃，臉上露出幸福的表情。
- **畫面**：小孩雙手捧著吐司，兩頰鼓鼓的，背景是早餐店。
- **色調**：童年（暖）

```
A happy 5-year-old child sitting at a small breakfast-shop table, holding a
bacon-and-egg toast with both hands, cheeks full, eyes closed with joy, a cup of iced
milk tea on the table, warm cozy Taiwanese breakfast shop in the background, morning light.
```

---

## 第三章：國高中

### 3. `mrt_alone.png`｜3.1 沒送禮物的路線

- **劇情**：你到了捷運站，沒找到倖芳。車門關上的瞬間，好像在隔壁車廂看到一個熟悉的背影，但人太多，你沒有擠過去。
- **畫面**：關上的車門玻璃，倒映出隔壁車廂一個女生的背影。
- **參考圖**：`倖芳.png`
- **色調**：冷、藍、有點遺憾

```
Inside a Taiwanese MRT train, the sliding doors have just closed, through the glass
window a faint figure of a high school girl with long straight black hair and a pink hair
clip is seen from behind in the next car, crowded commuters, melancholic cool blue tones,
lonely and quiet mood.
```

### 4. `mrt_gift.png`｜3.1 有送禮物的路線

- **劇情**：倖芳特地從隔壁車廂走過來找你。你拿出手作巧克力遞給她，擁擠的車廂裡好像只剩你們兩個。
- **畫面**：周圍乘客淡成模糊色塊，只有你（側面或背影）和倖芳清楚。倖芳捧著巧克力在笑。
- **參考圖**：`倖芳.png`
- **色調**：暖、粉色調、心動

```
Inside a crowded Taiwanese MRT car, the surrounding passengers dissolve into soft blurred
color shapes, only two high school students are in sharp focus: a girl with long straight
black hair, a pale pink hair clip and a sailor-style school uniform, smiling warmly while
holding a small handmade chocolate box, and a boy seen from the side or behind,
warm pink light, a feeling that time has stopped.
```

### 5. `grandma_prayer.png`｜3.3 奶奶擲筊

- **劇情**：奶奶擲了好多次，終於擲出連續三個聖杯，雙手合十，笑得眼睛瞇成一條線。
- **畫面**：從背後看，奶奶跪在紅色拜墊上雙手合十，香煙裊裊，前面是神桌。
- **參考圖**：`奶奶.png`
- **色調**：廟宇的紅與金、溫暖、莊嚴

```
View from behind of an elderly Taiwanese grandmother with short curly gray hair and a
floral print shirt, a cross-body bag, kneeling on a red temple cushion, hands pressed
together in prayer, two red crescent moon blocks on the floor in front of her,
incense smoke curling upward, a traditional temple altar with candles in the background,
warm red and gold light.
```

---

## 第四章：大學

### 6. `lake_promise.png`｜4.3 有聯絡倖芳的路線

- **劇情**：倖芳說：「畢業以後，找一個有湖的地方，我們一起去看日出。這次不准再失約了。」你說：「好。這次一定。」
- **畫面**：兩個人並肩坐在湖邊，從背後看日出，湖面有金光。（這是兩人心裡的約定，可以畫得像夢一樣）
- **參考圖**：`倖芳.png`
- **色調**：日出金、湖水藍

```
Two young adults sitting side by side on a lakeside, seen from behind, watching the sun
rise over a calm lake surrounded by mountains, golden light reflecting on the water,
the girl has long straight black hair with a pale pink hair clip, soft dreamy atmosphere,
a quiet promise.
```

### 7. `mrt_wave.png`｜4.3 沒聯絡倖芳的路線

- **劇情**：寒假在捷運站見面，聊了很多高中的糗事。分開時你終於說出「謝謝你」，她在人群中回頭揮手。
- **畫面**：捷運站人群裡，倖芳（大學生）回頭笑著揮手。
- **參考圖**：`倖芳.png`（改成大學生的便服）
- **色調**：冬天、溫柔的告別

```
In a busy Taiwanese MRT station platform crowd, a young woman in her early twenties with
long straight black hair, a pale pink hair clip and a winter coat turns back and waves
goodbye with a gentle smile, commuters around her slightly blurred, soft winter light,
bittersweet farewell.
```

---

## 第五章：工作

### 8. `mom_breakfast.png`｜5.1 第一份薪水

- **劇情**：你領到第一份薪水，買了培根蛋吐司回家放在餐桌上：「媽，以前都是你買給我吃，以後換我買給你。」媽媽愣住了。
- **畫面**：中年的媽媽坐在餐桌前，看著桌上的培根蛋吐司和奶茶，驚訝、眼眶泛紅。（呼應第 2 張 `breakfast`）
- **參考圖**：`媽媽.png`（改成五十多歲、頭髮有點白）
- **色調**：家裡、午後暖光、懷舊

```
A Taiwanese mother in her fifties with a low ponytail and a few gray hairs, sitting at a
home dining table, looking at a bacon-and-egg toast and an iced milk tea placed in front
of her, surprised, eyes glistening with tears, hands near her mouth,
warm afternoon light in a lived-in family home.
```

### 9. `claire_thumbs_up.png`｜5.2 被 Cindy 稱讚

- **劇情**：Cindy 難得說「報表做得好」。她一走遠，隔壁的 Claire 就在桌子底下偷偷對你比讚。
- **畫面**：辦公桌底下，Claire 偷偷比讚，臉上是調皮的笑。
- **參考圖**：`Claire.png`
- **色調**：辦公室、明亮、俏皮

```
In an office, a cheerful young woman with her hair in a bun and round glasses, sitting at
the next desk, secretly giving a thumbs-up under the desk with a playful grin, a snack on
her desk, bright office lighting, the shot focuses on the hand and her smiling face.
```

### 10. `farewell_party.png`｜5.4 Cindy 退休

- **劇情**：你五十五歲，Cindy 退休，部門替她辦歡送會。她拍拍你的肩膀：「現在換你帶新人了。」
- **畫面**：辦公室的歡送會，Cindy 抱著花，同事圍著蛋糕。Claire 也在。
- **參考圖**：`Cindy.png`（改成六十多歲、穿柔和的毛衣）、`Claire.png`（改成中年）
- **色調**：傍晚暖光、溫馨

```
An office farewell party for a retiring woman in her sixties with neat short gray hair
and a soft sweater, holding a bouquet of flowers, colleagues gathered around a cake on a
desk, a middle-aged woman with round glasses and a bun clapping beside her,
warm evening light, heartfelt and slightly emotional.
```

---

## 第六章：結局

### 11. `ending1.png`｜結局一

- **劇情**：你把回憶接了起來。派森說：「就算再也看不見我，我也會一直跟你在一起。」他漸漸化成點點亮光，融進你的身體裡。
- **畫面**：湖邊長椅、夕陽。派森化成藍黃光點，流進老年的你的胸口。
- **參考圖**：新派森的設定圖（見 [PAISEN_DESIGN.md](PAISEN_DESIGN.md)）
- **色調**：夕陽金、湖水藍

```
At a lakeside bench at sunset, an elderly person with white hair sits peacefully,
seen from the side, a glowing figure in a blue hooded robe with blue hair fading to yellow
dissolves into small points of blue and yellow light that flow gently into the elderly
person's chest, golden sunset reflecting on the lake, warm and peaceful.
```

### 12. `ending2.png`｜結局二

- **劇情**：你說：「人的壽命，不過是近乎無限的時間裡的一個點而已。」你第一次擁抱這個陪你走過一生的朋友，然後化成點點光芒，融進了 Python 裡。
- **畫面**：老年的你擁抱派森，身體化成光點，被派森的光吸收。
- **參考圖**：新派森的設定圖（見 [PAISEN_DESIGN.md](PAISEN_DESIGN.md)）
- **色調**：星空深藍、金色光點、空靈

```
An elderly person with white hair embraces a glowing figure in a blue hooded robe with
blue hair fading to yellow, the elderly person's body turning into floating points of
light that are absorbed into the glow, deep starry night-blue background,
golden and blue sparkles, ethereal and tender.
```

---

## 檢查清單

- [ ] `holding_hands`
- [ ] `breakfast`
- [ ] `mrt_alone`
- [ ] `mrt_gift`
- [ ] `grandma_prayer`
- [ ] `lake_promise`
- [ ] `mrt_wave`
- [ ] `mom_breakfast`
- [ ] `claire_thumbs_up`
- [ ] `farewell_party`
- [ ] `ending1`
- [ ] `ending2`
- [ ] （可選）`birth`：換成彩色版的父母剪影
