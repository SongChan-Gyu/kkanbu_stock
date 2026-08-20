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
  if (shared >= 0.5) return { emoji: "🚀", title: "신의 한 수 파트너" };
  if (shared <= -0.35) return { emoji: "🪦", title: "공동묘지 파트너" };
  if (shared <= -0.2) return { emoji: "💀", title: "최악의 주식 파트너" };
  if (shared >= 0.2) return { emoji: "🔥", title: "황금 깐부" };
  return { emoji: "🤝", title: "주식 깐부" };
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
    stocks: makeStocks(),
    onboarding: true,
    tab: "group",
    sheet: null,
    toast: null,
    error: null
  };
}

function seed(state) {
  const friends = [
    { id: "cheolsu", nickname: "철수", avatar: "🦊" },
    { id: "younghee", nickname: "영희", avatar: "🐰" },
    { id: "minsu", nickname: "민수", avatar: "🐼" },
    { id: "junho", nickname: "준호", avatar: "🐯" },
    { id: "sujin", nickname: "수진", avatar: "🐥" }
  ];
  state.users.push(...friends);
  const group = { id: "g1", name: "우리 주식팟", invite: "KKANBU", mood: "🔥", ownerId: "cheolsu" };
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

  const youngheeNVDA = H("younghee", "NVDA", 168.2, { quantity: 2, createdAt: now() - days(32) });
  const junhoTSLA = H("junho", "TSLA", 241, { verification: "suspected", createdAt: now() - days(10) });
  state.holdings.push(
    H("cheolsu", "NVDA", 163.4, { quantity: 4, verification: "screenshot", createdAt: now() - days(40) }),
    youngheeNVDA,
    H("cheolsu", "AAPL", 198, { verification: "screenshot", createdAt: now() - days(50) }),
    H("younghee", "AAPL", 210.4, { createdAt: now() - days(18) }),
    H("minsu", "TSLA", 180, { status: "sold", sellPrice: 212, createdAt: now() - days(25) }),
    junhoTSLA,
    H("sujin", "005930", 68500, { verification: "screenshot", createdAt: now() - days(60) }),
    H("minsu", "000660", 210000, { createdAt: now() - days(12) }),
    H("younghee", "AMD", 142, { createdAt: now() - days(22) }),
    H(state.me.id, "AAPL", 205, { createdAt: now() - days(14) })
  );

  state.recs.push({
    id: "rec1", groupId: group.id, senderId: "younghee", receiverId: state.me.id,
    stockId: "NVDA", holdingId: youngheeNVDA.id, message: "나 이거 샀으니까 너도 사 ㅋㅋ",
    status: "pending", createdAt: now() - hours(3)
  });
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
    ev(group.id, "👋 새 멤버", `${nick}님이 우리 주식팟에 들어왔습니다.`, now() - 120000, "member"),
    ev(group.id, "📣 너도 사!", `영희가 ${nick}에게 NVIDIA를 추천했습니다.\n“나 이거 샀으니까 너도 사 ㅋㅋ”`, now() - hours(3), "rec"),
    ev(group.id, "🤔 이거 어때?", "민수가 AMD 같이 사자고 제안했습니다.\n“이번에 같이 들어갈 사람?”", now() - hours(8), "prop"),
    ev(group.id, "😂 같이 사자고 조르기", `민수가 ${nick}에게 AMD를 두 번째로 같이 사자고 조르고 있습니다.`, now() - hours(1), "nag"),
    ev(group.id, "🤝 새로운 주식 깐부", `${nick} × 철수\nApple 깐부가 탄생했습니다.`, now() - days(14), "kk"),
    ev(group.id, "🤝 새로운 주식 깐부", "철수 × 영희\nNVIDIA 깐부가 탄생했습니다.", now() - days(32), "kk"),
    ev(group.id, "🔥 황금 깐부", "철수와 영희가 NVIDIA 황금 깐부가 되었습니다.", now() - days(4), "gold"),
    ev(group.id, "🏃 혼자 튐", "민수가 Tesla를 팔고 혼자 튀었습니다.\n준호는 아직 남아 있습니다.", now() - days(2), "solo"),
    ev(group.id, "🕵️ 구라핑 의혹", "친구들이 준호의 Tesla 매수가를 의심하고 있습니다.", now() - hours(5), "gura"),
    ev(group.id, "📸 매수가 인증 완료", "철수가 NVIDIA 매수가를 인증했습니다.", now() - days(39), "shot"),
    ev(group.id, "💎 끝까지 존버", "친구들이 Tesla에서 떠났는데 준호만 남아 있습니다.", now() - days(2) + 30000, "diamond")
  ];
  state.badges = [
    { userId: "cheolsu", title: "황금 깐부", emoji: "🔥" },
    { userId: "younghee", title: "황금 깐부", emoji: "🔥" },
    { userId: "junho", title: "끝까지 존버", emoji: "💎" }
  ];
  state.onboarding = false;
}

