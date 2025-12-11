# Guide d'intégration Flutter - TOTO Backend

Ce guide vous aidera à intégrer le backend TOTO dans vos applications Flutter (toto_client et toto_deliverer).

## 📦 Packages Flutter requis

Ajoutez ces dépendances dans votre `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP Client
  http: ^1.1.0
  dio: ^5.3.3  # Alternative à http, plus puissante

  # WebSocket
  socket_io_client: ^2.0.3

  # State Management
  provider: ^6.1.1  # ou riverpod, bloc, getx selon préférence

  # Stockage local
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0  # Pour tokens JWT

  # Géolocalisation
  geolocator: ^10.1.0
  google_maps_flutter: ^2.5.0

  # QR Code
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1

  # Utils
  intl: ^0.18.1  # Formatage dates
  uuid: ^4.2.1
```

---

## 🏗 Architecture recommandée

```
lib/
├── models/           # Modèles de données
├── services/         # Services API
│   ├── api_client.dart
│   ├── auth_service.dart
│   ├── delivery_service.dart
│   ├── quota_service.dart
│   └── tracking_service.dart
├── providers/        # State management
├── screens/          # Écrans UI
└── widgets/          # Widgets réutilisables
```

---

## 🔐 1. Configuration du client HTTP

### api_client.dart

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000'; // À remplacer en production
  final _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;

  // Constructeur singleton
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // Initialiser depuis le stockage
  Future<void> init() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
  }

  // Sauvegarder les tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  // Supprimer les tokens (logout)
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // Headers avec authentification
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // GET Request
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // POST Request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // PATCH Request
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // Gestion des réponses
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token expiré, tenter refresh
      // _refreshAccessToken();
      throw Exception('Unauthorized');
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Une erreur est survenue');
    }
  }
}
```

---

## 🔑 2. Service d'authentification

### auth_service.dart

```dart
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  // Inscription client
  Future<Map<String, dynamic>> registerClient({
    required String phoneNumber,
    required String password,
    required String fullName,
    String? email,
  }) async {
    final response = await _client.post('/auth/client/register', {
      'phone_number': phoneNumber,
      'password': password,
      'full_name': fullName,
      if (email != null) 'email': email,
    });

    // Sauvegarder les tokens
    await _client.saveTokens(
      response['access_token'],
      response['refresh_token'],
    );

    return response;
  }

  // Connexion client
  Future<Map<String, dynamic>> loginClient({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _client.post('/auth/client/login', {
      'phone_number': phoneNumber,
      'password': password,
    });

    await _client.saveTokens(
      response['access_token'],
      response['refresh_token'],
    );

    return response;
  }

  // Inscription livreur
  Future<Map<String, dynamic>> registerDeliverer({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String vehicleType,
    required String licensePlate,
  }) async {
    final response = await _client.post('/auth/deliverer/register', {
      'phone_number': phoneNumber,
      'password': password,
      'full_name': fullName,
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
    });

    await _client.saveTokens(
      response['access_token'],
      response['refresh_token'],
    );

    return response;
  }

  // Déconnexion
  Future<void> logout() async {
    await _client.post('/auth/logout', {
      'refresh_token': await _client._storage.read(key: 'refresh_token'),
    });
    await _client.clearTokens();
  }
}
```

---

## 📦 3. Service de quotas

### quota_service.dart

```dart
import 'api_client.dart';

class QuotaService {
  final ApiClient _client = ApiClient();

  // Obtenir les packs disponibles
  Future<List<dynamic>> getAvailablePackages() async {
    return (await _client.get('/quotas/packages')) as List;
  }

  // Acheter un pack
  Future<Map<String, dynamic>> purchaseQuota({
    required String quotaType,
    int? customQuantity,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    return await _client.post('/quotas/purchase', {
      'quota_type': quotaType,
      if (customQuantity != null) 'custom_quantity': customQuantity,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
    });
  }

  // Obtenir le quota actif
  Future<Map<String, dynamic>?> getActiveQuota() async {
    try {
      return await _client.get('/quotas/active');
    } catch (e) {
      return null; // Pas de quota actif
    }
  }

  // Obtenir mes quotas
  Future<List<dynamic>> getMyQuotas() async {
    return (await _client.get('/quotas/my-quotas')) as List;
  }

  // Obtenir l'historique d'un quota
  Future<Map<String, dynamic>> getQuotaHistory(String quotaId) async {
    return await _client.get('/quotas/$quotaId/history');
  }
}
```

---

## 🚚 4. Service de livraisons

### delivery_service.dart

```dart
import 'api_client.dart';

class DeliveryService {
  final ApiClient _client = ApiClient();

