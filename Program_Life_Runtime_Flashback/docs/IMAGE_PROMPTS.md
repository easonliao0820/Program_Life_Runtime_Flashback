# 生圖清單（給其他 AI 用）

依照目前劇本實際用到的場景、CG、角色整理。
**檔名照下面的寫法放到指定資料夾，遊戲就會自動換掉佔位圖，不用改程式。**

## 使用方式

1. 每一張圖都先貼「共同風格」，再接後面那一張的英文 prompt。
2. 背景、CG：輸出 **1920×1080**（16:9）。像素風可以先生成 960×540 或 1280×720，再用「最近鄰（Nearest Neighbor）」放大，像素才不會糊。
   **只在文字裡寫 16:9 沒用，大部分 AI 會忽略**，一定要用工具本身的比例設定（見下一節）。
3. 立繪：**去背 PNG**（透明背景）、半身或膝上、面向正面略側，建議約 **800×1300**。
4. 存成 PNG 或 JPG，檔名用表格裡的名稱。

### 尺寸不對、畫面不是全景怎麼辦

| 工具 | 怎麼設成橫向 16:9 |
|---|---|
| ChatGPT / DALL·E | prompt 最前面加一句：`Generate a wide landscape image (16:9, 1792x1024).`；如果還是方的，回覆「請重畫成橫向 16:9 寬版」 |
| Midjourney | prompt 最後加 `--ar 16:9` |
| Gemini / Imagen | 介面選「16:9」或「橫向」，prompt 也加 `wide 16:9 landscape` |
| Stable Diffusion / ComfyUI | 寬高直接填 **1344×768** 或 **1280×720**（不要用 1024×1024） |
| Leonardo / Ideogram 等 | 介面的 Aspect Ratio 選 16:9 |

- **每張背景都要是全景、包含地板**：共同風格已經要求「從左牆到右牆、從天花板到地板都入鏡，地板佔畫面下方三分之一」，每張背景的 prompt 第一行也寫了鏡頭站在哪裡、地板在哪。
- **如果生出來還是太近或沒地板**：回覆生圖 AI「鏡頭再拉遠，整個房間都要看到，包含地板」，或補英文 `zoom out more, show the whole room including the floor`。
- **已經生好但比例不對**：用工具的「擴展畫面（Outpaint / Expand / 生成式擴展）」往左右延伸成 16:9，不要硬拉長。
- 遊戲裡的背景是「填滿畫面、多的裁掉」，比例差一點不會變形，但上下或左右會被切掉，所以重要的東西要放在畫面中間。
- 左下角會疊站牌（地點名稱），下方三分之一會疊對話框，**主體放在畫面中上方**比較不會被擋住。

---

## 共同風格（每張都要加）

**背景用（全景、一定要看得到地板）：**

```
Wide landscape image, 16:9 aspect ratio (1920x1080), full panoramic establishing shot,
camera pulled far back at standing eye level, the ENTIRE space visible from the left wall
to the right wall and from the ceiling (or sky) down to the floor (or ground),
the floor clearly visible and filling the bottom third of the image, every piece of
furniture fully in frame and not cropped, no close-up, no extreme perspective, no fisheye.
Pixel art, 16-bit retro game background, detailed hand-placed pixels, soft warm lighting,
gentle muted colors, nostalgic and cozy atmosphere, modern-day Taiwan setting,
no people unless described, no text, no letters, no watermark, no UI, no border.
```

**CG 用：**

```
Wide landscape image, 16:9 aspect ratio (1920x1080), cinematic medium-wide shot,
characters shown full body with the floor or ground visible under their feet.
Pixel art, 16-bit retro game style, detailed hand-placed pixels, soft warm lighting,
gentle muted colors, nostalgic and cozy atmosphere, modern-day Taiwan setting,
no text, no letters, no watermark, no UI, no border.
```

**立繪用：**

