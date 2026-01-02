// Conditional imports for web vs mobile
// Export the appropriate implementation based on platform

export 'voice_service_stub.dart'
    if (dart.library.html) 'voice_service_web.dart'
    if (dart.library.io) 'voice_service_mobile.dart';
