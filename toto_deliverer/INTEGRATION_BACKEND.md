# Guide d'Intégration Backend - TOTO Deliverer App

## ✅ Travaux Complétés

### 📦 Architecture Implémentée

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Frontend)                │
├─────────────────────────────────────────────────────────┤
│  Providers (Riverpod)                                   │
│  ├─ DeliveryProvider                                    │
│  └─ QuotaProvider                                       │
├─────────────────────────────────────────────────────────┤
│  Hybrid Services (Simulation/Real Toggle)              │
│  └─ HybridDeliveryService                               │
│      ├─ SimulationService (Mock Data)                   │
│      └─ DeliveryService (Real API)                      │
├─────────────────────────────────────────────────────────┤
│  Core Services (JWT-based)                              │
│  ├─ DeliveryService                                     │
│  ├─ QuotaService                                        │
│  └─ TrackingService (WebSocket)                         │
├─────────────────────────────────────────────────────────┤
│  Adapters (Data Transformation)                         │
│  ├─ BaseAdapter (snake_case ↔ camelCase)              │
│  ├─ DeliveryAdapter                                     │
│  └─ QuotaAdapter                                        │
├─────────────────────────────────────────────────────────┤
│  API Client (Dio + Interceptors)                        │
│  ├─ Interceptor 1: Auto transformation                  │
│  ├─ Interceptor 2: JWT Auth + Error handling           │
│  └─ Token management (Access + Refresh)                │
└─────────────────────────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────┐
│              NestJS Backend (snake_case)                 │
│  Endpoints:                                              │
│  • POST /auth/deliverer/login                           │
│  • GET  /deliveries?status=pending                      │
│  • POST /deliveries/:id/accept                          │
│  • POST /deliveries/:id/verify-qr                       │
│  • GET  /quotas/active (JWT)                            │
│  • POST /quotas/purchase (JWT)                          │
│  • WebSocket: Real-time tracking                        │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Configuration

### 1. Configurer l'URL du Backend

**Fichier:** `lib/core/config/env_config.dart`

```dart
class EnvConfig {
  // 🔴 MODIFIER SELON VOTRE ENVIRONNEMENT
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Émulateur Android
      // return 'http://192.168.1.X:3000'; // Appareil physique
    } else if (Platform.isIOS) {
      return 'http://localhost:3000'; // Simulateur iOS
      // return 'http://192.168.1.X:3000'; // Appareil physique
    }
    return 'http://localhost:3000'; // Web/Desktop
  }

  static String get socketUrl {
    // Même logique que baseUrl
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    }
    return 'http://localhost:3000';
  }

  // 🎯 MODE SIMULATION (Basculer selon vos besoins)
  static const bool enableSimulationMode = false; // false = API réelle
  static const bool useRealPayments = false;      // false = Simulation
}
```

### 2. Basculer entre Simulation et API Réelle

**Mode Simulation** (Développement UI):
```dart
static const bool enableSimulationMode = true;
```
- Utilise `SimulationService` avec données mockées
- Pas d'appels réseau
- QR codes prédéfinis
- Parfait pour tester l'UI

**Mode Réel** (Tests Backend):
```dart
static const bool enableSimulationMode = false;
```
- Utilise l'API backend via `DeliveryService` et `QuotaService`
- Authentification JWT requise
- Connexion réseau nécessaire

## 🧪 Tests d'Intégration

### Prérequis

1. ✅ Backend NestJS démarré sur `http://localhost:3000`
2. ✅ Base de données PostgreSQL opérationnelle
3. ✅ `enableSimulationMode = false` dans `env_config.dart`

### Scénario de Test Complet

#### 1️⃣ **Authentification Livreur**

**Endpoint:** `POST /auth/deliverer/login`

**Test Frontend:**
```dart
// Via AuthProvider
final authProvider = ref.read(authProvider.notifier);
await authProvider.login(email, password);
```

