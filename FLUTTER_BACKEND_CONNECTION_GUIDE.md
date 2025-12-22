# 🔌 Guide de Connexion Flutter ↔ Backend

## 📋 Vue d'ensemble

Ce guide explique comment connecter l'application Flutter TOTO Client au backend NestJS et tester l'intégration complète.

**Statut** : ✅ Configuration prête
**Backend** : http://localhost:3000
**Flutter** : Configuration automatique selon la plateforme

---

## ✅ Configuration Actuelle

### 1. Configuration API ✅

**Fichier** : [lib/core/config/api_config.dart](toto_client/lib/core/config/api_config.dart)

```dart
// Endpoints Rating déjà configurés
static String rateDelivery(String deliveryId)
  => '/deliveries/$deliveryId/rate';

static String getDeliveryRating(String deliveryId)
  => '/deliveries/$deliveryId/rating';

static String checkHasRated(String deliveryId)
  => '/deliveries/$deliveryId/has-rated';
```

✅ **Tous les endpoints sont configurés !**

---

### 2. Configuration Environnement ✅

**Fichier** : [lib/core/config/env_config.dart](toto_client/lib/core/config/env_config.dart)

**URLs automatiques selon la plateforme** :
- **Android Emulator** : `http://10.0.2.2:3000`
- **iOS Simulator** : `http://localhost:3000`
- **Web** : `http://localhost:3000`

✅ **Détection automatique de la plateforme !**

---

### 3. Client HTTP (Dio) ✅

**Fichier** : [lib/core/network/dio_client.dart](toto_client/lib/core/network/dio_client.dart)

**Fonctionnalités** :
- ✅ Injection automatique du JWT dans les headers
- ✅ Refresh automatique du token si expiré
- ✅ Gestion d'erreurs complète (400, 401, 403, 404, 409, 500)
- ✅ Logging en mode développement
- ✅ Timeout configurables (30s)

---

## 🚀 Démarrage

### Étape 1 : Démarrer le Backend

```bash
cd toto-backend
npm run start:dev
```

**Vérification** :
```bash
curl http://localhost:3000
# Réponse attendue: "Hello World!"
```

✅ Backend disponible sur http://localhost:3000

---

### Étape 2 : Lancer l'App Flutter

#### Option A : Android Emulator

```bash
cd toto_client
flutter run
```

L'app utilisera automatiquement `http://10.0.2.2:3000`

#### Option B : iOS Simulator

```bash
cd toto_client
flutter run
```

L'app utilisera automatiquement `http://localhost:3000`

#### Option C : Chrome (Web)

```bash
cd toto_client
flutter run -d chrome
```

L'app utilisera `http://localhost:3000`

---

## 🧪 Tests de Connexion

### Test 1 : Vérifier la connexion réseau

**Dans l'app Flutter**, essayez de vous connecter ou de créer un compte.

**Logs à vérifier** :
```
[DIO] --> POST /auth/client/login
[DIO] <-- 200 OK
```

Si erreur de connexion :
- ✅ Vérifier que le backend tourne
- ✅ Vérifier l'URL dans les logs Dio
- ✅ Vérifier que le port 3000 est ouvert

---

### Test 2 : Créer un utilisateur de test

**Via cURL** (pour avoir un compte rapidement) :

```bash
# Créer un client
curl -X POST http://localhost:3000/auth/client/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@client.com",
    "password": "Password123!",
    "phone": "+22501020304",
    "firstName": "Test",
    "lastName": "Client"
  }'
```

