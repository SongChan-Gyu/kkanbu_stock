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
  if (shared >= 0.5) return { title: "신의 한 수" };
  if (shared <= -0.35) return { title: "공동묘지" };
  if (shared <= -0.2) return { title: "최악의 파트너" };
  if (shared >= 0.2) return { title: "황금 깐부" };
  return { title: "깐부" };
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
    stockId: "NVDA", holdingId: youngheeNVDA.id, message: "같이 들어가 봐.",
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
    ev(group.id, "멤버 참여", `${nick}님이 그룹에 참여했습니다.`, now() - 120000, "member", state.me.id),
    ev(group.id, "추천", `NVIDIA를 추천했습니다.`, now() - hours(3), "rec", "younghee"),
    ev(group.id, "같이 사기 제안", `AMD 매수를 제안했습니다.`, now() - hours(8), "prop", "minsu"),
    ev(group.id, "조르기", `${nick}에게 AMD를 같이 사자고 조르는 중`, now() - hours(1), "nag", "minsu"),
    ev(group.id, "깐부", `${nick} · 철수 · Apple`, now() - days(14), "kk", state.me.id),
    ev(group.id, "깐부", `철수 · 영희 · NVIDIA`, now() - days(32), "kk", "cheolsu"),
    ev(group.id, "황금 깐부", `철수 · 영희 · NVIDIA`, now() - days(4), "gold", "cheolsu"),
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

