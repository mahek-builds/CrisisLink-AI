import 'dart:io';

Future<bool> getConnectivityStatus() async {
  try {
    final result = await InternetAddress.lookup(
      'example.com',
    ).timeout(const Duration(seconds: 2));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
