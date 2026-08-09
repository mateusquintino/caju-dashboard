/* Caju · service worker mínimo.
   Cacheia só o shell (HTML/CSS/JS/fontes). Dados do Supabase NUNCA são
   cacheados — saldo velho em cache seria pior que ficar offline. */
var CACHE = 'caju-shell-v2';
var SHELL = ['./', './index.html', './mobile-caju.css', './mobile-caju.js'];

self.addEventListener('install', function(e){
  e.waitUntil(caches.open(CACHE).then(function(c){ return c.addAll(SHELL).catch(function(){}); }));
  self.skipWaiting();
});

self.addEventListener('activate', function(e){
  e.waitUntil(caches.keys().then(function(ks){
    return Promise.all(ks.filter(function(k){ return k!==CACHE; }).map(function(k){ return caches.delete(k); }));
  }));
  self.clients.claim();
});

self.addEventListener('fetch', function(e){
  var url = new URL(e.request.url);
  if(e.request.method!=='GET') return;
  /* API / dados: sempre rede */
  if(/supabase|\/rest\/|\/auth\//.test(url.href)) return;
  /* shell: cache primeiro, rede atualiza */
  e.respondWith(
    caches.match(e.request).then(function(hit){
      var net = fetch(e.request).then(function(res){
        if(res && res.status===200 && res.type==='basic'){
          var copy = res.clone();
          caches.open(CACHE).then(function(c){ c.put(e.request, copy); });
        }
        return res;
      }).catch(function(){ return hit; });
      return hit || net;
    })
  );
});
