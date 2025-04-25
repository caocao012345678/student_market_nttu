// This is a stub implementation of js_util for non-web platforms
// It provides empty implementations of js_util functions to avoid runtime errors

// Add any js_util functions that are used in the app
// For example:
dynamic callMethod(dynamic o, String method, List<dynamic> args) {
  throw UnsupportedError('js_util is only supported on web platforms');
}

dynamic getProperty(dynamic o, String name) {
  throw UnsupportedError('js_util is only supported on web platforms');
}

void setProperty(dynamic o, String name, dynamic value) {
  throw UnsupportedError('js_util is only supported on web platforms');
}

dynamic callConstructor(dynamic constructor, List<dynamic> arguments) {
  throw UnsupportedError('js_util is only supported on web platforms');
}

bool hasProperty(dynamic o, String name) {
  throw UnsupportedError('js_util is only supported on web platforms');
}

dynamic newObject() {
  throw UnsupportedError('js_util is only supported on web platforms');
}
