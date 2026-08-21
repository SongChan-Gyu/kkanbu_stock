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
const NEWS = {
  NVDA: [
    ["실적 발표 앞두고 거래량 늘었어요", "2시간 전"],
    ["데이터센터 가이던스 이야기가 나와요", "어제"]
  ],
  AAPL: [
    ["서비스 매출이 버텨 준다는 이야기", "3시간 전"],
    ["신제품 사이클 눈높이 조정 중", "어제"]
  ],
  TSLA: [
    ["인도량 숫자 가지고 말이 많아요", "1시간 전"],
    ["마진 이야기가 다시 나와요", "어제"]
  ],
  AMD: [
    ["AI 칩 수주 이야기가 돌아요", "4시간 전"],
    ["서버 GPU 수요 눈높이 이야기", "그제"]
  ],
  MSFT: [
    ["클라우드 실적 눈높이 이야기", "2시간 전"],
    ["AI 구독이 끌고 간다는 말", "어제"]
  ],
  AMZN: [
    ["광고·AWS가 끌고 간다는 말", "5시간 전"],
    ["물류 비용 이야기가 나와요", "어제"]
  ],
  "005930": [
    ["반도체 업황 이야기가 다시 나와요", "2시간 전"],
    ["HBM·파운드리 수주 이야기", "어제"]
  ],
  "000660": [
    ["HBM 수요 이야기가 나와요", "1시간 전"],
    ["공급 계약 눈높이 이야기", "어제"]
  ],
  "035420": [
    ["광고·커머스 회복 속도 이야기", "3시간 전"],
    ["웹툰·콘텐츠 매출 이야기", "어제"]
  ],
  "035720": [
    ["플랫폼 실적 눈높이 조정 중", "2시간 전"],
    ["톡비즈 회복 속도 이야기", "어제"]
  ]
};