```
Pixel art character portrait, 16-bit retro game style, clean outlines, soft shading,
half-body (knees up), facing the viewer slightly turned, full transparent background,
consistent proportions for a visual novel, no text, no watermark.
```

> 現有參考圖（畫風要跟這些一致）：
> `src/ui/login/` 的捷運月台登入畫面、`chapters/chapter_1/images/baby.png`（嬰兒房）、
> `assets/images/worm.jpeg`（子宮）、`src/actors/npc/paisen_float_sparkle_sheet.png`（派森）。
> 可以把這幾張一起丟給生圖 AI 當風格參考。

**人生階段色調（畫面設定書）：** 越早的人生越暖、越柔焦；越接近現在越清晰冷靜；晚年又變暖，像夕陽。

---

## 一、背景（放到 `assets/backgrounds/`）

### 第一章：出生

| 檔名 | 用在 | 中文說明 |
|---|---|---|
| `delivery_room.png` | 第一章 | **已有**（`chapters/chapter_1/images/baby.png`），不用再生 |

### 第二章：童年（暖黃、橘、草綠，陽光、安心）

**`temple_day.png`**｜2.1 一歲生日，奶奶帶全家去拜拜
中文：家附近的文昌帝君廟，白天。紅柱、金色神龕、香爐冒煙、拜墊、筊杯放在供桌上，陽光從廟埕照進來，溫暖熱鬧。

```
Wide view of the main hall of a small traditional Taiwanese Wenchang temple in daytime,
seen from the open courtyard entrance looking in: the whole hall fits in the frame,
red wooden pillars on both left and right edges, ornate roof beams and hanging red lanterns
at the top, the golden altar with a small deity statue far in the center background,
a long offering table with fruit and a pair of red moon blocks in the middle ground,
a large bronze incense burner with thin rising smoke, red kneeling cushions on the stone floor
in the foreground, warm sunlight streaming in, peaceful and festive mood.
```

**`living_room.png`**｜2.1 回家想把爸媽的愛存起來、2.2 開頭
中文：90 年代台灣家庭客廳，午後陽光。木頭沙發、舊電視、茶几上有水果、牆上掛月曆、地上有幾個發光的小木盒（回憶盒子）。

```
Full view of the whole living room seen from the doorway, wooden floor with a rug visible across the bottom of the image.
A cozy 1990s Taiwanese family living room in the afternoon, warm golden sunlight through
the window, wooden sofa with cushions, an old CRT television, a tea table with fruit,
a wall calendar, a few toys on the floor, soft dust particles in the light, nostalgic and warm.
```

**`breakfast_shop.png`**｜2.2 跟媽媽去買早餐、5.1 買早餐給媽媽、第六章 80 歲的最後早晨
中文：台灣巷口早餐店，早晨。鐵板煎台、蛋餅、培根蛋吐司、紅茶冰奶、菜單看板掛牆上、塑膠椅、騎樓。用小孩的低視角也可以。

```
Full view of the whole shop front seen from across the arcade walkway, the tiled arcade floor visible across the bottom of the image.
A classic Taiwanese neighborhood breakfast shop in the early morning, open storefront
under an arcade, steaming flat-top griddle with egg crepes and toast, a hand-written menu
board on the wall, plastic stools, cups of milk tea, warm morning light, slice-of-life atmosphere.
```

**`convenience_store.png`**｜2.3 國一第一次自己買早餐、遇見倖芳
中文：台灣便利商店店內，白色日光燈，貨架、御飯糰冷藏櫃、茶葉蛋鍋、結帳櫃台。明亮乾淨。

```
Full view of the whole store interior seen from the entrance, the shiny tiled floor visible across the bottom of the image.
Interior of a Taiwanese convenience store in the morning, bright white fluorescent lights,
neat shelves, a refrigerated rice-ball section, a tea-egg pot on the counter, a checkout
counter with a small screen, clean green-and-white color scheme, bright and fresh mood.
```

