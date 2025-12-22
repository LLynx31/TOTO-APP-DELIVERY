import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';
import '../websocket/socket_client.dart';

// Data sources
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/remote/delivery_remote_datasource.dart';
import '../../data/datasources/remote/rating_remote_datasource.dart';

// Repositories
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../domain/repositories/rating_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/delivery_repository_impl.dart';
import '../../data/repositories/rating_repository_impl.dart';

// Use cases - Auth
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/check_auth_usecase.dart';
import '../../domain/usecases/auth/update_profile_usecase.dart';
import '../../domain/usecases/auth/change_password_usecase.dart';

// Use cases - Delivery
import '../../domain/usecases/delivery/create_delivery_usecase.dart';
import '../../domain/usecases/delivery/get_deliveries_usecase.dart';
import '../../domain/usecases/delivery/get_delivery_usecase.dart';
import '../../domain/usecases/delivery/cancel_delivery_usecase.dart';

// Use cases - Rating
import '../../domain/usecases/rating/create_rating_usecase.dart';
import '../../domain/usecases/rating/get_rating_usecase.dart';
import '../../domain/usecases/rating/check_has_rated_usecase.dart';

// ==========================================
// Core Providers
// ==========================================

/// Provider pour le secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider pour le client HTTP Dio
final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage: secureStorage);
});

/// Provider pour le client WebSocket
final socketClientProvider = Provider<SocketClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SocketClient(secureStorage: secureStorage);
});

// ==========================================
// Data Source Providers
// ==========================================

/// Auth Remote Datasource
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDatasourceImpl(dioClient);
});

/// Auth Local Datasource
final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthLocalDatasourceImpl(secureStorage);
});

/// Delivery Remote Datasource
final deliveryRemoteDatasourceProvider = Provider<DeliveryRemoteDatasource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DeliveryRemoteDatasourceImpl(dioClient);
});

/// Rating Remote Datasource
final ratingRemoteDatasourceProvider = Provider<RatingRemoteDatasource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RatingRemoteDatasourceImpl(dioClient);
});

// ==========================================
// Repository Providers
// ==========================================

/// Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDatasource = ref.watch(authRemoteDatasourceProvider);
  final localDatasource = ref.watch(authLocalDatasourceProvider);
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepositoryImpl(
    remoteDatasource: remoteDatasource,
    localDatasource: localDatasource,
    dioClient: dioClient,
  );
});

/// Delivery Repository
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  final remoteDatasource = ref.watch(deliveryRemoteDatasourceProvider);
  return DeliveryRepositoryImpl(remoteDatasource: remoteDatasource);
});

/// Rating Repository
final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  final remoteDatasource = ref.watch(ratingRemoteDatasourceProvider);
  return RatingRepositoryImpl(remoteDatasource);
});

// ==========================================
// Use Case Providers - Auth
// ==========================================

/// Login Use Case
final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUsecase(repository);
});

/// Register Use Case
final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUsecase(repository);
});

/// Logout Use Case
final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUsecase(repository);
});

/// Get Current User Use Case
final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUsecase(repository);
});

/// Check Auth Use Case
final checkAuthUsecaseProvider = Provider<CheckAuthUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CheckAuthUsecase(repository);
});

/// Update Profile Use Case
final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateProfileUsecase(repository);
});

/// Change Password Use Case
final changePasswordUsecaseProvider = Provider<ChangePasswordUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ChangePasswordUsecase(repository);
});

// ==========================================
// Use Case Providers - Delivery
// ==========================================

/// Create Delivery Use Case
final createDeliveryUsecaseProvider = Provider<CreateDeliveryUsecase>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return CreateDeliveryUsecase(repository);
});

/// Get Deliveries Use Case
final getDeliveriesUsecaseProvider = Provider<GetDeliveriesUsecase>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return GetDeliveriesUsecase(repository);
});

/// Get Delivery Use Case
final getDeliveryUsecaseProvider = Provider<GetDeliveryUsecase>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return GetDeliveryUsecase(repository);
});

/// Cancel Delivery Use Case
final cancelDeliveryUsecaseProvider = Provider<CancelDeliveryUsecase>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return CancelDeliveryUsecase(repository);
});

// ==========================================
// Use Case Providers - Rating
// ==========================================

/// Create Rating Use Case
final createRatingUsecaseProvider = Provider<CreateRatingUsecase>((ref) {
  final repository = ref.watch(ratingRepositoryProvider);
  return CreateRatingUsecase(repository);
});

/// Get Rating Use Case
final getRatingUsecaseProvider = Provider<GetRatingUsecase>((ref) {
  final repository = ref.watch(ratingRepositoryProvider);
  return GetRatingUsecase(repository);
});

/// Check Has Rated Use Case
final checkHasRatedUsecaseProvider = Provider<CheckHasRatedUsecase>((ref) {
  final repository = ref.watch(ratingRepositoryProvider);
  return CheckHasRatedUsecase(repository);
});
