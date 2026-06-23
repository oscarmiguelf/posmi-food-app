import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_storage.dart';
import '../config/app_config.dart';
import '../../core/network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: AppConfig.current.cloudBaseUrl);
});

/// Raw Dio instance with auth headers + 401 handling.
/// Use apiClientProvider for most cases; use this for custom requests.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.current.cloudBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (err, handler) async {
      if (err.response?.statusCode == 401) {
        // Token expired — try refresh once
        final refresh = await storage.getRefreshToken();
        if (refresh != null) {
          try {
            final refreshDio = Dio(BaseOptions(
              baseUrl: AppConfig.current.cloudBaseUrl,
            ));
            final res = await refreshDio.post<Map<String, dynamic>>(
              '/auth/refresh',
              data: {'refreshToken': refresh},
            );
            final data = res.data!['data'] as Map<String, dynamic>;
            await storage.save(
              access: data['accessToken'] as String,
              refresh: data['refreshToken'] as String,
            );
            final opts = err.requestOptions;
            opts.headers['Authorization'] =
                'Bearer ${data['accessToken']}';
            final retry = await dio.fetch<dynamic>(opts);
            return handler.resolve(retry);
          } catch (_) {
            await storage.clear();
          }
        }
      }
      handler.next(err);
    },
  ));

  return dio;
});
