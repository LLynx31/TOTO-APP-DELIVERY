# TOTO Backend API - Documentation

## 🚀 Informations générales

- **URL Base**: `http://localhost:3000`
- **Documentation Swagger**: `http://localhost:3000/api`
- **Version**: 1.0.0
- **Framework**: NestJS + TypeORM + PostgreSQL

## 🔐 Authentication

Toutes les routes (sauf `/auth/*`) nécessitent un token JWT dans le header :
```
Authorization: Bearer <access_token>
```

### Endpoints d'authentification

#### 1. Inscription Client
```http
POST /auth/client/register
Content-Type: application/json

{
  "phone_number": "+225XXXXXXXXX",
  "password": "password123",
  "full_name": "Nom complet",
  "email": "email@example.com" (optionnel)
}
```

#### 2. Connexion Client
```http
POST /auth/client/login
Content-Type: application/json

{
  "phone_number": "+225XXXXXXXXX",
  "password": "password123"
}
```

**Réponse**:
```json
{
  "user": { ... },
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

#### 3. Inscription Livreur
```http
POST /auth/deliverer/register
Content-Type: application/json

{
  "phone_number": "+225XXXXXXXXX",
  "password": "password123",
  "full_name": "Nom complet",
  "vehicle_type": "moto",
  "license_plate": "AB-1234-CI"
}
```

#### 4. Connexion Livreur
```http
POST /auth/deliverer/login
Content-Type: application/json

{
  "phone_number": "+225XXXXXXXXX",
  "password": "password123"
}
```

#### 5. Rafraîchir le token
```http
POST /auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGc..."
}
```

#### 6. Déconnexion
```http
POST /auth/logout
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "refresh_token": "eyJhbGc..."
}
```

---

## 📦 Module Quotas (Packs prépayés)

### 1. Obtenir les packs disponibles
```http
GET /quotas/packages
Authorization: Bearer <access_token>
```

**Réponse**:
```json
[
  {
    "quota_type": "basic",
    "deliveries": 10,
    "price": 8000,
    "price_per_delivery": "800",
    "validity_days": 30,
    "savings": 0
  },
  {
    "quota_type": "standard",
    "deliveries": 50,
    "price": 35000,
    "price_per_delivery": "700",
    "validity_days": 60,
    "savings": 13
  },
  {
    "quota_type": "premium",
    "deliveries": 100,
    "price": 60000,
    "price_per_delivery": "600",
    "validity_days": 90,
    "savings": 25
  },
  {
    "quota_type": "custom",
    "deliveries": "Custom",
    "price": 700,
    "price_per_delivery": 700,
    "validity_days": 90,
    "savings": 0
  }
]
```

### 2. Acheter un pack
```http
POST /quotas/purchase
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "quota_type": "basic|standard|premium|custom",
  "custom_quantity": 25 (requis uniquement pour type "custom"),
  "payment_method": "mobile_money|credit_card|cash",
  "payment_reference": "REF-123456"
}
```

**Réponse**:
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "quota_type": "basic",
  "total_deliveries": 10,
  "used_deliveries": 0,
  "remaining_deliveries": 10,
  "price_paid": 8000,
  "payment_method": "mobile_money",
  "payment_reference": "REF-123456",
  "expires_at": "2025-12-29T00:00:00.000Z",
  "is_active": true,
  "purchased_at": "2025-11-29T00:00:00.000Z",
  "updated_at": "2025-11-29T00:00:00.000Z"
}
```

### 3. Obtenir mes quotas
```http
GET /quotas/my-quotas
Authorization: Bearer <access_token>
```

### 4. Obtenir le quota actif
```http
GET /quotas/active
Authorization: Bearer <access_token>
```

### 5. Obtenir l'historique d'un quota
```http
GET /quotas/:id/history
Authorization: Bearer <access_token>
```

**Réponse**:
```json
{
  "quota": { ... },
  "transactions": [
    {
      "id": "uuid",
      "quota_id": "uuid",
      "delivery_id": "uuid",
      "transaction_type": "purchase|usage|refund|expiration",
      "amount": -1,
      "balance_before": 10,
      "balance_after": 9,
      "description": "Used quota for delivery ...",
      "created_at": "2025-11-29T00:00:00.000Z"
    }
  ]
}
```

---

## 🚚 Module Deliveries (Livraisons)

### 1. Créer une livraison
```http
POST /deliveries
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "pickup_address": "Cocody Riviera, Abidjan",
  "pickup_latitude": 5.3599517,
  "pickup_longitude": -4.0082563,
  "pickup_phone": "+225XXXXXXXXX" (optionnel),
  "delivery_address": "Yopougon, Abidjan",
  "delivery_latitude": 5.3364032,
  "delivery_longitude": -4.0266334,
  "delivery_phone": "+225XXXXXXXXX",
  "receiver_name": "Nom du destinataire",
  "package_description": "Description du colis",
  "package_weight": 2.5 (optionnel),
  "special_instructions": "Instructions spéciales" (optionnel)
}
```

**Note**: Cette action consomme automatiquement 1 livraison du quota actif.