function headlines(ticker) {
  return NEWS[ticker] || [["그룹에서 이 종목 이야기 중", "데모"]];
}
function newsLine(ticker) {
  const [title, ago] = headlines(ticker)[0];
  return title + " · " + ago + " · 데모";
}
function pulseOf(stockId) {
  const s = stock(stockId);
  const n = commentsFor(stockId).length;
  const pending = state.recs.filter((r) => r.stockId === stockId && (r.status === "pending" || r.status === "willBuy")).length;
  const shared = bonds().find((b) => b.stockId === stockId)?.shared;
  const items = headlines(s ? s.ticker : stockId);
  if (n >= 3) return { rating: "들뜸", kick: "glory", take: "지금 말이 많은 종목", blurb: "댓글 " + n + (pending ? " · 추천 " + pending : ""), items };
  if (typeof shared === "number" && shared <= -0.15) return { rating: "물림", kick: "roast", take: "같이 물린 분위기", blurb: "깐부 수익률 " + formatPct(shared) + (n ? " · 댓글 " + n : ""), items };
  if (typeof shared === "number" && shared >= 0.15) return { rating: "웃는 중", kick: "glory", take: "같이 웃는 분위기", blurb: "깐부 수익률 " + formatPct(shared) + (n ? " · 댓글 " + n : ""), items };
  if (pending > 0) return { rating: "추천 중", kick: "plain", take: n ? "추천이 왔고 댓글도 있음" : "추천이 와 있음", blurb: "추천 " + pending + (n ? " · 댓글 " + n : ""), items };
  if (n > 0) return { rating: "이야기 중", kick: "plain", take: "댓글이 오가는 중", blurb: "댓글 " + n, items };
  return { rating: "조용", kick: "plain", take: "아직 말 없음", blurb: "그룹 평가 없음", items };
}
function pulseVibe(stockId) {
  return pulseOf(stockId).take;
}
function pulseStrip(stockId, compact) {
  const p = pulseOf(stockId);
  const news = compact
    ? `<div class="news">${esc(p.items[0][0])} · ${esc(p.items[0][1])}</div>`
    : `<div class="pulse-blurb">${esc(p.blurb)}</div>
    <div class="pulse-label">헤드라인</div>` + p.items.slice(0, 2).map((it) => `<div class="pulse-news-row"><span>${esc(it[0])}</span><span>${esc(it[1])}</span></div>`).join("");
  return `<div class="pulse ${compact ? "compact" : ""}">
    <div class="pulse-top"><span class="pulse-chip ${p.kick}">${esc(p.rating)}</span><span class="pulse-take">${esc(p.take)}</span></div>
    ${news}
  </div>`;
}
function seedValue(ticker) {
  return [...String(ticker)].reduce((a, c) => a + c.charCodeAt(0), 0);
}
function history(s, days) {
  days = days || 14;
  const base = priceOf(s);
  let price = base * 0.86;
  const seed = seedValue(s.ticker);
  const points = [];
  for (let i = days; i >= 0; i--) {
    const wave = Math.sin((i + seed) / 6.5) * 0.018;
    const drift = ((seed % 7) - 3) * 0.0015;
    price = Math.max(base * 0.55, price * (1 + wave + drift));
    const rounded = s.market === "krx" ? Math.round(price / 50) * 50 : Math.round(price * 100) / 100;
    points.push({ daysAgo: i, price: rounded });
  }
  points[points.length - 1].price = s.market === "krx" ? Math.round(base / 50) * 50 : Math.round(base * 100) / 100;
  return points;
}
function chartPickHTML(s) {
  const pts = history(s);
  const idx = state.chartIndex == null ? pts.length - 1 : Math.min(state.chartIndex, pts.length - 1);
  const ys = pts.map((p) => p.price);
  const min = Math.min.apply(null, ys);
  const max = Math.max.apply(null, ys);
  const span = max - min || 1;
  const w = 320;
  const h = 88;
  const coords = pts.map((p, i) => {
    const x = 8 + (i / (pts.length - 1)) * (w - 16);
    const y = 10 + (1 - (p.price - min) / span) * (h - 20);
    return [x, y];
  });
  const line = coords.map((c) => c[0].toFixed(1) + "," + c[1].toFixed(1)).join(" ");
  const sel = coords[idx];
  const picked = pts[idx];
  const when = picked.daysAgo === 0 ? "오늘" : picked.daysAgo + "일 전";
  const meta = state.chartIndex == null
    ? `눌러서 고르기 · 오늘 ${formatPrice(pts[pts.length - 1].price, s.market)}`
    : `${when} · ${formatPrice(picked.price, s.market)}`;
  return `<div class="chart-box">
    <div class="chart-cap">차트를 눌러 그날 가격을 고르세요. 데모 시세입니다. 주문이 나가지 않습니다.</div>
    <svg class="chart" viewBox="0 0 ${w} ${h}" role="img" aria-label="최근 시세 차트">
      <rect width="${w}" height="${h}" fill="transparent"></rect>
      <polyline fill="none" stroke="currentColor" stroke-width="2" points="${line}"></polyline>
      ${state.chartIndex == null ? "" : `<circle cx="${sel[0].toFixed(1)}" cy="${sel[1].toFixed(1)}" r="4.5" fill="currentColor"></circle>`}
    </svg>
    <div class="chart-meta">${meta}</div>
  </div>`;
}
function applyChartPick(clientX) {
  const svg = document.querySelector("svg.chart");
  const ticker = document.getElementById("add-ticker")?.value;
  const s = ticker ? stock(ticker) : null;
  if (!svg || !s) return;
  const pts = history(s);
  const rect = svg.getBoundingClientRect();
  const x = clientX - rect.left;
  const idx = Math.max(0, Math.min(pts.length - 1, Math.round((x / Math.max(rect.width, 1)) * (pts.length - 1))));
  state.chartIndex = idx;
  state.addTicker = ticker;
  const p = pts[idx].price;
  state.addPrice = s.market === "krx" ? String(Math.round(p)) : p.toFixed(2);
  const input = document.getElementById("add-price");
  if (input) input.value = state.addPrice;
  const meta = document.querySelector(".chart-meta");
  const when = pts[idx].daysAgo === 0 ? "오늘" : pts[idx].daysAgo + "일 전";
  if (meta) meta.textContent = when + " · " + formatPrice(p, s.market);
  const ys = pts.map((pt) => pt.price);
  const min = Math.min.apply(null, ys);
  const max = Math.max.apply(null, ys);
  const span = max - min || 1;
  const w = 320;
  const h = 88;
  const cx = 8 + (idx / (pts.length - 1)) * (w - 16);
  const cy = 10 + (1 - (pts[idx].price - min) / span) * (h - 20);
  let circle = svg.querySelector("circle");
  if (!circle) {
    circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    circle.setAttribute("r", "4.5");
    circle.setAttribute("fill", "currentColor");
    svg.appendChild(circle);
  }
  circle.setAttribute("cx", cx.toFixed(1));
  circle.setAttribute("cy", cy.toFixed(1));
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
    star: `<path d="M12 2l2.6 6.6L22 10l-5 4.9L18.2 22 12 18.3 5.8 22 7 14.9 2 10l7.4-1.4L12 2z"/>`
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
    chartIndex: null
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

  state.recs.push({
    id: "rec1", groupId: group.id, senderId: "younghee", receiverId: state.me.id,
    stockId: "NVDA", holdingId: youngheeNVDA.id, message: "같이 들어가 봐.",
    status: "pending", createdAt: now() - hours(3)
  });
  state.comments.push(
    { id: "cm1", groupId: group.id, stockId: "NVDA", authorId: "cheolsu", parentId: null, body: "지금 들어가도 늦었나", createdAt: now() - hours(2) },
    { id: "cm2", groupId: group.id, stockId: "NVDA", authorId: state.me.id, parentId: "cm1", body: "평단만 적어둘게", createdAt: now() - hours(1) },
    { id: "cm3", groupId: group.id, stockId: "NVDA", authorId: "minsu", parentId: null, body: "나는 패스ㅋㅋ 물리면 니 탓이다", createdAt: now() - hours(0.5) }
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
    ev(group.id, "댓글", `철수가 NVIDIA 추천에 댓글을 남겼습니다. “지금 들어가도 늦었나”`, now() - hours(2), "cmt", "cheolsu", "NVDA"),
    ev(group.id, "대댓글", `${nick}가 NVIDIA 추천에 답글을 남겼습니다. “평단만 적어둘게”`, now() - hours(1), "cmt", state.me.id, "NVDA"),
    ev(group.id, "매수 제안", `민수가 AMD 매수를 제안했습니다.`, now() - hours(8), "prop", "minsu"),
    ev(group.id, "매수 제안 · 재요청", `${nick}에게 AMD 매수를 다시 제안했습니다.`, now() - hours(1), "nag", "minsu"),
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
}

function ev(groupId, title, message, createdAt, type, actorId, stockId) {
  return { id: uid(), groupId, title, message, createdAt, type, actorId, stockId: stockId || null };
}

let state = emptyState({ id: "me", nickname: "나" });

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
  return items;
}