function ev(groupId, title, message, createdAt, type) {
  return { id: uid(), groupId, title, message, createdAt, type };
}

let state = emptyState({ id: "me", nickname: "나", avatar: "🐣" });

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
function pushEvent(title, message, type) {
  const g = group();
  state.events.unshift(ev(g.id, title, message, now(), type));
}

function inbox() {
  const me = state.me.id;
  const items = [];
  state.recs.filter((r) => r.receiverId === me && r.status === "pending").forEach((r) => items.push({ kind: "recommend", rec: r }));
  state.proposals.forEach((p) => {
    const mine = state.cobuys.find((c) => c.proposalId === p.id && c.userId === me);
    const nagger = state.cobuys.find((c) => c.proposalId === p.id && (c.nagCount || 0) > 0);
    if (!mine) {
      items.push({ kind: nagger ? "nag" : "proposal", proposal: p });
    } else if (mine.status === "promised" && !activeHoldings(me).some((h) => h.stockId === p.stockId)) {
      items.push({ kind: "cobuyRegister", proposal: p });
    }
  });
  state.holdings.filter((h) => h.userId === me && (h.verification === "suspected" || h.verification === "mismatch")).forEach((h) => {
    items.push({ kind: "suspect", holding: h });
  });
  return items;
}

function addHolding(ticker, avg, method = "manual") {
  if (activeHoldings(state.me.id).some((h) => h.stockId === ticker)) {
    toast("이미 보유 중이에요.");
    return;
  }
  const s = stock(ticker);
  const holding = {
    id: uid(), userId: state.me.id, stockId: ticker, averagePrice: avg,
    status: "holding", verification: method === "screenshot" ? "screenshot" : "unverified", createdAt: now()
  };
  state.holdings.push(holding);
  const beforePartners = partnersOf(state.me.id, ticker);
  const newBonds = bonds().filter((b) => b.stockId === ticker && (b.a === state.me.id || b.b === state.me.id));
  newBonds.forEach((b) => {
    const other = b.a === state.me.id ? b.b : b.a;
    pushEvent("🤝 새로운 주식 깐부", `${state.me.nickname} × ${nickname(other)}\n${s.name} 깐부가 탄생했습니다.`, "kk");
  });
  state.cobuys.filter((c) => c.userId === state.me.id && c.stockId === ticker && c.status === "promised").forEach((c) => {
    c.status = "registered";
  });
  toast(`${s.name} 등록 완료`);
  state.sheet = null;
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
    pushEvent("🏃 혼자 튐", `${state.me.nickname}가 ${s.name}를 팔고 혼자 튀었습니다.\n${nickname(leftovers[0].userId)}는 아직 남아 있습니다.`, "solo");
    leftovers.forEach((left) => {
      pushEvent("💎 끝까지 존버", `친구들이 ${s.name}에서 떠났는데 ${nickname(left.userId)}만 남아 있습니다.`, "diamond");
    });
  } else {
    pushEvent("🏃 매도", `${state.me.nickname}가 ${s.name}를 정리했습니다.`, "solo");
  }
  toast("매도 처리됨. 기록이 남고, 사건이 생길 수 있어요.");
  render();
}

function acceptRec(id, accept) {
  const rec = state.recs.find((r) => r.id === id);
  if (!rec) return;
  rec.status = accept ? "accepted" : "rejected";
  if (accept) addHolding(rec.stockId, priceOf(stock(rec.stockId)));
  else { toast("나중에로 미뤘어요"); render(); }
}

