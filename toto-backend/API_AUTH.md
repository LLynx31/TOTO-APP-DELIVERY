# API Documentation - Module d'Authentification

## Base URL
```
http://localhost:3000
```

## Endpoints disponibles

### 1. Inscription Client
**POST** `/auth/client/register`

Permet à un nouveau client de créer un compte.

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "phone_number": "+22512345678",
  "full_name": "Jean Kouassi",
  "email": "jean@example.com",  // optionnel
  "password": "motdepasse123"
}
```

**Réponse Success (201):**
```json
{
  "user": {
    "id": "uuid",
    "phone_number": "+22512345678",
    "full_name": "Jean Kouassi",
    "email": "jean@example.com",
    "photo_url": null,
    "is_verified": false,
    "is_active": true,
    "created_at": "2025-11-28T19:15:41.376Z",
    "updated_at": "2025-11-28T19:15:41.376Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

### 2. Connexion Client
**POST** `/auth/client/login`

Permet à un client existant de se connecter.

**Body:**
```json
{
  "phone_number": "+22512345678",
  "password": "motdepasse123"
}
```

**Réponse Success (200):**
```json
{
  "user": { ... },
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

### 3. Inscription Livreur
**POST** `/auth/deliverer/register`

Permet à un nouveau livreur de créer un compte.

**Body:**
```json
{
  "phone_number": "+22598765432",
  "full_name": "Mamadou Traoré",
  "email": "mamadou@example.com",  // optionnel
  "password": "motdepasse123",
  "vehicle_type": "Moto",  // optionnel
  "license_plate": "AB-1234-CI"  // optionnel
}
```

**Réponse Success (201):**
```json
{
  "deliverer": {
    "id": "uuid",
    "phone_number": "+22598765432",
    "full_name": "Mamadou Traoré",
    "email": "mamadou@example.com",
    "vehicle_type": "Moto",
    "license_plate": "AB-1234-CI",
    "kyc_status": "pending",
    "is_available": false,
    "is_active": true,
    "is_verified": false,
    "total_deliveries": 0,
    "rating": "0.00",
    "created_at": "2025-11-28T19:15:54.259Z",
    "updated_at": "2025-11-28T19:15:54.259Z"
  },
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

### 4. Connexion Livreur
**POST** `/auth/deliverer/login`

Permet à un livreur existant de se connecter.

**Body:**
```json
{
  "phone_number": "+22598765432",
  "password": "motdepasse123"
}
```

**Réponse Success (200):**
```json
{
  "deliverer": { ... },
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

### 5. Rafraîchir le Token
**POST** `/auth/refresh`

Permet d'obtenir un nouveau access token en utilisant le refresh token.

**Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Réponse Success (200):**
```json
{
  "access_token": "nouveau_access_token",
  "refresh_token": "nouveau_refresh_token",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

### 6. Déconnexion
**POST** `/auth/logout`

Permet de révoquer un refresh token.

**Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Réponse Success (200):**
```json
{
  "message": "Logged out successfully"
}
```

---

## Codes d'erreur

### 400 - Bad Request
```json
{
  "statusCode": 400,
  "message": [
    "phone_number must be in format +225XXXXXXXX",
    "Password must be at least 6 characters long"
  ],
  "error": "Bad Request"
}
```

### 401 - Unauthorized
```json
{
  "statusCode": 401,
  "message": "Invalid credentials",
  "error": "Unauthorized"
}
```

### 409 - Conflict
```json
{
  "statusCode": 409,
  "message": "Phone number already registered",
  "error": "Conflict"
}
```

---

## Utilisation des Tokens

### Access Token
- **Durée de validité:** 1 heure
- **Utilisation:** À inclure dans le header `Authorization` pour toutes les requêtes protégées
- **Format:** `Authorization: Bearer <access_token>`

### Refresh Token
- **Durée de validité:** 7 jours
- **Utilisation:** Pour obtenir un nouveau access token via `/auth/refresh`
- **Stockage:** À conserver de manière sécurisée côté client

---

## Exemples avec curl

### Inscription Client
```bash
curl -X POST http://localhost:3000/auth/client/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+22512345678",
    "full_name": "Jean Kouassi",
    "password": "test123456"
  }'
```

### Connexion Client
```bash
curl -X POST http://localhost:3000/auth/client/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+22512345678",
    "password": "test123456"
  }'
```

### Utilisation du Token
```bash
curl -X GET http://localhost:3000/protected-route \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

## Sécurité

- ✅ Mots de passe hashés avec bcrypt (10 rounds)
- ✅ Tokens JWT signés avec secret
- ✅ Refresh tokens stockés en base de données
- ✅ Validation des numéros de téléphone ivoiriens (+225)
- ✅ Validation du format email
- ✅ Longueur minimale du mot de passe: 6 caractères
- ✅ Protection contre les doublons (phone_number, email)

---

## Tests réalisés

### ✅ Client Registration
- User créé avec succès
- Access token et refresh token générés
- Mot de passe hashé correctement

### ✅ Client Login
- Authentification réussie
- Nouveaux tokens générés

### ✅ Deliverer Registration
- Livreur créé avec KYC status "pending"
- Champs véhicule optionnels enregistrés
- Rating initialisé à 0.00

### ✅ Deliverer Login
- Authentification réussie pour livreur

---

## Prochaines étapes

Selon le plan d'implémentation, les prochains modules à développer sont:

1. **Module Deliveries** - CRUD des livraisons
2. **Module Tracking** - WebSocket pour suivi GPS temps réel
3. **Module Quotas** - Gestion des packs de livraisons
4. **Module Notifications** - Système de notifications push
5. **Admin Panel** - Interface d'administration web
