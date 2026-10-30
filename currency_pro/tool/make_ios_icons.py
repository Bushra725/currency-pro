"""Generate iOS App Store icons from the 4-currency logo."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\AQSA\.cursor\projects\c-Users-AQSA-Currency-converter-App"
    r"\assets\c__Users_AQSA_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"912fb4441b36cc6c990c66a5493f0e11_images_Currency_converter_screenshot"
    r"___Ios_-65c44fc9-1f9f-4138-8717-ba80a91f4380.png"
)
ICON_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
LAUNCH_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
ASSET_COPY = ROOT / "assets" / "icon" / "ios_app_icon.png"

SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def crop_glyph(im: Image.Image) -> Image.Image:
    rgba = im.convert("RGBA")
    pixels = rgba.load()
    w, h = rgba.size
    left, top, right, bottom = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 40:
                continue
            chroma = max(r, g, b) - min(r, g, b)
            if chroma < 28 and r > 230 and g > 230 and b > 230:
                continue
            if chroma < 18:
                continue
            left = min(left, x)
            top = min(top, y)
            right = max(right, x)
            bottom = max(bottom, y)
    if right <= left or bottom <= top:
        return rgba
    pad = max(4, int(min(right - left, bottom - top) * 0.02))
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(w - 1, right + pad)
    bottom = min(h - 1, bottom + pad)
    side = max(right - left + 1, bottom - top + 1)
    cx = (left + right) // 2
    cy = (top + bottom) // 2
    half = side // 2
    box = (
        max(0, cx - half),
        max(0, cy - half),
        min(w, cx - half + side),
        min(h, cy - half + side),
    )
    cropped = rgba.crop(box)
    square = Image.new("RGBA", (side, side), (255, 255, 255, 255))
    ox = (side - cropped.size[0]) // 2
    oy = (side - cropped.size[1]) // 2
    square.paste(cropped, (ox, oy), cropped)
    return square


def save_rgb(im: Image.Image, path: Path, size: int) -> None:
    out = im.resize((size, size), Image.Resampling.LANCZOS).convert("RGB")
    path.parent.mkdir(parents=True, exist_ok=True)
    out.save(path, "PNG")


def main() -> None:
    src = Image.open(SRC)
    glyph = crop_glyph(src)
    ASSET_COPY.parent.mkdir(parents=True, exist_ok=True)
    glyph.convert("RGBA").save(ASSET_COPY, "PNG")
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    for name, size in SIZES.items():
        save_rgb(glyph, ICON_DIR / name, size)
    LAUNCH_DIR.mkdir(parents=True, exist_ok=True)
    save_rgb(glyph, LAUNCH_DIR / "LaunchImage.png", 168)
    save_rgb(glyph, LAUNCH_DIR / "LaunchImage@2x.png", 336)
    save_rgb(glyph, LAUNCH_DIR / "LaunchImage@3x.png", 504)
    print(f"wrote {len(SIZES)} app icons and 3 launch images")


if __name__ == "__main__":
    main()
