"""Sinh app icon 1024x1024 cho Expense Tracker (không cần font bên ngoài)."""
from PIL import Image, ImageDraw
import os

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "ExpenseTracker",
                   "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png")

os.makedirs(os.path.dirname(OUT), exist_ok=True)

img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)

# Nền gradient xanh dương -> tím
top = (47, 107, 255)
bottom = (123, 97, 255)
for y in range(SIZE):
    t = y / (SIZE - 1)
    color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    draw.line([(0, y), (SIZE, y)], fill=color)

# Các "hạt" sáng trang trí
spots = [
    (140, 190, 70), (860, 250, 52), (210, 810, 44),
    (760, 760, 64), (520, 120, 38), (120, 560, 34), (900, 560, 40),
]
for cx, cy, r in spots:
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 38))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")

draw = ImageDraw.Draw(img)

# Biểu tượng ví (rounded rectangle) màu trắng
wallet = [250, 320, 774, 704]
draw.rounded_rectangle(wallet, radius=90, fill=(255, 255, 255))

# Dải màu ví
draw.rounded_rectangle([250, 320, 774, 430], radius=90, fill=(232, 240, 255))
draw.rectangle([250, 390, 774, 430], fill=(232, 240, 255))

# Nút khoá
draw.ellipse([612, 486, 700, 574], fill=(47, 107, 255))
draw.rounded_rectangle([646, 512, 666, 590], radius=10, fill=(47, 107, 255))

# Biểu đồ tăng (cột) màu xanh trên ví
bars = [(320, 570, 55, 645), (395, 520, 55, 645), (470, 468, 55, 645)]
for x, top, w, bottom in bars:
    draw.rounded_rectangle([x, top, x + w, bottom], radius=12, fill=(47, 107, 255))

img.save(OUT, "PNG")
print("saved:", os.path.abspath(OUT), img.size)
