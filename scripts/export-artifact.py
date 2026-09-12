"""Derive the claude.ai artifact page from web/index.html.

The artifact host wraps the file in its own doctype/head/body and only allows
Google Fonts as an external stylesheet, so this strips the document shell,
swaps the bundled fonts for the Google Fonts link and writes the result next
to the artifact's image folder (../thy-gnosis-app/thy-gnosis.html).
"""
import pathlib, re, shutil

root = pathlib.Path(__file__).resolve().parents[1]
src = (root / "web" / "index.html").read_text(encoding="utf-8")
out_dir = root.parent / "thy-gnosis-app"

head_start = src.index("<title>")
body_start = src.index("<!-- app -->")
body_end = src.rindex("</body>")
style = src[head_start:src.index("</head>")]
style = style.replace(
    '<link rel="stylesheet" href="fonts/fonts.css">',
    '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Pirata+One&family=Barlow+Condensed:wght@400;500;600;700&family=Barlow:wght@400;500;600&display=swap">',
)
style = re.sub(r'<meta[^>]*>\s*', '', style)
page = style + "\n" + src[body_start:body_end]
(out_dir / "thy-gnosis.html").write_text(page, encoding="utf-8")

img_out = out_dir / "img"
img_out.mkdir(exist_ok=True)
for f in (root / "web" / "img").iterdir():
    shutil.copy2(f, img_out / f.name)
print("wrote", out_dir / "thy-gnosis.html", len(page), "chars")
