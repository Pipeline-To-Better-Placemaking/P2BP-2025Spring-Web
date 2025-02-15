'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "9d000d752c5f799b61e444f3bed3f956",
"version.json": "eb882bd0b495c65f241f4fe3c4d7887c",
"favicon.ico": "5214451d2ef63b537b668103ae919e13",
"index.html": "39256a7d36cb98dfbaa437b299595827",
"/": "39256a7d36cb98dfbaa437b299595827",
"main.dart.js": "630026575df0c1ff52507a61e0c9ade3",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"icons/P2BP-192.png": "6f79499097eeda67aab11122e234c9a7",
"icons/P2BP-512-maskable.png": "67bd7b320ad7c39f239a73d28fd4f62d",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/P2BP-512.png": "67bd7b320ad7c39f239a73d28fd4f62d",
"icons/P2BP-192-maskable.png": "6f79499097eeda67aab11122e234c9a7",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "cc81df33b2a5675dd1b378411ef849ed",
"assets/AssetManifest.json": "efd37781eb436f16d198e283c04ade9a",
"assets/NOTICES": "8aeafc49ef7b81c450deb3f245a97d58",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "c84c1babd522e0ec4602d579aa048f5c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "f16ab3856d74049556ef83f291df356b",
"assets/fonts/MaterialIcons-Regular.otf": "2057fe2932aeb798557889c9f290c52b",
"assets/assets/RedHouse.png": "f5d2f614be71e821b6f597de86faaf1f",
"assets/assets/email.png": "a62104daf5eabba4f61e754adfcf8cea",
"assets/assets/google_icon.png": "54d92439140ad747288601dac21b3c88",
"assets/assets/Profile_Icon.png": "3dd5223a78b6becd383c99190c6816cb",
"assets/assets/bell-03.png": "21f31a4e1f915d2317ba89431ce39873",
"assets/assets/Lock.png": "718bc6c672ed998be0b7e94ec11b32a5",
"assets/assets/Home_Icon.png": "8c8e338b564cf7c27d522fb8bc918e23",
"assets/assets/Add_Icon.png": "3fd9b039d5fc9295f9f2dd0a293ca571",
"assets/assets/hidden.png": "39738cc3f3c6d5da18d4f9f1bec27ed5",
"assets/assets/logo_coin.png": "f9636680af9a0a3533dc05e2eeddc719",
"assets/assets/P2BP_Logo.png": "6f79499097eeda67aab11122e234c9a7",
"assets/assets/user.png": "b8982e196d7c86f12143ffa41d2b33a8",
"assets/assets/PinkHouse.png": "85f740f9171403b1dc8fff02da6e8d8d",
"assets/assets/ResetPasswordBanner.png": "f9a809d88289e6d978b2d2e33959e37f",
"assets/assets/mail_icon.png": "465390205af2cbad9fccb2ae339ed701",
"assets/assets/User_box.png": "1a217ec3a229c92f539503ad3184020c",
"assets/assets/PTBP.png": "d24fa5cb2cf0f10969df95ebbbec468c",
"assets/assets/Compare_Icon.png": "d68a3bd6fc49de25ccc56b13939f2a79",
"assets/assets/ForgotPasswordBanner.png": "7b6cf392e8048c1089fa7ac70311f296",
"assets/assets/Filter_Icon.png": "a9b1b3897505e66f3e942e4fffb09b13",
"assets/assets/eye.png": "bb8e6498d17a21face18972834122eed",
"assets/assets/Unlock.png": "866df242289bf13bfd8c09aa5c4b2778",
"assets/assets/landscape_weather.png": "ec058fe2cfac2584976f53a3e857fbe6",
"assets/assets/custom_bell.png": "baab03ec96b1db7b6075b406e658d817",
"assets/assets/padlock.png": "5cfff37cc6859fbf132341d5956ebeda",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