function declineProposal(proposalId) {
  const p = state.proposals.find((x) => x.id === proposalId);
  if (!p) return;
  const existing = state.cobuys.find((c) => c.proposalId === proposalId && c.userId === state.me.id);
  if (existing) existing.status = "declined";
  else state.cobuys.push({ id: uid(), proposalId, groupId: p.groupId, userId: state.me.id, stockId: p.stockId, status: "declined", nagCount: 0 });
  toast("나중에로 미뤘어요");
  render();
}

function promiseCoBuy(proposalId) {
  const p = state.proposals.find((x) => x.id === proposalId);
  if (!p) return;
  if (!state.cobuys.some((c) => c.proposalId === proposalId && c.userId === state.me.id)) {
    state.cobuys.push({ id: uid(), proposalId, groupId: p.groupId, userId: state.me.id, stockId: p.stockId, status: "promised", nagCount: 0 });
  }
  pushEvent("🤝 같이 사기 약속", `${state.me.nickname}님이 ${stock(p.stockId).name} 같이 사기에 손을 올렸습니다.`, "prop");
  toast("약속만 했어요. 지금 등록해야 깐부가 됩니다.");
  render();
}

function recommend(holdingId, toUserId) {
  const h = state.holdings.find((x) => x.id === holdingId);
  const rec = {
    id: uid(), groupId: group().id, senderId: state.me.id, receiverId: toUserId,
    stockId: h.stockId, holdingId, message: "나 이거 샀으니까 너도 사 ㅋㅋ", status: "pending", createdAt: now()
  };
  state.recs.push(rec);
  pushEvent("📣 너도 사!", `${state.me.nickname}가 ${nickname(toUserId)}에게 ${stock(h.stockId).name}를 추천했습니다.`, "rec");
  toast("너도 사! 를 보냈어요");
  state.sheet = null;
  render();
}

function propose(ticker, message) {
  const p = { id: uid(), groupId: group().id, proposerId: state.me.id, stockId: ticker, message, createdAt: now() };
  state.proposals.push(p);
  state.cobuys.push({ id: uid(), proposalId: p.id, groupId: group().id, userId: state.me.id, stockId: ticker, status: "promised", nagCount: 0 });
  pushEvent("🤔 이거 어때?", `${state.me.nickname}가 ${stock(ticker).name} 같이 사자고 제안했습니다.\n“${message}”`, "prop");
  toast("이거 어때? 를 보냈어요");
  state.sheet = null;
  render();
}

function suspect(holdingId) {
  const h = state.holdings.find((x) => x.id === holdingId);
  if (h.userId === state.me.id) return;
  h.verification = "suspected";
  state.suspicions.push({ holdingId, actorId: state.me.id, targetUserId: h.userId, createdAt: now() });
  pushEvent("🕵️ 구라핑 의혹", `친구들이 ${nickname(h.userId)}의 ${stock(h.stockId).name} 매수가를 의심하고 있습니다.`, "gura");
  toast("구라핑 의심을 남겼어요. 단정은 하지 않아요.");
  render();
}

function verify(holdingId) {
  const h = state.holdings.find((x) => x.id === holdingId);
  h.verification = "screenshot";
  pushEvent("📸 매수가 인증 완료", `${state.me.nickname}가 ${stock(h.stockId).name} 매수가를 인증했습니다.`, "shot");
  toast("캡처 인증 완료 (웹 데모는 목 인증)");
  state.sheet = null;
  render();
}

function shock(ticker, pct) {
  stock(ticker).offset += pct;
  toast("시장이 흔들렸습니다");
  const s = stock(ticker);
  const holders = state.holdings.filter((h) => h.stockId === ticker && h.status === "holding");
  if (pct > 0 && holders.length >= 2) {
    const pair = holders.slice(0, 2);
    pushEvent("🔥 황금 깐부", `${nickname(pair[0].userId)}와 ${nickname(pair[1].userId)}가 ${s.name} 황금 깐부가 되었습니다.`, "gold");
  }
  const sold = state.holdings.filter((h) => h.stockId === ticker && h.status === "sold");
  if (pct > 0 && sold.length) {
    pushEvent("👀 너무 일찍 튐", `${nickname(sold[0].userId)}가 ${s.name}를 너무 일찍 팔았습니다. 이후에 더 올랐어요.`, "early");
  }
  if (pct < 0 && sold.length) {
    pushEvent("🔮 선견지명", `${nickname(sold[0].userId)}가 ${s.name}를 미리 정리했습니다. 이후에 빠졌어요.`, "foresight");
  }
  render();
}