**Vérifications:**
- ✅ Token JWT stocké dans FlutterSecureStorage
- ✅ Refresh token stocké
- ✅ ApiClient.isAuthenticated == true
- ✅ Navigation vers HomeScreen

**Backend attendu:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "deliverer": {
    "id": "uuid",
    "first_name": "Jean",
    "last_name": "Dupont",
    "email": "jean.dupont@email.com",
    "phone": "+225 01 02 03 04 05",
    "status": "active"
  }
}
```

---

#### 2️⃣ **Récupération Quota Actif**

**Endpoint:** `GET /quotas/active` (JWT-based)

**Test Frontend:**
```dart
// Via QuotaProvider
final quotaProvider = ref.read(quotaProvider.notifier);
await quotaProvider.loadActiveQuota();

// Vérifier l'état
final state = ref.read(quotaProvider);
print('Livraisons restantes: ${state.remainingDeliveries}');
```

**Vérifications:**
- ✅ Header `Authorization: Bearer <token>` envoyé automatiquement
- ✅ Backend extrait l'ID depuis le JWT
- ✅ Response transformée en `QuotaModel`
- ✅ `state.activeQuota` non null

**Backend attendu:**
```json
{
  "id": "quota-uuid",
  "user_id": "deliverer-uuid",
  "total_deliveries": 10,
  "remaining_deliveries": 7,
  "purchased_at": "2024-01-15T10:00:00Z",
  "expires_at": "2024-03-15T10:00:00Z",
  "is_active": true
}
```

**Transformation automatique (snake_case → camelCase):**
```dart
QuotaModel(
  id: "quota-uuid",
  delivererId: "deliverer-uuid", // user_id transformé
  totalPurchased: 10,
  remainingDeliveries: 7,
  lastUpdated: DateTime(2024, 1, 15, 10, 0, 0),
)
```

---

#### 3️⃣ **Récupération Livraisons Disponibles**

**Endpoint:** `GET /deliveries?status=pending`

**Test Frontend:**
```dart
// Via DeliveryProvider (Hybrid)
final deliveryProvider = ref.read(deliveryProvider.notifier);
await deliveryProvider.loadAvailableDeliveries();

