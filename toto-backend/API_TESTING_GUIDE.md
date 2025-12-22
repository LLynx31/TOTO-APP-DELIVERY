# 🧪 Guide de Test API - Système de Notation TOTO

## 📋 Prérequis

- ✅ Backend démarré : `npm run start:dev`
- ✅ Base de données accessible
- ✅ Token JWT valide

---

## 🔑 Obtenir un Token JWT

### 1. Se connecter (client)

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "client@test.com",
    "password": "password"
  }'
```

**Réponse** :
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "...",
  "user": {
    "id": "uuid-client",
    "email": "client@test.com",
    "type": "client"
  }
}
```

**Copier le `access_token`** pour l'utiliser dans les requêtes suivantes.

---

## 📦 Créer une Livraison (avec delivery_code)

```bash
curl -X POST http://localhost:3000/deliveries \
  -H "Authorization: Bearer {ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "pickup_address": "Cocody Riviera, Abidjan",
    "pickup_latitude": 5.3599517,
    "pickup_longitude": -4.0082563,
    "pickup_phone": "+22501020304",
    "delivery_address": "Yopougon, Abidjan",
    "delivery_latitude": 5.3364032,
    "delivery_longitude": -4.0266334,
    "delivery_phone": "+22598765432",
    "receiver_name": "Kouadio Aya",
    "package_description": "Colis fragile",
    "package_weight": 2.5,
    "special_instructions": "Appeler avant de livrer"
  }'
```

**Réponse** :
```json
{
  "id": "abc-123-def-456",
  "client_id": "uuid-client",
  "pickup_address": "Cocody Riviera, Abidjan",
  "delivery_address": "Yopougon, Abidjan",
  "delivery_code": "4729",  // 👈 CODE GÉNÉRÉ AUTOMATIQUEMENT
  "qr_code_pickup": "TOTO-PICKUP-1234567890-abc123...",
  "qr_code_delivery": "TOTO-DELIVERY-1234567890-def456...",
  "status": "pending",
  "price": 3500,
  "distance_km": 5.2,
  "created_at": "2025-12-20T15:30:00.000Z"
}
```

**📌 Noter le `id` et le `delivery_code` pour les tests suivants.**

---

## 🚚 Simuler le Workflow de Livraison

### 2. Livreur accepte la livraison

```bash
# Login livreur
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "deliverer@test.com",
    "password": "password"
  }'

# Accepter la livraison
curl -X POST http://localhost:3000/deliveries/{DELIVERY_ID}/accept \
  -H "Authorization: Bearer {DELIVERER_TOKEN}"
```

### 3. Livreur scanne QR pickup

```bash
curl -X POST http://localhost:3000/deliveries/{DELIVERY_ID}/verify-qr \
  -H "Authorization: Bearer {DELIVERER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "qr_code": "TOTO-PICKUP-1234567890-abc123...",
    "type": "pickup"
  }'
```

### 4. Livreur scanne QR delivery (ou entre code 4 chiffres)

```bash
curl -X POST http://localhost:3000/deliveries/{DELIVERY_ID}/verify-qr \
  -H "Authorization: Bearer {DELIVERER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "qr_code": "TOTO-DELIVERY-1234567890-def456...",
    "type": "delivery"
  }'
```

**Résultat** : La livraison passe au statut `delivered` ✅

---

## ⭐ Tester le Système de Notation

### 5. Client vérifie s'il a déjà noté

```bash
curl -X GET http://localhost:3000/deliveries/{DELIVERY_ID}/has-rated \
  -H "Authorization: Bearer {CLIENT_TOKEN}"
```

**Réponse** :
```json
{
  "has_rated": false
}
```

---

### 6. Client note le livreur

```bash
curl -X POST http://localhost:3000/deliveries/{DELIVERY_ID}/rate \
  -H "Authorization: Bearer {CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "stars": 5,
    "comment": "Excellent service, très rapide et professionnel !"
  }'
```

**Réponse 201** :
```json
{
  "id": "rating-uuid",
  "delivery_id": "{DELIVERY_ID}",
  "rated_by_id": "uuid-client",
  "rated_user_id": "uuid-livreur",
  "stars": 5,
  "comment": "Excellent service, très rapide et professionnel !",
  "created_at": "2025-12-20T16:00:00.000Z"
}
```

---

### 7. Livreur note le client

```bash
curl -X POST http://localhost:3000/deliveries/{DELIVERY_ID}/rate \
  -H "Authorization: Bearer {DELIVERER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "stars": 4,
    "comment": "Client sympa, ponctuel !"
  }'
```

**Réponse 201** :
```json
{
  "id": "rating-uuid-2",
  "delivery_id": "{DELIVERY_ID}",
  "rated_by_id": "uuid-livreur",
  "rated_user_id": "uuid-client",
  "stars": 4,
  "comment": "Client sympa, ponctuel !",
  "created_at": "2025-12-20T16:05:00.000Z"
}
```

---

### 8. Récupérer la notation du client

```bash
curl -X GET http://localhost:3000/deliveries/{DELIVERY_ID}/rating \
  -H "Authorization: Bearer {CLIENT_TOKEN}"
```

**Réponse 200** :
```json
{
  "id": "rating-uuid",
  "delivery_id": "{DELIVERY_ID}",
  "rated_by_id": "uuid-client",
  "rated_user_id": "uuid-livreur",
  "stars": 5,
  "comment": "Excellent service, très rapide et professionnel !",
  "created_at": "2025-12-20T16:00:00.000Z"
}
```