### 第三章：高中（青綠、天藍、粉紅點綴；青春、心動、焦慮）

**`my_room.png`**｜3.1 睡過頭、3.5 放榜
中文：高中生的房間，早上。書桌上堆課本、床鋪亂、書包放椅子上、牆上貼海報、窗外藍天。有點亂、很匆忙的感覺。

```
Full view of the whole bedroom seen from the doorway, wooden floor with scattered clothes visible across the bottom of the image.
A Taiwanese high school student's bedroom in the morning, messy bed, desk piled with
textbooks, a school backpack on the chair, posters on the wall, a window with blue sky,
slightly chaotic and hurried mood, teal and sky-blue palette.
```

**`my_room_dawn.png`**｜3.4 學測當天清晨
中文：同一間房間，清晨天剛亮，窗外淡藍帶粉，桌上整齊放著准考證、2B 鉛筆、橡皮擦、手錶。安靜、緊張。

```
Same full-room framing as my_room (seen from the doorway), wooden floor visible across the bottom of the image.
The same student bedroom at dawn, pale blue and pink sky outside the window, quiet,
a tidy desk with an exam admission ticket, 2B pencils, an eraser and a wristwatch,
calm but nervous atmosphere, soft cool light.
```

**`mrt_platform.png`**｜3.1 趕捷運、4.3 寒假約在捷運站
中文：台北捷運月台，月台門、關門警示燈、人潮、列車即將進站。跟登入畫面的捷運月台風格一致。

```
Full view of the platform seen from the middle of the platform, the platform floor with yellow safety line visible across the bottom of the image.
A Taipei MRT station platform during the morning rush, platform screen doors with
warning lights, commuters in motion blur, a train arriving, clean modern station design,
blue accents, busy but hopeful mood. Match the style of the existing MRT login screen.
```

**`mrt_car.png`**｜3.1 車廂裡派森解說、送巧克力
中文：擁擠的捷運車廂內部，扶手、吊環、窗外飛過的隧道光，人群有點模糊。

```
Full view down the length of the train car, seats on both sides, the train floor visible across the bottom of the image.
Interior of a crowded Taipei MRT train car, metal handrails and hanging straps,
tunnel lights streaking past the windows, passengers softly blurred, warm interior
lighting, intimate feeling in a crowded space.
```

**`desk.png`**｜3.2 學測前 100 天
中文：深夜書桌，檯燈、堆滿的參考書、便利貼、手機放旁邊。孤單但努力。

```
Full view of the bedroom corner with the desk, chair and bookshelf, the floor visible across the bottom of the image.
A study desk late at night, a single desk lamp casting warm light, stacks of reference
books and sticky notes, a smartphone beside the books, dark room around, lonely but
determined mood.
```

**`school.png`、`library.png`、`home.png`、`cafe.png`**｜3.2 「快轉 100 天」蒙太奇（背景快速切換）
中文：四張讀書地點：學校教室、圖書館、家裡、咖啡廳。四張構圖要相近（同樣視角、都有一張讀書的桌子），快速切換才順。

```
school.png  : A Taiwanese high school classroom after school, empty desks, chalkboard,
              orange evening light, a single desk with open books in the foreground.
library.png : A quiet public library study area, long wooden tables, bookshelves,
              soft lamps, a single desk with open books in the foreground.
home.png    : A family dining table at night used as a study desk, open books in the
              foreground, warm kitchen light behind.
cafe.png    : A small cozy café corner, wooden table with open books and a latte in the
              foreground, warm string lights.
（四張都：same camera angle and composition, full view of the whole room from a standing
  viewpoint, a study table in the lower middle, the floor visible across the bottom of the image.）
```

**`temple.png`**｜3.3 昏倒後靈魂出竅到廟裡、5.4 奶奶過世後一個人回廟裡
中文：同一間文昌帝君廟，但氣氛神祕：光線偏暗、香煙繚繞、金色與紅色。遊戲會自動把畫面降低彩度（靈魂狀態），所以原圖照正常顏色畫即可。

