from pathlib import Path
import shutil

import numpy as np
from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE_PATH = PROJECT_ROOT / "design" / "wheelseek-icon-master.png"
ICON_DIRECTORY = PROJECT_ROOT / "icons"
STORE_ICON_PATH = PROJECT_ROOT / "store" / "assets" / "icon-128.png"
SIZES = (16, 32, 48, 128)


def isolate_green_motif(source: Image.Image) -> Image.Image:
    rgb = np.asarray(source.convert("RGB"), dtype=np.float32)
    red = rgb[:, :, 0]
    green = rgb[:, :, 1]
    blue = rgb[:, :, 2]

    green_signal = green - ((red + blue) / 2.0)
    alpha = np.clip((green_signal - 4.0) * 5.5, 0, 255).astype(np.uint8)

    rgba = np.dstack((rgb.astype(np.uint8), alpha))
    return Image.fromarray(rgba, mode="RGBA")


def square_crop_around_motif(image: Image.Image) -> Image.Image:
    alpha = np.asarray(image.getchannel("A"))
    ys, xs = np.where(alpha >= 64)
    if len(xs) == 0:
        raise RuntimeError("Could not detect the green icon motif.")

    left, right = int(xs.min()), int(xs.max())
    top, bottom = int(ys.min()), int(ys.max())
    motif_width = right - left + 1
    motif_height = bottom - top + 1
    side = int(np.ceil(max(motif_width, motif_height) * 1.015))
    center_x = (left + right) / 2.0
    center_y = (top + bottom) / 2.0

    crop_left = int(round(center_x - side / 2.0))
    crop_top = int(round(center_y - side / 2.0))
    return image.crop(
        (crop_left, crop_top, crop_left + side, crop_top + side)
    )


def save_icon_sizes(source_square: Image.Image) -> None:
    ICON_DIRECTORY.mkdir(parents=True, exist_ok=True)
    for size in SIZES:
        padding = 2 if size >= 64 else 1
        motif_size = size - padding * 2
        resized = source_square.resize(
            (motif_size, motif_size),
            Image.Resampling.LANCZOS,
        )
        output = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        output.alpha_composite(resized, (padding, padding))
        output.save(ICON_DIRECTORY / f"icon-{size}.png", optimize=True)


def main() -> None:
    if not SOURCE_PATH.exists():
        raise FileNotFoundError(f"Master icon not found: {SOURCE_PATH}")

    with Image.open(SOURCE_PATH) as source:
        isolated = isolate_green_motif(source)
    source_square = square_crop_around_motif(isolated)
    save_icon_sizes(source_square)
    shutil.copy2(ICON_DIRECTORY / "icon-128.png", STORE_ICON_PATH)

    for size in SIZES:
        path = ICON_DIRECTORY / f"icon-{size}.png"
        print(f"{path.name}: {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
