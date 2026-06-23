import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient({required String baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _attachAuth,
      onError: _handleError,
    ));
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Future<void> _attachAuth(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _handleError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, String>? headers}) =>
      _dio.post(path, data: data, options: Options(headers: headers));

  Future<Response<T>> patch<T>(String path, {dynamic data}) => _dio.patch(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete(path);

  /// POST with idempotency key for critical operations
  Future<Response<T>> postIdempotent<T>(
    String path, {
    required String idempotencyKey,
    dynamic data,
  }) =>
      post(path, data: data, headers: {'Idempotency-Key': idempotencyKey});
}
