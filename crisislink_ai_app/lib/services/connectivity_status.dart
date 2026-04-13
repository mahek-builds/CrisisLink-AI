import 'connectivity_status_io.dart'
    if (dart.library.html) 'connectivity_status_web.dart' as platform;

Future<bool> getConnectivityStatus() => platform.getConnectivityStatus();
