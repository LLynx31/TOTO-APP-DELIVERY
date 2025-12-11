# TOTO Livreur

Application mobile Flutter pour les livreurs de la plateforme TOTO, destinée au marché ouest-africain (Côte d'Ivoire).

## Vue d'ensemble

TOTO Livreur est l'application compagnon de TOTO Client, permettant aux livreurs de recevoir et gérer des courses de livraison. L'application utilise un système de quota où les livreurs achètent des crédits de livraison via Mobile Money.

**Statut actuel** : Interface utilisateur de base complète (~40%), intégration backend en attente.

## Fonctionnalités implémentées

### Authentification et KYC
- Connexion avec téléphone/mot de passe
- Inscription avec vérification KYC complète :
  - Permis de conduire
  - Photo d'identité
  - Photo du véhicule
  - Informations du véhicule (type, plaque)

### Tableau de bord
- Carte statut en ligne/hors ligne
- Affichage du quota restant avec code couleur
- Liste des courses disponibles avec :
  - Mode de livraison (Standard/Express)
  - Taille et poids du colis
  - Adresses de collecte et livraison
  - Prix de la course

### Gestion du quota
- Système de packs de quota :
  - Pack 5 : 5 livraisons pour 5000 FCFA
  - Pack 10 : 10 livraisons pour 9500 FCFA (-5%)
  - Pack 20 : 20 livraisons pour 18000 FCFA (meilleure valeur, -10%)
- Interface de recharge avec sélection de pack
- Intégration Mobile Money (à implémenter)

## Workflow de livraison

1. **Acceptation** : Livreur accepte une course (déduit 1 quota)
2. **Collecte** : Livreur scanne le QR du client pour valider la récupération
3. **Livraison** : Livreur effectue la course
4. **Validation** : Livreur scanne le QR du destinataire OU entre un code à 4 chiffres
5. **Évaluation** : Livreur note le client

## Architecture

### Structure du projet

```
lib/
├── core/                    # Design system et constantes
│   ├── constants/
│   │   ├── app_colors.dart    # Palette de couleurs (vert primaire)
│   │   ├── app_sizes.dart     # Espacements et dimensions
│   │   └── app_strings.dart   # Textes en français
│   └── theme/
│       └── app_theme.dart     # Thème Material Design 3
├── features/                # Modules par fonctionnalité
│   ├── auth/               # Connexion et inscription KYC
│   ├── dashboard/          # Écran principal et courses
│   ├── quota/              # Recharge de quota
│   └── [À implémenter: tracking, scanner, wallet, history, profile]
└── shared/                  # Code partagé
    ├── models/             # Modèles de données
    │   ├── deliverer_model.dart
    │   ├── delivery_model.dart
    │   ├── quota_model.dart
    │   └── transaction_model.dart
    └── widgets/            # Widgets réutilisables
```

### Compatibilité avec l'app client

Les modèles de données partagés (`DeliveryModel`, `AddressModel`, `PackageModel`) sont identiques entre les deux applications pour assurer la compatibilité backend.

## Design System

### Couleurs

Palette verte pour différencier l'app livreur de l'app client (orange) :

- **Primaire** : Vert vif `#00C853`
- **Secondaire** : Bleu `#004E89`
- **Statuts** :
  - En ligne : Vert `#00C853`
  - Hors ligne : Gris `#9E9E9E`
  - Quota OK : Vert
  - Quota faible : Jaune `#FFD23F`
  - Quota épuisé : Rouge `#F44336`

### Constantes

Toutes les valeurs de design (couleurs, tailles, textes) sont définies dans `lib/core/constants/`. Ne jamais coder en dur les valeurs.

## Commandes de développement

### Installation et exécution

```bash
# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run

# Lancer sur un appareil spécifique
flutter run -d <device-id>

# Analyser le code
flutter analyze

# Lancer les tests
flutter test

# Nettoyer et réinstaller
flutter clean && flutter pub get
```

### Build

```bash
# Build APK Android
flutter build apk

# Build iOS
flutter build ios
```

## Dépendances principales

- **flutter_riverpod** `^2.4.9` : Gestion d'état (à implémenter)
- **go_router** `^12.1.3` : Navigation (à implémenter)
- **dio** `^5.4.0` : Client HTTP pour l'API
- **google_maps_flutter** `^2.5.0` : Affichage de cartes
- **geolocator** `^10.1.0` : Services de localisation
- **qr_code_scanner** `^1.0.1` : Scanner de codes QR
- **qr_flutter** `^4.1.0` : Génération de codes QR
- **image_picker** `^1.0.5` : Capture de photos pour KYC

## Configuration native

### Android

Permissions configurées dans `android/app/src/main/AndroidManifest.xml` :
- Caméra (scanner QR, photos KYC)
- Localisation (navigation GPS)
- Internet
- Clé API Google Maps

### iOS

Permissions configurées dans `ios/Runner/Info.plist` :
- NSCameraUsageDescription
- NSLocationWhenInUseUsageDescription
- Clé API Google Maps

## Écrans à implémenter

### Priorité 1 - Flow de livraison
1. **Détails de course** : Carte avec itinéraire, bouton d'acceptation
2. **Suivi en temps réel** : Carte avec position actuelle, statut de livraison
3. **Scanner QR** : Scan QR client/destinataire + entrée manuelle 4 chiffres
4. **Évaluation client** : Notes et commentaire après livraison

### Priorité 2 - Gestion
5. **Historique** : Liste des courses complétées avec recherche
6. **Portefeuille** : Solde, transactions, retraits
7. **Profil** : Infos personnelles, véhicule, documents vérifiés
8. **Notifications** : Liste des notifications

## État du projet

### Complété ✅
- Structure du projet et design system
- Authentification (UI uniquement)
- Inscription avec KYC (UI uniquement)
- Tableau de bord avec courses disponibles
- Système de quota et recharge (UI uniquement)
- Configuration des permissions natives
- Modèles de données compatibles avec l'app client

### En cours 🚧
- Implémentation des écrans restants
- Intégration backend
- Gestion d'état avec Riverpod
- Navigation avec GoRouter

### À faire 📋
- Intégration API backend
- Authentification réelle avec JWT
- Paiement Mobile Money
- Tracking GPS en temps réel
- Scanner QR fonctionnel
- Tests unitaires et d'intégration

## Notes importantes

1. **Tous les textes sont en français** dans `app_strings.dart`
2. **Utiliser le design system** : pas de valeurs codées en dur
3. **Backend non connecté** : données mockées pour le moment
4. **Pas d'authentification** : écran de connexion est UI uniquement
5. **Clé API Google Maps** : nécessaire pour les cartes (à activer)
6. **Permissions requises** : gérer les permissions runtime Android/iOS

## Compatibilité

- **Flutter SDK** : 3.10.0 ou supérieur
- **Dart SDK** : 3.0.0 ou supérieur
- **Android** : API 21+ (Android 5.0)
- **iOS** : 12.0+

## Support

Pour toute question ou problème, consulter la documentation Flutter : https://docs.flutter.dev/