```
Same full-hall framing as temple_day (seen from the courtyard entrance), the stone floor visible across the bottom of the image.
The same traditional Taiwanese Wenchang temple interior, dim and mysterious atmosphere,
thick incense smoke drifting, red and gold tones, a single red kneeling cushion in front
of the altar, quiet and spiritual mood.
```

**`hospital.png`**｜3.3 醒在病床、5.4 爸媽住院、結局二
中文：醫院病房，白色床單、點滴架、窗簾透光、床頭櫃上放一本相簿。安靜、柔和。

```
Full view of the whole hospital room seen from the door, the whole bed visible, the floor visible across the bottom of the image.
A hospital room, white bed sheets, an IV stand, sunlight filtered through curtains,
a bedside table with a photo album, soft and quiet atmosphere, gentle pastel light.
```

### 第三章 3.5 ～ 第四章：大學（夜晚的紫藍、宿舍燈的暖黃；自由、孤單、成長）

**`dorm.png`**｜3.5 搬進台中宿舍、4.1 期末考早晨
中文：大學四人宿舍，上下鋪、書桌、行李箱、電競主機，早晨，有點凌亂。

```
Full view of the whole four-person dorm room seen from the door, the floor with suitcases visible across the bottom of the image.
A Taiwanese university dormitory room in the morning, bunk beds, desks, unpacked
suitcases, a gaming PC on one desk, messy but lively, morning light, purple-blue and
warm yellow palette.
```

**`dorm_night.png`**｜4.3 深夜打一則訊息
中文：同一間宿舍，深夜，燈都關了，只有手機螢幕的光照在床上。

```
Same full-room framing as dorm (seen from the door), the dark floor visible across the bottom of the image.
The same university dorm room at night, all lights off, only the glow of a smartphone
screen lighting the bed area, deep blue darkness, quiet and lonely mood.
```

**`classroom.png`**｜4.1 期末考
中文：大學階梯教室，黑板寫滿公式，學生低頭考試。

```
Full view of the lecture hall seen from the back row looking down to the blackboard, aisles and floor visible across the bottom of the image.
A university lecture hall during a final exam, tiered seats, a blackboard full of
formulas, students bent over exam papers, tense atmosphere.
```

**`stir_fry.png`**｜4.2 慶功宴
中文：台灣熱炒店，暖黃燈泡、圓桌、啤酒杯、一桌熱炒菜，熱鬧。

```
Full view of the whole restaurant seen from the entrance, the floor between tables visible across the bottom of the image.
A lively Taiwanese stir-fry restaurant (re chao) at night, warm hanging bulbs, round
tables with many dishes, beer glasses, steam and chatter, cozy festive atmosphere.
```

**`graduation.png`**｜4.4 畢業典禮
中文：大學畢業典禮，校園大樹下，學士帽、學士服、陽光。

```
Full view of the campus plaza, the main building and big tree in the back, the brick plaza ground visible across the bottom of the image.
A university graduation day on campus, a large tree and the main building, graduation
caps and gowns, bright summer sunlight, joyful mood.
```

**`interview.png`**｜4.4 第八場面試
中文：公司小會議室，長桌、一張履歷、窗外城市，冷靜專業。

```
Full view of the whole meeting room seen from the door, the table and chairs fully in frame, the carpet floor visible across the bottom of the image.
A small corporate meeting room for a job interview, a long table with a single resume,
city view through the window, cool professional lighting, slightly tense mood.
```

### 第五章：出社會（辦公室的灰藍，搭配家裡的暖色；壓力與溫暖並存）

**`office.png`**｜5.1 報到、5.2、5.3、5.4
中文：開放式辦公室座位，電腦螢幕、文件，其中一張桌子堆滿零食（Claire 的座位）。

