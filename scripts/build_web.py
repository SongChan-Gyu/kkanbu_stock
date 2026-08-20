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
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
  <meta name="theme-color" content="#fff6eb" />
  <title>주식 깐부 — 웹 데모</title>
  <style>
{css}
  </style>
</head>
<body>
  <div class="page">
    <aside class="desk-note">
      <p class="brand">주식 깐부</p>
      <h1>맥 없이 브라우저에서 플레이</h1>
      <p>
        아이폰만으로는 네이티브 앱을 깔 수 없습니다. (빌드는 Mac + Xcode가 필요합니다.)
        이 페이지는 같은 핵심 루프를 Safari / Chrome에서 돌리는 플레이 데모입니다.
      </p>
      <ul>
        <li>아이폰 Safari, Windows, Mac 브라우저 모두 OK</li>
        <li>진짜 시세·푸시·OCR은 없음 (목 데이터)</li>
        <li>친구와 실시간 멀티플레이는 없음</li>
      </ul>
      <p class="hint">시작은 <strong>데모 주식팟으로 시작</strong>을 고르세요. 영희가 NVIDIA를, 민수가 AMD를 이미 찔러 둔 상태입니다.</p>
    </aside>

    <div class="phone">
      <div class="notch"></div>
      <div id="app"></div>
    </div>
  </div>
  <div id="toast" class="toast" hidden></div>
  <script>
{js}
  </script>
</body>
</html>
"""
(root / "index.html").write_text(html, encoding="utf-8")
print(f"wrote {root / 'index.html'} ({len(html)} bytes)")
