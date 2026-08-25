const CATALOG = [
  ["NVDA", "NVIDIA", "nasdaq", 182.4],
  ["AAPL", "Apple", "nasdaq", 231.42],
  ["TSLA", "Tesla", "nasdaq", 248.1],
  ["AMD", "AMD", "nasdaq", 156.8],
  ["MSFT", "Microsoft", "nasdaq", 428.5],
  ["AMZN", "Amazon", "nasdaq", 197.3],
  ["005930", "삼성전자", "krx", 72300],
  ["000660", "SK하이닉스", "krx", 178000],
  ["035420", "NAVER", "krx", 186500],
  ["035720", "카카오", "krx", 41200]
];

const uid = () => crypto.randomUUID ? crypto.randomUUID() : String(Date.now() + Math.random());
const now = () => Date.now();
const hours = (n) => n * 3600 * 1000;
const days = (n) => n * 24 * 3600 * 1000;

function formatPrice(value, market) {
  if (market === "krx") return Math.round(value).toLocaleString("ko-KR") + "원";
  return "$" + value.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}
function formatPct(value) {
  const sign = value >= 0 ? "+" : "";
  return sign + (value * 100).toFixed(1) + "%";
}
function relative(ts) {
  const d = Math.max(1, Math.round((now() - ts) / 60000));
  if (d < 60) return d + "분 전";
  const h = Math.round(d / 60);
  if (h < 24) return h + "시간 전";
  return Math.round(h / 24) + "일 전";
}

function makeStocks() {
  return CATALOG.map(([ticker, name, market, base]) => ({
    id: ticker, ticker, name, market, base, offset: 0
  }));
}
function priceOf(stock) {
  return stock.base * (1 + (stock.offset || 0));
}
function ret(avg, current) {
  return (current - avg) / avg;
}
function gradeFor(shared) {
  if (shared >= 0.5) return { title: "신의 한 수 파트너", kick: "glory" };
  if (shared <= -0.5) return { title: "공동묘지 파트너", kick: "roast" };
  if (shared <= -0.3) return { title: "최악의 주식 파트너", kick: "roast" };
  if (shared >= 0.3) return { title: "황금 깐부", kick: "glory" };
  return { title: "주식 깐부", kick: "plain" };
}

const MARKS = {
  NVDA: { bg: "#76B900", fg: "#111", g: "N" },
  AAPL: { bg: "#1C1C1E", fg: "#fff", g: "A" },
  TSLA: { bg: "#CC0000", fg: "#fff", g: "T" },
  AMD: { bg: "#000", fg: "#fff", g: "A" },
  MSFT: { bg: "#F5F5F5", fg: "#111", g: "M" },
  AMZN: { bg: "#FF9900", fg: "#111", g: "a" },
  GOOGL: { bg: "#fff", fg: "#4285F4", g: "G" },
  META: { bg: "#0668E1", fg: "#fff", g: "f" },
  "005930": { bg: "#1428A0", fg: "#fff", g: "삼" },
  "000660": { bg: "#EE1C25", fg: "#fff", g: "하" },
  "035420": { bg: "#03C75A", fg: "#fff", g: "N" },
  "035720": { bg: "#FEE500", fg: "#191919", g: "K" }
};
const SIMPLE_ICONS = {
  NVDA: "nvidia/111111",
  AAPL: "apple/ffffff",
  TSLA: "tesla/ffffff",
  AMD: "amd/ffffff",
  MSFT: "microsoft",
  AMZN: "amazon/111111",
  GOOGL: "google",
  META: "meta/ffffff",
  "005930": "samsung/ffffff",
  "035420": "naver/ffffff",
  "035720": "kakaotalk/191919"
};
const LOGO_DOMAINS = {
  "000660": "skhynix.com"
};

function logoSrc(ticker) {
  if (SIMPLE_ICONS[ticker]) return "https://cdn.simpleicons.org/" + SIMPLE_ICONS[ticker];
  if (LOGO_DOMAINS[ticker]) return "https://www.google.com/s2/favicons?sz=128&domain=" + encodeURIComponent(LOGO_DOMAINS[ticker]);
  return "";
}
function stockMark(s, size) {
  const mark = MARKS[s.ticker] || MARKS[s.id] || { bg: "#405DE6", fg: "#fff", g: (s.name || s.ticker || "?").slice(0, 1) };
  const src = logoSrc(s.ticker);
  const cls = `stock-mark${size === "sm" ? " sm" : size === "lg" ? " lg" : ""}${src ? " has-logo" : ""}`;
  const glyph = `<span class="stock-glyph">${esc(mark.g)}</span>`;
  const img = src ? `<img alt="" src="${esc(src)}" onerror="this.parentNode.classList.add('logo-failed')">` : "";
  return `<div class="${cls}" style="background:${mark.bg};color:${mark.fg}">${img}${glyph}</div>`;
}
const PHOTOS = {
  chip: "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=400&h=280&q=60",
  phone: "https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?auto=format&fit=crop&w=400&h=280&q=60",
  car: "https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=400&h=280&q=60",
  cloud: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=400&h=280&q=60",
  shop: "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=400&h=280&q=60",
  social: "https://images.unsplash.com/photo-1611162616475-46b635cb6868?auto=format&fit=crop&w=400&h=280&q=60"
};
const TAKE_LEVELS = [
  { v: -2, title: "강력 매도", short: "강매도", kick: "roast" },
  { v: -1, title: "매도", short: "매도", kick: "roast" },
  { v: 0, title: "관망", short: "관망", kick: "plain" },
  { v: 1, title: "추천", short: "추천", kick: "glory" },
  { v: 2, title: "강력 추천", short: "강추천", kick: "glory" }
];
const NEWS = {
  NVDA: [
    { t: "엔비디아, 실적 발표 앞두고 거래량 증가", ago: "2시간 전", src: "한국경제", q: "엔비디아 실적 거래량", img: PHOTOS.chip },
    { t: "데이터센터 가이던스 전망이 다시 나와", ago: "어제", src: "매일경제", q: "엔비디아 데이터센터 가이던스", img: PHOTOS.chip }
  ],
  AAPL: [
    { t: "애플 서비스 매출이 실적을 받쳐 준다는 분석", ago: "3시간 전", src: "서울경제", q: "애플 서비스 매출", img: PHOTOS.phone },
    { t: "신제품 사이클 눈높이 조정 중", ago: "어제", src: "한국경제", q: "애플 신제품 사이클", img: PHOTOS.phone }
  ],
  TSLA: [
    { t: "테슬라 인도량 숫자를 놓고 전망이 갈려", ago: "1시간 전", src: "매일경제", q: "테슬라 인도량", img: PHOTOS.car },
    { t: "마진 회복 속도가 다시 주목받는 이유", ago: "어제", src: "한국경제", q: "테슬라 마진", img: PHOTOS.car }
  ],
  AMD: [
    { t: "AMD, AI 칩 수주 이야기가 다시 나와", ago: "4시간 전", src: "서울경제", q: "AMD AI 칩 수주", img: PHOTOS.chip },
    { t: "서버 GPU 수요 눈높이 조정 중", ago: "어제", src: "매일경제", q: "AMD 서버 GPU", img: PHOTOS.chip }
  ],
  MSFT: [
    { t: "마이크로소프트 클라우드 실적 눈높이", ago: "2시간 전", src: "한국경제", q: "마이크로소프트 클라우드 실적", img: PHOTOS.cloud },
    { t: "AI 구독이 실적을 끌고 간다는 분석", ago: "어제", src: "매일경제", q: "마이크로소프트 AI 구독", img: PHOTOS.cloud }
  ],
  AMZN: [
    { t: "아마존 광고·AWS가 실적을 끌고 간다", ago: "5시간 전", src: "서울경제", q: "아마존 AWS 광고", img: PHOTOS.shop },
    { t: "물류 비용 이야기가 다시 나와", ago: "어제", src: "한국경제", q: "아마존 물류 비용", img: PHOTOS.shop }
  ],
  "005930": [
    { t: "삼성전자, 반도체 업황 이야기가 다시 나와", ago: "2시간 전", src: "한국경제", q: "삼성전자 반도체 업황", img: PHOTOS.chip, kr: true },
    { t: "HBM·파운드리 수주 전망", ago: "어제", src: "매일경제", q: "삼성전자 HBM 파운드리", img: PHOTOS.chip, kr: true }
  ],
  "000660": [
    { t: "SK하이닉스 HBM 수요 이야기가 나와", ago: "1시간 전", src: "한국경제", q: "SK하이닉스 HBM", img: PHOTOS.chip, kr: true },
    { t: "공급 계약 눈높이 조정 중", ago: "어제", src: "서울경제", q: "SK하이닉스 공급 계약", img: PHOTOS.chip, kr: true }
  ],
  "035420": [
    { t: "네이버 광고·커머스 회복 속도", ago: "3시간 전", src: "매일경제", q: "네이버 광고 커머스", img: PHOTOS.shop, kr: true },
    { t: "웹툰·콘텐츠 매출 이야기", ago: "어제", src: "한국경제", q: "네이버 웹툰 매출", img: PHOTOS.social, kr: true }
  ],
  "035720": [
    { t: "카카오 플랫폼 실적 눈높이 조정", ago: "2시간 전", src: "한국경제", q: "카카오 실적", img: PHOTOS.social, kr: true },
    { t: "톡비즈 회복 속도가 관전 포인트", ago: "어제", src: "서울경제", q: "카카오 톡비즈", img: PHOTOS.social, kr: true }
  ]
};