  // Créer une livraison
  Future<Map<String, dynamic>> createDelivery({
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required String deliveryPhone,
    required String receiverName,
    required String packageDescription,
    String? pickupPhone,
    double? packageWeight,
    String? specialInstructions,
  }) async {
    return await _client.post('/deliveries', {
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_phone': deliveryPhone,
      'receiver_name': receiverName,
      'package_description': packageDescription,
      if (pickupPhone != null) 'pickup_phone': pickupPhone,
      if (packageWeight != null) 'package_weight': packageWeight,
      if (specialInstructions != null)
        'special_instructions': specialInstructions,
    });
  }

  // Obtenir mes livraisons
  Future<List<dynamic>> getMyDeliveries({String? status}) async {
    String endpoint = '/deliveries';
    if (status != null) {
      endpoint += '?status=$status';
    }
    return (await _client.get(endpoint)) as List;
  }

  // Obtenir une livraison
  Future<Map<String, dynamic>> getDelivery(String id) async {
    return await _client.get('/deliveries/$id');
  }

  // Obtenir livraisons disponibles (livreurs)
  Future<List<dynamic>> getAvailableDeliveries() async {
    return (await _client.get('/deliveries/available')) as List;
  }

  // Accepter une livraison (livreur)
  Future<Map<String, dynamic>> acceptDelivery(String id) async {
    return await _client.post('/deliveries/$id/accept', {});
  }

  // Mettre à jour le statut
  Future<Map<String, dynamic>> updateDeliveryStatus(
    String id,
    String status,
  ) async {
    return await _client.patch('/deliveries/$id', {
      'status': status,
    });
  }

  // Annuler une livraison
  Future<Map<String, dynamic>> cancelDelivery(String id) async {
    return await _client.post('/deliveries/$id/cancel', {});
  }

  // Vérifier QR code
  Future<Map<String, dynamic>> verifyQRCode({
    required String deliveryId,
    required String qrCode,
    required String type, // 'pickup' ou 'delivery'
  }) async {
    return await _client.post('/deliveries/$deliveryId/verify-qr', {
      'qr_code': qrCode,
      'type': type,
    });
  }
}
```

---

## 📍 5. Service de tracking (WebSocket)

### tracking_service.dart

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TrackingService {
  static const String socketUrl = 'http://localhost:3000';
  IO.Socket? socket;

  // Callbacks
  Function(Map<String, dynamic>)? onLocationUpdate;
  Function(List<dynamic>)? onTrackingHistory;
  Function(String)? onError;

  // Connexion
  void connect() {
    socket = IO.io(socketUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket!.connect();

    // Écouter les événements
    socket!.on('location_updated', (data) {
      if (onLocationUpdate != null) {
        onLocationUpdate!(data);
      }
    });

    socket!.on('tracking_history', (data) {
      if (onTrackingHistory != null) {
        onTrackingHistory!(data);
      }
    });

    socket!.on('error', (error) {
      if (onError != null) {
        onError!(error['message']);
      }
    });
  }

  // Rejoindre une livraison
  void joinDelivery(String deliveryId, String userType) {
    socket?.emit('join_delivery', {
      'deliveryId': deliveryId,
      'userType': userType, // 'client' ou 'deliverer'
    });
  }

  // Quitter une livraison
  void leaveDelivery(String deliveryId) {
    socket?.emit('leave_delivery', {
      'deliveryId': deliveryId,
    });
  }

  // Mettre à jour la position (livreur)
  void updateLocation(String deliveryId, double lat, double lng) {
    socket?.emit('update_location', {
      'deliveryId': deliveryId,
      'latitude': lat,
      'longitude': lng,
    });
  }

  // Obtenir l'historique
  void getTrackingHistory(String deliveryId) {
    socket?.emit('get_tracking_history', {
      'deliveryId': deliveryId,
    });
  }

  // Déconnexion
  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
```

---

## 🗺️ 6. Exemple d'utilisation - Créer une livraison

### create_delivery_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/delivery_service.dart';
import '../services/quota_service.dart';

class CreateDeliveryScreen extends StatefulWidget {
  @override
  _CreateDeliveryScreenState createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  final _deliveryService = DeliveryService();
  final _quotaService = QuotaService();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _deliveryPhoneController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _packageDescriptionController = TextEditingController();