**Réponse attendue** :
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "user": {
    "id": "uuid",
    "email": "test@client.com",
    "type": "client"
  }
}
```

---

### Test 3 : Se connecter dans l'app

1. Ouvrir l'app Flutter
2. Aller sur l'écran de connexion
3. Saisir :
   - Email : `test@client.com`
   - Password : `Password123!`
4. Appuyer sur "Se connecter"

**Résultat attendu** : ✅ Connexion réussie → Redirection vers l'écran d'accueil

**Logs backend** :
```
[RouterExplorer] POST /auth/client/login
```

---

### Test 4 : Créer une livraison

1. Dans l'app, cliquer sur le bouton **"Nouvelle livraison"**
2. Remplir le formulaire en 4 étapes :
   - **Étape 1** : Adresse de ramassage
   - **Étape 2** : Adresse de livraison
   - **Étape 3** : Détails du colis
   - **Étape 4** : Récapitulatif
3. Valider

**Résultat attendu** : ✅ Livraison créée avec `delivery_code` (code 4 chiffres)

**Logs backend** :
```
[DeliveriesService] Generating delivery code...
[DeliveriesService] Created delivery with code: 4729
```

---

### Test 5 : Tester le système de notation

#### 5.1 Simuler une livraison complète

**Via cURL** (pour aller plus vite) :

```bash
# 1. Créer livraison (avec le token client)
DELIVERY_ID="..." # Copier l'ID de la réponse

# 2. Login livreur
curl -X POST http://localhost:3000/auth/deliverer/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "deliverer@test.com",
    "password": "Password123!"
  }'
# Copier le token livreur

# 3. Accepter livraison
curl -X POST http://localhost:3000/deliveries/$DELIVERY_ID/accept \
  -H "Authorization: Bearer {DELIVERER_TOKEN}"

# 4. Marquer comme livrée
curl -X PATCH http://localhost:3000/deliveries/$DELIVERY_ID \
  -H "Authorization: Bearer {DELIVERER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"status": "delivered"}'
```

#### 5.2 Noter dans l'app Flutter

1. Aller dans "Mes livraisons"
2. Sélectionner la livraison terminée
3. L'app devrait afficher automatiquement **RateDeliveryScreen**
4. Donner une note (1-5 étoiles)
5. Ajouter un commentaire (optionnel)
6. Valider

**Résultat attendu** :
- ✅ Notation créée
- ✅ Écran de félicitation avec confetti 🎉
- ✅ Redirection vers détails ou home

**Logs backend** :
```
[RatingsController] POST /deliveries/{id}/rate
[RatingsService] Creating rating: 5 stars
```

---

## 🐛 Troubleshooting

### Problème 1 : "Erreur de connexion"

**Symptômes** : L'app Flutter ne peut pas joindre le backend

**Solutions** :

1. **Vérifier que le backend tourne** :
   ```bash
   curl http://localhost:3000
   ```

2. **Android Emulator** : Utiliser `10.0.2.2` au lieu de `localhost`
   - Déjà configuré dans `EnvConfig` ✅

3. **Firewall** : Vérifier que le port 3000 n'est pas bloqué

4. **CORS** : Le backend NestJS a déjà CORS activé ✅

---

### Problème 2 : "Session expirée" après quelques minutes

**Cause** : Token JWT expiré (1h par défaut)

**Solution** : Le refresh automatique est déjà configuré ✅

Si le refresh échoue :
- Se déconnecter et se reconnecter
- Le refresh token dure 7 jours

---

### Problème 3 : "409 Conflict" lors de la notation

**Cause** : Tentative de noter deux fois la même livraison

**Solution** : C'est normal ! Le backend empêche les doubles notations.

Vérifier avec :
```dart
await ref.read(checkHasRatedUsecaseProvider)(deliveryId);
```

---

### Problème 4 : Code 4 chiffres non généré

**Symptômes** : `delivery_code` est null dans la réponse

**Causes possibles** :
1. Anciennes livraisons créées avant l'ajout du champ
2. Erreur lors de la génération

**Solution** :
- Les nouvelles livraisons ont toujours un code ✅
- Pour les anciennes, exécuter la migration SQL :
  ```bash
  psql -U postgres -d toto_db -f migrations/001_add_rating_system.sql
  ```

---

## 📊 Vérifications Backend

### Vérifier les livraisons créées

```sql
psql -U postgres -d toto_db

