import os
import subprocess
from PIL import Image, ImageDraw

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    assets_dir = os.path.join(base_dir, "assets")
    svg_path = os.path.join(assets_dir, "logo.svg")
    edge_png_path = os.path.join(assets_dir, "logo.png")
    disc_png_path = os.path.join(assets_dir, "logo_disc.png")

    # 1. Render SVG via Edge headless at 1024x1024
    edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    html_file = os.path.join(assets_dir, "render_temp.html")
    svg_url = svg_path.replace("\\", "/")
    html_url = html_file.replace("\\", "/")

    html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  html, body {{ margin: 0; padding: 0; width: 1000px; height: 1000px; overflow: hidden; background: #FFFFFF; }}
  img {{ width: 1000px; height: 1000px; display: block; border: none; }}
</style>
</head>
<body>
  <img src="{svg_url}" />
</body>
</html>"""
    with open(html_file, "w", encoding="utf-8") as f:
        f.write(html)

    cmd = [
        edge_path,
        "--headless",
        "--disable-gpu",
        f"--screenshot={edge_png_path}",
        "--window-size=1000,1000",
        f"file:///{html_url}"
    ]
    subprocess.run(cmd, check=True, capture_output=True)
    if os.path.exists(html_file):
        os.remove(html_file)

    print(f"Generated {edge_png_path}")

    # 2. Generate disc transparent mask
    img = Image.open(edge_png_path).convert("RGBA")
    w, h = img.size
    scale = 4
    mask_hi = Image.new("L", (w * scale, h * scale), 0)
    draw_hi = ImageDraw.Draw(mask_hi)
    cx, cy = 500.0 * scale, 500.0 * scale
    r_outer = (427.24609375 + 20.5 / 2.0) * scale

    draw_hi.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], fill=255)
    mask = mask_hi.resize((w, h), Image.Resampling.LANCZOS)

    disc_img = img.copy()
    disc_img.putalpha(mask)
    disc_img.save(disc_png_path)
    print(f"Generated {disc_png_path}")

    # 3. Generate Windows Runner app_icon.ico
    win_ico_path = os.path.join(base_dir, "windows", "runner", "resources", "app_icon.ico")
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    disc_img.save(win_ico_path, format="ICO", sizes=ico_sizes)
    print(f"Generated {win_ico_path}")

    # 4. Generate Android launcher icons
    android_res = os.path.join(base_dir, "android", "app", "src", "main", "res")
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in android_sizes.items():
        out_dir = os.path.join(android_res, folder)
        os.makedirs(out_dir, exist_ok=True)
        out_file = os.path.join(out_dir, "ic_launcher.png")
        resized = disc_img.resize((px, px), Image.Resampling.LANCZOS)
        resized.save(out_file, "PNG")
        print(f"Generated {out_file} ({px}x{px})")

    # Clean up test files if any
    test_ico = os.path.join(base_dir, "windows", "runner", "resources", "test_icon.ico")
    if os.path.exists(test_ico):
        os.remove(test_ico)

if __name__ == "__main__":
    main()