function addHolding(ticker, avg, method = "manual") {
  if (activeHoldings(state.me.id).some((h) => h.stockId === ticker)) {
    toast("이미 보유 중인 종목입니다.");
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
  const p = priceOf(s);
  h.status = "sold";
  h.sellPrice = p;
  const leftovers = state.holdings.filter((x) => x.stockId === h.stockId && x.status === "holding" && x.userId !== h.userId);
  if (leftovers.length) {
    pushEvent("혼자 매도", `${s.name}를 매도했습니다. ${nickname(leftovers[0].userId)}는 아직 보유 중.`, "solo");
    leftovers.forEach((left) => {
      pushEvent("존버", `${s.name}에서 ${nickname(left.userId)}만 남아 있습니다.`, "diamond", left.userId);
    });
  } else {
    pushEvent("매도", `${s.name}를 매도했습니다.`, "solo");
  }
  toast("매도 처리됨");
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
  if (!state.cobuys.some((c) => c.proposalId === proposalId && c.userId === state.me.id)) {
    state.cobuys.push({ id: uid(), proposalId, groupId: p.groupId, userId: state.me.id, stockId: p.stockId, status: "promised", nagCount: 0 });
  }
  pushEvent("매수 제안", `${stock(p.stockId).name} 매수 제안에 관심을 남겼습니다.`, "prop");
  toast("관심을 남겼습니다");
  render();
}

function recStatusLabel(status) {
  return { pending: "대기", willBuy: "매수 예정", accepted: "매수 기록", rejected: "거절" }[status] || status;
}
function commentsFor(stockId) {
  return (state.comments || []).filter((c) => c.stockId === stockId && c.groupId === group()?.id).sort((a, b) => a.createdAt - b.createdAt);
}
function addComment(stockId, body, parentId) {
  const text = (body || "").trim();
  if (!text) {
    toast("내용을 적어 주세요.");
    return;
  }
  const comment = {
    id: uid(), groupId: group().id, stockId, authorId: state.me.id,
    parentId: parentId || null, body: text, createdAt: now()
  };
  state.comments.push(comment);
  const title = parentId ? "대댓글" : "댓글";
  const kind = parentId ? "답글" : "댓글";
  pushEvent(title, `${stock(stockId).name} 추천에 ${kind}을 남겼습니다. “${text.slice(0, 40)}”`, "cmt", state.me.id, stockId);
  toast(parentId ? "대댓글을 남겼습니다" : "댓글을 남겼습니다");
  state.replyTo = null;
  render();
}

function recommend(holdingId, toUserId, message) {
  const h = state.holdings.find((x) => x.id === holdingId);
  const rec = {
    id: uid(), groupId: group().id, senderId: state.me.id, receiverId: toUserId,
    stockId: h.stockId, holdingId, message: (message || "").trim() || "같이 들어가 봐.", status: "pending", createdAt: now()
  };
  state.recs.push(rec);
  pushEvent("추천", `${stock(h.stockId).name}를 ${nickname(toUserId)}에게 추천했습니다.`, "rec", state.me.id, h.stockId);
  toast("추천을 보냈습니다");
  state.sheet = null;
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

function verify(holdingId) {
  const h = state.holdings.find((x) => x.id === holdingId);
  h.verification = "screenshot";
  pushEvent("인증", `${stock(h.stockId).name} 매수가를 인증했습니다.`, "shot");
  toast("캡처 인증 완료");
  state.sheet = null;
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
  const u = user(userId);
  state.me = u;
  toast(`${u.nickname}으로 보는 중`);
  render();
}

function resetDemo() {
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
  return `<div class="avatar c${n}${size === "sm" ? " sm" : ""}">${esc(initial(person.nickname))}</div>`;
}
function btn(label, kind, action) {
  return `<button class="btn ${kind || "primary"}" data-act="${esc(action)}">${label}</button>`;
}
function sm(label, action) {
  return `<button class="btn sm" data-act="${esc(action)}">${label}</button>`;
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
    actions = sm("친구에게 추천", `open-rec:${h.id}`) + sm("매도", `sell:${h.id}`);
    if (h.verification !== "screenshot") actions += sm("캡처 인증", `verify:${h.id}`);
  }
  const partnerLine = partners.length && g
    ? `${esc(partners.join(" · "))}와 <span class="grade ${g.kick}">${esc(g.title)}</span>`
    : "";
  const suspect = h.verification === "suspected" ? `<div class="caption">매수가 의심 중</div>` : "";
  return `
    <div class="row">
      ${stockMark(s)}
      <div class="grow">
        ${!isMine ? `<div class="caption">${esc(owner.nickname)}</div>` : ""}
        <div class="stock-name">${esc(s.name)}${verifyMark(h.verification)}</div>
        <div class="ticker">${esc(s.ticker)}</div>
        <div class="meta">평단 ${formatPrice(h.averagePrice, s.market)} · 현재가 ${formatPrice(priceOf(s), s.market)}</div>
        ${pulseStrip(s.id, true)}
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
    </div>`;
  }
  if (item.kind === "suspect") {
    const h = item.holding;
    const s = stock(h.stockId);
    return `<div class="action-block">
      <div class="kind">매수가 확인 요청</div>
      <div class="row" style="border:0;padding:0 0 8px">
        ${stockMark(s, "sm")}
        <div class="grow">
          <div class="stock-name">${esc(s.name)}</div>
          <div class="ticker">${esc(s.ticker)}</div>
        </div>
      </div>
      <p class="caption">${formatPrice(h.averagePrice, s.market)}에 산 기록이 맞는지 캡처로 확인합니다. 사기라고 단정하지 않습니다.</p>
      ${btn("캡처로 인증", "primary", `verify:${h.id}`)}
    </div>`;
  }
  return "";
}

