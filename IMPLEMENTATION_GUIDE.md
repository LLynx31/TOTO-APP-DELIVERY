# TOTO Delivery - Guide d'Implémentation

## 🎯 Fonctionnalités Implémentées

### App Client (toto_client)

#### 1. Tracking en Temps Réel
**Fichiers principaux:**
- `lib/core/websocket/websocket_service.dart` - Service WebSocket
- `lib/presentation/screens/delivery/tracking_screen.dart` - Écran de tracking
- `lib/presentation/providers/tracking_provider.dart` - State management

**Utilisation:**
```dart
// Navigation vers le tracking
context.goToTracking(deliveryId);

// Ou avec le provider
ref.read(trackingProvider.notifier).startTracking(deliveryId);
```

**Fonctionnalités:**
- ✅ Carte Google Maps plein écran
- ✅ Marqueurs animés (pickup, delivery, livreur)
- ✅ Polyline du trajet
- ✅ Mises à jour en temps réel via WebSocket
- ✅ Timeline des statuts de livraison
- ✅ Informations du livreur avec bouton appel
- ✅ Estimation d'arrivée (ETA)

#### 2. WebSocket Service
**Configuration:**
```dart
// Le service se connecte automatiquement avec le deliveryId
final webSocketService = ref.watch(webSocketServiceProvider);
await webSocketService.connect(deliveryId: 'delivery-123');

// Écouter les updates de position
webSocketService.locationStream.listen((update) {
  print('Position: ${update.latitude}, ${update.longitude}');
});

// Écouter les changements de statut
webSocketService.statusStream.listen((update) {
  print('Nouveau statut: ${update.newStatus}');
});
```

---

### App Deliverer (toto_deliverer)

#### 1. Tracking GPS Automatique
**Fichiers principaux:**
- `lib/core/services/location_tracking_service.dart` - Service de localisation
- `lib/features/tracking/providers/tracking_provider.dart` - Provider amélioré

**Utilisation:**
```dart
// Démarrer le tracking automatique
final trackingNotifier = ref.read(trackingProvider.notifier);
await trackingNotifier.startLocationTracking();

// Arrêter le tracking
trackingNotifier.stopLocationTracking();

// Envoyer manuellement la position
await trackingNotifier.sendCurrentLocation();
```

**Configuration:**
- Updates automatiques toutes les **8 secondes**
- Filtre de distance minimale: **10 mètres**
- Permissions: ACCESS_FINE_LOCATION, ACCESS_BACKGROUND_LOCATION

#### 2. Système de Quotas Amélioré
**Fichiers principaux:**
- `lib/features/quota/quota_recharge_screen.dart` - Écran de recharge
- `lib/features/quota/widgets/payment_confirmation_dialog.dart` - Confirmation
- `lib/features/quota/widgets/payment_processing_dialog.dart` - Processing
- `lib/features/quota/widgets/payment_receipt_screen.dart` - Reçu

**Flow de paiement:**
1. **Sélection du pack** (5, 10 ou 20 livraisons)
2. **Dialog de confirmation** - Affiche détails et prix
3. **Processing animé** - 3 étapes visualisées
4. **Écran de reçu** - Transaction ID, détails, nouveau quota

**API Call:**
```dart
await quotaService.purchaseQuota(
  delivererId: 'deliverer-123',
  packageId: 'BASIC', // ou 'STANDARD', 'PREMIUM'
  paymentMethod: 'mobileMoney',
);
```

---

## 🔧 Configuration Requise

### Backend Requirements

**WebSocket Endpoints:**
```
ws://localhost:3000/tracking
```

**Events émis par le client:**
- `join_delivery` - Rejoindre une room de livraison
- `leave_delivery` - Quitter une room
- `location_update` - Envoyer une position GPS

**Events reçus par le client:**
- `location_updated` - Position du livreur mise à jour
- `delivery_status_changed` - Statut de livraison changé
- `tracking_history` - Historique des positions

### API Endpoints

**Quotas:**
```
POST /quotas/purchase
GET /quotas/deliverer/:delivererId
GET /quotas/transaction/:transactionId
```

**Deliveries:**
```
GET /deliveries/:id
POST /deliveries
PATCH /deliveries/:id/status
```

---

## 🚀 Guide de Démarrage Rapide

### 1. Démarrer le Backend
```bash
cd toto-backend
npm run start:dev
```

### 2. Lancer l'App Client
```bash
cd toto_client
flutter run
```

### 3. Lancer l'App Deliverer
```bash
cd toto_deliverer
flutter run
```

### 4. Test du Flow Complet

**Scénario de test:**

