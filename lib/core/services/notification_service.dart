import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import 'storage_service.dart';

/// Service for managing notifications across platforms
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  final List<PendingNotification> _pendingNotifications = [];

  bool get isInitialized => _isInitialized;

  /// Initialize notification service
  Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        // Web notification initialization
        await _initializeWeb();
      } else {
        // Mobile notification initialization
        await _initializeMobile();
      }
      
      _isInitialized = true;
      await _logActivity('Notification service initialized');
      return true;
    } catch (e) {
      await _logError('Failed to initialize notification service: $e');
      return false;
    }
  }

  /// Initialize web notifications
  Future<void> _initializeWeb() async {
    // Web notifications using browser API
    if (kDebugMode) {
      print('Web notifications initialized');
    }
  }

  /// Initialize mobile notifications
  Future<void> _initializeMobile() async {
    // Mobile notifications would use flutter_local_notifications
    if (kDebugMode) {
      print('Mobile notifications initialized');
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required String title,
    required String message,
    String? taskId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (kIsWeb) {
        await _showWebNotification(title, message);
      } else {
        await _showMobileNotification(title, message, taskId);
      }

      await _logActivity('Notification sent: $title');
    } catch (e) {
      await _logError('Failed to show notification: $e');
    }
  }

  /// Schedule notification for later
  Future<void> scheduleNotification({
    required String title,
    required String message,
    required DateTime scheduledTime,
    String? taskId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final notification = PendingNotification(
        id: _generateNotificationId(),
        title: title,
        message: message,
        scheduledTime: scheduledTime,
        taskId: taskId,
        metadata: metadata ?? {},
      );

      _pendingNotifications.add(notification);
      
      // Schedule the notification
      if (kIsWeb) {
        _scheduleWebNotification(notification);
      } else {
        await _scheduleMobileNotification(notification);
      }

      await _logActivity('Notification scheduled: $title for ${scheduledTime.toIso8601String()}');
    } catch (e) {
      await _logError('Failed to schedule notification: $e');
    }
  }

  /// Show web notification
  Future<void> _showWebNotification(String title, String message) async {
    if (kIsWeb) {
      // In a real implementation, this would use the browser Notification API
      if (kDebugMode) {
        print('Web Notification: $title - $message');
      }
    }
  }

  /// Show mobile notification
  Future<void> _showMobileNotification(String title, String message, String? taskId) async {
    // In a real implementation, this would use flutter_local_notifications
    if (kDebugMode) {
      print('Mobile Notification: $title - $message');
    }
  }

  /// Schedule web notification
  void _scheduleWebNotification(PendingNotification notification) {
    final delay = notification.scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    Timer(delay, () async {
      await _showWebNotification(notification.title, notification.message);
      _pendingNotifications.removeWhere((n) => n.id == notification.id);
    });
  }

  /// Schedule mobile notification
  Future<void> _scheduleMobileNotification(PendingNotification notification) async {
    // In a real implementation, this would schedule with flutter_local_notifications
    if (kDebugMode) {
      print('Scheduled Mobile Notification: ${notification.title} for ${notification.scheduledTime}');
    }
  }

  /// Cancel scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    try {
      _pendingNotifications.removeWhere((n) => n.id == notificationId);
      await _logActivity('Notification cancelled: $notificationId');
    } catch (e) {
      await _logError('Failed to cancel notification: $e');
    }
  }

  /// Get pending notifications
  List<PendingNotification> getPendingNotifications() {
    return List.unmodifiable(_pendingNotifications);
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _pendingNotifications.clear();
      await _logActivity('All notifications cleared');
    } catch (e) {
      await _logError('Failed to clear notifications: $e');
    }
  }

  /// Generate unique notification ID
  String _generateNotificationId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }

  /// Log activity
  Future<void> _logActivity(String message) async {
    try {
      final log = ActivityLog.create(
        type: ActivityType.automationApplied,
        description: message,
        metadata: const {'service': 'notification'},
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log notification activity: $e');
      }
    }
  }

  /// Log error
  Future<void> _logError(String errorMessage) async {
    try {
      final log = ActivityLog.errorOccurred(
        errorMessage: errorMessage,
        additionalMetadata: const {'service': 'notification'},
      );
      await StorageService.instance.storeActivityLog(log);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log notification error: $e');
      }
    }
  }
}

/// Represents a pending notification
class PendingNotification {
  final String id;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final String? taskId;
  final Map<String, dynamic> metadata;

  PendingNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.scheduledTime,
    this.taskId,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'scheduledTime': scheduledTime.toIso8601String(),
      'taskId': taskId,
      'metadata': metadata,
    };
  }

  factory PendingNotification.fromJson(Map<String, dynamic> json) {
    return PendingNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      taskId: json['taskId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }
}