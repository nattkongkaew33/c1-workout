const CACHE="c1-workout-v41";
const CORE=["./","index.html","manifest.json","icon-180.png","icon-192.png","icon-512.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE)));self.skipWaiting()});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))));self.clients.claim()});
// Cache key without the query string, so "?r=<time>" from ↻ Refresh doesn't pile up copies of the page.
const key=req=>{const u=new URL(req.url);u.search="";return u.toString()};
// Network first, but give up after a few seconds on a weak signal (e.g. in the gym) and use the saved copy.
function netFirst(req,ms){
  return new Promise(resolve=>{
    let done=false;
    const fallback=()=>caches.open(CACHE).then(c=>c.match(key(req))).then(r=>r||(req.mode==="navigate"?caches.match("index.html"):undefined)).then(r=>{if(r&&!done){done=true;resolve(r)}return r});
    const t=setTimeout(()=>fallback(),ms);
    fetch(req).then(res=>{clearTimeout(t);if(res&&res.ok){const cp=res.clone();caches.open(CACHE).then(c=>c.put(key(req),cp))}if(!done){done=true;resolve(res)}})
      .catch(()=>{clearTimeout(t);fallback().then(r=>{if(!done){done=true;resolve(r||Response.error())}})});
  });
}
self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET")return;
  const url=new URL(e.request.url);
  // fonts: cache-first
  if(url.hostname.includes("fonts.g")){
    e.respondWith(caches.open(CACHE).then(c=>c.match(e.request).then(r=>r||fetch(e.request).then(res=>{c.put(e.request,res.clone());return res}))));return;
  }
  if(url.origin!==location.origin)return;
  e.respondWith(netFirst(e.request,e.request.mode==="navigate"?3500:5000));
});
