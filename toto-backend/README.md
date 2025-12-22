# TOTO Backend - API de gestion de livraisons

Backend NestJS pour l'application de livraison TOTO en Côte d'Ivoire.

## 📋 Table des matières

- [Caractéristiques](#caractéristiques)
- [Technologies](#technologies)
- [Installation](#installation)
- [Configuration](#configuration)
- [Lancement](#lancement)
- [Architecture](#architecture)
- [Documentation API](#documentation-api)
- [Tests](#tests)

## ✨ Caractéristiques

### 🔐 Authentification & Autorisation
- JWT Authentication avec access & refresh tokens
- Séparation Client / Livreur
- Guards NestJS pour la protection des routes

### 📦 Système de quotas prépayés
- 4 types de packs (BASIC, STANDARD, PREMIUM, CUSTOM)
- Gestion automatique de la consommation
- Remboursement automatique en cas d'annulation
- Historique complet des transactions
- Désactivation automatique à l'expiration

### 🚚 Gestion des livraisons
- CRUD complet des livraisons
- Machine à états pour le suivi du statut
- Calcul automatique de distance (Haversine)
- Calcul automatique du prix
- QR codes uniques pour pickup/delivery
- Attribution aux livreurs

### 📍 Suivi en temps réel (WebSocket)
- Suivi GPS en temps réel
- Historique de tracking
- Rooms par livraison
- Événements temps réel pour clients et livreurs

### 📚 Documentation
- Swagger UI intégré
- Documentation API complète
- Exemples d'intégration Flutter

## 🛠 Technologies

- **Framework**: NestJS 11.x
- **Base de données**: PostgreSQL
- **ORM**: TypeORM
- **Authentication**: JWT (jsonwebtoken)
- **WebSocket**: Socket.io
- **Validation**: class-validator, class-transformer
- **Documentation**: Swagger/OpenAPI
- **Sécurité**: bcrypt pour les mots de passe
- **Package Manager**: pnpm

## 📦 Installation

### Prérequis

- Node.js >= 18.x
- PostgreSQL >= 14.x
- **pnpm >= 8.x** (recommandé)

### Installer pnpm

```bash
npm install -g pnpm
# ou via script shell
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

### Étapes d'installation

1. **Cloner le projet**
```bash
cd toto-backend
```

2. **Installer les dépendances**
```bash
pnpm install
```

3. **Configurer la base de données PostgreSQL**
```bash
# Se connecter à PostgreSQL
psql -U postgres

# Créer la base de données
CREATE DATABASE toto_db;

# Créer un utilisateur (optionnel)
CREATE USER toto_user WITH PASSWORD 'votre_password';
GRANT ALL PRIVILEGES ON DATABASE toto_db TO toto_user;
```

## ⚙️ Configuration

Créer un fichier `.env` à la racine du projet :

```env
# Application
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=votre_password
DB_DATABASE=toto_db

# JWT
JWT_SECRET=votre_jwt_secret_super_securise
JWT_EXPIRES_IN=1h
JWT_REFRESH_SECRET=votre_refresh_secret_super_securise
JWT_REFRESH_EXPIRES_IN=7d
```

### Générer des secrets JWT sécurisés

```bash
# Pour JWT_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Pour JWT_REFRESH_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## 🚀 Lancement

### Mode développement (avec watch)
```bash
pnpm run start:dev
```

### Mode production
```bash
pnpm run build
pnpm run start:prod
```

### Créer des utilisateurs de test
```bash
pnpm run create-test-users
```

Cela créera automatiquement :
- 2 clients de test (client@test.com, aya@test.com)
- 1 livreur de test (deliverer@test.com)
- Tous avec le mot de passe : `Password123!`

### Accès aux services

- **API**: http://localhost:3000
- **Swagger Documentation**: http://localhost:3000/api
- **WebSocket**: ws://localhost:3000

## 🏗 Architecture

```
src/
├── auth/                   # Module d'authentification
│   ├── dto/               # DTOs pour login/register
│   ├── entities/          # User & Deliverer entities
│   ├── guards/            # JWT Auth Guards
│   ├── strategies/        # Passport JWT Strategy
│   └── auth.service.ts    # Logique d'authentification
│
├── deliveries/            # Module de gestion des livraisons
│   ├── dto/              # DTOs pour CRUD
│   ├── entities/         # Delivery entity
│   └── deliveries.service.ts
│
├── quotas/               # Module de gestion des quotas
│   ├── dto/             # DTOs pour purchase
│   ├── entities/        # DeliveryQuota & QuotaTransaction
│   └── quotas.service.ts
│
├── tracking/            # Module de suivi temps réel
│   ├── entities/       # DeliveryTracking entity
│   └── tracking.gateway.ts  # WebSocket Gateway
│
└── main.ts             # Point d'entrée de l'application
```

## 📖 Documentation API

La documentation complète de l'API est disponible dans [API_DOCUMENTATION.md](API_DOCUMENTATION.md).

### Accès rapide via Swagger

Une fois le serveur lancé, accédez à http://localhost:3000/api pour une documentation interactive complète avec :
- Tous les endpoints disponibles
- Schémas de données
- Possibilité de tester les endpoints directement

## 🧪 Tests

### Fichier de tests HTTP

Un fichier `test-quotas.http` est fourni pour tester rapidement les endpoints avec VS Code REST Client.

### Tests manuels avec curl

Voir les exemples dans [API_DOCUMENTATION.md](API_DOCUMENTATION.md).

## 📊 Modèle de données

### Users (Clients)
- id (UUID)
- phone_number (unique)
- full_name
- email
- password_hash
- is_verified, is_active

### Deliverers (Livreurs)
- id (UUID)
- phone_number (unique)
- full_name
- vehicle_type (moto, voiture, vélo)
- license_plate
- is_verified, is_active, is_available

### Deliveries (Livraisons)
- id (UUID)
- client_id, deliverer_id
- pickup_address, pickup_latitude, pickup_longitude
- delivery_address, delivery_latitude, delivery_longitude
- status (pending → accepted → picked_up → delivered)
- price, distance_km
- qr_code_pickup, qr_code_delivery

### DeliveryQuotas (Quotas)
- id (UUID)
- user_id
- quota_type (basic, standard, premium, custom)
- total_deliveries, used_deliveries, remaining_deliveries
- price_paid, payment_method
- expires_at, is_active

### QuotaTransactions (Transactions)
- id (UUID)
- quota_id, delivery_id
- transaction_type (purchase, usage, refund, expiration)
- amount, balance_before, balance_after

### DeliveryTracking (Suivi GPS)
- id (UUID)
- delivery_id, deliverer_id
- latitude, longitude
- timestamp

## 🔐 Sécurité

- Mots de passe hashés avec bcrypt (salt rounds: 10)
- JWT avec expiration courte (1h) + refresh token (7d)
- Validation stricte des données avec class-validator
- Guards NestJS pour protéger les routes
- Vérification des permissions (client ne peut voir que ses livraisons)
- Prévention injection SQL via TypeORM parameterized queries

## 🌍 Variables d'environnement

| Variable | Description | Exemple |
|----------|-------------|---------|
| NODE_ENV | Environnement | development, production |
| PORT | Port du serveur | 3000 |
| DB_HOST | Hôte PostgreSQL | localhost |
| DB_PORT | Port PostgreSQL | 5432 |
| DB_USERNAME | Utilisateur PostgreSQL | postgres |
| DB_PASSWORD | Mot de passe PostgreSQL | password |
| DB_DATABASE | Nom de la base de données | toto_db |
| JWT_SECRET | Secret pour les access tokens | random_string_64_chars |
| JWT_EXPIRES_IN | Durée de vie access token | 1h |
| JWT_REFRESH_SECRET | Secret pour les refresh tokens | random_string_64_chars |
| JWT_REFRESH_EXPIRES_IN | Durée de vie refresh token | 7d |

## 🛠️ Scripts Disponibles

| Script | Description |
|--------|-------------|
| `pnpm install` | Installer les dépendances |
| `pnpm run build` | Build le projet TypeScript |
| `pnpm run start` | Démarrer en mode normal |
| `pnpm run start:dev` | Démarrer en mode développement (watch) |
| `pnpm run start:prod` | Démarrer en mode production |
| `pnpm run lint` | Linter le code |
| `pnpm run format` | Formater le code avec Prettier |
| `pnpm test` | Exécuter les tests |
| `pnpm run create-test-users` | Créer les utilisateurs de test |
| `pnpm run migration:generate` | Générer une migration TypeORM |
| `pnpm run migration:run` | Exécuter les migrations |
| `pnpm run migration:revert` | Annuler la dernière migration |

## 📝 TODO / Améliorations futures

- [ ] Implémenter les notifications push (Firebase)
- [x] ~~Ajouter un système de rating/review~~ ✅ **Fait !**
- [ ] Intégration avec API de paiement mobile (Orange Money, MTN Money)
- [ ] Optimisation des routes pour les livreurs
- [ ] Dashboard admin (statistiques, gestion utilisateurs)
- [ ] Tests unitaires et E2E
- [ ] CI/CD Pipeline
- [ ] Containerisation (Docker)
- [ ] Rate limiting et throttling
- [ ] Logs structurés (Winston)
- [ ] Monitoring (Prometheus, Grafana)

## 🤝 Contribution

Ce projet est développé pour l'application TOTO - Service de livraison en Côte d'Ivoire.

## 📄 Licence

Propriétaire - TOTO CI

## 📞 Support

Pour toute question ou problème, veuillez contacter l'équipe de développement.

---

## 🆕 Nouveautés

### ✅ Système de Rating Bidirectionnel (Décembre 2025)

Le système de notation est maintenant implémenté :
- Client peut noter le livreur après livraison (1-5 étoiles + commentaire)
- Livreur peut noter le client après livraison
- Prévention des doubles notations (index unique en DB)
- Endpoints dédiés : `POST /deliveries/:id/rate`, `GET /deliveries/:id/rating`
- Documentation complète : [RATING_SYSTEM_INTEGRATION.md](RATING_SYSTEM_INTEGRATION.md)

### 📦 Migration vers pnpm

Le projet utilise maintenant **pnpm** comme gestionnaire de paquets pour :
- Installation plus rapide des dépendances
- Économie d'espace disque (store partagé)
- Résolution stricte des dépendances
- Meilleure performance globale

---

**Version**: 1.1.0
**Dernière mise à jour**: Décembre 2025
**Statut**: ✅ Production-ready avec système de rating complet
