import 'connectivity_status.dart';

abstract class ConnectivityService {
  const ConnectivityService();

  Future<bool> isOnline();
}

class DefaultConnectivityService implements ConnectivityService {
  const DefaultConnectivityService();

  @override
  Future<bool> isOnline() => getConnectivityStatus();
}