function headlines(ticker) {
  return NEWS[ticker] || [{ t: "그룹에서 이 종목 이야기 중", ago: "데모", src: "뉴스", q: ticker, img: PHOTOS.chip }];
}
function newsLine(ticker) {
  const item = headlines(ticker)[0];
  return item.t + " · " + item.ago + " · 데모";
}
function newsLink(item, ticker) {
  const q = encodeURIComponent(item.q || item.t);
  if (item.kr || (stock(ticker) || {}).market === "krx") {
    return "https://search.naver.com/search.naver?where=news&query=" + q;
  }
  return "https://news.google.com/search?q=" + q + "&hl=ko&gl=KR&ceid=KR:ko";
}
function newsCard(item, ticker) {
  return `<a class="news-card" href="${esc(newsLink(item, ticker))}" target="_blank" rel="noopener">
    <img class="news-thumb" src="${esc(item.img)}" alt="" onerror="this.style.visibility='hidden'">
    <span class="news-body">
      <span class="news-title">${esc(item.t)}</span>
      <span class="news-meta">${esc(item.src)} · ${esc(item.ago)}</span>
    </span>
  </a>`;
}
function takeMeta(v) {
  return TAKE_LEVELS.find((x) => x.v === v) || TAKE_LEVELS[2];
}
function takesFor(stockId) {
  return (state.takes || []).filter((t) => t.stockId === stockId);
}
function myTake(stockId) {
  const row = takesFor(stockId).find((t) => t.userId === state.me.id);
  return row ? row.level : null;
}
function groupTake(stockId) {
  const levels = takesFor(stockId).map((t) => t.level);
  if (!levels.length) return null;
  const avg = levels.reduce((a, b) => a + b, 0) / levels.length;
  const rounded = Math.sign(avg) * Math.round(Math.abs(avg));
  return Math.max(-2, Math.min(2, rounded));
}
function takeStepper(stockId) {
  const mine = myTake(stockId);
  const selected = mine == null ? groupTake(stockId) : mine;
  return `<div class="take-steps">${TAKE_LEVELS.map((lv) => `<button type="button" class="take-step ${lv.kick}${selected === lv.v ? " on" : ""}" data-act="take:${stockId}:${lv.v}">${esc(lv.short)}</button>`).join("")}</div>`;
}
function pulseOf(stockId) {
  const s = stock(stockId);
  const n = commentsFor(stockId).length;
  const pending = state.recs.filter((r) => r.stockId === stockId && (r.status === "pending" || r.status === "willBuy")).length;
  const shared = bonds().find((b) => b.stockId === stockId)?.shared;
  const items = headlines(s ? s.ticker : stockId);
  const voted = groupTake(stockId);
  const takeN = takesFor(stockId).length;
  let rating = "관망", kick = "plain", take = "아직 평가 없음", blurb = "그룹 평가 없음";
  if (n >= 3) { rating = "들뜸"; kick = "glory"; take = "지금 말이 많은 종목"; blurb = "댓글 " + n + (pending ? " · 추천 " + pending : ""); }
  else if (typeof shared === "number" && shared <= -0.15) { rating = "물림"; kick = "roast"; take = "같이 물린 분위기"; blurb = "깐부 수익률 " + formatPct(shared) + (n ? " · 댓글 " + n : ""); }
  else if (typeof shared === "number" && shared >= 0.15) { rating = "웃는 중"; kick = "glory"; take = "같이 웃는 분위기"; blurb = "깐부 수익률 " + formatPct(shared) + (n ? " · 댓글 " + n : ""); }
  else if (pending > 0) { rating = "추천 중"; kick = "plain"; take = n ? "추천이 왔고 댓글도 있음" : "추천이 와 있음"; blurb = "추천 " + pending + (n ? " · 댓글 " + n : ""); }
  else if (n > 0) { rating = "이야기 중"; kick = "plain"; take = "댓글이 오가는 중"; blurb = "댓글 " + n; }
  if (voted != null) {
    const meta = takeMeta(voted);
    rating = meta.title;
    kick = meta.kick;
    take = takeN ? "그룹 " + takeN + "명 평가" : meta.title;
  }
  return { rating, kick, take, blurb, items, voted, takeN, mine: myTake(stockId) };
}
function pulseStrip(stockId, compact) {
  const p = pulseOf(stockId);
  const ticker = (stock(stockId) || {}).ticker || stockId;
  const news = compact
    ? newsCard(p.items[0], ticker)
    : `<div class="pulse-blurb">${esc(p.blurb)}</div>
    ${takeStepper(stockId)}
    <div class="pulse-label">주요 뉴스</div>` + p.items.slice(0, 2).map((it) => newsCard(it, ticker)).join("");
  return `<div class="pulse ${compact ? "compact" : ""}">
    <div class="pulse-top"><span class="pulse-chip ${p.kick}">${esc(p.rating)}</span><span class="pulse-take">${esc(p.take)}</span></div>
    ${news}
  </div>`;
}
function seedValue(ticker) {
  return [...String(ticker)].reduce((a, c) => a + c.charCodeAt(0), 0);
}
function history(s, days) {
  days = days || 30;
  const base = priceOf(s);
  let prev = base * 0.86;
  const seed = seedValue(s.ticker);
  const points = [];
  const rnd = (v) => s.market === "krx" ? Math.round(v / 50) * 50 : Math.round(v * 100) / 100;
  for (let i = days; i >= 0; i--) {
    const wave = Math.sin((i + seed) / 6.5) * 0.018;
    const drift = ((seed % 7) - 3) * 0.0015;
    const closeRaw = Math.max(base * 0.55, prev * (1 + wave + drift));
    const close = i === 0 ? base : closeRaw;
    const open = prev * (1 + Math.sin((i + seed) / 3.1) * 0.005);
    const range = 0.008 + Math.abs(wave) * 1.4;
    const high = Math.max(open, close) * (1 + range);
    const low = Math.min(open, close) * (1 - range * 0.85);
    const volBase = 800000 + (seed % 11) * 90000;
    const volWave = 0.7 + Math.abs(Math.sin((i * 3 + seed) / 2.4));
    const spike = i <= 1 ? 2.15 : 1;
    const c = rnd(close);
    points.push({
      daysAgo: i,
      open: rnd(open),
      high: rnd(high),
      low: rnd(low),
      close: c,
      price: c,
      volume: volBase * volWave * spike
    });
    prev = closeRaw;
  }
  return points;
}
function rsiAt(closes, end, period) {
  period = period || 14;
  if (end < period) return null;
  let avgGain = 0;
  let avgLoss = 0;
  for (let i = 1; i <= period; i++) {
    const d = closes[i] - closes[i - 1];
    if (d >= 0) avgGain += d;
    else avgLoss -= d;
  }
  avgGain /= period;
  avgLoss /= period;
  for (let i = period + 1; i <= end; i++) {
    const d = closes[i] - closes[i - 1];
    avgGain = (avgGain * (period - 1) + Math.max(d, 0)) / period;
    avgLoss = (avgLoss * (period - 1) + Math.max(-d, 0)) / period;
  }
  if (avgLoss === 0) return avgGain === 0 ? 50 : 100;
  return 100 - 100 / (1 + avgGain / avgLoss);
}
function chartSignals(s) {
  const pts = history(s, 40);
  const closes = pts.map((p) => p.close);
  const rsi = rsiAt(closes, closes.length - 1);
  const vols = pts.map((p) => p.volume);
  const window = vols.slice(0, -1).slice(-20);
  const avg = window.length ? window.reduce((a, b) => a + b, 0) / window.length : 0;
  const last = vols[vols.length - 1] || 0;
  const ratio = avg ? last / avg : 1;
  const tags = [];
  if (rsi != null) {
    let label = "RSI " + Math.round(rsi);
    let on = false;
    if (rsi <= 30) { label += " 과매도"; on = true; }
    else if (rsi >= 70) { label += " 과매수"; on = true; }
    else if (rsi <= 35 || rsi >= 65) on = true;
    tags.push({ id: "rsi", label, on });
  }
  if (ratio >= 1.8) tags.push({ id: "vol", label: "거래량 급증 " + ratio.toFixed(1) + "배", on: true });
  else tags.push({ id: "vol", label: "거래량 " + ratio.toFixed(1) + "배", on: false });
  return { rsi, ratio, tags, pts };
}
function tvSymbol(s) {
  return (s.market === "krx" ? "KRX:" : "NASDAQ:") + s.ticker;
}
function tvURL(s) {
  return "https://www.tradingview.com/chart/?symbol=" + encodeURIComponent(tvSymbol(s));
}
function tvLink(s) {
  return `<a class="tv-link" href="${esc(tvURL(s))}" target="_blank" rel="noopener">새 탭에서 크게 보기</a>`;
}
const CHART_TAGS = [
  { id: "vol", label: "거래량 급증" },
  { id: "rsi-low", label: "RSI 과매도" },
  { id: "rsi-high", label: "RSI 과매수" },
  { id: "ma", label: "이평 돌파" },
  { id: "support", label: "지지선" }
];
function signalChips(labels) {
  if (!labels || !labels.length) return "";
  return `<div class="signal-row">${labels.map((l) => `<span class="signal-chip">${esc(l)}</span>`).join("")}</div>`;
}
function tvBoxHTML(s, height) {
  height = height || 440;
  return `<div class="tv-wrap">
    <div class="tv-box" id="tv-chart" data-tv-symbol="${esc(tvSymbol(s))}" style="height:${height}px"></div>
  </div>`;
}
let tvScriptTried = false;
function ensureTradingView(cb) {
  if (window.TradingView) {
    cb();
    return;
  }
  if (!tvScriptTried) {
    tvScriptTried = true;
    const s = document.createElement("script");
    s.src = "https://s3.tradingview.com/tv.js";
    s.async = true;
    s.onload = () => cb();
    s.onerror = () => {};
    document.head.appendChild(s);
  }
  const started = Date.now();
  const t = setInterval(() => {
    if (window.TradingView) {
      clearInterval(t);
      cb();
    } else if (Date.now() - started > 8000) {
      clearInterval(t);
    }
  }, 200);
}
function mountTradingView() {
  const el = document.getElementById("tv-chart");
  if (!el) return;
  const symbol = el.getAttribute("data-tv-symbol");
  if (!symbol) return;
  ensureTradingView(() => {
    if (!window.TradingView || !document.getElementById("tv-chart")) return;
    const node = document.getElementById("tv-chart");
    if (!node || node.getAttribute("data-tv-symbol") !== symbol) return;
    node.innerHTML = "";
    const dark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
    try {
      new TradingView.widget({
        autosize: true,
        symbol,
        interval: "D",
        timezone: "Asia/Seoul",
        theme: dark ? "dark" : "light",
        style: "1",
        locale: "kr",
        withdateranges: true,
        hide_side_toolbar: true,
        allow_symbol_change: false,
        save_image: true,
        hide_volume: false,
        enable_publishing: false,
        studies: ["STD;RSI", "Volume@tv-basicstudies"],
        container_id: "tv-chart"
      });
    } catch (_) {}
  });
}
function chartPickHTML(s, readonly) {
  const pts = history(s, 30);
  const idx = readonly || state.chartIndex == null ? pts.length - 1 : Math.min(state.chartIndex, pts.length - 1);
  const picked = pts[idx];
  const closes = pts.map((p) => p.close);
  const rsi = rsiAt(closes, idx);
  const min = Math.min.apply(null, pts.map((p) => p.low));
  const max = Math.max.apply(null, pts.map((p) => p.high));
  const span = max - min || 1;
  const maxVol = Math.max.apply(null, pts.map((p) => p.volume)) || 1;
  const w = 320;
  const candleTop = 8;
  const candleH = 118;
  const volTop = 132;
  const volH = 28;
  const rsiTop = 168;
  const rsiH = 26;
  const h = 202;
  const slot = (w - 16) / pts.length;
  const y = (v) => candleTop + (1 - (v - min) / span) * candleH;
  const candles = pts.map((p, i) => {
    const cx = 8 + slot * (i + 0.5);
    const bw = Math.max(2, slot * 0.62);
    const bull = p.close >= p.open;
    const color = bull ? "var(--up)" : "var(--down)";
    const top = y(Math.max(p.open, p.close));
    const bot = y(Math.min(p.open, p.close));
    return `<g class="cnd${i === idx ? " on" : ""}">
      <line x1="${cx.toFixed(1)}" x2="${cx.toFixed(1)}" y1="${y(p.high).toFixed(1)}" y2="${y(p.low).toFixed(1)}" stroke="${color}" stroke-width="1"></line>
      <rect x="${(cx - bw / 2).toFixed(1)}" y="${top.toFixed(1)}" width="${bw.toFixed(1)}" height="${Math.max(1.2, bot - top).toFixed(1)}" fill="${color}"></rect>
    </g>`;
  }).join("");
  const vols = pts.map((p, i) => {
    const cx = 8 + slot * (i + 0.5);
    const bw = Math.max(2, slot * 0.62);
    const vh = (p.volume / maxVol) * volH;
    const bull = p.close >= p.open;
    return `<rect x="${(cx - bw / 2).toFixed(1)}" y="${(volTop + volH - vh).toFixed(1)}" width="${bw.toFixed(1)}" height="${Math.max(1, vh).toFixed(1)}" fill="${bull ? "var(--up)" : "var(--down)"}" opacity="${i === idx ? 0.85 : 0.35}"></rect>`;
  }).join("");
  const rsiPts = [];
  for (let i = 0; i < pts.length; i++) {
    const v = rsiAt(closes, i);
    if (v == null) continue;
    const x = 8 + slot * (i + 0.5);
    const ry = rsiTop + (1 - v / 100) * rsiH;
    rsiPts.push(x.toFixed(1) + "," + ry.toFixed(1));
  }
  const when = picked.daysAgo === 0 ? "오늘" : picked.daysAgo + "일 전";
  const rsiTxt = rsi != null ? " · RSI " + Math.round(rsi) : "";
  const meta = readonly
    ? `데모 캔들 · ${when} ${formatPrice(picked.close, s.market)}${rsiTxt}`
    : state.chartIndex == null
      ? `캔들을 눌러 종가 고르기 · 오늘 ${formatPrice(pts[pts.length - 1].close, s.market)}${rsiTxt}`
      : `${when} · ${formatPrice(picked.close, s.market)}${rsiTxt}`;
  const cap = readonly
    ? "트레이딩뷰 일봉입니다. 거래량과 RSI가 같이 열립니다. 주문이 나가지 않습니다."
    : "위는 트레이딩뷰 실세입니다. 아래 캔들을 눌러 매수 기록용 종가를 고르세요. 두 가격은 다를 수 있습니다.";
  const tv = tvBoxHTML(s, readonly ? 460 : 380);
  if (readonly) {
    return `<div class="chart-box">
      <div class="chart-cap">${cap}</div>
      ${tv}
      ${tvLink(s)}
    </div>`;
  }
  return `<div class="chart-box">
    <div class="chart-cap">${cap}</div>
    ${tv}
    ${tvLink(s)}
    <div class="kind" style="margin-top:14px">매수 기록용</div>
    <svg class="chart" viewBox="0 0 ${w} ${h}" role="img" aria-label="매수 기록용 캔들">
      <rect width="${w}" height="${h}" fill="transparent"></rect>
      ${candles}
      ${vols}
      <line x1="8" x2="${w - 8}" y1="${(rsiTop + rsiH * 0.3).toFixed(1)}" y2="${(rsiTop + rsiH * 0.3).toFixed(1)}" stroke="currentColor" opacity="0.12"></line>
      <line x1="8" x2="${w - 8}" y1="${(rsiTop + rsiH * 0.7).toFixed(1)}" y2="${(rsiTop + rsiH * 0.7).toFixed(1)}" stroke="currentColor" opacity="0.12"></line>
      ${rsiPts.length ? `<polyline fill="none" stroke="currentColor" stroke-width="1.4" points="${rsiPts.join(" ")}"></polyline>` : ""}
    </svg>
    <div class="chart-meta">${meta}</div>
  </div>`;
}
function applyChartPick(clientX) {
  const svg = document.querySelector("svg.chart:not(.static)");
  const ticker = document.getElementById("add-ticker")?.value;
  const s = ticker ? stock(ticker) : null;
  if (!svg || !s) return;
  const pts = history(s, 30);
  const rect = svg.getBoundingClientRect();
  const x = clientX - rect.left;
  const idx = Math.max(0, Math.min(pts.length - 1, Math.floor((x / Math.max(rect.width, 1)) * pts.length)));
  state.chartIndex = idx;
  state.addTicker = ticker;
  const p = pts[idx].close;
  state.addPrice = s.market === "krx" ? String(Math.round(p)) : p.toFixed(2);
  const input = document.getElementById("add-price");
  if (input) input.value = state.addPrice;
  const meta = document.querySelector(".chart-meta");
  const when = pts[idx].daysAgo === 0 ? "오늘" : pts[idx].daysAgo + "일 전";
  const rsi = rsiAt(pts.map((pt) => pt.close), idx);
  if (meta) meta.textContent = when + " · " + formatPrice(p, s.market) + (rsi != null ? " · RSI " + Math.round(rsi) : "");
  svg.querySelectorAll(".cnd").forEach((el, i) => el.classList.toggle("on", i === idx));
}
function ico(name, filled) {
  const solid = filled && (name === "heart" || name === "me" || name === "star");
  const sw = solid
    ? `fill="currentColor" stroke="none"`
    : `fill="none" stroke="currentColor" stroke-width="${filled ? 2.15 : 1.7}" stroke-linecap="round" stroke-linejoin="round"`;
  const paths = {
    group: `<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>`,
    chart: `<path d="M3 3v18h18"/><path d="M7 14l4-4 4 4 6-7"/>`,
    heart: `<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78L12 21.23l8.84-8.84a5.5 5.5 0 0 0 0-7.78z"/>`,
    me: `<circle cx="12" cy="8" r="4"/><path d="M4 20a8 8 0 0 1 16 0"/>`,
    comment: `<path d="M21 11.5a8.5 8.5 0 0 1-8.5 8.4 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.7a8.4 8.4 0 0 1-.9-3.8 8.5 8.5 0 0 1 8.5-8.5h.5a8.5 8.5 0 0 1 8 8.5z"/>`,
    plane: `<path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4 20-7z"/>`,
    star: `<path d="M12 2l2.6 6.6L22 10l-5 4.9L18.2 22 12 18.3 5.8 22 7 14.9 2 10l7.4-1.4L12 2z"/>`,
    down: `<path d="M6 9l6 6 6-6"/>`
  };
  return `<svg viewBox="0 0 24 24" ${sw}>${paths[name] || ""}</svg>`;
}
function commentMeta(stockId) {
  const n = commentsFor(stockId).length;
  return `<span class="icon-meta">${ico("comment")}${n ? `<span>${n}</span>` : ""}</span>`;
}

function emptyState(me) {
  return {
    me,
    users: [me],
    groups: [],
    members: [],
    selectedGroupId: null,
    holdings: [],
    recs: [],
    proposals: [],
    cobuys: [],
    suspicions: [],
    events: [],
    badges: [],
    comments: [],
    takes: [],
    stocks: makeStocks(),
    onboarding: true,
    tab: "group",
    sheet: null,
    toast: null,
    error: null,
    replyTo: null,
    threadDraft: "",
    addTicker: null,
    addPrice: "",
    chartIndex: null,
    groupOpen: { turn: true, mood: true },
    inboxPage: 0,
    threadImage: null,
    lightbox: null,
    recTags: {},
    mode: null,
    roomId: null,
    sync: "off",
    pendingJoin: ""
  };
}

