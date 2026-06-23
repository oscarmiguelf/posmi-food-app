import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../auth/auth_notifier.dart';
import '../config/app_config.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final token = ref.read(authProvider).accessToken;
  final service = SocketService(
    baseUrl: AppConfig.current.cloudBaseUrl
        .replaceAll('/api/v1', ''), // socket.io root
    token: token,
  );
  ref.onDispose(service.dispose);
  return service;
});

class SocketService {
  SocketService({required String baseUrl, String? token}) {
    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .build(),
    );
    _socket.connect();
  }

  late final io.Socket _socket;

  void on(String event, void Function(dynamic data) handler) {
    _socket.on(event, handler);
  }

  void off(String event) {
    _socket.off(event);
  }

  void dispose() {
    _socket.disconnect();
    _socket.dispose();
  }
}