1. **Client crée une livraison**
   - Ouvre l'app client
   - Clique sur "Nouvelle livraison"
   - Remplit le wizard (3 étapes)
   - Confirme et paie

2. **Deliverer accepte la livraison**
   - Ouvre l'app deliverer
   - Voit la nouvelle livraison dans la liste
   - Accepte la livraison (quota décrémenté)

3. **Tracking en temps réel**
   - Client ouvre l'écran de tracking
   - Deliverer démarre le tracking GPS
   - Client voit la position du livreur se mettre à jour toutes les 8 secondes
   - La position est affichée sur la carte

4. **Recharge de quota**
   - Deliverer va dans "Quotas"
   - Sélectionne un pack
   - Confirme le paiement (simulé)
   - Reçoit le reçu avec le nouveau quota

---

## 📱 Widgets Réutilisables

### Client App

**DeliveryStatusTimeline**
```dart
DeliveryStatusTimeline(
  currentStatus: DeliveryStatus.pickupInProgress,
)
```

**DelivererInfoCard**
```dart
DelivererInfoCard(
  delivererName: 'John Doe',
  delivererPhone: '+225 07 XX XX XX XX',
  rating: 4.5,
  vehicleInfo: 'Moto',
)
```

**EstimatedArrivalCard**
```dart
EstimatedArrivalCard(
  estimatedMinutes: 15,
  distanceKm: 3.2,
  isLoading: false,
)
```

### Deliverer App

**PaymentConfirmationDialog**
```dart
showDialog(
  context: context,
  builder: (context) => PaymentConfirmationDialog(
    pack: QuotaPackType.pack10,
    paymentMethod: PaymentMethod.mobileMoney,
    onConfirm: () => processPurchase(),
  ),
);
```

**PaymentProcessingDialog**
```dart
showDialog(
  context: context,
  builder: (context) => PaymentProcessingDialog(
    onProcess: () => apiCall(),
  ),
);
```

---

## 🐛 Debugging

### Activer les logs WebSocket
```dart
// Dans websocket_service.dart, les logs sont déjà activés avec debugPrint
// Pour voir les logs:
flutter run --verbose
```

### Tester le GPS sans bouger
```bash
# Simuler une position GPS (Android Emulator)
adb emu geo fix -122.084 37.422

# Envoyer plusieurs positions
adb emu geo fix -122.085 37.423
adb emu geo fix -122.086 37.424
```

### Vérifier les permissions
```dart
// Dans l'app deliverer
final permission = await trackingNotifier.checkLocationPermission();
print('Permission status: $permission');
```

---

## 📊 Mapping des Packages

| App Pack Type | Backend Package ID | Livraisons | Prix (FCFA) |
|---------------|-------------------|------------|-------------|
| pack5         | BASIC             | 5          | 5,000       |
| pack10        | STANDARD          | 10         | 9,500       |
| pack20        | PREMIUM           | 20         | 18,000      |

---

## ⚠️ Notes Importantes

### TODOs Critiques

1. **Authentification**
   - Récupérer le vrai `delivererId` depuis l'auth state
   - Actuellement: `'deliverer-id-placeholder'`
   - Fichier: `quota_recharge_screen.dart:101`

2. **Infos Livreur**
   - Récupérer les vraies infos du livreur (nom, photo, téléphone)
   - Actuellement: Valeurs par défaut
   - Fichier: `tracking_screen.dart:356`

3. **ETA Calculation**
   - Utiliser une API de routing (Google Directions API)
   - Actuellement: Formule haversine simple
   - Fichier: `tracking_screen.dart:507`

### Performance

**WebSocket:**
- Reconnexion automatique après 5 secondes max
- Historique de positions limité à 100 points

**GPS:**
- Updates toutes les 8 secondes (configurable)
- Filtre de 10 mètres pour éviter le spam
- Batterie: Mode haute précision uniquement pendant livraison active

---

## 🔐 Sécurité

**Validations côté client:**
- ✅ Sélection de pack obligatoire
- ✅ Méthode de paiement obligatoire
- ✅ Confirmation avant paiement
- ✅ Gestion des erreurs réseau

**À implémenter côté backend:**
- Validation du delivererId
- Vérification du quota avant acceptation
- Transaction atomique pour l'achat
- Webhook de paiement réel

---

## 📞 Support

Pour toute question ou problème:
1. Vérifier les logs: `flutter run --verbose`
2. Tester la connexion backend: `curl http://localhost:3000/health`
3. Vérifier les permissions GPS dans les paramètres du téléphone

---

**Version**: 1.0.0
**Dernière mise à jour**: 2025-12-19
**Auteur**: Claude Code