function seed(state) {
  const friends = [
    { id: "cheolsu", nickname: "철수" },
    { id: "younghee", nickname: "영희" },
    { id: "minsu", nickname: "민수" },
    { id: "junho", nickname: "준호" },
    { id: "sujin", nickname: "수진" }
  ];
  state.users.push(...friends);
  const group = { id: "g1", name: "우리 주식팟", invite: "KKANBU", ownerId: "cheolsu" };
  state.groups.push(group);
  state.selectedGroupId = group.id;
  const people = [state.me, ...friends];
  people.forEach((p, i) => state.members.push({ groupId: group.id, userId: p.id, joinedAt: now() - days(20 - i) }));

  const H = (userId, ticker, avg, extra = {}) => ({
    id: uid(),
    userId,
    stockId: ticker,
    averagePrice: avg,
    quantity: extra.quantity,
    status: extra.status || "holding",
    sellPrice: extra.sellPrice,
    verification: extra.verification || "unverified",
    createdAt: extra.createdAt || now() - days(14)
  });

  const youngheeNVDA = H("younghee", "NVDA", 140, { quantity: 2, createdAt: now() - days(32) });
  const junhoTSLA = H("junho", "TSLA", 241, { verification: "suspected", createdAt: now() - days(10) });
  state.holdings.push(
    H("cheolsu", "NVDA", 138, { quantity: 4, verification: "screenshot", createdAt: now() - days(40) }),
    youngheeNVDA,
    H("cheolsu", "AAPL", 198, { verification: "screenshot", createdAt: now() - days(50) }),
    H("younghee", "AAPL", 210.4, { createdAt: now() - days(18) }),
    H("minsu", "TSLA", 180, { status: "sold", sellPrice: 212, createdAt: now() - days(25) }),
    junhoTSLA,
    H("sujin", "005930", 68500, { verification: "screenshot", createdAt: now() - days(60) }),
    H("minsu", "000660", 210000, { createdAt: now() - days(12) }),
    H("younghee", "AMD", 142, { createdAt: now() - days(22) }),
    H(state.me.id, "AAPL", 205, { createdAt: now() - days(14) }),
    H("minsu", "035720", 62000, { createdAt: now() - days(16) }),
    H("junho", "035720", 62000, { createdAt: now() - days(15) })
  );

  const nvdaTags = ["거래량 급증", "RSI 과매수"];
  state.recs.push({
    id: "rec1", groupId: group.id, senderId: "younghee", receiverId: state.me.id,
    stockId: "NVDA", holdingId: youngheeNVDA.id, message: "같이 들어가 봐.",
    status: "pending", createdAt: now() - hours(3), signals: nvdaTags
  });
  state.comments.push(
    { id: "cm1", groupId: group.id, stockId: "NVDA", authorId: "cheolsu", parentId: null, body: "지금 들어가도 늦었나", createdAt: now() - hours(2) },
    { id: "cm2", groupId: group.id, stockId: "NVDA", authorId: state.me.id, parentId: "cm1", body: "평단만 적어둘게", createdAt: now() - hours(1) },
    { id: "cm3", groupId: group.id, stockId: "NVDA", authorId: "minsu", parentId: null, body: "나는 패스ㅋㅋ 물리면 니 탓이다", createdAt: now() - hours(0.5) },
    { id: "cm4", groupId: group.id, stockId: "NVDA", authorId: "cheolsu", parentId: null, body: "차트 보니까 이 구간 지지선이야.", image: chartSnapshot("NVDA"), createdAt: now() - hours(0.4) }
  );
  state.takes.push(
    { id: "tk-nvda-yh", groupId: group.id, stockId: "NVDA", userId: "younghee", level: 2 },
    { id: "tk-nvda-cs", groupId: group.id, stockId: "NVDA", userId: "cheolsu", level: 1 },
    { id: "tk-nvda-ms", groupId: group.id, stockId: "NVDA", userId: "minsu", level: 2 },
    { id: "tk-aapl-me", groupId: group.id, stockId: "AAPL", userId: state.me.id, level: 1 },
    { id: "tk-kakao-ms", groupId: group.id, stockId: "035720", userId: "minsu", level: -2 },
    { id: "tk-kakao-jh", groupId: group.id, stockId: "035720", userId: "junho", level: -1 },
    { id: "tk-amd-ms", groupId: group.id, stockId: "AMD", userId: "minsu", level: 1 }
  );
  const proposal = {
    id: "p1", groupId: group.id, proposerId: "minsu", stockId: "AMD",
    message: "이번에 같이 들어갈 사람?", createdAt: now() - hours(8)
  };
  state.proposals.push(proposal);
  state.cobuys.push(
    { id: "c1", proposalId: "p1", groupId: group.id, userId: "minsu", stockId: "AMD", nagCount: 1, lastNagAt: now() - hours(1), status: "promised" },
    { id: "c2", proposalId: "p1", groupId: group.id, userId: "younghee", stockId: "AMD", nagCount: 0, status: "promised" }
  );
  state.suspicions.push({ holdingId: junhoTSLA.id, actorId: "minsu", targetUserId: "junho", createdAt: now() - hours(5) });

  const nick = state.me.nickname;
  state.events = [
    ev(group.id, "멤버 참여", `${nick}님이 그룹에 참여했습니다.`, now() - 120000, "member", state.me.id),
    ev(group.id, "추천", `영희가 ${nick}에게 NVIDIA를 추천했습니다.`, now() - hours(3), "rec", "younghee", "NVDA"),
    ev(group.id, "댓글", `철수가 NVIDIA에 댓글을 남겼습니다. “지금 들어가도 늦었나”`, now() - hours(2), "cmt", "cheolsu", "NVDA"),
    ev(group.id, "대댓글", `${nick}가 NVIDIA에 답글을 남겼습니다. “평단만 적어둘게”`, now() - hours(1), "cmt", state.me.id, "NVDA"),
    ev(group.id, "사진", `철수가 NVIDIA에 차트 사진을 남겼습니다.`, now() - hours(0.4), "cmt", "cheolsu", "NVDA"),
    ev(group.id, "매수 제안", `민수가 AMD 매수를 제안했습니다.`, now() - hours(8), "prop", "minsu", "AMD"),
    ev(group.id, "매수 제안 · 재요청", `${nick}에게 AMD 매수를 다시 제안했습니다.`, now() - hours(1), "nag", "minsu", "AMD"),
    ev(group.id, "깐부", `${nick} · 철수 · Apple`, now() - days(14), "kk", state.me.id),
    ev(group.id, "깐부", `철수 · 영희 · NVIDIA`, now() - days(32), "kk", "cheolsu"),
    ev(group.id, "황금 깐부", `철수 · 영희가 NVIDIA 황금 깐부가 되었습니다.`, now() - days(4), "gold", "cheolsu"),
    ev(group.id, "최악의 주식 파트너", `민수 · 준호가 카카오에서 최악의 주식 파트너가 되었습니다. 같이 물린 사이.`, now() - days(3), "worst", "minsu"),
    ev(group.id, "혼자 매도", `Tesla를 매도했습니다. 준호는 아직 보유 중.`, now() - days(2), "solo", "minsu"),
    ev(group.id, "구라핑 의심", `준호의 Tesla 매수가를 의심하고 있습니다.`, now() - hours(5), "gura", "minsu"),
    ev(group.id, "인증", `NVIDIA 매수가를 인증했습니다.`, now() - days(39), "shot", "cheolsu"),
    ev(group.id, "존버", `Tesla에서 친구들이 떠났는데 준호만 남아 있습니다.`, now() - days(2) + 30000, "diamond", "junho")
  ];
  state.badges = [
    { userId: "cheolsu", title: "황금 깐부" },
    { userId: "younghee", title: "황금 깐부" },
    { userId: "junho", title: "존버" }
  ];
  state.onboarding = false;
  state.mode = "demo";
  state.roomId = null;
}

function chartSnapshot(ticker) {
  const s = stock(ticker);
  if (!s) return null;
  const pts = history(s, 30);
  const c = document.createElement("canvas");
  c.width = 720;
  c.height = 340;
  const ctx = c.getContext("2d");
  ctx.fillStyle = "#fafafa";
  ctx.fillRect(0, 0, c.width, c.height);
  const min = Math.min.apply(null, pts.map((p) => p.low));
  const max = Math.max.apply(null, pts.map((p) => p.high));
  const span = max - min || 1;
  const maxVol = Math.max.apply(null, pts.map((p) => p.volume)) || 1;
  const left = 28;
  const usable = c.width - 56;
  const candleTop = 48;
  const candleH = 180;
  const volTop = 236;
  const volH = 44;
  const slot = usable / pts.length;
  const y = (v) => candleTop + (1 - (v - min) / span) * candleH;
  pts.forEach((p, i) => {
    const cx = left + slot * (i + 0.5);
    const bw = Math.max(2.8, slot * 0.56);
    const bull = p.close >= p.open;
    ctx.strokeStyle = ctx.fillStyle = bull ? "#e11d48" : "#2563eb";
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.moveTo(cx, y(p.high));
    ctx.lineTo(cx, y(p.low));
    ctx.stroke();
    const top = y(Math.max(p.open, p.close));
    const h = Math.max(2, y(Math.min(p.open, p.close)) - top);
    ctx.fillRect(cx - bw / 2, top, bw, h);
    const vh = Math.max(2, volH * (p.volume / maxVol));
    ctx.globalAlpha = 0.4;
    ctx.fillRect(cx - bw / 2, volTop + volH - vh, bw, vh);
    ctx.globalAlpha = 1;
  });
  ctx.fillStyle = "#111";
  ctx.font = "700 22px sans-serif";
  ctx.fillText(s.name + " · " + s.ticker, 28, 30);
  ctx.fillStyle = "#737373";
  ctx.font = "13px sans-serif";
  const rsi = rsiAt(pts.map((p) => p.close), pts.length - 1);
  ctx.fillText("데모 캔들 · RSI·거래량" + (rsi != null ? " · RSI " + Math.round(rsi) : ""), 28, c.height - 16);
  ctx.fillStyle = "#e11d48";
  ctx.font = "700 16px sans-serif";
  ctx.fillText(formatPrice(pts[pts.length - 1].close, s.market), c.width - 180, 30);
  return c.toDataURL("image/jpeg", 0.72);
}

function compressImageFile(file) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      const max = 1200;
      let w = img.width;
      let h = img.height;
      const scale = Math.min(1, max / Math.max(w, h));
      w = Math.max(1, Math.round(w * scale));
      h = Math.max(1, Math.round(h * scale));
      const c = document.createElement("canvas");
      c.width = w;
      c.height = h;
      c.getContext("2d").drawImage(img, 0, 0, w, h);
      URL.revokeObjectURL(url);
      resolve(c.toDataURL("image/jpeg", 0.72));
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("image"));
    };
    img.src = url;
  });
}

function persist() {
  if (state.onboarding) return;
  const snap = {
    ...state,
    sheet: null,
    toast: null,
    error: null,
    threadDraft: "",
    threadImage: null,
    lightbox: null,
    recTags: {},
    chartIndex: null,
    sync: state.sync || "off"
  };
  try {
    localStorage.setItem("kkanbu-web-v1", JSON.stringify(snap));
  } catch (_) {
    try {
      snap.comments = (snap.comments || []).map((c) => ({ ...c, image: null }));
      localStorage.setItem("kkanbu-web-v1", JSON.stringify(snap));
    } catch (__) {}
  }
  if (state.mode === "live") scheduleRoomPush(480);
}

function loadPersisted() {
  try {
    const raw = localStorage.getItem("kkanbu-web-v1");
    if (!raw) return null;
    const saved = JSON.parse(raw);
    if (!saved || !saved.me || saved.onboarding) return null;
    return saved;
  } catch (_) {
    return null;
  }
}

const ROOM_BROKERS = [
  "wss://broker.emqx.io:8084/mqtt",
  "wss://broker.hivemq.com:8884/mqtt"
];
const ROOM_TOPIC = (code) => "kkanbu/v1/" + code;
const ROOM_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

let roomClient = null;
let roomApplying = false;
let roomPushTimer = 0;
let roomRev = 0;
let roomWanted = "";

function loadIdentity() {
  try {
    const raw = localStorage.getItem("kkanbu-identity");
    if (raw) {
      const me = JSON.parse(raw);
      if (me && me.id) return { id: me.id, nickname: me.nickname || "나" };
    }
  } catch (_) {}
  const me = { id: uid(), nickname: "나" };
  try { localStorage.setItem("kkanbu-identity", JSON.stringify(me)); } catch (_) {}
  return me;
}

function saveIdentity(me) {
  try { localStorage.setItem("kkanbu-identity", JSON.stringify({ id: me.id, nickname: me.nickname })); } catch (_) {}
}

function ensureIdentity(nickname) {
  const name = (nickname || "").trim() || state.me.nickname || "나";
  let id = state.me && state.me.id;
  if (!id || id === "me") id = uid();
  state.me = { id, nickname: name };
  saveIdentity(state.me);
  if (!state.users.some((u) => u.id === id)) state.users.push(state.me);
  else {
    const u = state.users.find((x) => x.id === id);
    if (u) u.nickname = name;
  }
}

function makeInviteCode() {
  const buf = crypto.getRandomValues(new Uint8Array(8));
  let s = "";
  for (let i = 0; i < 8; i++) s += ROOM_ALPHABET[buf[i] % ROOM_ALPHABET.length];
  return s;
}

function parseJoinFromText(text) {
  if (!text) return "";
  const s = String(text).trim();
  const tagged = s.match(/join=([A-HJ-NP-Z2-9]{6,14})/i);
  if (tagged) return tagged[1].toUpperCase();
  const compact = s.toUpperCase().replace(/[^A-Z0-9]/g, "");
  if (compact.length >= 6 && compact.length <= 14 && ![...compact].every((c) => "01IO".includes(c))) return compact;
  return "";
}

function parseJoin() {
  try {
    const hash = (location.hash || "").replace(/^#/, "");
    const query = new URLSearchParams(location.search);
    const fromHash = new URLSearchParams(hash);
    return parseJoinFromText(query.get("join") || fromHash.get("join") || hash.replace(/^join=/i, ""));
  } catch (_) {
    return "";
  }
}

function setJoinHash(code) {
  try {
    const url = new URL(location.href);
    url.hash = code ? "join=" + code : "";
    history.replaceState(null, "", url.pathname + url.search + url.hash);
  } catch (_) {
    try { if (code) location.hash = "join=" + code; } catch (__) {}
  }
}

function inviteURL() {
  const base = String(location.href).split("#")[0].split("?")[0];
  const code = state.roomId || group()?.invite || "";
  return code ? base + "#join=" + code : base;
}

function mergeById(a, b) {
  const map = new Map();
  const keyOf = (item) => {
    if (!item) return "";
    if (item.id != null && item.id !== "") return "id:" + item.id;
    if (item.groupId && item.userId && item.averagePrice == null && item.stockId == null && item.proposalId == null && item.level == null) return "mem:" + item.groupId + ":" + item.userId;
    if (item.holdingId && item.actorId) return "sus:" + item.holdingId + ":" + item.actorId;
    if (item.userId && item.title && item.stockId == null) return "badge:" + item.userId + ":" + item.title;
    if (item.stockId && item.userId && item.level != null && item.averagePrice == null) return "take:" + item.groupId + ":" + item.userId + ":" + item.stockId;
    return "";
  };
  (a || []).concat(b || []).forEach((item) => {
    const key = keyOf(item);
    if (!key) return;
    const prev = map.get(key);
    if (!prev) {
      map.set(key, item);
      return;
    }
    const ta = prev.updatedAt || prev.createdAt || 0;
    const tb = item.updatedAt || item.createdAt || 0;
    if (tb > ta) map.set(key, item);
    else if (tb === ta && item.status === "sold" && prev.status !== "sold") map.set(key, item);
    else if (tb === ta && item.image && !prev.image) map.set(key, item);
  });
  return [...map.values()];
}

function loadMqtt() {
  if (window.mqtt && window.mqtt.connect) return Promise.resolve(window.mqtt);
  return new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = "https://cdn.jsdelivr.net/npm/mqtt@5.10.4/dist/mqtt.min.js";
    s.onload = () => (window.mqtt && window.mqtt.connect ? resolve(window.mqtt) : reject(new Error("mqtt")));
    s.onerror = () => reject(new Error("mqtt"));
    document.head.appendChild(s);
  });
}

function packRoom() {
  roomRev += 1;
  const body = {
    v: 1,
    room: state.roomId,
    rev: roomRev,
    client: state.me.id,
    ts: now(),
    users: state.users,
    groups: state.groups,
    members: state.members,
    holdings: state.holdings,
    recs: state.recs,
    proposals: state.proposals,
    cobuys: state.cobuys,
    suspicions: state.suspicions,
    events: state.events,
    badges: state.badges,
    comments: state.comments || [],
    takes: state.takes,
    offsets: Object.fromEntries((state.stocks || []).map((s) => [s.id, s.offset || 0]))
  };
  let json = JSON.stringify(body);
  if (json.length > 180000) {
    body.comments = (body.comments || []).map((c) => ({ ...c, image: null }));
    json = JSON.stringify(body);
  }
  return json;
}

