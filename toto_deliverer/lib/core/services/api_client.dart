import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../adapters/base_adapter.dart';

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteur 1: Transformation automatique snake_case → camelCase
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          // Auto-transformer les réponses backend en camelCase
          if (response.data != null) {
            if (response.data is Map<String, dynamic>) {
              response.data = BaseAdapter.snakeToCamel(
                response.data as Map<String, dynamic>,
              );
            } else if (response.data is List) {
              response.data = (response.data as List).map((item) {
                if (item is Map<String, dynamic>) {
                  return BaseAdapter.snakeToCamel(item);
                }
                return item;
              }).toList();
            }
          }
          return handler.next(response);
        },
      ),
    );

    // Intercepteur 2: Token + Gestion erreurs
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Gestion du token expiré (401)
          if (error.response?.statusCode == 401) {
            // Tenter de rafraîchir le token
            if (_refreshToken != null) {
              final refreshed = await _refreshAccessToken();
              if (refreshed) {
                // Réessayer la requête avec le nouveau token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $_accessToken';
                try {
                  final response = await _dio.fetch(opts);
                  return handler.resolve(response);
                } catch (e) {
                  return handler.next(error);
                }
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Initialiser depuis le stockage sécurisé
  Future<void> init() async {
    _accessToken = await _storage.read(key: ApiConfig.accessTokenKey);
    _refreshToken = await _storage.read(key: ApiConfig.refreshTokenKey);
  }

  // Sauvegarder les tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: ApiConfig.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
  }

  // Supprimer les tokens (déconnexion)
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: ApiConfig.accessTokenKey);
    await _storage.delete(key: ApiConfig.refreshTokenKey);
    await _storage.delete(key: ApiConfig.userKey);
  }

  // Rafraîchir le token d'accès
  Future<bool> _refreshAccessToken() async {
    try {
      final response = await _dio.post(
        ApiConfig.authRefresh,
        data: {'refresh_token': _refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await saveTokens(data['access_token'], data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      await clearTokens();
      return false;
    }
  }

  // Vérifier si l'utilisateur est authentifié
  bool get isAuthenticated => _accessToken != null;

  // Récupérer le refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: ApiConfig.refreshTokenKey);
  }

  // Récupérer l'access token (pour WebSocket authentication)
  Future<String?> getAccessToken() async {
    // Retourner le token en mémoire ou le lire depuis le storage
    return _accessToken ?? await _storage.read(key: ApiConfig.accessTokenKey);
  }

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Gestion centralisée des erreurs
  String _handleError(DioException error) {
    String errorMessage = 'Une erreur est survenue';

    if (error.response != null) {
      final data = error.response!.data;

      // Vérifier les différents formats d'erreur backend
      if (data is Map<String, dynamic>) {
        // Format 1: Backend NestJS standard avec 'message'
        if (data.containsKey('message')) {
          final message = data['message'];
          if (message is String) {
            errorMessage = message;
          } else if (message is List) {
            // Messages de validation (array)
            errorMessage = message.join(', ');
          }
        }
        // Format 2: Champ 'error' pour erreurs de validation
        else if (data.containsKey('error')) {
          final errorField = data['error'];
          if (errorField is String) {
            errorMessage = errorField;
          } else if (errorField is Map && errorField.containsKey('message')) {
            errorMessage = errorField['message'];
          }
        }
        // Format 3: Array d'erreurs de validation
        else if (data.containsKey('errors')) {
          final errors = data['errors'] as List;
          if (errors.isNotEmpty) {
            errorMessage = errors
                .map((e) => e is Map ? e['message'] ?? e.toString() : e.toString())
                .join(', ');
          }
        }
        // Format 4: Erreur simple avec 'statusCode' et 'message'
        else if (data.containsKey('statusCode') && data.containsKey('error')) {
          errorMessage = '${data['error']}: ${data['message'] ?? ''}';
        }
        // Fallback sur status code
        else {
          errorMessage = _getDefaultErrorMessage(error.response!.statusCode);
        }
      } else {
        errorMessage = _getDefaultErrorMessage(error.response!.statusCode);
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Délai d\'attente dépassé. Vérifiez votre connexion';
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'Pas de connexion Internet';
    } else if (error.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Temps d\'envoi dépassé';
    } else if (error.type == DioExceptionType.cancel) {
      errorMessage = 'Requête annulée';
    }

    return errorMessage;
  }

  // Messages d'erreur par défaut selon le code HTTP
  String _getDefaultErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide. Vérifiez les données envoyées';
      case 401:
        return 'Non autorisé. Veuillez vous reconnecter';
      case 403:
        return 'Accès interdit. Vous n\'avez pas les permissions nécessaires';
      case 404:
        return 'Ressource non trouvée';
      case 409:
        return 'Conflit. Cette ressource existe déjà';
      case 422:
        return 'Données invalides. Vérifiez les informations saisies';
      case 429:
        return 'Trop de requêtes. Veuillez réessayer plus tard';
      case 500:
        return 'Erreur serveur. Réessayez plus tard';
      case 502:
        return 'Serveur indisponible. Réessayez plus tard';
      case 503:
        return 'Service temporairement indisponible';
      default:
        return 'Erreur ${statusCode ?? "inconnue"}';
    }
  }
}
