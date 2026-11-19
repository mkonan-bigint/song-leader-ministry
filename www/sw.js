// Service worker : application disponible hors connexion.
// Le recueil (cantiques.json) est servi « réseau d'abord » pour recevoir les nouveaux cantiques.
const CACHE = "slm-v3";
const SHELL = ["./", "index.html", "config.js", "manifest.webmanifest", "cantiques.json",
  "icons/icon-192.png", "icons/icon-512.png", "icons/apple-touch-icon.png",
  "fonts/inter-latin-400-normal.woff2", "fonts/inter-latin-500-normal.woff2", "fonts/inter-latin-600-normal.woff2",
  "fonts/cinzel-latin-700-normal.woff2",
  "fonts/source-serif-4-latin-400-normal.woff2", "fonts/source-serif-4-latin-600-normal.woff2", "fonts/source-serif-4-latin-400-italic.woff2"];

self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL))); self.skipWaiting() });
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE && k !== "slm-data").map(k => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener("fetch", e => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET" || url.origin !== location.origin) return;
  const networkFirst = url.pathname.endsWith("cantiques.json") || url.pathname.endsWith("index.html") || url.pathname.endsWith("/") || url.pathname.endsWith("config.js");
  if (networkFirst){
    e.respondWith(fetch(e.request).then(r => { const copy = r.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); return r })
      .catch(() => caches.match(e.request, {ignoreSearch: true})));
  } else {
    e.respondWith(caches.match(e.request).then(m => m || fetch(e.request)));
  }
});