function ev(groupId, title, message, createdAt, type, actorId) {
  return { id: uid(), groupId, title, message, createdAt, type, actorId };
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
function pushEvent(title, message, type, actorId) {
  const g = group();
  state.events.unshift(ev(g.id, title, message, now(), type, actorId || state.me.id));
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
  toast(`${s.name} 등록됨`);
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
  rec.status = accept ? "accepted" : "rejected";
  if (accept) addHolding(rec.stockId, priceOf(stock(rec.stockId)));
  else { toast("나중에로 미뤘습니다"); render(); }
}

function declineProposal(proposalId) {
  const p = state.proposals.find((x) => x.id === proposalId);
  if (!p) return;
  const existing = state.cobuys.find((c) => c.proposalId === proposalId && c.userId === state.me.id);
  if (existing) existing.status = "declined";
  else state.cobuys.push({ id: uid(), proposalId, groupId: p.groupId, userId: state.me.id, stockId: p.stockId, status: "declined", nagCount: 0 });
  toast("나중에로 미뤘습니다");
  render();
}

function promiseCoBuy(proposalId) {
  const p = state.proposals.find((x) => x.id === proposalId);
  if (!p) return;
  if (!state.cobuys.some((c) => c.proposalId === proposalId && c.userId === state.me.id)) {
    state.cobuys.push({ id: uid(), proposalId, groupId: p.groupId, userId: state.me.id, stockId: p.stockId, status: "promised", nagCount: 0 });
  }
  pushEvent("같이 사기 약속", `${stock(p.stockId).name} 같이 사기에 참여했습니다.`, "prop");
  toast("약속만 했습니다. 등록해야 깐부가 됩니다.");
  render();
}

function recommend(holdingId, toUserId) {
  const h = state.holdings.find((x) => x.id === holdingId);
  const rec = {
    id: uid(), groupId: group().id, senderId: state.me.id, receiverId: toUserId,
    stockId: h.stockId, holdingId, message: "같이 들어가 봐.", status: "pending", createdAt: now()
  };
  state.recs.push(rec);
  pushEvent("추천", `${stock(h.stockId).name}를 ${nickname(toUserId)}에게 추천했습니다.`, "rec");
  toast("추천을 보냈습니다");
  state.sheet = null;
  render();
}

function propose(ticker, message) {
  const p = { id: uid(), groupId: group().id, proposerId: state.me.id, stockId: ticker, message, createdAt: now() };
  state.proposals.push(p);
  state.cobuys.push({ id: uid(), proposalId: p.id, groupId: group().id, userId: state.me.id, stockId: ticker, status: "promised", nagCount: 0 });
  pushEvent("같이 사기 제안", `${stock(ticker).name} 매수를 제안했습니다.`, "prop");
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
  const g = partners.length ? gradeFor(r) : null;
  const owner = user(h.userId);
  let actions = "";
  if (isMine && h.status === "holding") {
    actions = sm("친구에게 추천", `open-rec:${h.id}`) + sm("같이 사자고 제안", `open-prop:${h.stockId}`) + sm("매도", `sell:${h.id}`);
    if (h.verification !== "screenshot") actions += sm("캡처 인증", `verify:${h.id}`);
  } else if (!isMine && h.status === "holding") {
    actions = sm("매수가 의심", `suspect:${h.id}`);
  }
  const partnerLine = partners.length
    ? `${esc(partners.join(" · "))}와 ${esc(g.title)}`
    : "";
  const suspect = h.verification === "suspected" ? `<div class="caption">매수가 의심 중</div>` : "";
  return `
    <div class="row">
      <div class="grow">
        ${!isMine ? `<div class="caption">${esc(owner.nickname)}</div>` : ""}
        <div class="stock-name">${esc(s.name)}${verifyMark(h.verification)}</div>
        <div class="ticker">${esc(s.ticker)}</div>
        <div class="meta">평단 ${formatPrice(h.averagePrice, s.market)} · 현재가 ${formatPrice(priceOf(s), s.market)}</div>
        ${partnerLine ? `<div class="caption">${partnerLine}</div>` : ""}
        ${h.status === "sold" ? `<div class="caption">매도 · ${formatPct(ret(h.averagePrice, h.sellPrice))}</div>` : ""}
        ${suspect}
        <div class="actions">${actions}</div>
      </div>
      <div class="right">
        <div class="pct ${r >= 0 ? "up" : "down"}">${formatPct(r)}</div>
      </div>
    </div>`;
}

function inboxBlock(item) {
  if (item.kind === "recommend") {
    const rec = item.rec;
    const s = stock(rec.stockId);
    const h = state.holdings.find((x) => x.id === rec.holdingId);
    const r = h ? ret(h.averagePrice, priceOf(s)) : null;
    return `<div class="action-block">
      <div class="kind">친구가 이미 보유한 종목</div>
      <div class="stock-name">${esc(s.name)}${h ? verifyMark(h.verification) : ""}</div>
      <div class="ticker">${esc(s.ticker)} · ${esc(nickname(rec.senderId))}</div>
      ${h ? `<div class="meta">평단 ${formatPrice(h.averagePrice, s.market)} · ${formatPct(r)}</div>` : ""}
      <p class="caption">같은 종목을 내 보유로 등록하면 ${esc(nickname(rec.senderId))}와 깐부가 됩니다.</p>
      <div class="split">${btn("같은 종목 등록", "primary", `accept:${rec.id}`)}${btn("나중에", "secondary", `reject:${rec.id}`)}</div>
    </div>`;
  }
  if (item.kind === "proposal" || item.kind === "nag") {
    const p = item.proposal;
    const s = stock(p.stockId);
    const kind = item.kind === "nag" ? "같이 사자고 다시 요청" : "아직 안 산 종목을 같이 사자는 제안";
    return `<div class="action-block">
      <div class="kind">${kind}</div>
      <div class="stock-name">${esc(s.name)}</div>
      <div class="ticker">${esc(s.ticker)} · ${esc(nickname(p.proposerId))}</div>
      <p class="caption">지금은 참여 약속만 합니다. 이후 실제로 등록해야 깐부가 됩니다.</p>
      <div class="split">${btn("같이 살게요", "primary", `promise:${p.id}`)}${btn("나중에", "secondary", `later:${p.id}`)}</div>
    </div>`;
  }
  if (item.kind === "cobuyRegister") {
    const p = item.proposal;
    const s = stock(p.stockId);
    return `<div class="action-block">
      <div class="kind">약속 완료 · 보유 등록 전</div>
      <div class="stock-name">${esc(s.name)}</div>
      <div class="ticker">${esc(s.ticker)}</div>
      <p class="caption">약속만으로는 깐부가 되지 않습니다. ${esc(s.name)}를 내 보유로 등록하세요.</p>
      ${btn(s.name + " 등록", "primary", `register:${s.id}`)}
    </div>`;
  }
  if (item.kind === "suspect") {
    const h = item.holding;
    const s = stock(h.stockId);
    return `<div class="action-block">
      <div class="kind">매수가 확인 요청</div>
      <div class="stock-name">${esc(s.name)}</div>
      <div class="ticker">${esc(s.ticker)}</div>
      <p class="caption">${formatPrice(h.averagePrice, s.market)}에 산 기록이 맞는지 캡처로 확인합니다. 사기라고 단정하지 않습니다.</p>
      ${btn("캡처로 인증", "primary", `verify:${h.id}`)}
    </div>`;
  }
  return "";
}

function eventRow(e) {
  const actor = e.actorId ? user(e.actorId) : null;
  return `<div class="feed-item">
    ${actor ? avatarHTML(actor, "sm") : `<div class="avatar sm c0">·</div>`}
    <div class="grow">
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
        ${btn("내 주식 등록", "primary", "open-add")}
        ${btn("같이 살 종목 제안", "secondary", "open-prop:")}
      </div>

      ${items.length ? `<div class="section"><div class="section-title">내 차례</div><div class="row-list">${items.map(inboxBlock).join("")}</div></div>` : ""}

      <div class="section">
        <div class="section-title">멤버</div>
        <div class="members">${memberUsers().map((u) => `<button class="member" data-act="play:${u.id}">${avatarHTML(u)}${`<span>${esc(u.id === state.me.id ? "나" : u.nickname)}</span>`}</button>`).join("")}</div>
      </div>

      <div class="section">
        <div class="section-title">깐부</div>
        ${kk.length ? kk.map((b) => `
          <div class="pair-row">
            <div>
              <div class="names">${esc(nickname(b.a))} · ${esc(nickname(b.b))}</div>
              <div class="stock">${esc(stock(b.stockId).name)} · ${esc(b.grade.title)}</div>
            </div>
            <div class="pct ${b.shared >= 0 ? "up" : "down"}">${formatPct(b.shared)}</div>
          </div>`).join("") : `<p class="empty">아직 깐부가 없습니다.</p>`}
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
    ${btn("내 주식 등록", "primary", "open-add")}
    ${active.length ? `<div class="section"><div class="section-title">보유 중</div><div class="row-list">${active.map((h) => holdingRow(h, true)).join("")}</div></div>` : `<p class="empty">아직 등록한 주식이 없습니다.</p>`}
    ${sold.length ? `<div class="section"><div class="section-title">매도 기록</div><div class="row-list">${sold.map((h) => holdingRow(h, true)).join("")}</div></div>` : ""}
    <p class="note">직접 입력한 보유 정보는 증권 계좌로 검증되지 않습니다.</p>
  </div>`;
}

function renderActivity() {
  const mine = inbox();
  const recs = state.recs.filter((r) => r.senderId === state.me.id || r.receiverId === state.me.id);
  const recStatus = { pending: "대기", accepted: "수락", rejected: "거절" };
  return `<div class="screen">
    <div class="page-title">활동</div>
    <p class="page-sub">이미 산 종목 추천과, 아직 안 산 종목 제안</p>
    ${mine.length ? `<div class="row-list">${mine.map(inboxBlock).join("")}</div>` : `<p class="empty">대기 중인 일이 없습니다.</p>`}
    <div class="section">
      <div class="section-title">추천 기록</div>
      ${recs.length ? recs.map((r) => `<div class="pair-row"><div class="names">${esc(nickname(r.senderId))} → ${esc(nickname(r.receiverId))}</div><div class="stock">${esc(stock(r.stockId).name)} · ${recStatus[r.status] || r.status}</div></div>`).join("") : `<p class="empty">기록이 없습니다.</p>`}
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

function sheetHTML() {
  if (!state.sheet) return "";
  if (state.sheet.startsWith("add") || state.sheet.startsWith("register:")) {
    const pre = state.sheet.startsWith("register:") ? state.sheet.split(":")[1] : "";
    const options = state.stocks.map((s) => `<option value="${s.id}" ${s.id === pre ? "selected" : ""}>${s.name} (${s.ticker})</option>`).join("");
    return `<div class="sheet" data-act="close"><div class="panel" onclick="event.stopPropagation()">
      <h2>내 주식 등록</h2>
      <p class="note">내가 보유한 종목을 기록합니다. 친구가 같은 종목을 들고 있으면 깐부가 됩니다.</p>
      <label>종목</label>
      <select id="add-ticker">${options}</select>
      <label>매수가</label>
      <input id="add-price" type="number" step="0.01" value="${pre ? priceOf(stock(pre)).toFixed(2) : ""}" />
      ${btn("등록", "primary full", "do-add")}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    </div></div>`;
  }
  if (state.sheet.startsWith("open-rec:")) {
    const hid = state.sheet.split(":")[1];
    const others = memberUsers().filter((u) => u.id !== state.me.id);
    return `<div class="sheet" data-act="close"><div class="panel" onclick="event.stopPropagation()">
      <h2>친구에게 추천</h2>
      <p class="note">이미 내가 보유한 종목을 친구에게 알립니다. 친구가 같은 종목을 등록하면 깐부가 됩니다.</p>
      ${others.map((u) => `<div style="margin-bottom:8px">${btn(u.nickname + "에게", "secondary full", `send-rec:${hid}:${u.id}`)}</div>`).join("")}
      ${btn("닫기", "ghost full", "close")}
    </div></div>`;
  }
  if (state.sheet.startsWith("open-prop")) {
    const pre = state.sheet.split(":")[1] || "AMD";
    const options = state.stocks.map((s) => `<option value="${s.id}" ${s.id === pre ? "selected" : ""}>${s.name}</option>`).join("");
    return `<div class="sheet" data-act="close"><div class="panel" onclick="event.stopPropagation()">
      <h2>같이 살 종목 제안</h2>
      <p class="note">아직 안 산 종목을 그룹에 제안합니다. 참여 약속과 실제 등록은 다릅니다.</p>
      <label>종목</label>
      <select id="prop-ticker">${options}</select>
      <label>메시지</label>
      <input id="prop-msg" value="이번에 같이 들어갈 사람?" />
      ${btn("보내기", "primary full", "do-prop")}
      <div style="height:8px"></div>
      ${btn("닫기", "secondary full", "close")}
    </div></div>`;
  }
  return "";
}

function tabs() {
  if (state.onboarding) return "";
  const items = [["group", "그룹"], ["hold", "내 주식"], ["act", "활동"], ["me", "프로필"]];
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
  const btnEl = e.target.closest("[data-act]");
  if (!btnEl) return;
  handle(btnEl.getAttribute("data-act"));
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
    const parts = act.split(":");
    return recommend(parts[1], parts[2]);
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
