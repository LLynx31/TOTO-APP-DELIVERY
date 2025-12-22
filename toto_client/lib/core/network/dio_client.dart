import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../config/env_config.dart';
import 'api_exception.dart';

/// Client HTTP Dio avec gestion automatique des tokens
class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  Dio get dio => _dio;

  BaseOptions get _baseOptions => BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConfig.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

  void _setupInterceptors() {
    // Auth Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to request
          final token = await _secureStorage.read(key: ApiConfig.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Handle 401 - Token expired
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with new token
              try {
                final response = await _retryRequest(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.reject(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Logging Interceptor (only in development)
    if (EnvConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (log) => debugPrint('[DIO] $log'),
        ),
      );
    }
  }

  /// Refresh the access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: ApiConfig.refreshTokenKey);
      if (refreshToken == null) return false;

      // Create a new Dio instance to avoid interceptor loops
      final refreshDio = Dio(_baseOptions);

      final response = await refreshDio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        await _secureStorage.write(
          key: ApiConfig.accessTokenKey,
          value: newAccessToken,
        );
        await _secureStorage.write(
          key: ApiConfig.refreshTokenKey,
          value: newRefreshToken,
        );

        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  /// Retry the failed request with new token
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final token = await _secureStorage.read(key: ApiConfig.accessTokenKey);

    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Store tokens after login/register
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(
      key: ApiConfig.accessTokenKey,
      value: accessToken,
    );
    await _secureStorage.write(
      key: ApiConfig.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Clear tokens on logout
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: ApiConfig.accessTokenKey);
    await _secureStorage.delete(key: ApiConfig.refreshTokenKey);
    await _secureStorage.delete(key: ApiConfig.userKey);
  }

  /// Check if user has valid tokens
  Future<bool> hasValidTokens() async {
    final token = await _secureStorage.read(key: ApiConfig.accessTokenKey);
    return token != null;
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connexion timeout. Vérifiez votre connexion internet.',
          statusCode: null,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Erreur de connexion. Vérifiez votre connexion internet.',
          statusCode: null,
        );
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Requête annulée.',
          statusCode: null,
        );
      default:
        return ApiException(
          message: error.message ?? 'Une erreur est survenue.',
          statusCode: null,
        );
    }
  }

  /// Handle HTTP response errors
  ApiException _handleResponseError(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'Une erreur est survenue.';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? message;
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          message: message,
          statusCode: statusCode,
          errors: data is Map ? data['errors'] : null,
        );
      case 401:
        return ApiException(
          message: 'Session expirée. Veuillez vous reconnecter.',
          statusCode: statusCode,
        );
      case 403:
        return ApiException(
          message: 'Accès refusé.',
          statusCode: statusCode,
        );
      case 404:
        return ApiException(
          message: 'Ressource non trouvée.',
          statusCode: statusCode,
        );
      case 409:
        return ApiException(
          message: message,
          statusCode: statusCode,
        );
      case 422:
        return ApiException(
          message: 'Données invalides.',
          statusCode: statusCode,
          errors: data is Map ? data['errors'] : null,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message: 'Erreur serveur. Veuillez réessayer plus tard.',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          message: message,
          statusCode: statusCode,
        );
    }
  }
}
