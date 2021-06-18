import { registerRoute } from "workbox-routing";
import {
  NetworkFirst,
  StaleWhileRevalidate,
  CacheFirst,
} from "workbox-strategies";

// Used for filtering matches based on status code, header, or both
import { CacheableResponsePlugin } from "workbox-cacheable-response";
// Used to limit entries in cache, remove entries after a certain period of time
import { ExpirationPlugin } from "workbox-expiration";

import { precacheAndRoute } from "workbox-precaching";

/// <reference lib="WebWorker" />

// export empty type because of tsc --isolatedModules flag
export type {};
declare const self: ServiceWorkerGlobalScope;

// Use with precache injection
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
// eslint-disable-next-line no-underscore-dangle
precacheAndRoute(self.__WB_MANIFEST);

registerRoute(
  // Check to see if the request is a navigation to a new page
  ({ request }) => request.mode === "navigate",
  // Use a Network First caching strategy
  new NetworkFirst({
    // Put all cached files in a cache named 'pages'
    cacheName: "pages",
    plugins: [
      // Ensure that only requests that result in a 200 status are cached
      new CacheableResponsePlugin({
        statuses: [200],
      }),
    ],
  })
);

// Cache CSS, JS, and Web Worker requests with a Stale While Revalidate strategy
registerRoute(
  // Check to see if the request's destination is style for stylesheets, script for JavaScript, font, or worker for web worker
  ({ request }) =>
    request.destination === "style" ||
    request.destination === "script" ||
    request.destination === "font" ||
    request.destination === "worker",
  // Use a Stale While Revalidate caching strategy
  new StaleWhileRevalidate({
    // Put all cached files in a cache named 'assets'
    cacheName: "assets",
    plugins: [
      // Ensure that only requests that result in a 200 status are cached
      new CacheableResponsePlugin({
        statuses: [200],
      }),
    ],
  })
);

// Cache images with a Cache First strategy
registerRoute(
  // Check to see if the request's destination is style for an image
  ({ request }) => request.destination === "image",
  // Use a Cache First caching strategy
  new CacheFirst({
    // Put all cached files in a cache named 'images'
    cacheName: "images",
    plugins: [
      // Ensure that only requests that result in a 200 status are cached
      new CacheableResponsePlugin({
        statuses: [200],
      }),
      // Don't cache more than 50 items, and expire them after 30 days
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 60 * 60 * 24 * 30, // 30 Days
      }),
    ],
  })
);

self.addEventListener("push", async (event: PushEvent) => {
  if (!event.data) return;
  const payload = event.data.json();
  console.log("received push", payload);
  const options = {
    body: payload.body,
    icon: "/img/icons/android-chrome-512x512.png",
    badge: "/img/icons/badge-128x128.png",
    timestamp: new Date(payload.timestamp).getTime(),
    lang: payload.locale,
    data: {
      dateOfArrival: Date.now(),
      url: payload.url,
    },
  };

  event.waitUntil(self.registration.showNotification(payload.title, options));
});

self.addEventListener("notificationclick", function (event: NotificationEvent) {
  const url = event.notification.data.url;
  event.notification.close();

  // This looks to see if the current is already open and
  // focuses if it is
  event.waitUntil(
    (async () => {
      const clientList = await self.clients.matchAll({
        type: "window",
      });
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i] as WindowClient;
        if (client.url == url && "focus" in client) {
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(url);
      }
    })()
  );
});

self.addEventListener("message", (event: ExtendableMessageEvent) => {
  const replyPort = event.ports[0];
  const message = event.data;
  if (replyPort && message && message.type === "skip-waiting") {
    console.log("doing skip waiting");
    event.waitUntil(
      self.skipWaiting().then(
        () => replyPort.postMessage({ error: null }),
        (error) => replyPort.postMessage({ error })
      )
    );
  }
});
