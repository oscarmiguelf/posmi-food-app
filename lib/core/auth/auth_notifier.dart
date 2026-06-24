import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'auth_state.dart';
import 'token_storage.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState.initial();
  }

  TokenStorage get _storage => ref.read(tokenStorageProvider);

  Future<void> _restoreSession() async {
    final token = await _storage.getAccessToken();
    state = AuthState(accessToken: token);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.current.cloudBaseUrl));
      final res = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = (res.data!['data'] as Map<String, dynamic>);
      final access = data['accessToken'] as String;
      final refresh = data['refreshToken'] as String;
      await _storage.save(access: access, refresh: refresh);
      state = AuthState(accessToken: access);
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg, clearToken: true);
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState();
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String) {
        if (msg.contains('Invalid credentials')) return 'Correo o contraseña incorrectos';
        return msg;
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Sin conexión. Verifica la red.';
    }
    return 'Error al iniciar sesión';
  }
}
