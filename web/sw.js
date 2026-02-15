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

/* Fetch: network-first for HTML pages, cache-first for heavy assets */
self.addEventListener('fetch', function(event) {
  var url = new URL(event.request.url);
  var isNavigation = event.request.mode === 'navigate';
  var isHTML = url.pathname.endsWith('.html') || url.pathname.endsWith('/');

  if (isNavigation || isHTML) {
    /* Network-first for pages — always get the latest HTML */
    event.respondWith(
      fetch(event.request).then(function(networkResponse) {
        if (networkResponse && networkResponse.status === 200) {
          var responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then(function(cache) {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      }).catch(function() {
        return caches.match(event.request);
      })
    );
  } else {
    /* Cache-first for assets (wasm, js, data) — fast and offline-friendly */
    event.respondWith(
      caches.match(event.request).then(function(cachedResponse) {
        if (cachedResponse) {
          return cachedResponse;
        }
        return fetch(event.request).then(function(networkResponse) {
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
  }
});