function playAs(userId) {
  const u = user(userId);
  state.me = u;
  toast(`${u.nickname}로 플레이합니다`);
  render();
}

function resetDemo() {
  const me = { id: "me", nickname: state.me.nickname === "나" || ["철수","영희","민수","준호","수진"].includes(state.me.nickname) ? "나" : state.me.nickname, avatar: "🐣" };
  if (["철수","영희","민수","준호","수진"].includes(state.me.nickname)) me.nickname = "나";
  state = emptyState(me);
  seed(state);
  toast("데모를 다시 깔았습니다");
  render();
}

function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

function pill(label, kind, action) {
  return `<button class="pill ${kind || "primary"}" data-act="${esc(action)}">${label}</button>`;
}
function small(label, action) {
  return `<button class="pill small" data-act="${esc(action)}">${label}</button>`;
}

function renderOnboarding() {
  return `
    <div class="screen">
      <p class="muted">친구 비공개 그룹 · 증권 앱 아님</p>
      <h1 class="nav-title">주식 깐부</h1>
      <div class="card">
        <p>같은 종목을 들고 있으면 깐부가 됩니다. 주가 숫자보다 오늘 친구들 사이에서 벌어진 일이 주인공입니다.</p>
        <label>닉네임</label>
        <input id="nick" value="${esc(state.me.nickname)}" />
        <div class="disclaimer">직접 입력한 보유 정보는 증권 계좌로 검증되지 않아요. 이 앱은 투자 자문이 아니라 친구랑 노는 게임입니다.</div>
        ${pill("데모 주식팟으로 시작", "primary", "demo")}
        <div style="height:8px"></div>
        ${pill("빈 그룹으로 시작", "secondary", "empty-start")}
      </div>
    </div>`;
}

function holdingCard(h, isMine) {
  const s = stock(h.stockId);
  const p = h.status === "sold" ? (h.sellPrice || priceOf(s)) : priceOf(s);
  const r = ret(h.averagePrice, p);
  const partners = partnersOf(h.userId, h.stockId);
  const g = partners.length ? gradeFor(r) : null;
  const vLabel = { unverified: "⚪ 직접 입력", screenshot: "🟢 캡처 인증", suspected: "👀 의심 중", mismatch: "🚨 정보 불일치" }[h.verification];
  let actions = "";
  if (isMine && h.status === "holding") {
    actions = small("📣 너도 사!", `open-rec:${h.id}`) + small("🤔 이거 어때?", `open-prop:${h.stockId}`) + small("🏃 매도", `sell:${h.id}`);
    if (h.verification !== "screenshot") actions += small("📸 인증", `verify:${h.id}`);
  } else if (!isMine && h.status === "holding") {
    actions = small("🕵️ 구라핑 의심", `suspect:${h.id}`);
  }
  return `
    <div class="card">
      <div class="row" style="align-items:flex-start">
        <div>
          <h2>${esc(s.name)}</h2>
          <div class="muted">${esc(s.ticker)}</div>
        </div>
        <span class="badge">${vLabel}</span>
      </div>
      <div class="ret ${r >= 0 ? "up" : "down"}">${formatPct(r)}</div>
      <div class="row">
        <div><div class="muted">평단</div><b>${formatPrice(h.averagePrice, s.market)}</b></div>
        <div><div class="muted">현재가</div><b>${formatPrice(priceOf(s), s.market)}</b></div>
      </div>
      ${partners.length ? `<p>${g.emoji} ${esc(partners.join(", "))}와 ${g.title}</p>` : ""}
      ${h.status === "sold" ? `<p class="muted">매도 완료 · ${formatPct(ret(h.averagePrice, h.sellPrice))}</p>` : ""}
      <div class="wrap">${actions}</div>
    </div>`;
}