function applyRoom(remote) {
  if (!remote || remote.v !== 1 || !Array.isArray(remote.users)) return false;
  roomApplying = true;
  const stocks = state.stocks;
  const me = state.me;
  const sheet = state.sheet;
  const tab = state.tab;
  const groupOpen = state.groupOpen;
  const mode = state.mode;
  const roomId = state.roomId;
  state.users = mergeById(state.users, remote.users);
  state.groups = mergeById(state.groups, remote.groups);
  state.members = mergeById(state.members, remote.members);
  state.holdings = mergeById(state.holdings, remote.holdings);
  state.recs = mergeById(state.recs, remote.recs);
  state.proposals = mergeById(state.proposals, remote.proposals);
  state.cobuys = mergeById(state.cobuys, remote.cobuys);
  state.suspicions = mergeById(state.suspicions, remote.suspicions);
  state.events = mergeById(state.events, remote.events).sort((a, b) => (b.createdAt || 0) - (a.createdAt || 0));
  state.badges = mergeById(state.badges, remote.badges);
  state.comments = mergeById(state.comments, remote.comments);
  state.takes = mergeById(state.takes, remote.takes);
  if (!state.users.some((u) => u.id === me.id)) state.users.push(me);
  state.me = state.users.find((u) => u.id === me.id) || me;
  state.stocks = stocks;
  if (remote.offsets) {
    state.stocks.forEach((s) => {
      if (remote.offsets[s.id] != null) s.offset = remote.offsets[s.id];
    });
  }
  state.sheet = sheet;
  state.tab = tab;
  state.groupOpen = groupOpen;
  state.mode = mode;
  state.roomId = roomId;
  state.onboarding = false;
  roomRev = Math.max(roomRev, remote.rev || 0);
  if (state.groups[0] && !state.selectedGroupId) state.selectedGroupId = state.groups[0].id;
  roomApplying = false;
  return true;
}

function ensureMembership() {
  const g = group() || state.groups[0];
  if (!g) return false;
  let changed = false;
  state.selectedGroupId = g.id;
  if (!state.users.some((u) => u.id === state.me.id)) {
    state.users.push(state.me);
    changed = true;
  }
  if (!state.members.some((m) => m.groupId === g.id && m.userId === state.me.id)) {
    state.members.push({ id: uid(), groupId: g.id, userId: state.me.id, joinedAt: now() });
    state.events.unshift(ev(g.id, "멤버 참여", `${state.me.nickname}님이 그룹에 참여했습니다.`, now(), "member", state.me.id));
    changed = true;
  }
  return changed;
}

function canRerenderFromSync() {
  const sheet = state.sheet || "";
  if (document.getElementById("tv-chart")) return false;
  if (sheet.startsWith("thread:") || sheet.startsWith("open-rec") || sheet === "add" || sheet.startsWith("register:") || sheet.startsWith("addon:")) return false;
  return true;
}

function paintSync() {
  const el = document.querySelector(".sync-dot");
  if (!el) return;
  el.className = "sync-dot " + (state.sync || "off");
  el.textContent = state.sync === "on" ? "친구와 연결됨" : state.sync === "connecting" ? "연결 중" : state.sync === "error" ? "연결 실패" : "다시 연결 중";
}

function scheduleRoomPush(ms) {
  if (roomApplying || state.mode !== "live" || !state.roomId) return;
  clearTimeout(roomPushTimer);
  roomPushTimer = setTimeout(pushRoom, ms == null ? 480 : ms);
}

function pushRoom() {
  if (state.mode !== "live" || !state.roomId || !roomClient || !roomClient.connected) return;
  try {
    roomClient.publish(ROOM_TOPIC(state.roomId), packRoom(), { qos: 1, retain: true });
  } catch (_) {}
}

function stopRoom() {
  roomWanted = "";
  clearTimeout(roomPushTimer);
  if (roomClient) {
    try { roomClient.end(true); } catch (_) {}
    roomClient = null;
  }
  state.sync = "off";
}

function bindRoomClient(client) {
  const topic = ROOM_TOPIC(state.roomId);
  roomClient = client;
  client.subscribe(topic, { qos: 1 });
  state.sync = "on";
  paintSync();
  client.on("message", (_t, buf) => {
    if (state.mode !== "live") return;
    let remote;
    try { remote = JSON.parse(String(buf)); } catch (_) { return; }
    if (remote.room && state.roomId && remote.room !== state.roomId) return;
    if (remote.client === state.me.id && (remote.rev || 0) <= roomRev) return;
    applyRoom(remote);
    const joined = ensureMembership();
    persist();
    if (joined) scheduleRoomPush(120);
    if (canRerenderFromSync()) render();
    else paintSync();
  });
  client.on("offline", () => { state.sync = "off"; paintSync(); });
  client.on("reconnect", () => { state.sync = "connecting"; paintSync(); });
  client.on("connect", () => {
    state.sync = "on";
    paintSync();
    scheduleRoomPush(80);
  });
  client.on("error", () => { state.sync = "error"; paintSync(); });
  scheduleRoomPush(80);
}

async function connectRoom() {
  if (state.mode !== "live" || !state.roomId) return;
  roomWanted = state.roomId;
  state.sync = "connecting";
  paintSync();
  try {
    const mqtt = await loadMqtt();
    if (roomWanted !== state.roomId) return;
    if (roomClient) {
      try { roomClient.end(true); } catch (_) {}
      roomClient = null;
    }
    let lastErr;
    for (const url of ROOM_BROKERS) {
      if (roomWanted !== state.roomId) return;
      try {
        const client = await new Promise((resolve, reject) => {
          const c = mqtt.connect(url, {
            clientId: "kk" + String(state.me.id).replace(/[^a-zA-Z0-9]/g, "").slice(0, 10) + Math.random().toString(16).slice(2, 6),
            clean: true,
            keepalive: 30,
            reconnectPeriod: 2500,
            connectTimeout: 8000,
            protocolVersion: 4
          });
          let settled = false;
          const to = setTimeout(() => {
            if (settled) return;
            settled = true;
            try { c.end(true); } catch (_) {}
            reject(new Error("timeout"));
          }, 9000);
          c.once("connect", () => {
            if (settled) return;
            settled = true;
            clearTimeout(to);
            resolve(c);
          });
          c.once("error", (err) => {
            if (settled) return;
            settled = true;
            clearTimeout(to);
            try { c.end(true); } catch (_) {}
            reject(err || new Error("mqtt"));
          });
        });
        if (roomWanted !== state.roomId) {
          try { client.end(true); } catch (_) {}
          return;
        }
        bindRoomClient(client);
        return;
      } catch (err) {
        lastErr = err;
      }
    }
    throw lastErr || new Error("mqtt");
  } catch (_) {
    if (roomWanted !== state.roomId) return;
    state.sync = "error";
    paintSync();
    toast("친구 연결에 실패했습니다. 잠시 후 다시 열어 보세요.");
  }
}

async function shareInvite() {
  if (state.mode === "demo") {
    try { await navigator.clipboard.writeText(group()?.invite || "KKANBU"); } catch (_) {}
    toast("초대 코드 복사됨");
    return;
  }
  if (state.mode !== "live") {
    await promoteToLive();
  }
  const url = inviteURL();
  const code = state.roomId || group()?.invite || "";
  try {
    if (navigator.share) {
      await navigator.share({ title: "주식 깐부", text: "이 링크로 그룹에 들어와. 코드 " + code, url });
      toast("초대 링크를 보냈습니다");
      return;
    }
  } catch (err) {
    if (err && err.name === "AbortError") return;
  }
  try {
    await navigator.clipboard.writeText(url);
    toast("초대 링크 복사됨. 친구에게 보내세요.");
  } catch (_) {
    toast(url);
  }
}

async function promoteToLive() {
  ensureIdentity(state.me.nickname);
  const code = makeInviteCode();
  state.mode = "live";
  state.roomId = code;
  let g = group();
  if (!g) {
    g = { id: "g-" + code, name: (state.me.nickname || "우리") + "의 주식팟", invite: code, ownerId: state.me.id };
    state.groups.push(g);
    state.selectedGroupId = g.id;
    state.members.push({ id: uid(), groupId: g.id, userId: state.me.id, joinedAt: now() });
  } else {
    g.invite = code;
  }
  setJoinHash(code);
  persist();
  render();
  await connectRoom();
}

function createLiveRoom() {
  const nick = document.getElementById("nick")?.value?.trim() || "나";
  const name = document.getElementById("group-name")?.value?.trim() || nick + "의 주식팟";
  ensureIdentity(nick);
  const code = makeInviteCode();
  state = emptyState(state.me);
  state.mode = "live";
  state.roomId = code;
  state.onboarding = false;
  state.users = [state.me];
  state.groups = [{ id: "g-" + code, name, invite: code, ownerId: state.me.id }];
  state.selectedGroupId = state.groups[0].id;
  state.members = [{ id: uid(), groupId: state.groups[0].id, userId: state.me.id, joinedAt: now() }];
  state.events = [ev(state.groups[0].id, "멤버 참여", `${state.me.nickname}님이 그룹을 만들었습니다.`, now(), "member", state.me.id)];
  setJoinHash(code);
  toast("그룹을 만들었습니다. 초대를 눌러 친구에게 보내세요.");
  render();
  connectRoom();
}

async function joinLiveRoom() {
  const nick = document.getElementById("nick")?.value?.trim() || state.me.nickname || "나";
  const raw = document.getElementById("join-code")?.value || state.pendingJoin || parseJoin();
  const code = parseJoinFromText(raw);
  if (!code) {
    toast("초대 링크나 코드를 넣어 주세요");
    return;
  }
  ensureIdentity(nick);
  state = emptyState(state.me);
  state.mode = "live";
  state.roomId = code;
  state.onboarding = false;
  state.users = [state.me];
  state.pendingJoin = code;
  setJoinHash(code);
  toast("그룹에 들어가는 중");
  render();
  await connectRoom();
  const started = Date.now();
  while (Date.now() - started < 10000 && !(state.groups && state.groups.length)) {
    await new Promise((r) => setTimeout(r, 350));
  }
  if (!state.groups.length) {
    toast("아직 그룹이 없습니다. 초대한 친구가 앱을 열어 두었는지 확인해 주세요.");
    return;
  }
  if (ensureMembership()) {
    persist();
    scheduleRoomPush(80);
    render();
  }
  toast(group()?.name ? group().name + "에 들어왔습니다" : "그룹에 들어왔습니다");
}

function leaveRoom() {
  stopRoom();
  try { localStorage.removeItem("kkanbu-web-v1"); } catch (_) {}
  const me = loadIdentity();
  state = emptyState(me);
  state.pendingJoin = "";
  try { history.replaceState(null, "", location.pathname + location.search); } catch (_) {}
  toast("그룹에서 나갔습니다");
  render();
}

function ev(groupId, title, message, createdAt, type, actorId, stockId) {
  return { id: uid(), groupId, title, message, createdAt, type, actorId, stockId: stockId || null };
}

let state = emptyState(loadIdentity());
const saved = loadPersisted();
if (saved) {
  state = Object.assign(emptyState(saved.me), saved);
  state.sheet = null;
  state.lightbox = null;
  state.threadImage = null;
  if (!state.mode) {
    if ((state.groups || []).some((g) => g.invite === "KKANBU")) state.mode = "demo";
    else if ((state.groups || []).length) state.mode = "local";
  }
}
state.pendingJoin = parseJoin() || "";

function stock(id) { return state.stocks.find((s) => s.id === id); }
function user(id) { return state.users.find((u) => u.id === id); }
function nickname(id) { return user(id)?.nickname || "?"; }
function group() { return state.groups.find((g) => g.id === state.selectedGroupId); }
function memberUsers() {
  const g = group();
  if (!g) return [];
  return state.members.filter((m) => m.groupId === g.id).map((m) => user(m.userId)).filter(Boolean);
}
function activeHoldings(userId) {
  return state.holdings.filter((h) => h.userId === userId && h.status === "holding");
}
function bonds() {
  const g = group();
  if (!g) return [];
  const memberIds = new Set(memberUsers().map((u) => u.id));
  const active = state.holdings.filter((h) => h.status === "holding" && memberIds.has(h.userId));
  const byStock = {};
  active.forEach((h) => { (byStock[h.stockId] ||= []).push(h); });
  const out = [];
  Object.entries(byStock).forEach(([stockId, hs]) => {
    const unique = [];
    const seen = new Set();
    hs.forEach((h) => { if (!seen.has(h.userId)) { seen.add(h.userId); unique.push(h); } });
    if (unique.length < 2) return;
    for (let i = 0; i < unique.length; i++) {
      for (let j = i + 1; j < unique.length; j++) {
        const a = unique[i], b = unique[j];
        const p = priceOf(stock(stockId));
        const shared = (ret(a.averagePrice, p) + ret(b.averagePrice, p)) / 2;
        out.push({ stockId, a: a.userId, b: b.userId, shared, grade: gradeFor(shared) });
      }
    }
  });
  return out;
}
function partnersOf(userId, stockId) {
  return bonds()
    .filter((b) => b.stockId === stockId && (b.a === userId || b.b === userId))
    .map((b) => nickname(b.a === userId ? b.b : b.a));
}
function toast(msg) {
  state.toast = msg;
  const el = document.getElementById("toast");
  el.hidden = false;
  el.textContent = msg;
  clearTimeout(toast._t);
  toast._t = setTimeout(() => { el.hidden = true; }, 2200);
}
function pushEvent(title, message, type, actorId, stockId) {
  const g = group();
  state.events.unshift(ev(g.id, title, message, now(), type, actorId || state.me.id, stockId));
}

function inbox() {
  const me = state.me.id;
  const items = [];
  state.recs.filter((r) => r.receiverId === me && (r.status === "pending" || r.status === "willBuy")).forEach((r) => items.push({ kind: "recommend", rec: r }));
  state.proposals.forEach((p) => {
    const mine = state.cobuys.find((c) => c.proposalId === p.id && c.userId === me);
    const nagger = state.cobuys.find((c) => c.proposalId === p.id && (c.nagCount || 0) > 0);
    if (!mine) {
      items.push({ kind: nagger ? "nag" : "proposal", proposal: p });
    }
  });
  state.holdings.filter((h) => h.userId === me && (h.verification === "suspected" || h.verification === "mismatch")).forEach((h) => {
    items.push({ kind: "suspect", holding: h });
  });
  state.holdings.filter((h) => h.userId === me && h.verification === "needsReview").forEach((h) => {
    items.push({ kind: "reverify", holding: h });
  });
  return items;
}

function blendedAverage(oldAvg, oldQty, addPrice, addQty) {
  const total = oldQty + addQty;
  if (!(oldAvg > 0) || !(addPrice > 0) || !(oldQty > 0) || !(addQty > 0) || !(total > 0)) return null;
  return (oldAvg * oldQty + addPrice * addQty) / total;
}

