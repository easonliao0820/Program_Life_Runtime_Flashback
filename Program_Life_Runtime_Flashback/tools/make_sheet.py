"""把 PixelLab 匯出的動畫轉成遊戲要的「一列橫排」sprite sheet。

用法（需要 Pillow：pip3 install pillow）：

    # GIF → sheet
    python3 tools/make_sheet.py steam.gif -o assets/backgrounds/fx/steam.png

    # 好幾張分開的 PNG（照順序）→ sheet
    python3 tools/make_sheet.py open.png half.png closed.png half.png -o assets/characters/倖芳_idle.png

    # PixelLab 匯出的是多列的 sheet（例如 4×2 格）→ 改成一列
    python3 tools/make_sheet.py walk_sheet.png --grid 4x2 -o out.png

選項：
    --size 640x360   每一格縮放成這個大小（最近鄰，不會糊）。立繪建議 128x256。
    --pingpong       播完再倒著播回來（1 2 3 4 3 2），蒸氣、窗簾這類來回擺動的很好用。
"""
import argparse
import sys

from PIL import Image, ImageSequence


def load_frames(paths, grid):
    frames = []
    for p in paths:
        im = Image.open(p)
        if getattr(im, "is_animated", False):
            frames += [f.convert("RGBA") for f in ImageSequence.Iterator(im)]
            continue
        im = im.convert("RGBA")
        if grid:
            cols, rows = grid
            fw, fh = im.width // cols, im.height // rows
            for r in range(rows):
                for c in range(cols):
                    frames.append(im.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh)))
        else:
            frames.append(im)
    return frames


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--grid", help="輸入是多列 sheet 時的欄×列，例如 4x2")
    ap.add_argument("--size", help="每格縮放成 寬x高，例如 640x360")
    ap.add_argument("--pingpong", action="store_true")
    a = ap.parse_args()

    grid = tuple(int(v) for v in a.grid.lower().split("x")) if a.grid else None
    frames = load_frames(a.inputs, grid)
    if not frames:
        sys.exit("沒有讀到任何一格")
    if a.size:
        w, h = (int(v) for v in a.size.lower().split("x"))
        frames = [f.resize((w, h), Image.NEAREST) for f in frames]
    w, h = frames[0].size
    if any(f.size != (w, h) for f in frames):
        sys.exit("每一格大小不一樣，請加 --size 統一（例如 --size %dx%d）" % (w, h))
    if a.pingpong and len(frames) > 2:
        frames = frames + frames[-2:0:-1]

    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * w, 0))
    sheet.save(a.out)
    print("%s：%d 格，每格 %dx%d，整張 %dx%d" % (a.out, len(frames), w, h, sheet.width, h))


if __name__ == "__main__":
    main()
