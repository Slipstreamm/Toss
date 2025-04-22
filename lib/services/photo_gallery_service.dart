// Conditionally export the appropriate implementation based on platform
export 'photo_gallery_service_stub.dart' if (dart.library.io) 'photo_gallery_service_mobile.dart';