// Vérifier
final state = ref.read(deliveryProvider);
print('${state.availableDeliveries.length} livraisons disponibles');
```

**Vérifications:**
- ✅ Query parameter `?status=pending` ajouté automatiquement
- ✅ Response transformée en `List<DeliveryModel>`
- ✅ Filtrage des livraisons sans deliverer_id

**Backend attendu:**
```json
[
  {
    "id": "delivery-uuid-1",
    "client_id": "client-uuid",
    "deliverer_id": null,
    "pickup_address": "Cocody Angré",
    "pickup_latitude": 5.3599517,
    "pickup_longitude": -3.9810350,
    "delivery_address": "Plateau",
    "delivery_latitude": 5.3250984,
    "delivery_longitude": -4.0267813,
    "package_description": "Documents",
    "package_weight": 1.5,
    "price": 2500,
    "distance_km": 8.5,
    "status": "pending",
    "created_at": "2024-01-20T14:30:00Z"
  }
]
```

---

#### 4️⃣ **Acceptation d'une Livraison**

**Endpoint:** `POST /deliveries/:id/accept`

**Test Frontend:**
```dart
await deliveryProvider.acceptDelivery('delivery-uuid-1');
```

**Vérifications:**
- ✅ Consomme 1 quota automatiquement (backend)
- ✅ `deliverer_id` assigné au livreur JWT
- ✅ Status passe à `accepted`
- ✅ `accepted_at` timestamp ajouté
- ✅ Provider rafraîchit les listes (available → active)

**Backend attendu:**
```json
{
  "id": "delivery-uuid-1",
  "deliverer_id": "deliverer-uuid",
  "status": "accepted",
  "accepted_at": "2024-01-20T14:35:00Z",
  // ... autres champs
}
```

---

#### 5️⃣ **Workflow Complet de Livraison**

**5.1 - Démarrer vers Point A (Pickup)**

```dart
await deliveryProvider.startPickup('delivery-uuid-1');
```

**Endpoint:** `PATCH /deliveries/:id`
**Body:** `{ "status": "pickupInProgress" }`

---

**5.2 - Scan QR au Point A**

```dart
await deliveryProvider.confirmPickup(
  'delivery-uuid-1',
  'QR-CODE-PICKUP-SCANNED',
);
```

**Endpoint:** `POST /deliveries/:id/verify-qr`
**Body:**
```json
{
  "qr_code": "QR-CODE-PICKUP-SCANNED",
  "type": "pickup"
}
```

**Backend doit:**
- ✅ Vérifier que le QR correspond à `qr_code_pickup`
- ✅ Changer status → `pickedUp`
- ✅ Ajouter timestamp `picked_up_at`

---

**5.3 - Démarrer vers Point B (Delivery)**

```dart
await deliveryProvider.startDelivery('delivery-uuid-1');
```

**Endpoint:** `PATCH /deliveries/:id`
**Body:** `{ "status": "deliveryInProgress" }`

---

**5.4 - Scan QR au Point B**

```dart
await deliveryProvider.confirmDelivery(
  'delivery-uuid-1',
  'QR-CODE-DELIVERY-SCANNED',
);
```

**Endpoint:** `POST /deliveries/:id/verify-qr`
**Body:**
```json
{
  "qr_code": "QR-CODE-DELIVERY-SCANNED",
  "type": "delivery"
}
```

**OU avec code 4 chiffres (fallback):**

```dart
await deliveryProvider.confirmDeliveryWithCode(
  'delivery-uuid-1',
  '1234', // Code 4 chiffres
);
```

**Body:**
```json
{
  "delivery_code": "1234",
  "type": "delivery"
}
```

**Backend doit:**
- ✅ Vérifier QR ou code 4 chiffres
- ✅ Changer status → `delivered`
- ✅ Ajouter timestamp `delivered_at`

---

#### 6️⃣ **Rating Bidirectionnel**

**Endpoint:** `POST /deliveries/:id/rate`

**Test Frontend:**
```dart
await deliveryProvider.rateCustomer(
  'delivery-uuid-1',
  5, // Stars (1-5)
  'Excellent client, très ponctuel!', // Comment (optionnel)
);
```

**Vérifications:**
- ✅ Backend stocke le rating du livreur vers le client
- ✅ Le client peut aussi noter le livreur sur le même endpoint
- ✅ Rating associé au JWT (qui note)

---

#### 7️⃣ **Achat de Quota**

**Endpoint:** `POST /quotas/purchase` (JWT-based)

**Test Frontend:**
```dart
await quotaProvider.purchaseQuota(
  packType: QuotaPackType.pack10, // 10 livraisons
  paymentMethod: PaymentMethod.mobileMoney,
  phoneNumber: '+225 01 02 03 04 05', // Pour Mobile Money
);
```

**Body envoyé (via QuotaAdapter):**
```json
{
  "quota_type": "standard",
  "payment_method": "mobile_money",
  "phone_number": "+225 01 02 03 04 05"
}
```

**Backend doit:**
- ✅ Extraire deliverer_id depuis JWT
- ✅ Créer un nouveau quota ou ajouter au quota actif
- ✅ Créer une transaction de type `purchase`
- ✅ Initier le paiement (Mobile Money simulé)
- ✅ Retourner le quota créé/mis à jour

---

#### 8️⃣ **WebSocket Tracking GPS**

**Connexion:**
```dart
final trackingService = TrackingService();

// Configurer les listeners
trackingService.setOnConnected(() {
  print('WebSocket connecté!');
});

trackingService.setOnConnectError((error) {
  print('Erreur WebSocket: $error');
});