function addToPosition(id) {
  const h = state.holdings.find((x) => x.id === id && x.userId === state.me.id);
  if (!h || h.status !== "holding") return;
  const s = stock(h.stockId);
  const addPrice = Number(document.getElementById("add-price")?.value);
  const addQty = Number(document.getElementById("add-qty")?.value);
  const oldQty = h.quantity || Number(document.getElementById("old-qty")?.value);
  const direct = Number(document.getElementById("new-avg")?.value);
  const directQty = Number(document.getElementById("new-qty")?.value);
  const blended = blendedAverage(h.averagePrice, oldQty, addPrice, addQty);
  if (blended != null) {
    h.averagePrice = blended;
    h.quantity = oldQty + addQty;
  } else if (direct > 0) {
    if (Math.abs(direct - h.averagePrice) < 1e-9 && !(directQty > 0 && directQty !== h.quantity)) {
      toast("바꿀 값이 없습니다.");
      return;
    }
    h.averagePrice = direct;
    if (directQty > 0) h.quantity = directQty;
  } else {
    toast("추가 매수가와 수량을 적거나, 새 평단을 적어 주세요.");
    return;
  }
  h.verification = "needsReview";
  pushEvent("평단 수정", `${nickname(state.me.id)}가 ${s.name} 평단을 ${formatPrice(h.averagePrice, s.market)}로 고쳤습니다. 인증이 풀렸습니다.`, "rec", state.me.id, h.stockId);
  toast("평단 " + formatPrice(h.averagePrice, s.market) + "로 바꿨습니다. 다시 인증해 주세요.");
  h.updatedAt = now();
  state.sheet = null;
  state.addTicker = null;
  state.addPrice = "";
  state.chartIndex = null;
  render();
}

function addHolding(ticker, avg, method = "manual") {
  if (activeHoldings(state.me.id).some((h) => h.stockId === ticker)) {
    toast("이미 보유 중인 종목입니다. 추매에서 평단을 고치세요.");
    return;
  }
  const s = stock(ticker);
  const holding = {
    id: uid(), userId: state.me.id, stockId: ticker, averagePrice: avg,
    status: "holding", verification: method === "screenshot" ? "screenshot" : "unverified", createdAt: now()
  };
  state.holdings.push(holding);
  const newBonds = bonds().filter((b) => b.stockId === ticker && (b.a === state.me.id || b.b === state.me.id));
  newBonds.forEach((b) => {
    const other = b.a === state.me.id ? b.b : b.a;
    pushEvent("깐부", `${s.name} · ${nickname(other)}`, "kk");
  });
  state.cobuys.filter((c) => c.userId === state.me.id && c.stockId === ticker && c.status === "promised").forEach((c) => {
    c.status = "registered";
  });
  let fromRec = false;
  state.recs.filter((r) => r.receiverId === state.me.id && r.stockId === ticker && (r.status === "pending" || r.status === "willBuy")).forEach((r) => {
    r.status = "accepted";
    fromRec = true;
  });
  if (fromRec) {
    pushEvent("추천 수락", `${s.name}를 사서 기록했습니다.`, "rec");
    toast(`${s.name}를 사서 기록했습니다`);
  } else {
    toast(`${s.name} 기록됨`);
  }
  state.sheet = null;
  state.addTicker = null;
  state.addPrice = "";
  state.chartIndex = null;
  render();
}

function sellHolding(id) {
  const h = state.holdings.find((x) => x.id === id);
  if (!h) return;
  const s = stock(h.stockId);
  const typed = Number(document.getElementById("sell-price")?.value);
  if (!(typed > 0)) {
    toast("내가 판 가격을 적어 주세요. 현재가로 채우지 않습니다.");
    return;
  }
  const p = typed;
  h.status = "sold";
  h.sellPrice = p;
  h.verification = "needsReview";
  h.updatedAt = now();
  const leftovers = state.holdings.filter((x) => x.stockId === h.stockId && x.status === "holding" && x.userId !== h.userId);
  if (leftovers.length) {
    pushEvent("혼자 매도", `${s.name}를 매도했습니다. ${nickname(leftovers[0].userId)}는 아직 보유 중.`, "solo", state.me.id, h.stockId);
    leftovers.forEach((left) => {
      pushEvent("존버", `${s.name}에서 ${nickname(left.userId)}만 남아 있습니다.`, "diamond", left.userId, h.stockId);
    });
  } else {
    pushEvent("매도", `${s.name}를 매도했습니다.`, "solo", state.me.id, h.stockId);
  }
  toast("매도 처리됨. 매도가 인증을 남겨 주세요.");
  state.sheet = null;
  render();
}

function verify(holdingId, mode) {
  const h = state.holdings.find((x) => x.id === holdingId);
  if (!h) return;
  const s = stock(h.stockId);
  const isSell = h.status === "sold";
  const label = isSell ? "매도가" : "매수가";
  if (mode === "mismatch") {
    h.verification = "mismatch";
    pushEvent("정보 불일치", `${s.name} ${label}와 캡처 정보가 다릅니다.`, "gura", state.me.id, h.stockId);
    toast("입력과 캡처가 다릅니다. 사기라고 단정하지 않습니다.");
    render();
    return;
  }
  if (mode === "adopt") {
    const next = Number(document.getElementById("verify-ocr")?.value);
    if (next > 0) {
      if (isSell) h.sellPrice = next;
      else h.averagePrice = next;
    }
  }
  h.verification = "screenshot";
  pushEvent(isSell ? "매도가 인증" : "인증", `${s.name} ${label}를 인증했습니다.`, "shot", state.me.id, h.stockId);
  toast(isSell ? "매도가 인증 완료" : "캡처 인증 완료");
  state.sheet = null;
  render();
}

function acceptRec(id, accept) {
  const rec = state.recs.find((r) => r.id === id);
  if (!rec) return;
  if (accept) {
    rec.status = "willBuy";
    pushEvent("매수 예정", `${stock(rec.stockId).name} 매수 예정으로 남겼습니다.`, "rec");
    toast("매수 예정으로 남겼습니다");
    render();
    return;
  }
  rec.status = "rejected";
  pushEvent("거절", `${stock(rec.stockId).name} 추천을 거절했습니다.`, "rec");
  toast("거절했습니다");
  render();
}

function declineProposal(proposalId) {
  const p = state.proposals.find((x) => x.id === proposalId);
  if (!p) return;
  const existing = state.cobuys.find((c) => c.proposalId === proposalId && c.userId === state.me.id);
  if (existing) existing.status = "declined";
  else state.cobuys.push({ id: uid(), proposalId, groupId: p.groupId, userId: state.me.id, stockId: p.stockId, status: "declined", nagCount: 0 });
  toast("패스했습니다");
  render();
}

function promiseCoBuy(proposalId) {
  const p = state.proposals.find((x) => x.id === proposalId);
  if (!p) return;
  const mine = state.cobuys.find((c) => c.proposalId === proposalId && c.userId === state.me.id);
  if (mine && mine.status === "promised") return;
  if (mine) mine.status = "promised";
  else state.cobuys.push({ id: uid(), proposalId, groupId: p.groupId, userId: state.me.id, stockId: p.stockId, status: "promised", nagCount: 0 });
  addComment(p.stockId, "관심 있음", null, true);
  pushEvent("관심", `${stock(p.stockId).name} 매수 제안에 관심을 남겼습니다.`, "prop", state.me.id, p.stockId);
  toast("관심을 남겼습니다");
  render();
}

function recStatusLabel(status) {
  return { pending: "대기", willBuy: "매수 예정", accepted: "매수 기록", rejected: "거절" }[status] || status;
}
function saveThreadDraft() {
  const input = document.getElementById("thread-text");
  if (input) state.threadDraft = input.value;
}
function commentsFor(stockId) {
  return (state.comments || []).filter((c) => c.stockId === stockId && c.groupId === group()?.id).sort((a, b) => a.createdAt - b.createdAt);
}
function photosFor(stockId) {
  return commentsFor(stockId).filter((c) => c.image);
}
function addComment(stockId, body, parentId, silent, image) {
  const text = (body || "").trim();
  const photo = image || (!silent ? state.threadImage : null);
  if (!text && !photo) {
    if (!silent) toast("내용이나 사진을 넣어 주세요.");
    return;
  }
  const already = silent && commentsFor(stockId).some((c) => c.authorId === state.me.id && c.body === text);
  if (already) return;
  const comment = {
    id: uid(), groupId: group().id, stockId, authorId: state.me.id,
    parentId: parentId || null, body: text, image: photo || null, createdAt: now()
  };
  state.comments.push(comment);
  if (silent) return;
  const title = photo && !text ? "사진" : parentId ? "대댓글" : "댓글";
  const kind = photo && !text ? "사진" : parentId ? "답글" : "댓글";
  const msg = photo && !text
    ? `${stock(stockId).name}에 차트 사진을 남겼습니다.`
    : photo
      ? `${stock(stockId).name}에 사진 댓글을 남겼습니다. “${text.slice(0, 40)}”`
      : `${stock(stockId).name}에 ${kind}을 남겼습니다. “${text.slice(0, 40)}”`;
  pushEvent(title, msg, "cmt", state.me.id, stockId);
  toast(parentId ? "대댓글을 남겼습니다" : (photo && !text ? "사진을 남겼습니다" : "댓글을 남겼습니다"));
  state.replyTo = null;
  state.threadImage = null;
  render();
}

function recommend(holdingId, toUserId, message) {
  const h = state.holdings.find((x) => x.id === holdingId);
  const signals = CHART_TAGS.filter((t) => state.recTags && state.recTags[t.id]).map((t) => t.label);
  const rec = {
    id: uid(), groupId: group().id, senderId: state.me.id, receiverId: toUserId,
    stockId: h.stockId, holdingId, message: (message || "").trim() || "같이 들어가 봐.",
    status: "pending", createdAt: now(), signals
  };
  state.recs.push(rec);
  pushEvent("추천", `${stock(h.stockId).name}를 ${nickname(toUserId)}에게 추천했습니다.`, "rec", state.me.id, h.stockId);
  toast("추천을 보냈습니다");
  state.sheet = null;
  state.recTags = {};
  render();
}

function propose(ticker, message) {
  const p = { id: uid(), groupId: group().id, proposerId: state.me.id, stockId: ticker, message, createdAt: now() };
  state.proposals.push(p);
  state.cobuys.push({ id: uid(), proposalId: p.id, groupId: group().id, userId: state.me.id, stockId: ticker, status: "promised", nagCount: 0 });
  pushEvent("매수 제안", `${stock(ticker).name} 매수를 제안했습니다.`, "prop");
  toast("제안을 보냈습니다");
  state.sheet = null;
  render();
}

function suspect(holdingId) {
  const h = state.holdings.find((x) => x.id === holdingId);
  if (h.userId === state.me.id) return;
  h.verification = "suspected";
  state.suspicions.push({ holdingId, actorId: state.me.id, targetUserId: h.userId, createdAt: now() });
  pushEvent("구라핑 의심", `${nickname(h.userId)}의 ${stock(h.stockId).name} 매수가를 의심하고 있습니다.`, "gura");
  toast("의심을 남겼습니다. 단정은 하지 않습니다.");
  render();
}

function shock(ticker, pct) {
  stock(ticker).offset += pct;
  toast("시세가 반영되었습니다");
  const s = stock(ticker);
  const holders = state.holdings.filter((h) => h.stockId === ticker && h.status === "holding");
  if (pct > 0 && holders.length >= 2) {
    const pair = holders.slice(0, 2);
    pushEvent("황금 깐부", `${nickname(pair[0].userId)} · ${nickname(pair[1].userId)} · ${s.name}`, "gold", pair[0].userId);
  }
  const sold = state.holdings.filter((h) => h.stockId === ticker && h.status === "sold");
  if (pct > 0 && sold.length) {
    pushEvent("너무 이른 매도", `${s.name}를 너무 일찍 매도했습니다.`, "early", sold[0].userId);
  }
  if (pct < 0 && sold.length) {
    pushEvent("선견지명", `${s.name}를 미리 정리했습니다.`, "foresight", sold[0].userId);
  }
  render();
}

function playAs(userId) {
  if (state.mode === "live") {
    toast("실제 그룹에서는 내 화면만 봅니다");
    return;
  }
  const u = user(userId);
  state.me = u;
  toast(`${u.nickname}으로 보는 중`);
  render();
}

function resetDemo() {
  stopRoom();
  try { localStorage.removeItem("kkanbu-web-v1"); } catch (_) {}
  const nick = ["철수", "영희", "민수", "준호", "수진"].includes(state.me.nickname) ? "나" : state.me.nickname;
  state = emptyState({ id: "me", nickname: nick || "나" });
  seed(state);
  toast("데모를 다시 시작했습니다");
  render();
}

function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

function initial(name) {
  return (name || "?").trim().slice(0, 1);
}
function avatarHTML(person, size) {
  const id = person.id || person.nickname || "x";
  const n = [...String(id)].reduce((a, c) => a + c.charCodeAt(0), 0) % 6;
  return `<div class="avatar c${n}${size === "sm" ? " sm" : size === "lg" ? " lg" : ""}">${esc(initial(person.nickname))}</div>`;
}
function brandMark() {
  return `<div class="brand-mark" aria-hidden="true"><span></span><span></span></div>`;
}
function emptyStateHTML(title, message) {
  return `<div class="empty-state">${brandMark()}<div class="empty-title">${esc(title)}</div><p class="empty-msg">${esc(message)}</p></div>`;
}
function btn(label, kind, action) {
  return `<button type="button" class="btn ${kind || "primary"}" data-act="${esc(action)}">${label}</button>`;
}
function sm(label, action) {
  return `<button type="button" class="btn sm" data-act="${esc(action)}">${label}</button>`;
}

function verifyMark(v) {
  if (v === "screenshot") return `<span class="verified" title="캡처 인증">✓</span>`;
  return "";
}

function holdingRow(h, isMine) {
  const s = stock(h.stockId);
  const p = h.status === "sold" ? (h.sellPrice || priceOf(s)) : priceOf(s);
  const r = ret(h.averagePrice, p);
  const partners = partnersOf(h.userId, h.stockId);
  const bond = bonds().find((b) => b.stockId === h.stockId && (b.a === h.userId || b.b === h.userId));
  const g = bond?.grade;
  const owner = user(h.userId);
  let actions = "";
  if (isMine && h.status === "holding") {
    actions = sm("친구에게 추천", `open-rec:${h.id}`) + sm("추매", `addon:${h.id}`) + sm("매도", `sell:${h.id}`);
  }
  if (isMine && h.verification !== "screenshot") {
    actions += sm(h.status === "sold" ? "매도가 인증" : "캡처 인증", `verify:${h.id}`);
  }
  const partnerLine = partners.length && g
    ? `${esc(partners.join(" · "))}와 <span class="grade ${g.kick}">${esc(g.title)}</span>`
    : "";
  const suspect = h.verification === "suspected" ? `<div class="caption">매수가 의심 중</div>`
    : h.verification === "needsReview"
      ? `<div class="caption">${h.status === "sold" ? "매도가 인증이 필요합니다" : "평단을 고쳐서 다시 인증이 필요합니다"}</div>`
      : "";
  return `
    <div class="row">
      ${stockMark(s)}
      <div class="grow">
        ${!isMine ? `<div class="caption">${esc(owner.nickname)}</div>` : ""}
        <div class="stock-name">${esc(s.name)}${verifyMark(h.verification)}</div>
        <div class="ticker">${esc(s.ticker)}</div>
        <div class="meta">평단 ${formatPrice(h.averagePrice, s.market)} · 현재가 ${formatPrice(priceOf(s), s.market)}</div>
        ${isMine ? pulseStrip(s.id, true) : ""}
        ${partnerLine ? `<div class="caption">${partnerLine}</div>` : ""}
        ${h.status === "sold" ? `<div class="caption">매도 · ${formatPct(ret(h.averagePrice, h.sellPrice))}</div>` : ""}
        ${suspect}
        ${actions ? `<div class="actions">${actions}</div>` : ""}
      </div>
      <div class="right">
        <div class="pct ${r >= 0 ? "up" : "down"}">${formatPct(r)}</div>
      </div>
    </div>`;
}

