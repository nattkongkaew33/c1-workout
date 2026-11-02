const CACHE="c1-workout-v29";
const CORE=["./","index.html","manifest.json","icon-180.png","icon-192.png","icon-512.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE)));self.skipWaiting()});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))));self.clients.claim()});
self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET")return;
  const url=new URL(e.request.url);
  // fonts: cache-first
  if(url.hostname.includes("fonts.g")){
    e.respondWith(caches.open(CACHE).then(c=>c.match(e.request).then(r=>r||fetch(e.request).then(res=>{c.put(e.request,res.clone());return res}))));return;
  }
  if(url.origin!==location.origin)return;
  // app files: network first, fall back to cache when offline
  e.respondWith(fetch(e.request).then(res=>{const cp=res.clone();caches.open(CACHE).then(c=>c.put(e.request,cp));return res}).catch(()=>caches.match(e.request).then(r=>r||caches.match("index.html"))));
});
