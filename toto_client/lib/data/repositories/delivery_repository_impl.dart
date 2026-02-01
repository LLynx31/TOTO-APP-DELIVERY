import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../datasources/remote/delivery_remote_datasource.dart';
import '../models/delivery/create_delivery_dto.dart';
import 'auth_repository_impl.dart';

/// Implémentation du repository de livraison
class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDatasource remoteDatasource;

  DeliveryRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Result<Delivery>> createDelivery(CreateDeliveryParams params) async {
    try {
      final dto = CreateDeliveryDto(
        pickupAddress: params.pickupAddress,
        pickupLatitude: params.pickupLatitude,
        pickupLongitude: params.pickupLongitude,
        pickupPhone: params.pickupPhone,
        deliveryAddress: params.deliveryAddress,
        deliveryLatitude: params.deliveryLatitude,
        deliveryLongitude: params.deliveryLongitude,
        deliveryPhone: params.deliveryPhone,
        receiverName: params.receiverName,
        packageDescription: params.packageDescription,
        packageWeight: params.packageWeight,
        specialInstructions: params.specialInstructions,
      );

      debugPrint('[DeliveryRepository] createDelivery called');
      debugPrint('[DeliveryRepository] DTO: ${dto.toJson()}');

      final result = await remoteDatasource.createDelivery(dto);
      debugPrint('[DeliveryRepository] Success: ${result.id}');
      return Success(_mapDtoToEntity(result));
    } on ApiException catch (e) {
      debugPrint('[DeliveryRepository] ApiException: ${e.message}');
      debugPrint('[DeliveryRepository] ApiException statusCode: ${e.statusCode}');
      return Failure(e.message);
    } catch (e, stackTrace) {
      debugPrint('[DeliveryRepository] Exception: $e');
      debugPrint('[DeliveryRepository] StackTrace: $stackTrace');
      return Failure('Erreur lors de la création de la livraison: $e');
    }
  }

  @override
  Future<Result<List<Delivery>>> getDeliveries({DeliveryStatus? status}) async {
    try {
      debugPrint('[DeliveryRepository] getDeliveries called, status: $status');
      final statusString = status != null ? _statusToString(status) : null;
      final result = await remoteDatasource.getDeliveries(status: statusString);
      debugPrint('[DeliveryRepository] Got ${result.length} DTOs from datasource');
      final deliveries = result.map(_mapDtoToEntity).toList();
      debugPrint('[DeliveryRepository] Mapped to ${deliveries.length} entities');
      return Success(deliveries);
    } on ApiException catch (e) {
      debugPrint('[DeliveryRepository] ApiException: ${e.message}');
      return Failure(e.message);
    } catch (e, stackTrace) {
      debugPrint('[DeliveryRepository] Exception: $e');
      debugPrint('[DeliveryRepository] StackTrace: $stackTrace');
      return Failure('Erreur lors de la récupération des livraisons: $e');
    }
  }

  @override
  Future<Result<Delivery>> getDeliveryById(String id) async {
    try {
      final result = await remoteDatasource.getDeliveryById(id);
      return Success(_mapDtoToEntity(result));
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Erreur lors de la récupération de la livraison');
    }
  }

  @override
  Future<Result<Delivery>> cancelDelivery(String id) async {
    try {
      final result = await remoteDatasource.cancelDelivery(id);
      return Success(_mapDtoToEntity(result));
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Erreur lors de l\'annulation de la livraison');
    }
  }

  @override
  Future<Result<Delivery>> verifyQRCode({
    required String deliveryId,
    required String qrCode,
    required String type,
  }) async {
    try {
      final result = await remoteDatasource.verifyQRCode(
        deliveryId: deliveryId,
        qrCode: qrCode,
        type: type,
      );
      return Success(_mapDtoToEntity(result));
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Erreur lors de la vérification du code QR');
    }
  }

  // Mapper DTO vers Entity
  Delivery _mapDtoToEntity(dynamic dto) {
    // Mapper les infos du livreur si disponibles
    DelivererInfo? delivererInfo;
    if (dto.deliverer != null) {
      delivererInfo = DelivererInfo(
        id: dto.deliverer.id,
        fullName: dto.deliverer.fullName,
        phoneNumber: dto.deliverer.phoneNumber,
        photoUrl: dto.deliverer.photoUrl,
        rating: dto.deliverer.rating,
        vehicleType: dto.deliverer.vehicleType,
        licensePlate: dto.deliverer.licensePlate,
      );
    }

    return Delivery(
      id: dto.id,
      clientId: dto.clientId,
      delivererId: dto.delivererId,
      deliverer: delivererInfo,
      pickupLocation: Location(
        address: dto.pickupAddress,
        latitude: dto.pickupLatitude,
        longitude: dto.pickupLongitude,
        phone: dto.pickupPhone,
      ),
      deliveryLocation: Location(
        address: dto.deliveryAddress,
        latitude: dto.deliveryLatitude,
        longitude: dto.deliveryLongitude,
        phone: dto.deliveryPhone,
      ),
      package: Package(
        receiverName: dto.receiverName,
        receiverPhone: dto.deliveryPhone,
        description: dto.packageDescription,
        weight: dto.packageWeight,
      ),
      qrCodes: QRCodes(
        pickup: dto.qrCodePickup,
        delivery: dto.qrCodeDelivery,
      ),
      status: DeliveryStatus.fromString(dto.status),
      price: dto.price,
      distanceKm: dto.distanceKm,
      specialInstructions: dto.specialInstructions,
      deliveryCode: dto.deliveryCode,
      timestamps: DeliveryTimestamps(
        createdAt: dto.createdAt,
        acceptedAt: dto.acceptedAt,
        pickedUpAt: dto.pickedUpAt,
        deliveredAt: dto.deliveredAt,
        cancelledAt: dto.cancelledAt,
      ),
    );
  }

  String _statusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.accepted:
        return 'accepted';
      case DeliveryStatus.pickupInProgress:
        return 'pickupInProgress';
      case DeliveryStatus.pickedUp:
        return 'pickedUp';
      case DeliveryStatus.deliveryInProgress:
        return 'deliveryInProgress';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
    }
  }
}
