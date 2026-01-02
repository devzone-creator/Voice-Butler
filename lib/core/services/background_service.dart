// Conditional imports for web vs mobile

export 'background_service_stub.dart'
    if (dart.library.html) 'background_service_web_full.dart'
    if (dart.library.io) 'background_service_mobile.dart';
