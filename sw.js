const CACHE="eksen-v3.0-github";
const ASSETS=["./","./index.html","./styles.css","./catalog-tyt.js","./catalog-ayt-1.js","./catalog-ayt-2.js","./catalog-ayt-3.js","./catalog-ayt-4.js","./catalog-ydt.js","./app-1.js","./app-2.js","./app-3.js","./app-4.js","./manifest.webmanifest"];
self.addEventListener("install",e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS))));
self.addEventListener("activate",e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k))))));
self.addEventListener("fetch",e=>e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request))));