function eventRow(e) {
  const actor = e.actorId ? user(e.actorId) : null;
  const kick = /황금|신의|매수 예정/.test(e.title) || e.type === "gold" ? "glory"
    : /최악|공동묘지|거절|혼자/.test(e.title) || e.type === "worst" || e.type === "solo" ? "roast"
    : "plain";
  const open = e.stockId && (e.type === "rec" || e.type === "cmt") ? ` data-act="thread:${e.stockId}"` : "";
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
  return `
    <div class="screen">
      <div class="page-title">주식 깐부</div>
      <p class="page-sub">친구와 같은 종목을 보유하면 깐부가 됩니다.</p>
      <label>닉네임</label>
      <input id="nick" value="${esc(state.me.nickname)}" />
      <p class="note">직접 입력한 보유 정보는 증권 계좌로 검증되지 않습니다. 투자 자문이 아닙니다.</p>
      ${btn("데모 그룹으로 시작", "primary full", "demo")}
      <div style="height:8px"></div>
      ${btn("빈 그룹으로 시작", "secondary full", "empty-start")}
    </div>`;
}

function recommendedSection() {
  const recs = state.recs.filter((r) => r.groupId === group()?.id);
  const ids = [];
  recs.forEach((r) => { if (!ids.includes(r.stockId)) ids.push(r.stockId); });
  if (!ids.length) return "";
  return `<div class="section"><div class="section-title">추천 종목</div>${ids.map((id) => {
    const s = stock(id);
    const related = recs.filter((r) => r.stockId === id);
    const last = related[related.length - 1];
    return `<button class="row btn" data-act="thread:${id}">
      ${stockMark(s)}
      <div class="grow">
        <div class="stock-name">${esc(s.name)}</div>
        <div class="caption">${esc(related.map((r) => `${nickname(r.senderId)} → ${nickname(r.receiverId)}`).join(" · "))}</div>
        ${pulseStrip(id, true)}
        <div class="meta">“${esc(last.message)}”</div>
      </div>
      <div class="right">${commentMeta(id)}</div>
    </button>`;
  }).join("")}</div>`;
}

