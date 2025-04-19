importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyAeBvXjTdJGACPYEGfXBThsOiFOO-Dlj40",
  authDomain: "carrot-foodelivery.firebaseapp.com",
  projectId: "carrot-foodelivery",
  storageBucket: "carrot-foodelivery.appspot.com",
  messagingSenderId: "629553534814",
  appId: "1:629553534814:android:c05fa4f5a6e40735a9a1cf",
  databaseURL: "...",
});

const messaging = firebase.messaging();

// Receive background messages
messaging.setBackgroundMessageHandler(function (payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            // Extract notification data or use defaults
            const notificationTitle = payload.notification?.title || payload.data?.title || 'New Notification';
            const notificationOptions = {
                body: payload.notification?.body || payload.data?.body || 'You have a new notification',
                icon: '/icons/Icon-192.png',
                badge: '/icons/Icon-512.png',
                data: payload.data,
                requireInteraction: true,
                tag: payload.data?.order_id || 'general-notification'  // Use tag to group similar notifications
            };
            return self.registration.showNotification(notificationTitle, notificationOptions);
        });
    return promiseChain;
});

// Handle notification click events
self.addEventListener('notificationclick', function (event) {
    console.log('Notification clicked: ', event);
    
    // Close the notification
    event.notification.close();
    
    // Get notification data
    const notificationData = event.notification.data;
    
    // Determine URL to open based on notification type
    let url = '/';
    if (notificationData) {
        if (notificationData.type === 'order' || notificationData.order_id) {
            url = '/order-details/' + notificationData.order_id;
        } else if (notificationData.type === 'message') {
            url = '/chat';
        } else if (notificationData.type === 'wallet') {
            url = '/wallet';
        }
    }
    
    // Open or focus window with the appropriate URL
    const urlToOpen = new URL(url, self.location.origin).href;
    
    const promiseChain = clients.matchAll({
        type: 'window',
        includeUncontrolled: true
    })
    .then((windowClients) => {
        // Check if there is already a window/tab open with the target URL
        for (let i = 0; i < windowClients.length; i++) {
            const client = windowClients[i];
            // If so, focus it
            if (client.url === urlToOpen && 'focus' in client) {
                return client.focus();
            }
        }
        // If not, open a new window/tab
        if (clients.openWindow) {
            return clients.openWindow(urlToOpen);
        }
    });
    
    event.waitUntil(promiseChain);
});