```
Full view of the open office seen from the aisle, rows of desks fully in frame, the carpet floor visible across the bottom of the image.
An open-plan office in Taipei, rows of desks with monitors and documents, one desk
cluttered with snacks, gray-blue palette, daytime fluorescent light.
```

**`office_dusk.png`**｜5.2 星期五傍晚、5.4 退休
中文：同一間辦公室，傍晚，夕陽從百葉窗照進來，橘色光條。

```
Same full-office framing as office (seen from the aisle), the floor with light stripes visible across the bottom of the image.
The same office at dusk, orange sunset light streaming through window blinds in
stripes, most people gone home, calm and slightly tired mood.
```

**`meeting_room.png`**｜5.2 被退件、報告
中文：會議室，大螢幕投影報表，長桌。被退件時遊戲會讓色調變冷。

```
Full view of the whole conference room seen from the back, the floor visible across the bottom of the image.
A corporate conference room with a large projection screen showing a sales report
chart, long table, cool lighting.
```

**`parents_home.png`**｜5.1 包紅包、5.3 爸媽的血壓
中文：爸媽家餐桌，比第二章的客廳舊一點，牆上多了主角的照片，桌上有血壓計。

```
Full view of the dining area and part of the living room, the tiled floor visible across the bottom of the image.
The parents' home dining area, older and more worn than the childhood living room,
family photos of the grown-up child on the wall, a blood pressure monitor on the table,
warm evening light.
```

**`photo_room.png`**｜5.4 整理舊照片
中文：整理舊東西的房間，打開的紙箱裡滿是照片、一本相簿攤開。

```
Full view of the whole small room, the open box and photo album on the wooden floor in the lower middle of the image.
A quiet room with an open cardboard box full of old photographs and an open photo album
on the floor, soft afternoon light, nostalgic mood.
```

### 第六章：告別（夕陽金、湖水藍、星空深藍）

**`lake_sunset.png`**｜5.4 婚禮、結局一
中文：湖邊長椅，夕陽，湖面金光，樹林。

```
Full landscape view of the lake, sky at the top, the grassy shore and the bench fully in frame across the bottom of the image.
A peaceful lakeside bench at sunset, golden light reflecting on the water, trees along
the shore, warm and bittersweet farewell mood.
```

**`lake_dawn.png`**｜5.4 看日出的約定、結局二
中文：清晨的湖邊，日出，薄霧，湖水藍。

```
Same framing as lake_sunset, sky at the top, the grassy shore fully in frame across the bottom of the image.
A lakeside at sunrise, soft mist over the water, pale gold and lake-blue colors,
quiet hopeful morning.
```

**`star_sky.png`**｜回憶遊戲（結局一、二）
中文：深藍星空，碎片漂浮的回憶空間。（遊戲目前用程式畫星星，有圖會更好）

```
A deep blue starry night sky, an abstract memory space with faint glowing particles,
dreamy and calm.
```

---

## 二、CG（放到 `assets/cg/`）

每張 CG 會在劇情中出現，也會在回憶相簿與結局再出現一次，**縮小成縮圖時也要看得懂**。