function threadBtn(stockId) {
  const n = commentsFor(stockId).length;
  return `<div style="height:8px"></div><button class="btn ghost" data-act="thread:${stockId}"><span class="icon-meta">${ico("comment")}<span>${n ? n : "댓글"}</span></span></button>`;
}

function inboxBlock(item) {
  if (item.kind === "recommend") {
    const rec = item.rec;
    const s = stock(rec.stockId);
    if (rec.status === "willBuy") {
      return `<div class="action-block">
        <div class="kind">매수 예정</div>
        <div class="row" style="border:0;padding:0 0 8px">
          ${stockMark(s)}
          <div class="grow">
            <div class="stock-name">${esc(nickname(rec.senderId))} · ${esc(s.name)}</div>
            <div class="ticker">${esc(s.ticker)}</div>
            ${signalChips(rec.signals)}
            ${pulseStrip(s.id, true)}
          </div>
        </div>
        ${btn("매수가 기록", "primary", `bought:${rec.id}`)}
        <div style="height:8px"></div>
        ${btn("취소", "secondary", `reject:${rec.id}`)}
        ${threadBtn(s.id)}
      </div>`;
    }
    return `<div class="action-block">
      <div class="kind">추천</div>
      <div class="row" style="border:0;padding:0 0 8px">
        ${stockMark(s)}
        <div class="grow">
          <div class="stock-name">${esc(nickname(rec.senderId))} · ${esc(s.name)}</div>
          <div class="ticker">${esc(s.ticker)}</div>
          ${signalChips(rec.signals)}
          ${pulseStrip(s.id, true)}
        </div>
      </div>
      ${btn("살게요", "primary", `accept:${rec.id}`)}
      <div style="height:8px"></div>
      ${btn("안 살게", "secondary", `reject:${rec.id}`)}
      ${threadBtn(s.id)}
    </div>`;
  }
  if (item.kind === "proposal" || item.kind === "nag") {
    const p = item.proposal;
    const s = stock(p.stockId);
    const kind = item.kind === "nag" ? "매수 제안 · 재요청" : "매수 제안";
    return `<div class="action-block">
      <div class="kind">${kind}</div>
      <div class="row" style="border:0;padding:0 0 8px">
        ${stockMark(s)}
        <div class="grow">
          <div class="stock-name">${esc(nickname(p.proposerId))} · ${esc(s.name)}</div>
          <div class="ticker">${esc(s.ticker)}</div>
        </div>
      </div>
      ${btn("관심 있음", "primary", `promise:${p.id}`)}
      <div style="height:8px"></div>
      ${btn("패스", "secondary", `later:${p.id}`)}
      ${threadBtn(s.id)}
    </div>`;
  }
  if (item.kind === "suspect" || item.kind === "reverify") {
    const h = item.holding;
    const s = stock(h.stockId);
    const isSell = h.status === "sold";
    const title = item.kind === "reverify" ? (isSell ? "매도가 인증" : "평단 재인증") : "매수가 확인 요청";
    const price = isSell ? (h.sellPrice || h.averagePrice) : h.averagePrice;
    const blurb = isSell
      ? `${formatPrice(price, s.market)}에 판 기록이 맞는지 캡처로 확인합니다. 사기라고 단정하지 않습니다.`
      : `${formatPrice(price, s.market)}에 산 기록이 맞는지 캡처로 확인합니다. 사기라고 단정하지 않습니다.`;
    return `<div class="action-block">
      <div class="kind">${title}</div>
      <div class="row" style="border:0;padding:0 0 8px">
        ${stockMark(s, "sm")}
        <div class="grow">
          <div class="stock-name">${esc(s.name)}</div>
          <div class="ticker">${esc(s.ticker)}</div>
        </div>
      </div>
      <p class="caption">${blurb}</p>
      ${btn(isSell ? "매도가 인증" : "캡처로 인증", "primary", `verify:${h.id}`)}
    </div>`;
  }
  return "";
}

function eventRow(e) {
  const actor = e.actorId ? user(e.actorId) : null;
  const kick = /황금|신의|매수 예정/.test(e.title) || e.type === "gold" ? "glory"
    : /최악|공동묘지|거절|혼자/.test(e.title) || e.type === "worst" || e.type === "solo" ? "roast"
    : "plain";
  const open = e.stockId && (e.type === "rec" || e.type === "cmt" || e.type === "prop" || e.type === "nag") ? ` data-act="thread:${e.stockId}"` : "";
  const badgeIco = e.type === "cmt" ? "comment" : e.type === "rec" ? "plane" : /황금|신의/.test(e.title) ? "star" : "plane";
  const badgeColor = kick === "glory" ? "var(--up)" : kick === "roast" ? "var(--down)" : "#262626";
  return `<div class="feed-item"${open} style="${open ? "cursor:pointer" : ""}">
    <div class="avatar-wrap">
      ${actor ? avatarHTML(actor, "sm") : `<div class="avatar sm c0">·</div>`}
      <span class="feed-badge" style="background:${badgeColor}">${ico(badgeIco, true)}</span>
    </div>
    <div class="grow">
      <div class="kind ${kick}">${esc(e.title)}</div>
      ${actor ? `<b>${esc(actor.nickname)}</b>` : ""}
      <div class="body">${esc(e.message)}</div>
      <div class="time">${relative(e.createdAt)}</div>
    </div>
  </div>`;
}

function renderOnboarding() {
  const pending = state.pendingJoin || "";
  return `
    <div class="screen onboard">
      ${brandMark()}
      <h1 class="brand-name">주식 깐부</h1>
      <p class="lead">친구를 초대하면 같은 그룹에서 주식을 같이 봅니다. 같은 종목을 사면 깐부가 됩니다.</p>
      <label>닉네임</label>
      <input id="nick" value="${esc(state.me.nickname)}" />
      ${pending ? `
        <p class="note">초대받은 그룹입니다. 닉네임을 적고 들어가세요.</p>
        <input type="hidden" id="join-code" value="${esc(pending)}" />
        ${btn("그룹에 참여", "primary full", "join-room")}
      ` : `
        <label>그룹 이름</label>
        <input id="group-name" placeholder="우리 주식팟" />
        ${btn("그룹 만들고 친구 초대", "primary full", "create-room")}
        <label>초대 링크 또는 코드</label>
        <input id="join-code" placeholder="링크를 붙여넣거나 코드" />
        ${btn("초대로 참여", "secondary full", "join-room")}
      `}
      <div style="height:8px"></div>
      ${btn("데모 둘러보기", "ghost full", "demo")}
      <p class="note">직접 입력한 보유 정보는 증권 계좌로 검증되지 않습니다. 투자 자문이 아닙니다.</p>
      <p class="note">Safari에서 공유 → 홈 화면에 추가하면 앱처럼 열립니다. 초대 링크를 아는 친구만 들어옵니다.</p>
    </div>`;
}

function isOpen(id, fallback) {
  if (state.groupOpen && state.groupOpen[id] === true) return true;
  if (state.groupOpen && state.groupOpen[id] === false) return false;
  return !!fallback;
}
function foldSection(id, title, count, preview, body, fallbackOpen) {
  const open = isOpen(id, fallbackOpen);
  const extra = !open && preview
    ? `<span class="preview">${esc(preview)}</span>`
    : `<span class="count">${count || ""}</span>`;
  return `<div class="section ${open ? "open" : ""}">
    <button type="button" class="section-head" data-act="fold:${id}" aria-expanded="${open}">
      <span class="label">${esc(title)}</span>
      ${extra}
      <span class="chev${open ? " up" : ""}">${ico("down")}</span>
    </button>
    ${open ? `<div class="section-body">${body}</div>` : ""}
  </div>`;
}
function turnPager(items) {
  if (!items.length) return "";
  const page = Math.max(0, Math.min(state.inboxPage || 0, items.length - 1));
  const body = `<div class="pager" id="turn-pager">
      ${items.map((it) => `<div class="pager-slide">${inboxBlock(it)}</div>`).join("")}
    </div>
    ${items.length > 1 ? `<div class="pager-nav">
      <span class="pager-idx">${page + 1} / ${items.length}</span>
      <div class="pager-dots">${items.map((_, i) => `<button type="button" class="${i === page ? "on" : ""}" data-act="page:${i}"></button>`).join("")}</div>
    </div>` : ""}`;
  return foldSection("turn", "내 차례", items.length, "", body, true);
}
function bindPager() {
  const pager = document.getElementById("turn-pager");
  if (!pager) return;
  const slides = pager.querySelectorAll(".pager-slide");
  const n = slides.length;
  if (!n) return;
  const sync = () => {
    const i = Math.max(0, Math.min(n - 1, Math.round(pager.scrollLeft / Math.max(pager.clientWidth, 1))));
    state.inboxPage = i;
    const idx = document.querySelector(".pager-idx");
    if (idx) idx.textContent = (i + 1) + " / " + n;
    document.querySelectorAll(".pager-dots button").forEach((d, k) => d.classList.toggle("on", k === i));
  };
  pager.addEventListener("scroll", sync, { passive: true });
  requestAnimationFrame(() => {
    pager.scrollLeft = (state.inboxPage || 0) * pager.clientWidth;
    sync();
  });
}

function talkedStockIds() {
  const gid = group()?.id;
  const ids = [];
  const push = (id) => { if (id && !ids.includes(id)) ids.push(id); };
  state.recs.filter((r) => r.groupId === gid).forEach((r) => push(r.stockId));
  state.proposals.filter((p) => p.groupId === gid).forEach((p) => push(p.stockId));
  (state.takes || []).filter((t) => !t.groupId || t.groupId === gid).forEach((t) => push(t.stockId));
  (state.comments || []).filter((c) => c.groupId === gid).forEach((c) => push(c.stockId));
  bonds().forEach((b) => push(b.stockId));
  return ids;
}

function stockCaption(stockId) {
  const gid = group()?.id;
  const recs = state.recs.filter((r) => r.groupId === gid && r.stockId === stockId);
  if (recs.length) {
    const last = recs[recs.length - 1];
    const arrows = recs.map((r) => `${nickname(r.senderId)} → ${nickname(r.receiverId)}`).join(" · ");
    return `<div class="caption">${esc(arrows)}</div>${last.message ? `<div class="meta">“${esc(last.message)}”</div>` : ""}`;
  }
  const proposals = state.proposals.filter((p) => p.groupId === gid && p.stockId === stockId);
  if (proposals.length) {
    const last = proposals[proposals.length - 1];
    return `<div class="caption">${esc(nickname(last.proposerId))} · 매수 제안</div>${last.message ? `<div class="meta">“${esc(last.message)}”</div>` : ""}`;
  }
  return "";
}

function moodSection() {
  const ids = talkedStockIds();
  if (!ids.length) return "";
  const first = stock(ids[0]);
  const preview = first ? first.name : "";
  const body = ids.map((id) => {
    const s = stock(id);
    return `<div class="row-block">
      <button class="row btn" data-act="thread:${id}">
        ${stockMark(s)}
        <div class="grow">
          <div class="stock-name">${esc(s.name)}</div>
          ${stockCaption(id)}
        </div>
        <div class="right">${commentMeta(id)}</div>
      </button>
      ${pulseStrip(id, false)}
    </div>`;
  }).join("");
  return foldSection("mood", "종목 평가", ids.length, preview, body, true);
}

function renderGroup() {
  const g = group();
  if (!g) {
    return `<div class="screen">${emptyStateHTML("아직 그룹이 없습니다", "그룹을 만들거나 초대 코드로 들어가세요.")}
      ${btn("데모 그룹으로 시작", "primary", "demo")}</div>`;
  }
  const items = inbox();
  const kk = bonds();
  const friendsHoldings = state.holdings.filter((h) => h.userId !== state.me.id && memberUsers().some((u) => u.id === h.userId) && h.status === "holding");
  return `
    <div class="screen">
      <div class="header-meta">
        <div class="page-title">${esc(g.name)}</div>
        <button class="btn text" data-act="rank">랭킹</button>
      </div>
      <div class="members story">${memberUsers().map((u) => `<button class="member" data-act="play:${u.id}">${avatarHTML(u)}<span>${esc(u.id === state.me.id ? "나" : u.nickname)}</span></button>`).join("")}</div>
      <div class="header-actions">
        <button class="invite-chip" data-act="share-invite"><span>초대</span>${esc(g.invite)}</button>
        ${state.mode === "live" ? `<span class="sync-dot ${esc(state.sync || "off")}">${state.sync === "on" ? "친구와 연결됨" : state.sync === "connecting" ? "연결 중" : state.sync === "error" ? "연결 실패" : "다시 연결 중"}</span>` : ""}
      </div>
      <div class="split">
        ${btn("주식 추가", "primary", "open-add")}
        ${btn("매수 제안", "secondary", "open-prop:")}
      </div>

      ${turnPager(items)}
      ${moodSection()}

      ${kk.length ? foldSection("kk", "깐부", kk.length, (kk.find((b) => b.grade.kick === "roast") || kk.find((b) => b.grade.kick === "glory") || kk[0]).grade.title, (() => {
          const mood = kk.find((b) => b.grade.kick === "roast") || kk.find((b) => b.grade.kick === "glory");
          const moodLine = mood ? `<p class="mood ${mood.grade.kick}">지금 분위기 · ${esc(nickname(mood.a))} · ${esc(nickname(mood.b))}, ${esc(mood.grade.title)}</p>` : "";
          return moodLine + kk.map((b) => `
          <div class="pair-row">
            ${stockMark(stock(b.stockId), "sm")}
            <div class="grow">
              <div class="names">${esc(nickname(b.a))} · ${esc(nickname(b.b))}</div>
              <div class="grade ${b.grade.kick}">${esc(b.grade.title)}</div>
              <div class="stock">${esc(stock(b.stockId).name)}</div>
            </div>
            <div class="pct ${b.shared >= 0 ? "up" : "down"}">${formatPct(b.shared)}</div>
          </div>`).join("");
        })()) : ""}

      ${friendsHoldings.length ? foldSection("friends", "친구 주식", friendsHoldings.length, "", `<div class="row-list">${friendsHoldings.map((h) => holdingRow(h, false)).join("")}</div>`) : ""}
    </div>`;
}

function renderHoldings() {
  const mine = state.holdings.filter((h) => h.userId === state.me.id);
  const active = mine.filter((h) => h.status === "holding");
  const sold = mine.filter((h) => h.status === "sold");
  const avg = active.length
    ? active.map((h) => ret(h.averagePrice, priceOf(stock(h.stockId)))).reduce((a, b) => a + b, 0) / active.length
    : 0;
  return `<div class="screen">
    <div class="page-title">내 주식</div>
    <div class="pct ${avg >= 0 ? "up" : "down"}" style="font-size:28px;margin:8px 0 4px">${active.length ? formatPct(avg) : "—"}</div>
    <p class="page-sub">보유 ${active.length}종목</p>
    <div class="split">
      ${btn("주식 추가", "primary", "open-add")}
      ${btn("매수 제안", "secondary", "open-prop:")}
    </div>
    ${active.length ? `<div class="section"><div class="section-title">보유 중</div><div class="row-list">${active.map((h) => holdingRow(h, true)).join("")}</div></div>` : emptyStateHTML("아직 주식이 없습니다", "종목을 넣으면 친구가 같은 걸 샀을 때 깐부가 됩니다.")}
    ${sold.length ? `<div class="section"><div class="section-title">매도 기록</div><div class="row-list">${sold.map((h) => holdingRow(h, true)).join("")}</div></div>` : ""}
    <p class="note">직접 입력한 보유 정보는 증권 계좌로 검증되지 않습니다.</p>
  </div>`;
}