function inboxCard(item) {
  if (item.kind === "recommend") {
    const rec = item.rec;
    const s = stock(rec.stockId);
    const h = state.holdings.find((x) => x.id === rec.holdingId);
    return `<div class="card">
      <h2>📣 ${esc(nickname(rec.senderId))}가 ${esc(s.name)}를 추천했어요</h2>
      ${h ? `<p class="muted">${esc(nickname(rec.senderId))} 평단 ${formatPrice(h.averagePrice, s.market)} · ${formatPct(ret(h.averagePrice, priceOf(s)))}</p>` : ""}
      <p>“${esc(rec.message)}”</p>
      <div class="row">${pill("나도 추가하기", "primary", `accept:${rec.id}`)}${pill("나중에", "secondary", `reject:${rec.id}`)}</div>
    </div>`;
  }
  if (item.kind === "proposal" || item.kind === "nag") {
    const p = item.proposal;
    const title = item.kind === "nag" ? "😂 같이 사자고 또 찔렀어요" : `🤔 ${esc(nickname(p.proposerId))}가 같이 사자고 해요`;
    return `<div class="card">
      <h2>${title}</h2>
      <p>${esc(p.message)}</p>
      <div class="row">${pill("🤝 같이 사자", "primary", `promise:${p.id}`)}${pill("나중에", "secondary", `later:${p.id}`)}</div>
    </div>`;
  }
  if (item.kind === "cobuyRegister") {
    const p = item.proposal;
    const s = stock(p.stockId);
    return `<div class="card">
      <h2>🤝 약속만 하고 아직 등록 전</h2>
      <p>${esc(s.name)}를 실제로 넣어야 깐부가 됩니다.</p>
      ${pill("지금 등록하기", "primary", `register:${s.id}`)}
    </div>`;
  }
  if (item.kind === "suspect") {
    const h = item.holding;
    const s = stock(h.stockId);
    return `<div class="card">
      <h2>😂 친구들이 네 ${esc(s.name)} 매수가를 의심하고 있습니다</h2>
      <p>진짜 ${formatPrice(h.averagePrice, s.market)}에 산 거 맞아?</p>
      <p class="muted">사기라고 단정하지 않아요. 캡처로 확인만 하면 됩니다.</p>
      ${pill("📸 캡처로 인증하기", "primary", `verify:${h.id}`)}
    </div>`;
  }
  return "";
}

function renderGroup() {
  const g = group();
  if (!g) {
    return `<div class="screen"><h1 class="nav-title">그룹</h1>
      <div class="card"><h2>아직 그룹이 없어요</h2>
      ${pill("데모 주식팟 불러오기", "primary", "demo")}</div></div>`;
  }
  const items = inbox();
  const spicy = state.events.find((e) => ["solo", "gold", "gura", "diamond"].includes(e.type)) || state.events[0];
  const kk = bonds();
  const friendsHoldings = state.holdings.filter((h) => h.userId !== state.me.id && memberUsers().some((u) => u.id === h.userId));
  return `
    <div class="screen">
      <h1 class="nav-title">${esc(g.name)}</h1>
      <div class="card">
        <h2>${g.mood} ${esc(g.name)}</h2>
        <div class="muted">초대 코드 ${g.invite}</div>
        <h2>오늘 누가 튀었지?</h2>
        <div class="row">${pill("코드 복사", "primary", "copy")}${pill("주식 추가", "secondary", "open-add")}</div>
        <div style="height:8px"></div>
        ${pill("🤔 이거 어때?", "secondary", "open-prop:")}
      </div>
      ${items.length ? `<h3>나한테 온 일</h3><p class="muted">앱을 연 이유. 숫자 확인이 아니라 이거.</p>${items.map(inboxCard).join("")}` : ""}
      ${spicy ? `<div class="card"><div class="muted">지금 제일 핫한 일</div>${eventRow(spicy)}</div>` : ""}
      <div class="members">${memberUsers().map((u) => `<button class="member" data-act="play:${u.id}"><div class="avatar">${u.avatar}</div>${esc(u.nickname)}</button>`).join("")}</div>
      <h3>깐부</h3>
      <div class="card">${kk.length ? kk.map((b) => `<div>${b.grade.emoji} ${esc(nickname(b.a))} × ${esc(nickname(b.b))} · ${esc(stock(b.stockId).name)} · ${formatPct(b.shared)}</div>`).join("") : "아직 깐부가 없어요"}</div>
      <h3>친구 주식</h3>
      ${friendsHoldings.map((h) => holdingCard(h, false)).join("")}
      <h3>피드</h3>
      <div class="card">${state.events.map(eventRow).join("")}</div>
    </div>`;
}

