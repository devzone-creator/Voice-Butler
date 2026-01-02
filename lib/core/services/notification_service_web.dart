import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Web-compatible notification service using Web Notifications API
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  bool _permissionGranted = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permission
      _permissionGranted = await _requestPermission();
      _initialized = true;

      if (kDebugMode) {
        print('Notification service initialized. Permission granted: $_permissionGranted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize notification service: $e');
      }
    }
  }

  /// Requests notification permission from the user
  Future<bool> _requestPermission() async {
    try {
      // Use NotificationBridge from JavaScript
      final isSupported = js.context.callMethod('eval', [
        'window.NotificationBridge && window.NotificationBridge.isSupported()'
      ]) as bool?;
      
      if (isSupported != true) {
        return false;
      }
      
      final permission = js.context.callMethod('eval', [
        'window.NotificationBridge.getPermission()'
      ]) as String?;
      
      if (permission == 'granted') {
        return true;
      }

      if (permission == 'default' || permission == 'denied') {
        // Request permission via bridge
        final result = await js.context.callMethod('eval', [
          'window.NotificationBridge.requestPermission()'
        ]) as Future<String>;
        final permissionResult = await result;
        return permissionResult == 'granted';
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permission: $e');
      }
      return false;
    }
  }

  Future<void> showTaskReminder({
    required int id,
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) async {
    if (!_permissionGranted) {
      _permissionGranted = await _requestPermission();
      if (!_permissionGranted) {
        if (kDebugMode) {
          print('Cannot show notification: permission not granted');
        }
        return;
      }
    }

    try {
      // Use NotificationBridge from JavaScript
      final isSupported = js.context.callMethod('eval', [
        'window.NotificationBridge && window.NotificationBridge.isSupported()'
      ]) as bool?;
      
      if (isSupported != true) {
        if (kDebugMode) {
          print('Notifications not supported in this browser');
        }
        return;
      }

      final notificationBody = scheduledDate != null 
          ? '$body (Scheduled for: ${scheduledDate.toString()})' 
          : body;

      // Use NotificationBridge to show notification
      js.context.callMethod('eval', [
        '''
        if (window.NotificationBridge) {
          window.NotificationBridge.show("Voice Butler: $title", {
            body: ${_escapeJsString(notificationBody)},
            icon: "/icons/Icon-192.png",
            tag: "task-reminder-$id"
          });
        }
        '''
      ]);

      if (kDebugMode) {
        print('Notification shown: $title - $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to show notification: $e');
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    // Web Notifications API doesn't support canceling by ID directly
    // Notifications close automatically or can be closed by user
    if (kDebugMode) {
      print('Cancel notification requested for id: $id (web notifications close automatically)');
    }
  }

  Future<void> cancelAllNotifications() async {
    // Web Notifications API doesn't support canceling all notifications
    if (kDebugMode) {
      print('Cancel all notifications requested (web notifications close automatically)');
    }
  }

  Future<bool> requestPermissions() async {
    _permissionGranted = await _requestPermission();
    return _permissionGranted;
  }

  bool get isPermissionGranted => _permissionGranted;
  
  /// Escapes a string for use in JavaScript
  String _escapeJsString(String str) {
    return '"${str.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r')}"';
  }
}