SELECT id, delivery_code, status, created_at
FROM deliveries
ORDER BY created_at DESC
LIMIT 5;
```

### Vérifier les notations

```sql
SELECT
  r.id,
  r.stars,
  r.comment,
  d.id as delivery_id,
  r.created_at
FROM ratings r
JOIN deliveries d ON r.delivery_id = d.id
ORDER BY r.created_at DESC
LIMIT 5;
```

---

## 🔐 Sécurité

### Headers HTTP envoyés

Chaque requête authentifiée contient :

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Accept: application/json
```

### Stockage sécurisé

Les tokens sont stockés dans **FlutterSecureStorage** :
- ✅ Chiffré sur Android (Keystore)
- ✅ Chiffré sur iOS (Keychain)
- ✅ Automatiquement supprimés à la déconnexion

---

## 📝 Workflow Complet de Test

### Scénario : Livraison avec notation

```
1. Se connecter dans l'app Flutter
   → GET /auth/client/login

2. Créer une livraison
   → POST /deliveries
   → Réponse : { "delivery_code": "4729", ... }

3. (Backend) Livreur accepte
   → POST /deliveries/:id/accept

4. (Backend) Marquer comme livrée
   → PATCH /deliveries/:id {"status": "delivered"}

5. (App) Rafraîchir les livraisons
   → GET /deliveries

6. (App) Ouvrir livraison terminée
   → Détection automatique : status = "delivered"

7. (App) Vérifier si déjà noté
   → GET /deliveries/:id/has-rated
   → { "has_rated": false }

8. (App) Afficher RateDeliveryScreen

9. (App) Soumettre notation
   → POST /deliveries/:id/rate
   → { "stars": 5, "comment": "..." }

10. (App) Afficher DeliverySuccessScreen
    → Animation confetti 🎉

11. (App) Retour à l'accueil
```

---

## 🎯 Checklist de Connexion

### Backend
- [x] Backend démarré (`npm run start:dev`)
- [x] Swagger accessible (http://localhost:3000/api)
- [x] Routes rating enregistrées
- [x] Base de données PostgreSQL connectée

### Flutter
- [x] Configuration API complète
- [x] DioClient configuré
- [x] EnvConfig détecte la plateforme
- [x] Endpoints rating configurés
- [x] Dependency injection OK

### Tests
- [ ] Connexion réussie
- [ ] Création livraison OK
- [ ] delivery_code généré
- [ ] Notation créée
- [ ] Écran félicitation affiché
- [ ] Workflow complet testé

---

## 📚 Documentation Complémentaire

- **Backend** : [RATING_SYSTEM_INTEGRATION.md](toto-backend/RATING_SYSTEM_INTEGRATION.md)
- **API Testing** : [API_TESTING_GUIDE.md](toto-backend/API_TESTING_GUIDE.md)
- **Frontend** : [IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md)

---

## 🚀 Prochaines Étapes

Une fois la connexion testée :

1. **Tests E2E** : Tester le workflow complet plusieurs fois
2. **Gestion d'erreurs** : Vérifier tous les cas d'erreur
3. **Performance** : Tester avec plusieurs livraisons
4. **UI Polish** : Affiner les animations et transitions
5. **Logs** : Vérifier que tout est bien loggé

---

## 💡 Astuces

### Activer les logs réseau

Les logs Dio sont **automatiquement activés** en mode développement.

Vous verrez dans la console :
```
[DIO] --> POST /deliveries/abc-123/rate
[DIO] {"stars": 5, "comment": "Excellent"}
[DIO] <-- 201 Created
```

### Reset complet

Si besoin de tout réinitialiser :

```bash
# Flutter
cd toto_client
flutter clean
flutter pub get
flutter run

# Backend
cd toto-backend
npm run build
pkill -f "nest start"
npm run start:dev
```

---

**L'app Flutter est prête à communiquer avec le backend ! 🎉**