function renderActivity() {
  const mine = inbox();
  const events = state.events || [];
  const spicy = events.find((e) => /황금|최악|공동묘지|혼자|선견|존버/.test(e.title));
  const rest = events.filter((e) => e !== spicy);
  const feed = rest.length
    ? rest.map(eventRow).join("")
    : (spicy ? "" : `<p class="empty">아직 기록이 없습니다.</p>`);
  return `<div class="screen">
    <div class="page-title">활동</div>
    <p class="page-sub">나를 향한 일과 그룹 기록</p>
    ${mine.length ? `<div class="row-list">${mine.map(inboxBlock).join("")}</div>` : emptyStateHTML("대기 중인 일이 없습니다", "추천이나 매수 제안이 오면 여기에 모입니다.")}
    ${spicy ? `<div class="section"><div class="section-title">지금</div>${eventRow(spicy)}</div>` : ""}
    ${feed ? `<div class="section"><div class="section-title">최근 기록</div>${feed}</div>` : ""}
  </div>`;
}

function renderProfile() {
  const g = group();
  const n = memberUsers().length;
  return `<div class="screen">
    <div class="page-title">프로필</div>
    <div class="profile-head">
      ${avatarHTML(state.me, "lg")}
      <div class="brand-name" style="font-size:22px;margin:12px 0 4px">${esc(state.me.nickname)}</div>
      <div class="caption">${g ? `${esc(g.name)} · 멤버 ${n}` : "아직 그룹 없음"}</div>
    </div>
    <div class="section">
      <div class="section-title">실험</div>
      <p class="note">시세를 흔들어 사건을 만들어 봅니다.</p>
      <div class="actions">
        ${sm("NVDA +12%", "shock:NVDA:0.12")}
        ${sm("NVDA -12%", "shock:NVDA:-0.12")}
        ${sm("TSLA +15%", "shock:TSLA:0.15")}
        ${sm("TSLA -15%", "shock:TSLA:-0.15")}
        ${sm("AAPL +8%", "shock:AAPL:0.08")}
      </div>
    </div>
    <div class="section">
      <div class="section-title">이 그룹</div>
      ${state.mode === "live" ? `
        <p class="note">초대를 누르면 링크가 복사됩니다. 친구가 그 링크를 열면 같은 그룹에 들어옵니다. 링크를 아는 사람만 들어올 수 있습니다.</p>
        ${btn("초대 링크 보내기", "primary full", "share-invite")}
        <div style="height:8px"></div>
        ${btn("그룹 나가기", "secondary full", "leave-room")}
      ` : state.mode === "demo" ? `
        <p class="note">데모입니다. 실친구와 쓰려면 나가서 그룹을 새로 만드세요.</p>
        <div class="section-title" style="margin-top:16px">친구로 보기</div>
        <p class="note">한 브라우저에서 상대 화면을 확인합니다.</p>
        <div class="actions">${memberUsers().map((u) => sm(u.nickname, `play:${u.id}`)).join("")}</div>
        ${btn("데모 리셋", "secondary full", "reset")}
      ` : `
        <p class="note">초대를 누르면 친구와 이 그룹을 같이 봅니다.</p>
        ${btn("친구 초대하기", "primary full", "share-invite")}
      `}
    </div>
    ${state.mode !== "live" ? `<div class="section">
      <div class="section-title">이 브라우저에서</div>
      <p class="note">Safari 공유 → 홈 화면에 추가하면 홈 화면에서 바로 열립니다.</p>
    </div>` : `<div class="section">
      <p class="note">Safari 공유 → 홈 화면에 추가하면 홈 화면에서 바로 열립니다.</p>
    </div>`}
  </div>`;
}

function sheetWrap(inner) {
  return `<div class="sheet"><div class="panel"><div class="grabber"></div>${inner}</div></div>`;
}

function sheetHTML() {
  if (!state.sheet) return "";
  if (state.sheet === "add" || state.sheet.startsWith("register:")) {
    const pre = state.sheet.startsWith("register:") ? state.sheet.split(":")[1] : "";
    const selectedId = state.addTicker || pre || state.stocks[0]?.id;
    const selected = stock(selectedId) || state.stocks[0];
    const options = state.stocks.map((s) => `<option value="${s.id}" ${s.id === selectedId ? "selected" : ""}>${s.name} (${s.ticker})</option>`).join("");
    const priceVal = state.addPrice || "";
    return sheetWrap(`
      <h2>주식 추가</h2>
      <p class="note">${pre ? "추천받은 종목입니다. 샀으면 아래 캔들 종가나 내가 산 가격을 적으세요. 현재가로 채우지 않습니다." : "위 트레이딩뷰에서 보고, 아래 캔들을 눌러 그날 종가를 고르거나 직접 적으세요. 캡처는 iOS 앱에 있습니다."}</p>
      <label>종목</label>
      <select id="add-ticker">${options}</select>
      ${selected ? chartPickHTML(selected) : ""}
      <label>매수가</label>
      <input id="add-price" type="number" step="0.01" placeholder="내가 산 가격" value="${esc(priceVal)}" />
      ${btn("등록", "primary full", "do-add")}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    `);
  }
  if (state.sheet.startsWith("addon:")) {
    const hid = state.sheet.split(":")[1];
    const h = state.holdings.find((x) => x.id === hid);
    const s = h ? stock(h.stockId) : null;
    if (!h || !s) return "";
    const priceVal = state.addPrice || "";
    const avgVal = String(s.market === "krx" ? Math.round(h.averagePrice) : h.averagePrice);
    return sheetWrap(`
      <h2>추매 · 평단</h2>
      <p class="note">더 산 가격과 수량을 적으면 평단이 다시 계산됩니다. 평단만 고쳐도 됩니다. 현재가로 채우지 않습니다. 반영하면 인증이 풀리고, 캡처로 다시 인증합니다.</p>
      <div class="row" style="border:0;padding:0 0 8px">
        ${stockMark(s)}
        <div class="grow">
          <div class="stock-name">${esc(s.name)}</div>
          <div class="meta">지금 평단 ${formatPrice(h.averagePrice, s.market)}${h.quantity ? " · 수량 " + h.quantity : ""}</div>
        </div>
      </div>
      <input type="hidden" id="add-ticker" value="${esc(s.id)}" />
      ${chartPickHTML(s)}
      <label>추가 매수가</label>
      <input id="add-price" type="number" step="0.01" placeholder="더 산 가격" value="${esc(priceVal)}" />
      ${h.quantity ? "" : `<label>기존 수량</label><input id="old-qty" type="number" step="0.0001" placeholder="지금 몇 주인지" />`}
      <label>추가 수량</label>
      <input id="add-qty" type="number" step="0.0001" placeholder="몇 주 더 샀나요" />
      <label>또는 새 평단</label>
      <input id="new-avg" type="number" step="0.01" value="${esc(avgVal)}" />
      <label>수량 (선택)</label>
      <input id="new-qty" type="number" step="0.0001" value="${h.quantity ? esc(String(h.quantity)) : ""}" />
      ${btn("반영", "primary full", "do-addon")}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    `);
  }
  if (state.sheet.startsWith("sell:")) {
    const hid = state.sheet.split(":")[1];
    const h = state.holdings.find((x) => x.id === hid);
    const s = h ? stock(h.stockId) : null;
    if (!h || !s) return "";
    const quote = formatPrice(priceOf(s), s.market);
    return sheetWrap(`
      <h2>매도하기</h2>
      <p class="note">매도해도 기록은 남아요. 매도가도 캡처로 인증해 주세요. 현재가로 자동 체결하지 않습니다.</p>
      <div class="row" style="border:0;padding:0 0 8px">
        ${stockMark(s)}
        <div class="grow">
          <div class="stock-name">${esc(s.name)}</div>
          <div class="meta">지금 시세 ${quote} · 데모 시세입니다</div>
        </div>
      </div>
      <label>매도가</label>
      <input id="sell-price" type="number" step="0.01" placeholder="내가 판 가격" />
      ${btn("매도 처리", "primary full", "do-sell")}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    `);
  }
  if (state.sheet.startsWith("verify:")) {
    const hid = state.sheet.split(":")[1];
    const h = state.holdings.find((x) => x.id === hid);
    const s = h ? stock(h.stockId) : null;
    if (!h || !s) return "";
    const isSell = h.status === "sold";
    const target = isSell ? (h.sellPrice || h.averagePrice) : h.averagePrice;
    const fake = Math.round(target * 120) / 100;
    const mismatch = h.verification === "mismatch";
    return sheetWrap(`
      <h2>${isSell ? "매도가 인증" : "캡처 인증"}</h2>
      <p class="note">${isSell ? "매도 체결 캡처로 매도가를 확인합니다. " : ""}친구에게 원본 캡처는 보여주지 않아요. 인증 배지만 올라갑니다. 웹 데모는 샘플로 확인합니다.</p>
      <div class="row" style="border:0;padding:0 0 8px">
        ${stockMark(s)}
        <div class="grow">
          <div class="stock-name">${esc(s.name)}</div>
          <div class="meta">확인할 가격 ${formatPrice(target, s.market)}</div>
        </div>
      </div>
      ${btn("샘플로 인증 테스트", "primary full", `do-verify:${hid}:ok`)}
      <div style="height:8px"></div>
      ${btn("일부러 다른 가격 샘플", "secondary full", `do-verify:${hid}:mismatch`)}
      ${mismatch ? `<input type="hidden" id="verify-ocr" value="${fake}" /><p class="caption">입력과 캡처가 다릅니다. 사기라고 단정하지 않습니다.</p>${btn("캡처 가격으로 맞추기", "primary full", `do-verify:${hid}:adopt`)}` : ""}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    `);
  }
  if (state.sheet.startsWith("open-rec:")) {
    const hid = state.sheet.split(":")[1];
    const h = state.holdings.find((x) => x.id === hid);
    const s = h ? stock(h.stockId) : null;
    const others = memberUsers().filter((u) => u.id !== state.me.id);
    if (!state.recTags || !Object.keys(state.recTags).length) {
      state.recTags = {};
      CHART_TAGS.forEach((t) => { state.recTags[t.id] = false; });
    }
    const tagBtns = CHART_TAGS.map((t) => {
      const on = !!state.recTags[t.id];
      return `<button type="button" class="signal-chip${on ? " on" : ""}" data-act="rec-tag:${t.id}">${esc(t.label)}</button>`;
    }).join("");
    return sheetWrap(`
      <h2>친구에게 추천</h2>
      <p class="note">트레이딩뷰 차트에서 본 거래량·RSI를 태그로 남깁니다. 주문이 나가지 않습니다.</p>
      ${s ? chartPickHTML(s, true) : ""}
      <div class="kind">차트에서 본 것</div>
      <div class="signal-row">${tagBtns}</div>
      <label>한마디</label>
      <input id="rec-msg" value="같이 들어가 봐." />
      ${others.map((u) => `<div style="margin-bottom:8px">${btn(u.nickname + "에게", "secondary full", `send-rec:${hid}:${u.id}`)}</div>`).join("")}
      ${btn("닫기", "ghost full", "close")}
    `);
  }
  if (state.sheet.startsWith("open-prop")) {
    const pre = state.sheet.split(":")[1] || "AMD";
    const options = state.stocks.map((s) => `<option value="${s.id}" ${s.id === pre ? "selected" : ""}>${s.name}</option>`).join("");
    return sheetWrap(`
      <h2>매수 제안</h2>
      <p class="note">아직 안 산 종목을 그룹에 제안합니다.</p>
      <label>종목</label>
      <select id="prop-ticker">${options}</select>
      <label>메시지</label>
      <input id="prop-msg" value="이번에 같이 들어갈 사람?" />
      ${btn("보내기", "primary full", "do-prop")}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    `);
  }
  if (state.sheet === "rank") {
    const rows = memberUsers().map((u) => {
      const hs = state.holdings.filter((h) => h.userId === u.id && h.status === "holding");
      const avg = hs.length ? hs.map((h) => ret(h.averagePrice, priceOf(stock(h.stockId)))).reduce((a, b) => a + b, 0) / hs.length : 0;
      return { u, avg, n: hs.length };
    }).sort((a, b) => b.avg - a.avg);
    return sheetWrap(`
      <h2>랭킹</h2>
      <p class="note">그룹 안 기록입니다. 금융 리그가 아닙니다.</p>
      ${rows.map((r, i) => `<div class="pair-row">
        ${avatarHTML(r.u, "sm")}
        <div class="grow">
          <div class="names">${esc(r.u.id === state.me.id ? "나" : r.u.nickname)}</div>
          <div class="stock">보유 ${r.n}종목</div>
        </div>
        <div class="pct ${r.avg >= 0 ? "up" : "down"}">${r.n ? formatPct(r.avg) : "—"}</div>
      </div>`).join("")}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    `);
  }
  if (state.sheet.startsWith("thread:")) {
    const stockId = state.sheet.split(":")[1];
    const s = stock(stockId);
    if (!s) return "";
    const recs = state.recs.filter((r) => r.stockId === stockId && r.groupId === group()?.id).sort((a, b) => a.createdAt - b.createdAt);
    const proposals = state.proposals.filter((p) => p.stockId === stockId && p.groupId === group()?.id);
    const comments = commentsFor(stockId);
    const photos = photosFor(stockId);
    const roots = comments.filter((c) => !c.parentId);
    const reply = state.replyTo ? comments.find((c) => c.id === state.replyTo) : null;
    const commentHTML = (c, isReply) => {
      const photoIdx = c.image ? photos.findIndex((p) => p.id === c.id) : -1;
      return `<div class="comment ${isReply ? "reply" : ""}">
      ${avatarHTML(user(c.authorId) || { nickname: "?" }, "sm")}
      <div class="grow">
        <div class="names">${esc(nickname(c.authorId))}</div>
        ${c.body ? `<div class="body">${esc(c.body)}</div>` : ""}
        ${c.image && photoIdx >= 0 ? `<button type="button" class="comment-photo" data-act="photo:${stockId}:${photoIdx}"><img src="${c.image}" alt=""></button>` : ""}
        <div class="time">${relative(c.createdAt)}${!c.parentId ? ` · <button class="btn text" data-act="reply:${c.id}">답글</button>` : ""}</div>
      </div>
    </div>`;
    };
    const recHTML = recs.length ? recs.map((r) => `<div class="history-item">
        <div class="names">${esc(nickname(r.senderId))} → ${esc(nickname(r.receiverId))}</div>
        <div class="body">“${esc(r.message)}”</div>
        ${signalChips(r.signals)}
        <div class="time">${esc(recStatusLabel(r.status))} · ${relative(r.createdAt)}</div>
      </div>`).join("") : "";
    const propHTML = proposals.map((p) => {
      const n = state.cobuys.filter((c) => c.proposalId === p.id && c.status !== "declined").length;
      return `<div class="history-item">
        <div class="names">${esc(nickname(p.proposerId))} · 매수 제안</div>
        <div class="body">“${esc(p.message)}”</div>
        <div class="time">관심 ${n}명 · ${relative(p.createdAt)}</div>
      </div>`;
    }).join("");
    const rail = photos.length ? `<div class="kind" style="margin-top:16px">사진 ${photos.length}</div>
      <div class="photo-rail">${photos.map((c, i) => `<button type="button" class="rail-shot" data-act="photo:${stockId}:${i}"><img src="${c.image}" alt=""></button>`).join("")}</div>` : "";
    const preview = state.threadImage ? `<div class="composer-preview">
        <img src="${state.threadImage}" alt="">
        <button type="button" class="btn text" data-act="clear-photo">사진 빼기</button>
      </div>` : "";
    return sheetWrap(`
      <div class="thread-head">
        <div class="thread-title">
          ${stockMark(s, "lg")}
          <div class="grow">
            <h2 style="margin:0">${esc(s.name)}</h2>
            <div class="ticker">${esc(s.ticker)}</div>
          </div>
        </div>
        ${chartPickHTML(s, true)}
        ${pulseStrip(s.id, false)}
      </div>
      <p class="note">트레이딩뷰 일봉입니다. 거래량과 RSI가 같이 열립니다. 이 종목의 추천·매수 제안과 댓글입니다.</p>
      <div class="kind">이 종목 이야기</div>
      ${recHTML || propHTML ? recHTML + propHTML : `<p class="empty">아직 추천이나 매수 제안이 없습니다.</p>`}
      ${rail}
      <div class="kind" style="margin-top:16px">댓글 ${comments.length}</div>
      ${roots.length ? roots.map((c) => commentHTML(c, false) + comments.filter((x) => x.parentId === c.id).map((x) => commentHTML(x, true)).join("")).join("") : `<p class="empty">아직 댓글이 없습니다. 차트 분석 사진이나 한마디를 남겨 보세요.</p>`}
      ${reply ? `<div class="caption">${esc(nickname(reply.authorId))}에게 답글 · <button class="btn text" data-act="cancel-reply">취소</button></div>` : ""}
      ${preview}
      <div class="composer-attach" id="thread-composer">
        <label class="btn secondary composer-file">사진 고르기<input id="thread-photo" type="file" accept="image/*"></label>
        ${btn("차트 첨부", "secondary", "attach-chart")}
      </div>
      <label>${reply ? "답글" : "댓글"}</label>
      <input id="thread-text" placeholder="${reply ? "답글 적기" : "이 종목에 한마디"}" value="${esc(state.threadDraft || "")}" />
      ${btn("보내기", "primary full", "do-comment")}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    `);
  }
  return "";
}

