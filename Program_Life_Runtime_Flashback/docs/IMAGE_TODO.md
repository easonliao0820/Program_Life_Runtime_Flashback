# 還缺的圖（2026-11-15）

照檔名放進資料夾，遊戲會自動換掉佔位圖，不用改程式。

## 待辦

**背景** `assets/backgrounds/`（16:9 橫向）
- [x] `photo_room` — 5.4 整理舊照片（2026-11-15）
- [x] `school`、`library`、`cafe` — 3.2 快轉（2026-11-15）

**CG** `assets/cg/`
- [ ] 12 張 → [CG_PROMPTS.md](CG_PROMPTS.md)

**立繪** `assets/characters/`（去背、128×256）→ prompt 見 [PIXELLAB_ANIM.md](PIXELLAB_ANIM.md) 4.1
- [ ] `倖芳_老年`、`媽媽_老年`、`爸爸_老年`、`翊丞_臉紅`（沒有時遊戲先顯示一般版）
- [ ] `老闆娘` 重生成半身（現在是全身小人，比別人小一號）

**選做**
- [ ] 動態背景、角色眨眼 → [PIXELLAB_ANIM.md](PIXELLAB_ANIM.md)
- [ ] 現有 19 張背景是 512×512 正方形，有空用 Outpaint 擴成 16:9

---

## 背景 prompt

每張都先貼這段**共同開頭**，再接各自的描述：

```
Wide landscape image, 16:9 (1920x1080), full establishing shot at standing eye level,
the whole room visible from wall to wall, floor visible across the bottom third,
no close-up, no fisheye. Pixel art, 16-bit retro game background, soft warm lighting,
gentle muted colors, nostalgic, no people, no text, no watermark, no UI, no border.
Set in Taiwan (Taipei, 2000s-2010s): aluminum-frame windows with white iron window grilles,
glossy ceramic or terrazzo floor tiles, white fluorescent tube lights, a wall-mounted electric fan,
through the window: grey concrete apartment blocks with iron-caged balconies, rooftop water tanks,
air-conditioner units and parked scooters. Taiwan, NOT Japan, NOT Korea, NOT mainland China.
```

| 檔名 | 接在後面的描述 |
|---|---|
| `photo_room` | `A small spare room in an old Taiwanese apartment, terrazzo floor, a red diamond-shaped spring couplet on the door, an old wooden cabinet and a wall calendar, an open cardboard box full of old photographs and an open photo album on the floor in the lower middle, soft afternoon light through the iron window grille.` |
| `school` | `A Taiwanese high school classroom after school, green chalkboard, rows of wooden desks on steel frames with school bags hanging on the side hooks, ceiling fans, a notice board, louvered aluminum windows with a corridor and palm trees outside, orange evening light, a single desk with open books in the lower middle.` |
| `library` | `A Taiwanese public library self-study room, long rows of desks with low wooden dividers, steel bookshelves, fluorescent lights, a water dispenser by the wall, window view of a street with scooters, a single desk with open books in the lower middle.` |
| `cafe` | `A small café in a renovated old Taiwanese townhouse, terrazzo floor, vintage iron window grilles, potted plants, warm string lights, view of an arcade walkway with parked scooters outside, a wooden table with open books and a latte in the lower middle.` |

> 快轉三張的構圖要一樣（桌子都在下方中間），切換才順。
> 用 PixelLab 時，Negative description 加上 `Japanese style, tatami, shoji, sakura, Korean, hanok`。
> 還是不夠台灣：把專案裡的 `mrt_platform.png` 或 `living_room.png` 當 Style image 一起丟進去。
> PixelLab 的尺寸和欄位設定見 [IMAGE_PROMPTS.md](IMAGE_PROMPTS.md)。
