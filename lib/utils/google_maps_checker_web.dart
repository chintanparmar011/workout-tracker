import 'dart:js_interop';

@JS('isGoogleMapsLoaded')
external JSBoolean? _isGoogleMapsLoadedJs();

bool isGoogleMapsAvailableOnWeb() {
  try {
    return _isGoogleMapsLoadedJs()?.toDart ?? false;
  } catch (_) {
    return false;
  }
}
