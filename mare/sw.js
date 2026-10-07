// Service worker: mantém o app abrindo mesmo sem internet e busca a versão nova sempre que houver rede.
const CACHE = "mare-shell-v2";
const SHELL = ["./", "./index.html", "./manifest.json"];
const MARK = 'id="srcinfo"';             // só guarda HTML que seja mesmo o app (não páginas de aviso / Wi-Fi de marina)
self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(async c => {
    for (const u of SHELL) { try { const r = await fetch(u, {cache:"no-store"}); if (await ok(r)) await c.put(u, r); } catch (_) {} }
  }).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
async function ok(r){
  if (!r || !r.ok) return false;
  if ((r.headers.get("content-type") || "").includes("text/html")) return (await r.clone().text()).includes(MARK);
  return true;
}
self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET" || new URL(req.url).origin !== location.origin) return; // APIs: a página trata
  e.respondWith((async () => {
    const c = await caches.open(CACHE);
    try {
      const r = await fetch(req);
      if (await ok(r)) { c.put(req, r.clone()); return r; }
      const hit = await c.match(req) || (req.mode === "navigate" && await c.match("./index.html"));
      return hit || r;
    } catch (_) {
      return (await c.match(req)) || (await c.match("./index.html")) || Response.error();
    }
  })());
});
