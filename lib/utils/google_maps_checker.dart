import 'package:flutter/foundation.dart';
import 'google_maps_checker_stub.dart'
    if (dart.library.js_interop) 'google_maps_checker_web.dart';

bool isGoogleMapsReady() {
  if (kIsWeb) {
    return isGoogleMapsAvailableOnWeb();
  }
  return true;
}
