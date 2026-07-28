var CACHE_NAME = 'doukanban-v18';
var ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './logo.png',
  './favicon.png',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png'
];

self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(ASSETS);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(names) {
      return Promise.all(
        names.filter(function(n) { return n !== CACHE_NAME; })
             .map(function(n) { return caches.delete(n); })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', function(e) {
  if (e.request.method !== 'GET') return;
  var url = e.request.url;
  if (url.indexOf('http') !== 0) return;
  if (url.indexOf('/rest/v1/') !== -1 || url.indexOf('/auth/') !== -1 || url.indexOf('cdn.jsdelivr.net') !== -1) return;
  e.respondWith(
    fetch(e.request).then(function(resp) {
      var clone = resp.clone();
      caches.open(CACHE_NAME).then(function(cache) {
        cache.put(e.request, clone);
      });
      return resp;
    }).catch(function() {
      return caches.match(e.request);
    })
  );
});
