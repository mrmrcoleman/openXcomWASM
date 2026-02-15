/*
 * Service Worker for OpenXcom Browser Edition.
 *
 * Caches all static assets on first visit so the game works fully offline.
 * Bump CACHE_VERSION when deploying a new build — this triggers a cache
 * refresh on the user's next visit.
 */

var CACHE_VERSION = 'v1';
var CACHE_NAME = 'openxcom-' + CACHE_VERSION;

var ASSETS_TO_CACHE = [
  './',
  './index.html',
  './play.html',
  './openxcom.js',
  './openxcom.wasm',
  './openxcom.data',
  './jszip.min.js',
];

/* Install: pre-cache all critical assets */
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      console.log('[SW] Caching assets for offline use');
      return cache.addAll(ASSETS_TO_CACHE);
    }).then(function() {
      /* Activate immediately without waiting for old SW to finish */
      return self.skipWaiting();
    })
  );
});

/* Activate: clean up old caches from previous versions */
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames
          .filter(function(name) { return name.startsWith('openxcom-') && name !== CACHE_NAME; })
          .map(function(name) {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(function() {
      return self.clients.claim();
    })
  );
});

/* Fetch: serve from cache first, fall back to network */
self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request).then(function(cachedResponse) {
      if (cachedResponse) {
        return cachedResponse;
      }
      return fetch(event.request).then(function(networkResponse) {
        /* Cache any new requests we haven't seen (e.g. fonts) */
        if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
          var responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then(function(cache) {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      });
    })
  );
});