// Connecter avec JWT
await trackingService.connect();
```

**Vérifications:**
- ✅ Header `Authorization: Bearer <token>` envoyé dans handshake
- ✅ Backend vérifie le JWT et autorise la connexion
- ✅ `isConnected == true`

**Rejoindre une room de livraison:**
```dart
trackingService.joinDeliveryRoom('delivery-uuid-1');
```

**Envoyer position GPS:**
```dart
trackingService.updateLocation(
  'delivery-uuid-1',
  5.3599517, // latitude
  -3.9810350, // longitude
);
```

**Écouter les updates:**
```dart
trackingService.onLocationUpdate((data) {
  print('Position mise à jour: ${data['latitude']}, ${data['longitude']}');
});

trackingService.onStatusUpdate((data) {
  print('Statut changé: ${data['status']}');
});
```

---

## 🐛 Débogage

### Vérifier les Logs API

**Activer les logs Dio:**

```dart
// Dans api_client.dart, ajouter temporairement:
_dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
  error: true,
));
```

### Problèmes Courants

#### ❌ Erreur 401 Unauthorized

**Cause:** Token JWT expiré ou invalide

**Solution:**
```dart
// Forcer le rafraîchissement du token
await _apiClient.clearTokens();
await authProvider.login(email, password);
```

---

#### ❌ Erreur de transformation snake_case

**Cause:** Clé backend non gérée par BaseAdapter

**Solution:**
- Vérifier la clé dans la réponse backend
- Ajouter un cas spécial dans l'adapter si nécessaire
- Vérifier que l'intercepteur de transformation fonctionne

**Debug:**
```dart
// Dans api_client.dart, ligne 33:
onResponse: (response, handler) {
  print('AVANT transformation: ${response.data}');
  if (response.data != null) {
    response.data = BaseAdapter.snakeToCamel(response.data);
  }
  print('APRÈS transformation: ${response.data}');
  return handler.next(response);
},
```

---

#### ❌ WebSocket ne se connecte pas

**Causes possibles:**
1. URL incorrecte (http vs ws)
2. Token JWT invalide
3. Backend n'accepte pas WebSocket

**Solution:**
```dart
// Vérifier le token
final token = await _apiClient.getAccessToken();
print('Token pour WebSocket: $token');

// Vérifier l'URL
print('Socket URL: ${ApiConfig.socketUrl}');
```

---

## 📊 Tests de Performance

### Mesurer le Temps de Réponse

```dart
import 'package:flutter/foundation.dart';

final stopwatch = Stopwatch()..start();

await deliveryProvider.loadAvailableDeliveries();

stopwatch.stop();
debugPrint('Temps de chargement: ${stopwatch.elapsedMilliseconds}ms');
```

**Objectifs:**
- Login: < 1000ms
- Liste livraisons: < 500ms
- Acceptation: < 800ms
- Scan QR: < 600ms

---

## 🔐 Sécurité

### Tokens JWT

**Storage:**
- ✅ `FlutterSecureStorage` (encrypted)
- ✅ Clés: `access_token`, `refresh_token`

**Rafraîchissement automatique:**
- ✅ Intercepteur détecte 401
- ✅ Tente refresh avec `refresh_token`
- ✅ Réexécute la requête originale avec nouveau token

**Expiration:**
- Access token: 1 heure
- Refresh token: 7 jours

---

## 🚀 Prochaines Étapes

1. **Tests unitaires des adapters** ✅ (54/54 tests passent)
2. **Tests d'intégration** avec backend réel ⏳
3. **Tests de charge** (100+ livraisons simultanées)
4. **Gestion d'erreurs avancée** (retry logic, offline mode)
5. **Migration vers paiements réels** (MTN Mobile Money, Orange Money)

---

## 📞 Support

En cas de problème:
1. Vérifier `flutter analyze` (aucune erreur attendue)
2. Vérifier les logs backend
3. Tester en mode simulation d'abord
4. Contacter l'équipe backend pour vérification endpoints

---

**Date de dernière mise à jour:** Janvier 2025
**Version:** 1.0.0
**Backend compatible:** NestJS v10+
**Flutter version:** 3.24+
