#!/usr/bin/env python3
"""Bundle web/styles.css + web/app.js into a single HTML file Safari can open."""
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "web"
css = (root / "styles.css").read_text(encoding="utf-8")
js = (root / "app.js").read_text(encoding="utf-8")
html = f"""<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <meta name="apple-mobile-web-app-capable" content="yes" />
  <meta name="mobile-web-app-capable" content="yes" />
  <meta name="apple-mobile-web-app-title" content="주식 깐부" />
  <meta name="apple-mobile-web-app-status-bar-style" content="default" />
  <meta name="theme-color" content="#FAFAFA" />
  <title>주식 깐부</title>
  <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect fill='%23FAFAFA' width='64' height='64'/%3E%3Ccircle cx='26' cy='32' r='14' fill='%23111111'/%3E%3Ccircle cx='38' cy='32' r='14' fill='%23E11D48'/%3E%3C/svg%3E" />
  <link rel="apple-touch-icon" href="icon.png" />
  <style>
{css}
  </style>
</head>
<body>
  <div class="device">
    <div id="app"></div>
  </div>
  <div id="toast" class="toast" hidden></div>
  <script>
{js}
  </script>
</body>
</html>
"""
(root / "index.html").write_text(html, encoding="utf-8")
docs = root.parent / "docs"
docs.mkdir(exist_ok=True)
(docs / "index.html").write_text(html, encoding="utf-8")
(docs / ".nojekyll").write_text("", encoding="utf-8")
icon = Path(__file__).resolve().parents[1] / "KkanbuStock/KkanbuStock/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
if icon.exists():
    data = icon.read_bytes()
    (root / "icon.png").write_bytes(data)
    (docs / "icon.png").write_bytes(data)
print(f"wrote {root / 'index.html'} and {docs / 'index.html'} ({len(html)} bytes)")