function eventRow(e) {
  const emoji = (e.title.match(/^(\S+)/) || ["📌"])[0];
  return `<div class="event"><div class="emoji">${emoji}</div><div><b>${esc(e.title)}</b><div class="muted">${esc(e.message)}</div><div class="muted">${relative(e.createdAt)}</div></div></div>`;
}

function renderHoldings() {
  const mine = state.holdings.filter((h) => h.userId === state.me.id);
  return `<div class="screen">
    <h1 class="nav-title">내 주식</h1>
    <div class="disclaimer">직접 입력한 보유 정보는 증권 계좌로 검증되지 않아요.</div>
    ${pill("주식 추가", "primary", "open-add")}
    <div style="height:10px"></div>
    ${mine.length ? mine.map((h) => holdingCard(h, true)).join("") : `<div class="card">아직 등록한 주식이 없어요.</div>`}
  </div>`;
}

function renderActivity() {
  const mine = inbox();
  const recs = state.recs.filter((r) => r.senderId === state.me.id || r.receiverId === state.me.id);
  return `<div class="screen">
    <h1 class="nav-title">활동</h1>
    ${mine.length ? mine.map(inboxCard).join("") : `<div class="card">지금은 대기 중인 일이 없어요.</div>`}
    <h3>너도 사 기록</h3>
    <div class="card">${recs.map((r) => `<div class="muted">${esc(nickname(r.senderId))} → ${esc(nickname(r.receiverId))} · ${esc(stock(r.stockId).name)} · ${r.status}</div>`).join("") || "없음"}</div>
  </div>`;
}

function renderProfile() {
  return `<div class="screen">
    <h1 class="nav-title">프로필</h1>
    <div class="card">
      <div class="row" style="align-items:center">
        <div class="avatar">${state.me.avatar}</div>
        <div><h2>${esc(state.me.nickname)}</h2><div class="muted">웹 데모 · 로컬만 저장</div></div>
      </div>
    </div>
    <div class="card">
      <h2>시장 흔들기</h2>
      <p class="muted">데모에서 사건을 만들기 위한 치트입니다.</p>
      <div class="wrap">
        ${small("NVDA +12%", "shock:NVDA:0.12")}
        ${small("NVDA -12%", "shock:NVDA:-0.12")}
        ${small("TSLA +15%", "shock:TSLA:0.15")}
        ${small("TSLA -15%", "shock:TSLA:-0.15")}
        ${small("AAPL +8%", "shock:AAPL:0.08")}
      </div>
    </div>
    <div class="card">
      <h2>친구로 플레이</h2>
      <p class="muted">한 브라우저에서 상대방 차례를 확인합니다. 실서버 멀티플레이는 없습니다.</p>
      <div class="wrap">${memberUsers().map((u) => small(u.nickname, `play:${u.id}`)).join("")}</div>
    </div>
    ${pill("데모 리셋", "secondary", "reset")}
  </div>`;
}

function sheetHTML() {
  if (!state.sheet) return "";
  if (state.sheet.startsWith("add") || state.sheet.startsWith("register:")) {
    const pre = state.sheet.startsWith("register:") ? state.sheet.split(":")[1] : "";
    const options = state.stocks.map((s) => `<option value="${s.id}" ${s.id === pre ? "selected" : ""}>${s.name} (${s.ticker})</option>`).join("");
    return `<div class="sheet" data-act="close"><div class="panel" onclick="event.stopPropagation()">
      <h2>주식 추가</h2>
      <p class="muted">같이 사기 약속만으로는 깐부가 되지 않습니다. 여기서 등록해야 합니다.</p>
      <select id="add-ticker">${options}</select>
      <label>매수가</label>
      <input id="add-price" type="number" step="0.01" value="${pre ? priceOf(stock(pre)).toFixed(2) : ""}" />
      ${pill("등록", "primary", "do-add")}
      <div style="height:8px"></div>
      ${pill("닫기", "secondary", "close")}
    </div></div>`;
  }
  if (state.sheet.startsWith("open-rec:")) {
    const hid = state.sheet.split(":")[1];
    const others = memberUsers().filter((u) => u.id !== state.me.id);
    return `<div class="sheet" data-act="close"><div class="panel" onclick="event.stopPropagation()">
      <h2>너도 사!</h2>
      ${others.map((u) => pill(u.nickname + "에게 보내기", "secondary", `send-rec:${hid}:${u.id}`)).join("<div style='height:8px'></div>")}
      <div style="height:8px"></div>${pill("닫기", "secondary", "close")}
    </div></div>`;
  }
  if (state.sheet.startsWith("open-prop")) {
    const pre = state.sheet.split(":")[1] || "AMD";
    const options = state.stocks.map((s) => `<option value="${s.id}" ${s.id === pre ? "selected" : ""}>${s.name}</option>`).join("");
    return `<div class="sheet" data-act="close"><div class="panel" onclick="event.stopPropagation()">
      <h2>이거 어때?</h2>
      <select id="prop-ticker">${options}</select>
      <input id="prop-msg" value="이번에 같이 들어갈 사람?" />
      ${pill("보내기", "primary", "do-prop")}
      <div style="height:8px"></div>${pill("닫기", "secondary", "close")}
    </div></div>`;
  }
  return "";
}