  Position? _pickupPosition;
  Position? _deliveryPosition;

  @override
  void initState() {
    super.initState();
    _checkQuota();
  }

  // Vérifier si l'utilisateur a un quota actif
  Future<void> _checkQuota() async {
    final quota = await _quotaService.getActiveQuota();
    if (quota == null || quota['remaining_deliveries'] <= 0) {
      // Rediriger vers l'achat de quota
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous devez acheter un pack de livraisons'),
          action: SnackBarAction(
            label: 'Acheter',
            onPressed: () {
              // Navigator.push vers écran d'achat
            },
          ),
        ),
      );
    }
  }

  // Obtenir position actuelle
  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _pickupPosition = position;
    });
  }

  // Créer la livraison
  Future<void> _createDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupPosition == null || _deliveryPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner les positions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final delivery = await _deliveryService.createDelivery(
        pickupAddress: _pickupAddressController.text,
        pickupLatitude: _pickupPosition!.latitude,
        pickupLongitude: _pickupPosition!.longitude,
        deliveryAddress: _deliveryAddressController.text,
        deliveryLatitude: _deliveryPosition!.latitude,
        deliveryLongitude: _deliveryPosition!.longitude,
        deliveryPhone: _deliveryPhoneController.text,
        receiverName: _receiverNameController.text,
        packageDescription: _packageDescriptionController.text,
      );

      // Succès - rediriger vers détails
      Navigator.pop(context, delivery);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nouvelle livraison')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Champs du formulaire
            TextFormField(
              controller: _pickupAddressController,
              decoration: InputDecoration(labelText: 'Adresse de ramassage'),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            // ... autres champs

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _createDelivery,
              child: _isLoading
                ? CircularProgressIndicator()
                : Text('Créer la livraison'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📱 7. Exemple - Suivi en temps réel

### delivery_tracking_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/tracking_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String deliveryId;
  final String userType;

  DeliveryTrackingScreen({
    required this.deliveryId,
    required this.userType,
  });

  @override
  _DeliveryTrackingScreenState createState() =>
    _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final _trackingService = TrackingService();
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  void _initTracking() {
    // Callbacks
    _trackingService.onLocationUpdate = (data) {
      setState(() {
        _currentPosition = LatLng(
          data['latitude'],
          data['longitude'],
        );
      });

      // Animer la caméra vers la nouvelle position
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    };

    // Connexion et join
    _trackingService.connect();
    _trackingService.joinDelivery(widget.deliveryId, widget.userType);
  }

  @override
  void dispose() {
    _trackingService.leaveDelivery(widget.deliveryId);
    _trackingService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Suivi en temps réel')),
      body: _currentPosition == null
        ? Center(child: CircularProgressIndicator())
        : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              if (_currentPosition != null)
                Marker(
                  markerId: MarkerId('deliverer'),
                  position: _currentPosition!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                ),
            },
          ),
    );
  }
}
```

---

## 🔧 Configuration pour production

### 1. Variables d'environnement

Créer un fichier `lib/config/env.dart` :

```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://localhost:3000',
  );
}
```

Lancer l'app avec :
```bash
flutter run --dart-define=API_BASE_URL=https://api.toto.ci
```

### 2. Gestion des erreurs

Créer un intercepteur global pour gérer les erreurs :

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
```

---

## ✅ Checklist d'intégration

- [ ] Installer tous les packages requis
- [ ] Configurer ApiClient avec l'URL du backend
- [ ] Implémenter AuthService
- [ ] Implémenter DeliveryService
- [ ] Implémenter QuotaService
- [ ] Implémenter TrackingService (WebSocket)
- [ ] Tester l'authentification
- [ ] Tester la création de livraison
- [ ] Tester l'achat de quota
- [ ] Tester le suivi en temps réel
- [ ] Gérer les erreurs réseau
- [ ] Implémenter le retry sur échec
- [ ] Tester en mode hors ligne
- [ ] Optimiser le state management

---

## 📞 Support

Pour toute question sur l'intégration :
- Consulter [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- Tester avec Swagger: http://localhost:3000/api
- Utiliser le fichier [test-quotas.http](test-quotas.http)

---

**Version**: 1.0.0
**Backend**: Prêt pour intégration
**Statut**: Guide complet ✅
