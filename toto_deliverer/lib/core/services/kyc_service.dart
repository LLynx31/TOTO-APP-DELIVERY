import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

/// Service pour gérer les documents KYC (Know Your Customer)
class KycService {
  final ApiClient _apiClient;

  // Singleton
  static final KycService _instance = KycService._internal();
  factory KycService() => _instance;

  KycService._internal() : _apiClient = ApiClient();

  /// Upload tous les documents KYC en une seule requête
  ///
  /// [drivingLicense] - Photo du permis de conduire
  /// [idCard] - Photo de la CNI
  /// [vehiclePhoto] - Photo du véhicule
  /// [onProgress] - Callback pour suivre la progression
  Future<KycUploadResult> uploadAllDocuments({
    File? drivingLicense,
    File? idCard,
    File? vehiclePhoto,
    void Function(double progress)? onProgress,
  }) async {
    // Vérifier qu'il y a au moins un document
    if (drivingLicense == null && idCard == null && vehiclePhoto == null) {
      throw Exception('Au moins un document est requis');
    }

    // Créer le FormData avec les fichiers
    final formData = FormData();

    if (drivingLicense != null) {
      formData.files.add(MapEntry(
        'driving_license',
        await MultipartFile.fromFile(
          drivingLicense.path,
          filename: 'driving_license_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ));
    }

    if (idCard != null) {
      formData.files.add(MapEntry(
        'id_card',
        await MultipartFile.fromFile(
          idCard.path,
          filename: 'id_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ));
    }

    if (vehiclePhoto != null) {
      formData.files.add(MapEntry(
        'vehicle_photo',
        await MultipartFile.fromFile(
          vehiclePhoto.path,
          filename: 'vehicle_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ));
    }

    final response = await _apiClient.postMultipart(
      '/uploads/kyc',
      formData: formData,
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data;
      return KycUploadResult(
        drivingLicenseUrl: data['drivingLicenseUrl'] ?? data['driving_license_url'],
        idCardUrl: data['idCardUrl'] ?? data['id_card_url'],
        vehiclePhotoUrl: data['vehiclePhotoUrl'] ?? data['vehicle_photo_url'],
        kycStatus: data['kycStatus'] ?? data['kyc_status'] ?? 'pending',
      );
    }

    throw Exception('Erreur lors de l\'upload des documents');
  }

  /// Upload un document KYC spécifique
  ///
  /// [documentType] - Type de document: driving_license, id_card, vehicle_photo
  /// [file] - Le fichier à uploader
  Future<SingleDocumentResult> uploadSingleDocument({
    required String documentType,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    final response = await _apiClient.postMultipart(
      '/uploads/kyc/$documentType',
      formData: formData,
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data;
      return SingleDocumentResult(
        url: data['url'],
        documentType: data['documentType'] ?? documentType,
      );
    }

    throw Exception('Erreur lors de l\'upload du document');
  }

  /// Obtenir le statut des documents KYC
  Future<KycStatus> getKycStatus() async {
    final response = await _apiClient.get('/uploads/kyc');

    if (response.statusCode == 200) {
      final data = response.data;
      return KycStatus(
        drivingLicenseUrl: data['drivingLicenseUrl'] ?? data['driving_license_url'],
        idCardUrl: data['idCardUrl'] ?? data['id_card_url'],
        vehiclePhotoUrl: data['vehiclePhotoUrl'] ?? data['vehicle_photo_url'],
        kycStatus: data['kycStatus'] ?? data['kyc_status'] ?? 'pending',
        kycSubmittedAt: data['kycSubmittedAt'] != null || data['kyc_submitted_at'] != null
            ? DateTime.parse(data['kycSubmittedAt'] ?? data['kyc_submitted_at'])
            : null,
        kycReviewedAt: data['kycReviewedAt'] != null || data['kyc_reviewed_at'] != null
            ? DateTime.parse(data['kycReviewedAt'] ?? data['kyc_reviewed_at'])
            : null,
      );
    }

    throw Exception('Erreur lors de la récupération du statut KYC');
  }
}

/// Résultat de l'upload de tous les documents
class KycUploadResult {
  final String? drivingLicenseUrl;
  final String? idCardUrl;
  final String? vehiclePhotoUrl;
  final String kycStatus;

  KycUploadResult({
    this.drivingLicenseUrl,
    this.idCardUrl,
    this.vehiclePhotoUrl,
    required this.kycStatus,
  });

  bool get hasAllDocuments =>
      drivingLicenseUrl != null &&
      idCardUrl != null &&
      vehiclePhotoUrl != null;
}

/// Résultat de l'upload d'un seul document
class SingleDocumentResult {
  final String url;
  final String documentType;

  SingleDocumentResult({
    required this.url,
    required this.documentType,
  });
}

/// Statut KYC complet
class KycStatus {
  final String? drivingLicenseUrl;
  final String? idCardUrl;
  final String? vehiclePhotoUrl;
  final String kycStatus;
  final DateTime? kycSubmittedAt;
  final DateTime? kycReviewedAt;

  KycStatus({
    this.drivingLicenseUrl,
    this.idCardUrl,
    this.vehiclePhotoUrl,
    required this.kycStatus,
    this.kycSubmittedAt,
    this.kycReviewedAt,
  });

  bool get isPending => kycStatus == 'pending';
  bool get isApproved => kycStatus == 'approved';
  bool get isRejected => kycStatus == 'rejected';

  bool get hasAllDocuments =>
      drivingLicenseUrl != null &&
      idCardUrl != null &&
      vehiclePhotoUrl != null;

  int get documentCount {
    int count = 0;
    if (drivingLicenseUrl != null) count++;
    if (idCardUrl != null) count++;
    if (vehiclePhotoUrl != null) count++;
    return count;
  }
}