function tabs() {
  if (state.onboarding) return "";
  const items = [
    ["group", "그룹", "group"],
    ["hold", "내 주식", "chart"],
    ["act", "활동", "heart"],
    ["me", "프로필", "me"]
  ];
  return `<nav class="tabs">${items.map(([id, label, icon]) => `<button class="${state.tab === id ? "on" : ""}" data-act="tab:${id}">${ico(icon, state.tab === id)}<span>${label}</span></button>`).join("")}</nav>`;
}

function lightboxHTML() {
  if (!state.lightbox) return "";
  const stockId = state.lightbox.stockId;
  const photos = photosFor(stockId);
  if (!photos.length) return "";
  const i = Math.max(0, Math.min(state.lightbox.index | 0, photos.length - 1));
  state.lightbox.index = i;
  const c = photos[i];
  const cap = c.body ? nickname(c.authorId) + " · " + c.body : nickname(c.authorId);
  return `<div class="lightbox" data-act="lightbox-close">
    <button type="button" class="lightbox-close" data-act="lightbox-close">닫기</button>
    ${photos.length > 1 ? `<button type="button" class="lightbox-nav prev" data-act="lightbox-prev">‹</button>` : ""}
    ${photos.length > 1 ? `<button type="button" class="lightbox-nav next" data-act="lightbox-next">›</button>` : ""}
    <img src="${c.image}" alt="" data-act="lightbox-stay">
    <div class="lightbox-cap" data-act="lightbox-stay">${esc(cap)} · ${i + 1} / ${photos.length}</div>
  </div>`;
}

function render() {
  const root = document.getElementById("app");
  let body = "";
  if (state.onboarding) body = renderOnboarding();
  else if (state.tab === "hold") body = renderHoldings();
  else if (state.tab === "act") body = renderActivity();
  else if (state.tab === "me") body = renderProfile();
  else body = renderGroup();
  root.innerHTML = body + tabs() + sheetHTML() + lightboxHTML();
  bindPager();
  persist();
  mountTradingView();
  const panel = document.querySelector(".sheet .panel");
  if (panel && (state.sheet || "").startsWith("thread:") && (state.threadImage || state.replyTo)) {
    const anchor = document.querySelector(".composer-preview") || document.getElementById("thread-composer");
    if (anchor) {
      const delta = anchor.getBoundingClientRect().top - panel.getBoundingClientRect().top - 16;
      panel.scrollTop = Math.max(0, panel.scrollTop + delta);
    }
  }
}

let sheetGuard = 0;
function openSheet(name) {
  state.sheet = name;
  sheetGuard = Date.now() + 700;
  render();
}
function closeSheet() {
  if (Date.now() < sheetGuard) return;
  state.sheet = null;
  state.replyTo = null;
  state.addTicker = null;
  state.addPrice = "";
  state.chartIndex = null;
  state.threadImage = null;
  state.threadDraft = "";
  render();
}

let chartTracking = false;
let lightboxSwipeX = null;
function onChartPointer(e) {
  const svg = e.target.closest && e.target.closest("svg.chart:not(.static)");
  if (!svg) return false;
  e.preventDefault();
  applyChartPick(e.clientX);
  return true;
}
document.addEventListener("pointerdown", (e) => {
  if (onChartPointer(e)) {
    chartTracking = true;
    if (e.target.setPointerCapture) {
      try { e.target.setPointerCapture(e.pointerId); } catch (_) {}
    }
    return;
  }
  if (state.lightbox && e.target.closest && e.target.closest(".lightbox")) {
    lightboxSwipeX = e.clientX;
  }
});
document.addEventListener("pointermove", (e) => {
  if (!chartTracking) return;
  onChartPointer(e);
});
document.addEventListener("pointerup", (e) => {
  chartTracking = false;
  if (lightboxSwipeX != null && state.lightbox) {
    const dx = e.clientX - lightboxSwipeX;
    if (dx > 50) handle("lightbox-prev");
    else if (dx < -50) handle("lightbox-next");
  }
  lightboxSwipeX = null;
});
document.addEventListener("pointercancel", () => { chartTracking = false; lightboxSwipeX = null; });

document.addEventListener("change", (e) => {
  if (e.target && e.target.id === "add-ticker") {
    state.addTicker = e.target.value;
    state.chartIndex = null;
    state.addPrice = "";
    render();
  }
  if (e.target && e.target.id === "thread-photo") {
    const file = e.target.files && e.target.files[0];
    if (!file) return;
    saveThreadDraft();
    compressImageFile(file).then((data) => {
      state.threadImage = data;
      render();
    }).catch(() => toast("사진을 읽지 못했습니다"));
  }
});
document.addEventListener("input", (e) => {
  if (e.target && e.target.id === "add-price") state.addPrice = e.target.value;
  if (e.target && e.target.id === "thread-text") state.threadDraft = e.target.value;
});

document.addEventListener("click", (e) => {
  if (e.target.closest && e.target.closest("svg.chart:not(.static)")) {
    e.preventDefault();
    return;
  }
  if (e.target.closest && e.target.closest("a[href]")) return;
  if (e.target.closest && e.target.closest(".tv-wrap")) return;
  if (e.target.classList.contains("sheet") && !state.lightbox) {
    closeSheet();
    return;
  }
  const actEl = e.target.closest("[data-act]");
  if (!actEl) return;
  handle(actEl.getAttribute("data-act"));
});

function handle(act) {
  if (act === "demo") {
    stopRoom();
    const nick = document.getElementById("nick")?.value?.trim() || "나";
    state.me.nickname = nick;
    seed(state);
    toast("데모 그룹에 들어갔습니다");
    render();
    return;
  }
  if (act === "create-room" || act === "empty-start") {
    createLiveRoom();
    return;
  }
  if (act === "join-room") {
    joinLiveRoom();
    return;
  }
  if (act === "leave-room") {
    leaveRoom();
    return;
  }
  if (act.startsWith("tab:")) { state.tab = act.split(":")[1]; render(); return; }
  if (act.startsWith("fold:")) {
    if (!state.groupOpen) state.groupOpen = { turn: true };
    const id = act.slice(5);
    const fallback = id === "turn" || id === "mood";
    state.groupOpen[id] = !isOpen(id, fallback);
    render();
    return;
  }
  if (act.startsWith("page:")) {
    const pager = document.getElementById("turn-pager");
    const i = Number(act.split(":")[1]);
    state.inboxPage = i;
    if (pager) pager.scrollTo({ left: i * pager.clientWidth, behavior: "smooth" });
    document.querySelectorAll(".pager-dots button").forEach((d, k) => d.classList.toggle("on", k === i));
    const idx = document.querySelector(".pager-idx");
    const n = pager ? pager.querySelectorAll(".pager-slide").length : 0;
    if (idx && n) idx.textContent = (i + 1) + " / " + n;
    return;
  }
  if (act === "copy" || act === "share-invite") { shareInvite(); return; }
  if (act === "rank") { openSheet("rank"); return; }
  if (act === "open-add") {
    state.addTicker = null;
    state.addPrice = "";
    state.chartIndex = null;
    openSheet("add");
    return;
  }
  if (act === "close") { closeSheet(); return; }
  if (act === "do-add") {
    const ticker = document.getElementById("add-ticker").value;
    const price = Number(document.getElementById("add-price").value);
    if (!price) {
      toast("내가 산 가격을 적어 주세요. 현재가로 채워 넣지 않습니다.");
      return;
    }
    const method = state.chartIndex != null ? "chart" : "manual";
    addHolding(ticker, price, method);
    return;
  }
  if (act.startsWith("bought:")) {
    const rec = state.recs.find((r) => r.id === act.split(":")[1]);
    if (!rec) return;
    state.addTicker = rec.stockId;
    state.addPrice = "";
    state.chartIndex = null;
    openSheet("register:" + rec.stockId);
    return;
  }
  if (act.startsWith("accept:")) return acceptRec(act.split(":")[1], true);
  if (act.startsWith("reject:")) return acceptRec(act.split(":")[1], false);
  if (act.startsWith("promise:")) return promiseCoBuy(act.split(":")[1]);
  if (act.startsWith("later:")) return declineProposal(act.split(":")[1]);
  if (act.startsWith("register:")) {
    state.addTicker = act.split(":")[1];
    state.addPrice = "";
    state.chartIndex = null;
    openSheet(act);
    return;
  }
  if (act.startsWith("addon:")) {
    const h = state.holdings.find((x) => x.id === act.split(":")[1]);
    state.addTicker = h ? h.stockId : null;
    state.addPrice = "";
    state.chartIndex = null;
    openSheet(act);
    return;
  }
  if (act === "do-addon") {
    const id = (state.sheet || "").split(":")[1];
    addToPosition(id);
    return;
  }
  if (act.startsWith("sell:")) { openSheet(act); return; }
  if (act === "do-sell") {
    const id = (state.sheet || "").split(":")[1];
    sellHolding(id);
    return;
  }
  if (act.startsWith("verify:")) { openSheet(act); return; }
  if (act.startsWith("do-verify:")) {
    const parts = act.split(":");
    verify(parts[1], parts[2]);
    return;
  }
  if (act.startsWith("suspect:")) return suspect(act.split(":")[1]);
  if (act.startsWith("open-rec:")) {
    state.recTags = {};
    openSheet(act);
    return;
  }
  if (act.startsWith("rec-tag:")) {
    const id = act.slice(8);
    state.recTags = state.recTags || {};
    state.recTags[id] = !state.recTags[id];
    const btn = document.querySelector(`[data-act="rec-tag:${id}"]`);
    if (btn) btn.classList.toggle("on", !!state.recTags[id]);
    persist();
    return;
  }
  if (act.startsWith("open-prop")) { openSheet(act); return; }
  if (act.startsWith("send-rec:")) {
    const parts = act.split(":");
    const msg = document.getElementById("rec-msg")?.value;
    return recommend(parts[1], parts[2], msg);
  }
  if (act.startsWith("take:")) {
    const parts = act.split(":");
    const stockId = parts[1];
    const level = Number(parts[2]);
    if (!stockId || Number.isNaN(level)) return;
    if (!state.takes) state.takes = [];
    const idx = state.takes.findIndex((t) => t.stockId === stockId && t.userId === state.me.id);
    if (idx >= 0) state.takes[idx].level = level;
    else state.takes.push({ id: uid(), groupId: group()?.id, stockId, userId: state.me.id, level });
    const s = stock(stockId);
    toast(takeMeta(level).title + (s ? " · " + s.name : ""));
    render();
    return;
  }
  if (act.startsWith("thread:")) {
    state.replyTo = null;
    state.threadDraft = "";
    state.threadImage = null;
    openSheet(act);
    return;
  }
  if (act === "attach-chart") {
    saveThreadDraft();
    const stockId = (state.sheet || "").split(":")[1];
    const snap = chartSnapshot(stockId);
    if (!snap) {
      toast("차트를 만들지 못했습니다");
      return;
    }
    state.threadImage = snap;
    toast("차트를 붙였습니다");
    render();
    return;
  }
  if (act === "clear-photo") {
    saveThreadDraft();
    state.threadImage = null;
    render();
    return;
  }
  if (act.startsWith("photo:")) {
    saveThreadDraft();
    const parts = act.split(":");
    state.lightbox = { stockId: parts[1], index: Number(parts[2]) || 0 };
    render();
    return;
  }
  if (act === "lightbox-stay") return;
  if (act === "lightbox-close") {
    state.lightbox = null;
    render();
    return;
  }
  if (act === "lightbox-prev" || act === "lightbox-next") {
    if (!state.lightbox) return;
    const photos = photosFor(state.lightbox.stockId);
    if (!photos.length) return;
    const delta = act === "lightbox-next" ? 1 : -1;
    state.lightbox.index = (state.lightbox.index + delta + photos.length) % photos.length;
    render();
    return;
  }
  if (act.startsWith("reply:")) {
    saveThreadDraft();
    state.replyTo = act.split(":")[1];
    render();
    return;
  }
  if (act === "cancel-reply") {
    saveThreadDraft();
    state.replyTo = null;
    render();
    return;
  }
  if (act === "do-comment") {
    const stockId = (state.sheet || "").split(":")[1];
    const text = document.getElementById("thread-text")?.value || "";
    state.threadDraft = "";
    addComment(stockId, text, state.replyTo);
    return;
  }
  if (act === "do-prop") {
    propose(document.getElementById("prop-ticker").value, document.getElementById("prop-msg").value);
    return;
  }
  if (act.startsWith("shock:")) {
    const parts = act.split(":");
    return shock(parts[1], Number(parts[2]));
  }
  if (act.startsWith("play:")) return playAs(act.split(":")[1]);
  if (act === "reset") return resetDemo();
}

window.addEventListener("hashchange", () => {
  const join = parseJoin();
  if (!join) return;
  if (state.onboarding) {
    state.pendingJoin = join;
    render();
    return;
  }
  if (state.mode === "live" && state.roomId && state.roomId !== join) {
    toast("다른 그룹 초대입니다. 프로필에서 나간 뒤 들어가세요.");
  }
});

render();
if (state.mode === "live" && state.roomId) connectRoom();