| 檔名 | 用在 | 中文說明 |
|---|---|---|
| `birth.png` | 第一章 | **已有**（`assets/images/parentsfull.png` 父母剪影），想換成彩色版再生 |
| `holding_hands.png` | 2.2 | 媽媽牽著小孩的手走在巷子裡的背影，早晨 |
| `breakfast.png` | 2.2 | 小孩捧著培根蛋吐司吃得很開心的特寫 |
| `mrt_gift.png` | 3.1 有送禮 | 擁擠車廂裡，周圍人群淡成模糊色塊，只有主角與倖芳清晰，倖芳收到巧克力在笑 |
| `mrt_alone.png` | 3.1 沒送禮 | 車門關上，玻璃窗倒映出隔壁車廂一個熟悉的背影（倖芳） |
| `grandma_prayer.png` | 3.3 | 奶奶跪在拜墊上雙手合十的背影，香煙裊裊 |
| `lake_promise.png` | 4.3 有送禮 | 兩人並肩在湖邊看日出 |
| `mrt_wave.png` | 4.3 沒送禮 | 捷運站人群中，倖芳回頭揮手 |
| `mom_breakfast.png` | 5.1 | 媽媽看到餐桌上的培根蛋吐司，愣住、眼眶泛紅 |
| `claire_thumbs_up.png` | 5.2 | Claire 在桌子底下偷偷比讚 |
| `farewell_party.png` | 5.4 | Cindy 的退休歡送會 |
| `ending1.png` | 結局一 | 派森化成光點，融進老年主角的胸口（湖邊夕陽） |
| `ending2.png` | 結局二 | 主角第一次擁抱派森，整個人化成光點 |

**英文 prompt：**

```
holding_hands.png  : View from behind of a young mother holding a small child's hand,
                     walking down a narrow Taiwanese alley in the morning, long soft shadows.
breakfast.png      : Close-up of a happy 5-year-old child holding a bacon-and-egg toast
                     with both hands, cheeks full, warm breakfast-shop background.
mrt_gift.png       : Inside a crowded MRT car, surrounding passengers dissolve into soft
                     blurred color shapes, only two high school students are in sharp focus,
                     a girl with shoulder-length black hair and a pink hair clip smiling while
                     holding a small handmade chocolate box.
mrt_alone.png      : MRT train doors closing, the glass window reflects the faint back of a
                     familiar girl in the next car, melancholic blue tones.
grandma_prayer.png : View from behind of an elderly woman with short curly hair and a floral
                     shirt kneeling on a red temple cushion, hands pressed together in prayer,
                     incense smoke curling upward.
lake_promise.png   : Two young adults sitting side by side at a lakeside watching the
                     sunrise, seen from behind, golden light on the water.
mrt_wave.png       : In a busy MRT station crowd, a young woman turns back and waves goodbye
                     with a gentle smile.
mom_breakfast.png  : A middle-aged mother at the dining table looking at a bacon-and-egg
                     toast and iced milk tea placed in front of her, surprised and teary-eyed.
claire_thumbs_up.png: Under an office desk, a hand of a woman with round glasses giving a
                     secret thumbs-up, playful.
farewell_party.png : An office farewell party for a retiring female manager with short hair,
                     colleagues holding flowers and a cake, warm light.
ending1.png        : At a lakeside bench at sunset, a glowing figure dissolves into small
                     points of blue and yellow light that flow into an elderly person's chest.
ending2.png        : An elderly person embraces a glowing blue-and-yellow figure, their body
                     turning into floating points of light absorbed into the glow, ethereal.
```

> 派森（`ending1`、`ending2` 裡的發光人物）要跟現有的派森動圖長得一樣：
> 藍色連帽長袍、藍色頭髮帶黃色漸層、身邊有藍黃光點。生圖時把 `paisen_float_sparkle_sheet.png` 當參考圖一起給。

---

## 三、角色立繪（放到 `assets/characters/`）

- 基本立繪：`角色名.png`（例如 `倖芳.png`）
- 其他版本：`角色名_版本.png`（例如 `倖芳_老年.png`、`翊丞_臉紅.png`）
- 劇本目前**有用到**的版本標 ★；其他是畫面設定書要求、之後可以補的表情。
- 「你」是第一人稱視角，**不需要立繪**。

### 主要角色（代表色寫在括號裡，衣服或配件帶一點這個顏色）

**倖芳**（櫻花粉）｜國高中同學，夢想在湖邊定居
外觀：及肩黑髮、笑起來眼睛彎彎；高中制服配淡粉色髮夾。