function moodSection() {
  const recIds = state.recs.filter((r) => r.groupId === group()?.id).map((r) => r.stockId);
  const bondIds = bonds().map((b) => b.stockId);
  const ids = [];
  recIds.concat(bondIds).forEach((id) => { if (!ids.includes(id)) ids.push(id); });
  if (!ids.length) return "";
  return `<div class="section"><div class="section-title">종목 평가</div>${ids.slice(0, 3).map((id) => {
    const s = stock(id);
    return `<button class="row btn" data-act="thread:${id}">
      ${stockMark(s)}
      <div class="grow">
        <div class="stock-name">${esc(s.name)}</div>
        ${pulseStrip(id, false)}
      </div>
    </button>`;
  }).join("")}</div>`;
}

function renderGroup() {
  const g = group();
  if (!g) {
    return `<div class="screen"><div class="page-title">그룹</div>
      <p class="empty">아직 그룹이 없습니다.</p>
      ${btn("데모 그룹 불러오기", "primary", "demo")}</div>`;
  }
  const items = inbox();
  const kk = bonds();
  const friendsHoldings = state.holdings.filter((h) => h.userId !== state.me.id && memberUsers().some((u) => u.id === h.userId) && h.status === "holding");
  return `
    <div class="screen">
      <div class="header-meta">
        <div>
          <div class="page-title">${esc(g.name)}</div>
          <div class="invite">초대 코드 ${g.invite}</div>
        </div>
        <button class="btn text" data-act="copy">코드 복사</button>
      </div>
      <div class="split">
        ${btn("주식 추가", "primary", "open-add")}
        ${btn("매수 제안", "secondary", "open-prop:")}
      </div>

      ${items.length ? `<div class="section"><div class="section-title">내 차례</div><div class="row-list">${items.map(inboxBlock).join("")}</div></div>` : ""}

      ${recommendedSection()}
      ${moodSection()}

      <div class="section">
        <div class="section-title">멤버</div>
        <div class="members">${memberUsers().map((u) => `<button class="member" data-act="play:${u.id}">${avatarHTML(u)}${`<span>${esc(u.id === state.me.id ? "나" : u.nickname)}</span>`}</button>`).join("")}</div>
      </div>

      <div class="section">
        <div class="section-title">깐부</div>
        ${kk.length ? (() => {
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
        })() : `<p class="empty">아직 깐부가 없습니다.</p>`}
      </div>

      <div class="section">
        <div class="section-title">친구 주식</div>
        <div class="row-list">${friendsHoldings.map((h) => holdingRow(h, false)).join("") || `<p class="empty">표시할 보유가 없습니다.</p>`}</div>
      </div>

      <div class="section">
        <div class="section-title">활동</div>
        ${state.events.map(eventRow).join("")}
      </div>
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
    ${active.length ? `<div class="section"><div class="section-title">보유 중</div><div class="row-list">${active.map((h) => holdingRow(h, true)).join("")}</div></div>` : `<p class="empty">아직 등록한 주식이 없습니다.</p>`}
    ${sold.length ? `<div class="section"><div class="section-title">매도 기록</div><div class="row-list">${sold.map((h) => holdingRow(h, true)).join("")}</div></div>` : ""}
    <p class="note">직접 입력한 보유 정보는 증권 계좌로 검증되지 않습니다.</p>
  </div>`;
}

