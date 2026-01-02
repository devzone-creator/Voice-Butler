// JavaScript bridge for Web Speech API and Notifications
// This provides a simple interface for Dart to access Chrome's APIs

window.SpeechRecognitionBridge = {
  create: function() {
    return new (window.SpeechRecognition || window.webkitSpeechRecognition)();
  },
  
  isAvailable: function() {
    return !!(window.SpeechRecognition || window.webkitSpeechRecognition);
  }
};

// Notification API bridge
window.NotificationBridge = {
  isSupported: function() {
    return 'Notification' in window;
  },
  
  getPermission: function() {
    if (!('Notification' in window)) return 'denied';
    return Notification.permission;
  },
  
  requestPermission: function() {
    if (!('Notification' in window)) {
      return Promise.resolve('denied');
    }
    return Notification.requestPermission();
  },
  
  show: function(title, options) {
    if (!('Notification' in window)) return;
    return new Notification(title, options);
  }
};

