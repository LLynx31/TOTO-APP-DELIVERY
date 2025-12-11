# TOTO Client - Application de Livraison

Application mobile de livraison de colis développée avec Flutter.

## Fonctionnalités Implémentées

### ✅ Authentification
- Écran de connexion
- Écran d'inscription
- Validation des formulaires

### ✅ Page d'Accueil
- Vue d'ensemble avec avatar utilisateur
- Bouton "Nouvelle Livraison"
- Historique récent des livraisons
- Bottom navigation bar

### ✅ Nouvelle Livraison (Flow en 3 étapes)
1. **Sélection des Adresses**
   - Point A (départ)
   - Point B (arrivée)
   - Aperçu carte
   - Bouton "Utiliser ma position"

2. **Détails du Colis**
   - Upload photo
   - Sélection de la taille (Petit/Moyen/Grand)
   - Poids en kg
   - Description
   - Mode de livraison (Standard/Express)
   - Option assurance
   - Calcul du prix estimé

3. **Récapitulatif**
   - Résumé complet de la livraison
   - Prix final
   - Confirmation

### ✅ Suivi de Livraison
- Carte avec position en temps réel
- Informations du livreur
- Timeline de progression
- QR Code pour validation
- Bouton "Contacter le livreur"

### ✅ Profil Utilisateur
- Photo de profil
- Informations personnelles
- Gestion des adresses favorites
- Bouton déconnexion

### ✅ Notifications
- Liste des notifications
- Filtrage et recherche
- Badge de notifications non lues
- Différents types de notifications

## Structure du Projet

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # Couleurs de l'app
│   │   ├── app_sizes.dart        # Tailles et espacements
│   │   └── app_strings.dart      # Textes en français
│   ├── theme/
│   │   └── app_theme.dart        # Thème Material
│   ├── router/                   # Navigation (à implémenter)
│   └── utils/                    # Utilitaires
│
├── features/
│   ├── auth/
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   │
│   ├── home/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── main_screen.dart
│   │   └── widgets/
│   │       └── delivery_card.dart
│   │
│   ├── delivery/
│   │   └── screens/
│   │       ├── new_delivery_screen.dart
│   │       ├── tracking_screen.dart
│   │       └── steps/
│   │           ├── location_step.dart
│   │           ├── package_details_step.dart
│   │           └── summary_step.dart
│   │
│   ├── profile/
│   │   └── screens/
│   │       └── profile_screen.dart
│   │
│   └── notifications/
│       └── screens/
│           └── notifications_screen.dart
│
└── shared/
    ├── models/
    │   ├── user_model.dart
    │   ├── delivery_model.dart
    │   ├── notification_model.dart
    │   ├── transaction_model.dart
    │   └── models.dart
    │
    ├── widgets/
    │   ├── custom_button.dart
    │   ├── custom_text_field.dart
    │   ├── custom_card.dart
    │   ├── loading_indicator.dart
    │   ├── empty_state.dart
    │   ├── error_view.dart
    │   ├── status_badge.dart
    │   ├── rating_stars.dart
    │   └── widgets.dart
    │
    ├── services/          # Services API (à implémenter)
    └── providers/         # State management (à implémenter)
```

## Prochaines Étapes

### Backend Integration
- [ ] Configuration Dio pour les appels API
- [ ] Implémentation des services API
- [ ] Gestion des tokens d'authentification
- [ ] WebSocket pour le tracking en temps réel

### State Management
- [ ] Configuration Riverpod
- [ ] Création des providers
- [ ] Gestion de l'état global

### Navigation
- [ ] Configuration GoRouter
- [ ] Routes et deep linking
- [ ] Navigation guards

### Fonctionnalités Avancées
- [ ] Intégration Google Maps
- [ ] Géolocalisation
- [ ] Upload d'images
- [ ] Scanner QR Code
- [ ] Notifications push (FCM)
- [ ] Paiement mobile money

### Tests
- [ ] Tests unitaires
- [ ] Tests de widgets
- [ ] Tests d'intégration

## Installation et Lancement

### Prérequis
- Flutter SDK (>=3.10.0)
- Dart SDK
- Android Studio / VS Code
- Émulateur ou appareil physique

### Installation

```bash
# Cloner le projet
cd toto_client

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

### Build

```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS (sur macOS)
flutter build ios --release
```

## Dépendances Principales

- **flutter_riverpod**: State management
- **go_router**: Navigation
- **dio**: HTTP client
- **google_maps_flutter**: Cartes
- **geolocator**: Géolocalisation
- **qr_flutter**: Génération QR codes
- **image_picker**: Sélection d'images
- **intl**: Internationalisation et formatage

## Palette de Couleurs

- **Primary**: #00D9A3 (Vert)
- **Secondary**: #4A9DFF (Bleu)
- **Accent**: #FFB800 (Orange/Jaune)
- **Success**: #00D9A3
- **Error**: #FF4D4F
- **Warning**: #FFB800
- **Info**: #4A9DFF

## Contribution

Pour contribuer:
1. Créer une branche depuis `develop`
2. Faire vos modifications
3. Tester l'application
4. Créer une pull request

## Licence

Propriétaire - TOTO © 2025