function renderActivity() {
  const mine = inbox();
  const recs = state.recs.filter((r) => r.senderId === state.me.id || r.receiverId === state.me.id);
  const recStatus = { pending: "대기", willBuy: "매수 예정", accepted: "매수 기록", rejected: "거절" };
  return `<div class="screen">
    <div class="page-title">활동</div>
    <p class="page-sub">추천과 매수 제안</p>
    ${mine.length ? `<div class="row-list">${mine.map(inboxBlock).join("")}</div>` : `<p class="empty">대기 중인 일이 없습니다.</p>`}
    <div class="section">
      <div class="section-title">추천 기록</div>
      ${recs.length ? recs.map((r) => `<div class="pair-row">${stockMark(stock(r.stockId), "sm")}<div class="grow"><div class="names">${esc(nickname(r.senderId))} → ${esc(nickname(r.receiverId))}</div><div class="stock">${esc(stock(r.stockId).name)} · ${recStatus[r.status] || r.status}</div></div></div>`).join("") : `<p class="empty">기록이 없습니다.</p>`}
    </div>
  </div>`;
}

function renderProfile() {
  return `<div class="screen">
    <div class="page-title">프로필</div>
    <div class="row" style="border-top:1px solid var(--line)">
      ${avatarHTML(state.me)}
      <div class="grow">
        <div class="stock-name">${esc(state.me.nickname)}</div>
        <div class="caption">로컬 데모 · 서버 없음</div>
      </div>
    </div>
    <div class="section">
      <div class="section-title">시장 흔들기</div>
      <p class="note">데모에서 사건을 만들기 위한 시세 조작입니다.</p>
      <div class="actions">
        ${sm("NVDA +12%", "shock:NVDA:0.12")}
        ${sm("NVDA -12%", "shock:NVDA:-0.12")}
        ${sm("TSLA +15%", "shock:TSLA:0.15")}
        ${sm("TSLA -15%", "shock:TSLA:-0.15")}
        ${sm("AAPL +8%", "shock:AAPL:0.08")}
      </div>
    </div>
    <div class="section">
      <div class="section-title">친구로 보기</div>
      <p class="note">한 브라우저에서 상대 화면을 확인합니다.</p>
      <div class="actions">${memberUsers().map((u) => sm(u.nickname, `play:${u.id}`)).join("")}</div>
    </div>
    <div class="section">${btn("데모 리셋", "secondary full", "reset")}</div>
  </div>`;
}

