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
print(f"wrote {root / 'index.html'} and {docs / 'index.html'} ({len(html)} bytes)")