**Réponse**:
```json
{
  "id": "uuid",
  "client_id": "uuid",
  "deliverer_id": null,
  "pickup_address": "Cocody Riviera, Abidjan",
  "pickup_latitude": 5.3599517,
  "pickup_longitude": -4.0082563,
  "delivery_address": "Yopougon, Abidjan",
  "delivery_latitude": 5.3364032,
  "delivery_longitude": -4.0266334,
  "qr_code_pickup": "TOTO-PICKUP-...",
  "qr_code_delivery": "TOTO-DELIVERY-...",
  "status": "pending",
  "price": 2657.99,
  "distance_km": 3.32,
  "created_at": "2025-11-29T00:00:00.000Z"
}
```

### 2. Obtenir mes livraisons
```http
GET /deliveries?status=pending|accepted|picked_up|delivered|cancelled
Authorization: Bearer <access_token>
```

### 3. Obtenir une livraison
```http
GET /deliveries/:id
Authorization: Bearer <access_token>
```

### 4. Obtenir les livraisons disponibles (Livreurs)
```http
GET /deliveries/available
Authorization: Bearer <access_token>
```

### 5. Accepter une livraison (Livreur)
```http
POST /deliveries/:id/accept
Authorization: Bearer <access_token>
```

### 6. Mettre à jour une livraison
```http
PATCH /deliveries/:id
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "status": "accepted|pickup_in_progress|picked_up|delivery_in_progress|delivered|cancelled"
}
```

### 7. Annuler une livraison
```http
POST /deliveries/:id/cancel
Authorization: Bearer <access_token>
```

**Note**: Cette action rembourse automatiquement 1 livraison au quota du client.

### 8. Vérifier un QR code
```http
POST /deliveries/:id/verify-qr
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "qr_code": "TOTO-PICKUP-...",
  "type": "pickup|delivery"
}
```

---

## 📍 Module Tracking (Suivi en temps réel)

### WebSocket Connection

**URL**: `ws://localhost:3000`

**Événements Client → Serveur**:

#### 1. Rejoindre une livraison
```javascript
socket.emit('join_delivery', {
  deliveryId: 'uuid',
  userType: 'client|deliverer'
});
```

#### 2. Quitter une livraison
```javascript
socket.emit('leave_delivery', {
  deliveryId: 'uuid'
});
```

#### 3. Mettre à jour la position (Livreur)
```javascript
socket.emit('update_location', {
  deliveryId: 'uuid',
  latitude: 5.3599517,
  longitude: -4.0082563
});
```

#### 4. Obtenir l'historique de suivi
```javascript
socket.emit('get_tracking_history', {
  deliveryId: 'uuid'
});
```

**Événements Serveur → Client**:

```javascript
// Mise à jour de position
socket.on('location_updated', (data) => {
  // data: { deliveryId, latitude, longitude, timestamp }
});

// Historique de suivi
socket.on('tracking_history', (data) => {
  // data: [{ latitude, longitude, timestamp }, ...]
});

// Erreurs
socket.on('error', (error) => {
  // error: { message: 'Error message' }
});
```

---

## 📊 Statuts des livraisons

```
pending → accepted → pickup_in_progress → picked_up →
delivery_in_progress → delivered

                    ↓
                cancelled (à tout moment avant delivered)
```

## 🔄 Gestion automatique des quotas

1. **Création de livraison**: Consomme automatiquement 1 livraison du quota actif
2. **Annulation**: Rembourse automatiquement 1 livraison au quota
3. **Épuisement**: Désactive automatiquement le quota quand `remaining_deliveries = 0`
4. **Expiration**: Désactive automatiquement le quota après la date d'expiration (via CRON)

## 🔑 Codes d'erreur

- `400` - Bad Request (données invalides)
- `401` - Unauthorized (token manquant ou invalide)
- `403` - Forbidden (pas de quota actif, accès non autorisé)
- `404` - Not Found (ressource introuvable)
- `500` - Internal Server Error

## 💡 Exemples d'intégration Flutter

### Configuration HTTP Client
```dart
class ApiClient {
  static const String baseUrl = 'http://localhost:3000';
  String? _accessToken;

  Future<Response> get(String endpoint) {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );
  }

  // ... autres méthodes
}
```

### Configuration WebSocket
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TrackingService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.on('location_updated', (data) {
      print('Location updated: $data');
    });
  }

  void joinDelivery(String deliveryId, String userType) {
    socket.emit('join_delivery', {
      'deliveryId': deliveryId,
      'userType': userType,
    });
  }
}
```

## 📝 Notes importantes

- Tous les prix sont en **CFA (Francs CFA)**
- Les coordonnées GPS doivent être au format **décimal** (ex: 5.3599517)
- Les numéros de téléphone doivent inclure l'**indicatif pays** (+225 pour Côte d'Ivoire)
- Les tokens JWT expirent après **1 heure**
- Les refresh tokens expirent après **7 jours**
- La distance est calculée automatiquement avec la **formule Haversine**
- Le prix est calculé: `1000 CFA + (distance_km × 500 CFA)`

## 🧪 Tests

Un fichier de tests HTTP est disponible: [test-quotas.http](test-quotas.http)

Pour tester avec VS Code, installez l'extension **REST Client**.