function sheetWrap(inner) {
  return `<div class="sheet"><div class="panel">${inner}</div></div>`;
}

function sheetHTML() {
  if (!state.sheet) return "";
  if (state.sheet.startsWith("add") || state.sheet.startsWith("register:")) {
    const pre = state.sheet.startsWith("register:") ? state.sheet.split(":")[1] : "";
    const selectedId = state.addTicker || pre || state.stocks[0]?.id;
    const selected = stock(selectedId) || state.stocks[0];
    const options = state.stocks.map((s) => `<option value="${s.id}" ${s.id === selectedId ? "selected" : ""}>${s.name} (${s.ticker})</option>`).join("");
    const priceVal = state.addPrice || "";
    return sheetWrap(`
      <h2>주식 추가</h2>
      <p class="note">${pre ? "추천받은 종목입니다. 샀으면 내가 산 가격을 적으세요. 현재가로 채우지 않습니다." : "목록에서 종목을 고르고, 차트에서 그날 가격을 고르거나 직접 적으세요. 캡처는 iOS 앱에 있습니다."}</p>
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
  if (state.sheet.startsWith("open-rec:")) {
    const hid = state.sheet.split(":")[1];
    const others = memberUsers().filter((u) => u.id !== state.me.id);
    return sheetWrap(`
      <h2>친구에게 추천</h2>
      <p class="note">이미 내가 보유한 종목을 친구에게 알립니다. 한마디를 적으면 추천 히스토리에 남습니다.</p>
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
  if (state.sheet.startsWith("thread:")) {
    const stockId = state.sheet.split(":")[1];
    const s = stock(stockId);
    if (!s) return "";
    const recs = state.recs.filter((r) => r.stockId === stockId && r.groupId === group()?.id).sort((a, b) => a.createdAt - b.createdAt);
    const comments = commentsFor(stockId);
    const roots = comments.filter((c) => !c.parentId);
    const reply = state.replyTo ? comments.find((c) => c.id === state.replyTo) : null;
    const commentHTML = (c, isReply) => `<div class="comment ${isReply ? "reply" : ""}">
      ${avatarHTML(user(c.authorId) || { nickname: "?" }, "sm")}
      <div class="grow">
        <div class="names">${esc(nickname(c.authorId))}</div>
        <div class="body">${esc(c.body)}</div>
        <div class="time">${relative(c.createdAt)}${!c.parentId ? ` · <button class="btn text" data-act="reply:${c.id}">답글</button>` : ""}</div>
      </div>
    </div>`;
    return sheetWrap(`
      <div class="thread-head">
        ${stockMark(s, "lg")}
        <div class="grow">
          <h2 style="margin:0">${esc(s.name)}</h2>
          <div class="ticker">${esc(s.ticker)}</div>
          ${pulseStrip(s.id, false)}
        </div>
      </div>
      <p class="note">이 종목을 추천한 기록과 댓글입니다. 한 줄 남기면 히스토리에 남습니다.</p>
      <div class="kind">추천 히스토리</div>
      ${recs.length ? recs.map((r) => `<div class="history-item">
        <div class="names">${esc(nickname(r.senderId))} → ${esc(nickname(r.receiverId))}</div>
        <div class="body">“${esc(r.message)}”</div>
        <div class="time">${esc(recStatusLabel(r.status))} · ${relative(r.createdAt)}</div>
      </div>`).join("") : `<p class="empty">아직 이 종목을 추천한 기록이 없습니다.</p>`}
      <div class="kind" style="margin-top:16px">댓글 ${comments.length}</div>
      ${roots.length ? roots.map((c) => commentHTML(c, false) + comments.filter((x) => x.parentId === c.id).map((x) => commentHTML(x, true)).join("")).join("") : `<p class="empty">아직 댓글이 없습니다. 이 추천에 한마디 남겨 보세요.</p>`}
      ${reply ? `<div class="caption">${esc(nickname(reply.authorId))}에게 답글 · <button class="btn text" data-act="cancel-reply">취소</button></div>` : ""}
      <label>${reply ? "답글" : "댓글"}</label>
      <input id="thread-text" placeholder="${reply ? "답글 적기" : "이 추천에 한마디"}" value="${esc(state.threadDraft || "")}" />
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

function render() {
  const root = document.getElementById("app");
  let body = "";
  if (state.onboarding) body = renderOnboarding();
  else if (state.tab === "hold") body = renderHoldings();
  else if (state.tab === "act") body = renderActivity();
  else if (state.tab === "me") body = renderProfile();
  else body = renderGroup();
  root.innerHTML = body + tabs() + sheetHTML();
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
  render();
}

let chartTracking = false;
function onChartPointer(e) {
  const svg = e.target.closest && e.target.closest("svg.chart");
  if (!svg) return false;
  e.preventDefault();
  applyChartPick(e.clientX);
  return true;
}
document.addEventListener("pointerdown", (e) => {
  if (!onChartPointer(e)) return;
  chartTracking = true;
  if (e.target.setPointerCapture) {
    try { e.target.setPointerCapture(e.pointerId); } catch (_) {}
  }
});
document.addEventListener("pointermove", (e) => {
  if (!chartTracking) return;
  onChartPointer(e);
});
document.addEventListener("pointerup", () => { chartTracking = false; });
document.addEventListener("pointercancel", () => { chartTracking = false; });

document.addEventListener("change", (e) => {
  if (e.target && e.target.id === "add-ticker") {
    state.addTicker = e.target.value;
    state.chartIndex = null;
    state.addPrice = "";
    render();
  }
});
document.addEventListener("input", (e) => {
  if (e.target && e.target.id === "add-price") state.addPrice = e.target.value;
  if (e.target && e.target.id === "thread-text") state.threadDraft = e.target.value;
});

document.addEventListener("click", (e) => {
  if (e.target.closest && e.target.closest("svg.chart")) {
    e.preventDefault();
    return;
  }
  if (e.target.classList.contains("sheet")) {
    closeSheet();
    return;
  }
  const actEl = e.target.closest("[data-act]");
  if (!actEl) return;
  handle(actEl.getAttribute("data-act"));
});

function handle(act) {
  if (act === "demo") {
    const nick = document.getElementById("nick")?.value?.trim() || "나";
    state.me.nickname = nick;
    seed(state);
    toast("그룹에 참여했습니다");
    render();
    return;
  }
  if (act === "empty-start") {
    const nick = document.getElementById("nick")?.value?.trim() || "나";
    state.me.nickname = nick;
    state.onboarding = false;
    state.groups.push({ id: "g-empty", name: "내 그룹", invite: "SOLO", ownerId: state.me.id });
    state.selectedGroupId = "g-empty";
    state.members.push({ groupId: "g-empty", userId: state.me.id, joinedAt: now() });
    render();
    return;
  }
  if (act.startsWith("tab:")) { state.tab = act.split(":")[1]; render(); return; }
  if (act === "copy") { navigator.clipboard?.writeText("KKANBU"); toast("초대 코드 복사됨"); return; }
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
  if (act.startsWith("sell:")) return sellHolding(act.split(":")[1]);
  if (act.startsWith("verify:")) return verify(act.split(":")[1]);
  if (act.startsWith("suspect:")) return suspect(act.split(":")[1]);
  if (act.startsWith("open-rec:")) { openSheet(act); return; }
  if (act.startsWith("open-prop")) { openSheet(act); return; }
  if (act.startsWith("send-rec:")) {
    const parts = act.split(":");
    const msg = document.getElementById("rec-msg")?.value;
    return recommend(parts[1], parts[2], msg);
  }
  if (act.startsWith("thread:")) {
    state.replyTo = null;
    state.threadDraft = "";
    openSheet(act);
    return;
  }
  if (act.startsWith("reply:")) {
    const input = document.getElementById("thread-text");
    if (input) state.threadDraft = input.value;
    state.replyTo = act.split(":")[1];
    render();
    return;
  }
  if (act === "cancel-reply") {
    const input = document.getElementById("thread-text");
    if (input) state.threadDraft = input.value;
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

render();
