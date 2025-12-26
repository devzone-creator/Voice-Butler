// Stub implementation for web platforms
class Workmanager {
  void executeTask(Function callback) {
    // No-op for web
  }
  
  Future<void> initialize(Function callback, {bool? isInDebugMode}) async {
    // No-op for web
  }
  
  Future<void> registerPeriodicTask(String uniqueName, String taskName, {Duration? frequency, dynamic constraints}) async {
    // No-op for web
  }
  
  Future<void> registerOneOffTask(String uniqueName, String taskName, {Duration? initialDelay, Map<String, dynamic>? inputData}) async {
    // No-op for web
  }
  
  Future<void> cancelByUniqueName(String uniqueName) async {
    // No-op for web
  }
  
  Future<void> cancelAll() async {
    // No-op for web
  }
}

class Constraints {
  Constraints({
    dynamic networkType,
    bool? requiresBatteryNotLow,
    bool? requiresCharging,
    bool? requiresDeviceIdle,
    bool? requiresStorageNotLow,
  });
}

class NetworkType {
  static const not_required = 'not_required';
}