function tabs() {
  if (state.onboarding) return "";
  const items = [["group","그룹"],["hold","내 주식"],["act","활동"],["me","프로필"]];
  return `<nav class="tabs">${items.map(([id, label]) => `<button class="${state.tab === id ? "on" : ""}" data-act="tab:${id}">${label}</button>`).join("")}</nav>`;
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

document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-act]");
  if (!btn) return;
  const act = btn.getAttribute("data-act");
  handle(act);
});

function handle(act) {
  if (act === "demo") {
    const nick = document.getElementById("nick")?.value?.trim() || "나";
    state.me.nickname = nick;
    seed(state);
    toast("우리 주식팟에 들어왔습니다");
    render();
    return;
  }
  if (act === "empty-start") {
    const nick = document.getElementById("nick")?.value?.trim() || "나";
    state.me.nickname = nick;
    state.onboarding = false;
    state.groups.push({ id: "g-empty", name: "나만의 팟", invite: "SOLO", mood: "🐣", ownerId: state.me.id });
    state.selectedGroupId = "g-empty";
    state.members.push({ groupId: "g-empty", userId: state.me.id, joinedAt: now() });
    render();
    return;
  }
  if (act.startsWith("tab:")) { state.tab = act.split(":")[1]; render(); return; }
  if (act === "copy") { navigator.clipboard?.writeText("KKANBU"); toast("초대 코드 KKANBU 복사"); return; }
  if (act === "open-add") { state.sheet = "add"; render(); return; }
  if (act === "close") { state.sheet = null; render(); return; }
  if (act === "do-add") {
    const ticker = document.getElementById("add-ticker").value;
    const price = Number(document.getElementById("add-price").value) || priceOf(stock(ticker));
    addHolding(ticker, price);
    return;
  }
  if (act.startsWith("accept:")) return acceptRec(act.split(":")[1], true);
  if (act.startsWith("reject:")) return acceptRec(act.split(":")[1], false);
  if (act.startsWith("promise:")) return promiseCoBuy(act.split(":")[1]);
  if (act.startsWith("later:")) return declineProposal(act.split(":")[1]);
  if (act.startsWith("register:")) { state.sheet = act; render(); return; }
  if (act.startsWith("sell:")) return sellHolding(act.split(":")[1]);
  if (act.startsWith("verify:")) return verify(act.split(":")[1]);
  if (act.startsWith("suspect:")) return suspect(act.split(":")[1]);
  if (act.startsWith("open-rec:")) { state.sheet = act; render(); return; }
  if (act.startsWith("open-prop")) { state.sheet = act; render(); return; }
  if (act.startsWith("send-rec:")) {
    const [, hid, uid] = act.split(":");
    return recommend(hid, uid);
  }
  if (act === "do-prop") {
    propose(document.getElementById("prop-ticker").value, document.getElementById("prop-msg").value);
    return;
  }
  if (act.startsWith("shock:")) {
    const [, ticker, pct] = act.split(":");
    return shock(ticker, Number(pct));
  }
  if (act.startsWith("play:")) return playAs(act.split(":")[1]);
  if (act === "reset") return resetDemo();
}

render();
