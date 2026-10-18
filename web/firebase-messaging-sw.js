importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyC9hjRrTZQaSWwfIH6te5N9FriSaXmmrzo",
  appId: "1:576803754283:web:fab1fbcd8a7f862e7a756e",
  messagingSenderId: "576803754283",
  projectId: "green-corridor-web",
  authDomain: "green-corridor-web.firebaseapp.com",
  storageBucket: "green-corridor-web.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message: ", payload);
  const notificationTitle = payload.notification
    ? payload.notification.title
    : (payload.data && payload.data.title ? payload.data.title : "🚨 Green Corridor Alert");
  const notificationOptions = {
    body: payload.notification
      ? payload.notification.body
      : (payload.data && payload.data.body ? payload.data.body : "Emergency medical transport incoming. Clear the active corridor!"),
    icon: "/favicon.png",
    badge: "/favicon.png",
    tag: "green-corridor-notification",
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