---

### 9. Vérifier à nouveau si le client a noté

```bash
curl -X GET http://localhost:3000/deliveries/{DELIVERY_ID}/has-rated \
  -H "Authorization: Bearer {CLIENT_TOKEN}"
```

**Réponse 200** :
```json
{
  "has_rated": true
}
```

---

## ❌ Cas d'erreur à tester

### Erreur 1 : Noter deux fois la même livraison

```bash
curl -X POST http://localhost:3000/deliveries/{DELIVERY_ID}/rate \
  -H "Authorization: Bearer {CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "stars": 5,
    "comment": "Test double notation"
  }'
```

**Réponse 409 Conflict** :
```json
{
  "statusCode": 409,
  "message": "Vous avez déjà noté cette livraison"
}
```

---

### Erreur 2 : Noter une livraison non terminée

```bash
# Créer nouvelle livraison (statut = pending)
# Essayer de la noter immédiatement

curl -X POST http://localhost:3000/deliveries/{NEW_DELIVERY_ID}/rate \
  -H "Authorization: Bearer {CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "stars": 5,
    "comment": "Test notation prématurée"
  }'
```

**Réponse 400 Bad Request** :
```json
{
  "statusCode": 400,
  "message": "Vous ne pouvez noter qu'une livraison terminée"
}
```

---

### Erreur 3 : Stars invalides

```bash
curl -X POST http://localhost:3000/deliveries/{DELIVERY_ID}/rate \
  -H "Authorization: Bearer {CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "stars": 10,
    "comment": "Test validation"
  }'
```

**Réponse 400 Bad Request** :
```json
{
  "statusCode": 400,
  "message": [
    "stars must not be greater than 5"
  ],
  "error": "Bad Request"
}
```

---

### Erreur 4 : Commentaire trop long

```bash
curl -X POST http://localhost:3000/deliveries/{DELIVERY_ID}/rate \
  -H "Authorization: Bearer {CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "stars": 5,
    "comment": "Lorem ipsum dolor sit amet... (> 500 caractères)"
  }'
```

**Réponse 400 Bad Request** :
```json
{
  "statusCode": 400,
  "message": [
    "comment must be shorter than or equal to 500 characters"
  ],
  "error": "Bad Request"
}
```

---

## 📊 Vérifier la Base de Données

### Consulter les ratings

```sql
-- Se connecter à PostgreSQL
psql -U postgres -d toto_db

-- Voir toutes les notations
SELECT * FROM ratings ORDER BY created_at DESC;

-- Voir les notations d'une livraison spécifique
SELECT
  r.id,
  r.stars,
  r.comment,
  u1.email AS rated_by,
  u2.email AS rated_user,
  r.created_at
FROM ratings r
LEFT JOIN users u1 ON r.rated_by_id = u1.id
LEFT JOIN users u2 ON r.rated_user_id = u2.id
WHERE r.delivery_id = '{DELIVERY_ID}';

-- Moyenne des notations d'un livreur
SELECT
  rated_user_id,
  COUNT(*) as total_ratings,
  AVG(stars) as average_stars
FROM ratings
WHERE rated_user_id = '{DELIVERER_ID}'
GROUP BY rated_user_id;
```

### Vérifier les delivery_code

```sql
-- Voir les livraisons avec leur code
SELECT id, delivery_code, status, created_at
FROM deliveries
ORDER BY created_at DESC
LIMIT 10;

-- Vérifier l'unicité
SELECT delivery_code, COUNT(*)
FROM deliveries
WHERE delivery_code IS NOT NULL
GROUP BY delivery_code
HAVING COUNT(*) > 1;
-- (Doit retourner 0 lignes)
```

---

## 🔧 Debugging

### Vérifier les logs backend

```bash
tail -f /tmp/backend_start.log
```

### Activer les logs SQL

Modifier `src/app.module.ts` :
```typescript
logging: true  // Au lieu de configService.get('NODE_ENV') === 'development'
```

---

## ✅ Checklist de test

### Tests fonctionnels
- [ ] Créer une livraison → delivery_code généré automatiquement
- [ ] Vérifier que delivery_code est unique (créer plusieurs livraisons)
- [ ] Accepter livraison → Scanner QR pickup → Scanner QR delivery
- [ ] Client vérifie has_rated → false
- [ ] Client note le livreur → 201 Created
- [ ] Client vérifie has_rated → true
- [ ] Client récupère sa notation → 200 OK
- [ ] Livreur note le client → 201 Created
- [ ] Tentative double notation → 409 Conflict

### Tests validation
- [ ] Stars < 1 → 400 Bad Request
- [ ] Stars > 5 → 400 Bad Request
- [ ] Comment > 500 chars → 400 Bad Request
- [ ] Noter livraison non terminée → 400 Bad Request
- [ ] Noter livraison d'un autre client → 400 Bad Request

### Tests DB
- [ ] Index unique sur (delivery_id, rated_by_id) fonctionne
- [ ] Clés étrangères valides
- [ ] delivery_code unique

---

## 📝 Notes

- **Tokens JWT** : Expiration par défaut à 1h (access_token)
- **Refresh token** : Utiliser pour obtenir nouveau access_token
- **Swagger UI** : http://localhost:3000/api pour tests interactifs
- **Base de données** : PostgreSQL sur port 5432

---

**Bon test ! 🧪**