```
A Taiwanese teenage girl, shoulder-length straight black hair, a pale pink hair clip,
gentle smile with eyes curved like crescents, high school uniform (white shirt, navy
skirt), cherry-blossom pink accents.
```

需要的檔案：★`倖芳.png`（高中）、★`倖芳_老年.png`（結局：白髮、溫柔的老奶奶，仍戴淡粉色髮夾）；
之後可補：國中版、大學版、成人版；表情：微笑、大笑、驚訝、難過、害羞、哭泣。

**Cindy**（酒紅）｜第一位主管，嚴格但護著組員

```
A sharp professional woman in her 40s, neat short hair, dark blazer, holding a tablet,
piercing confident eyes, wine-red accents, strict but trustworthy.
```

需要的檔案：★`Cindy.png`；之後可補：`Cindy_退休.png`（柔和的毛衣）、微笑、嚴肅、驚訝。

**Claire**（薄荷綠）｜隔壁同事，熱心愛吃零食

```
A cheerful young office woman, hair in a bun, round glasses, holding a snack, very
expressive face, mint-green accents.
```

需要的檔案：★`Claire.png`；之後可補：大笑、驚訝、比讚。

### 次要角色

**媽媽**（暖橘）

```
A kind Taiwanese mother in her 30s, low ponytail, wearing an apron over a cardigan,
warm gentle smile, warm orange accents.
```

需要的檔案：★`媽媽.png`（年輕）、★`媽媽_老年.png`（白髮、更瘦、仍溫柔）；之後可補：中年、微笑、驚訝、難過。

**爸爸**（深綠）

```
A Taiwanese father in his 30s, glasses, looks a little stern but has a gentle smile,
dark green accents.
```

需要的檔案：★`爸爸.png`、★`爸爸_老年.png`（白髮多、皺紋、戴眼鏡）。

**奶奶**（紫紅）

```
An elderly Taiwanese grandmother, short curly gray hair, floral print shirt, a
cross-body bag, holding prayer beads, warm grandmotherly smile, magenta-purple accents.
```

需要的檔案：★`奶奶.png`。

**翊丞**（橘黃）｜大學室友，講義氣

```
A university student, messy hair, wearing a hoodie, very exaggerated expressive face,
energetic and goofy, orange-yellow accents.
```

需要的檔案：★`翊丞.png`、★`翊丞_臉紅.png`（4.2 慶功宴喝到臉紅）。

**面試官**（其實就是 Cindy）

需要的檔案：★`面試官.png`（直接複製一份 `Cindy.png` 改名即可，或畫成翻履歷、皺眉的 Cindy）。

**老闆娘**（早餐店阿姨的女兒，第六章）

```
A friendly middle-aged woman running a breakfast shop, apron, headscarf, cheerful smile.
```

需要的檔案：★`老闆娘.png`。

---

## 四、之後可以補（目前程式還沒接上，先列著）

| 用途 | 說明 |
|---|---|
| 探索模式的俯視房間 | 2.1 客廳、3.1 主角房間、3.4 清晨房間的**俯視角**地圖（畫面設定書：「主角房間（俯視＋一般）」）。目前房間是米色底，需要的話我再加讀圖的功能 |
| 探索模式的主角角色 | 目前用藍灰色圓形代替；可以畫一組俯視角、四方向走路的小角色圖 |
| 記憶地圖縮圖 | `assets/thumbnails/<小節id>.png`（例如 `ch2_2.png`），沒有的話會用色調代替 |

---

## 檢查清單

- [ ] 背景 29 張（另有 `delivery_room` 已經有圖；`school`、`library`、`home`、`cafe` 四張構圖要一致；`star_sky` 目前程式還是自己畫星星，要用圖的話跟我說）
- [ ] CG 12 張（另有 `birth` 已經有圖）
- [ ] 立繪 ★ 標記的 13 張
- [ ] 全部都是像素風、跟現有的登入畫面／嬰兒房／子宮／派森同一個畫風
