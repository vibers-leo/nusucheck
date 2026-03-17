// 누수체크 Service Worker - 오프라인 지원 & 캐싱
const CACHE_NAME = "nusucheck-v2"
const OFFLINE_URL = "/offline.html"

// 정적 자산 프리캐시
const PRECACHE_URLS = [
  "/offline.html"
]

// 설치 시 오프라인 페이지 캐싱
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
  )
  self.skipWaiting()
})

// 활성화 시 이전 캐시 정리
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  )
  self.clients.claim()
})

// 네트워크 우선, 오프라인 시 캐시 폴백
self.addEventListener("fetch", (event) => {
  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(OFFLINE_URL))
    )
  }
})
