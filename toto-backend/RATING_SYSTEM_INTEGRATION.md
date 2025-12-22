# 🎯 Intégration du Système de Notation - TOTO Backend

## 📋 Vue d'ensemble

Cette documentation détaille l'intégration du système de notation bidirectionnel et du code de validation 4 chiffres dans le backend TOTO.

**Date d'intégration** : Décembre 2025
**Modules affectés** : Deliveries, Ratings (nouveau)

---

## ✅ Modifications apportées

### 1. Module Deliveries - Code 4 chiffres

#### Fichier : `src/deliveries/entities/delivery.entity.ts`

**Ajout du champ** :
```typescript
@Column({ type: 'varchar', length: 4, unique: true })
delivery_code: string;
```

#### Fichier : `src/deliveries/deliveries.service.ts`

**Nouvelle méthode** :
```typescript
private async generateDeliveryCode(): Promise<string>
```

Cette méthode génère un code unique de 4 chiffres (1000-9999) et vérifie qu'il n'existe pas déjà dans la base de données.

**Modification de `create()`** :
- Appelle `generateDeliveryCode()` lors de la création
- Stocke le code dans `delivery.delivery_code`

---

### 2. Nouveau Module : Ratings

#### Structure créée

```
src/ratings/
├── entities/
│   └── rating.entity.ts
├── dto/
│   ├── create-rating.dto.ts
│   └── rating-response.dto.ts
├── ratings.controller.ts
├── ratings.service.ts
└── ratings.module.ts
```

#### Entity : `rating.entity.ts`

```typescript
@Entity('ratings')
export class Rating {
  id: string;                  // UUID
  delivery_id: string;         // ID de la livraison notée
  rated_by_id: string;         // ID de celui qui note
  rated_user_id: string;       // ID de celui qui est noté
  stars: number;               // 1-5 étoiles
  comment?: string;            // Commentaire optionnel (max 500 caractères)
  created_at: Date;            // Date de création
}
```

**Contraintes** :
- Index unique sur `(delivery_id, rated_by_id)` → Un utilisateur ne peut noter qu'une fois par livraison
- Contraintes de clés étrangères vers `deliveries` et `users`

---

## 🔌 Endpoints API

### Ratings

#### 1. Noter une livraison

**POST** `/deliveries/:id/rate`

**Headers** :
```
Authorization: Bearer {JWT_TOKEN}
```

**Body** :
```json
{
  "stars": 5,
  "comment": "Excellent service, très rapide et professionnel !" // optionnel
}
```

**Response 201** :
```json
{
  "id": "uuid",
  "delivery_id": "uuid",
  "rated_by_id": "uuid",
  "rated_user_id": "uuid",
  "stars": 5,
  "comment": "Excellent service...",
  "created_at": "2025-12-20T10:30:00.000Z"
}
```

**Erreurs** :
- `400` : Livraison non terminée ou données invalides
- `404` : Livraison non trouvée
- `409` : Vous avez déjà noté cette livraison

---

#### 2. Obtenir la notation d'une livraison

**GET** `/deliveries/:id/rating`

**Headers** :
```
Authorization: Bearer {JWT_TOKEN}
```

**Response 200** :
```json
{
  "id": "uuid",
  "delivery_id": "uuid",
  "rated_by_id": "uuid",
  "rated_user_id": "uuid",
  "stars": 5,
  "comment": "...",
  "created_at": "2025-12-20T10:30:00.000Z"
}
```

Ou `null` si aucune notation n'existe.

---

#### 3. Vérifier si l'utilisateur a déjà noté

**GET** `/deliveries/:id/has-rated`

**Headers** :
```
Authorization: Bearer {JWT_TOKEN}
```

**Response 200** :
```json
{
  "has_rated": true
}
```

---

## 🔄 Workflow complet

### Scénario : Client note le livreur

1. **Livraison terminée** : Le livreur scanne le QR code delivery → statut = `delivered`

2. **Client reçoit notification** : "Votre colis est livré ! Notez votre expérience"

3. **Client ouvre l'app** :
   - App vérifie si déjà noté : `GET /deliveries/{id}/has-rated`
   - Si `has_rated: false`, affiche l'écran de notation

4. **Client soumet sa note** :
   ```
   POST /deliveries/{id}/rate
   {
     "stars": 5,
     "comment": "Très professionnel"
   }
   ```

5. **Backend valide** :
   - ✓ Livraison existe ?
   - ✓ Statut = `delivered` ?
   - ✓ Client fait partie de la livraison ?
   - ✓ Pas déjà noté ?
   - ✓ Stars entre 1-5 ?
   - ✓ Commentaire < 500 caractères ?

6. **Backend sauvegarde** :
   - Crée l'entrée dans `ratings`
   - Détermine automatiquement `rated_user_id` (le livreur)

7. **App affiche écran de félicitation** avec confetti

---

### Scénario : Livreur note le client

**Même workflow** mais inversé :
- Le livreur note après avoir scanné le QR code delivery
- `rated_user_id` sera automatiquement le client

---

## 📊 Base de données

### Table : `deliveries`

**Nouveau champ** :
```sql
delivery_code VARCHAR(4) UNIQUE NOT NULL
```

**Exemple** :
```
id: "123e4567-e89b-12d3-a456-426614174000"
delivery_code: "4729"
```

---

### Table : `ratings` (nouvelle)

```sql
CREATE TABLE ratings (
  id UUID PRIMARY KEY,
  delivery_id UUID NOT NULL REFERENCES deliveries(id),
  rated_by_id UUID NOT NULL REFERENCES users(id),
  rated_user_id UUID NOT NULL REFERENCES users(id),
  stars INTEGER CHECK (stars >= 1 AND stars <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(delivery_id, rated_by_id)
);
```

---

## 🚀 Déploiement

### En développement (automatique)

Le backend utilise `synchronize: true` donc les changements de schéma sont appliqués automatiquement au démarrage.

```bash
npm run start:dev
```

---

### En production (migration manuelle)

**Étape 1** : Exécuter la migration SQL

```bash
psql -U postgres -d toto_db -f migrations/001_add_rating_system.sql
```

**Étape 2** : Redémarrer le backend

```bash
npm run build
npm run start:prod
```

---

## 🧪 Tests

### Test manuel avec cURL

#### 1. Créer une livraison et obtenir son ID

```bash
# Login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"client@test.com","password":"password"}'

# Créer livraison (récupérer le delivery_id et delivery_code dans la réponse)
```

#### 2. Marquer la livraison comme livrée (en tant que livreur)

```bash
curl -X PATCH http://localhost:3000/deliveries/{delivery_id} \
  -H "Authorization: Bearer {DELIVERER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"status":"delivered"}'
```

#### 3. Noter la livraison (en tant que client)

```bash
curl -X POST http://localhost:3000/deliveries/{delivery_id}/rate \
  -H "Authorization: Bearer {CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"stars":5,"comment":"Super service !"}'
```

#### 4. Vérifier la notation

```bash
curl -X GET http://localhost:3000/deliveries/{delivery_id}/rating \
  -H "Authorization: Bearer {CLIENT_TOKEN}"
```

---

## 📝 Validations

### CreateRatingDto

- `stars` : **Obligatoire**, Integer entre 1 et 5
- `comment` : **Optionnel**, String max 500 caractères

### Business Rules

1. ✅ Seules les livraisons avec statut `delivered` peuvent être notées
2. ✅ Seuls le client ou le livreur de la livraison peuvent noter
3. ✅ Un utilisateur ne peut noter qu'une fois par livraison
4. ✅ Le système détermine automatiquement qui est noté (client vs livreur)

---

## 🔐 Sécurité

- **Authentication** : JWT via `JwtAuthGuard`
- **Authorization** : Vérification que l'utilisateur fait partie de la livraison
- **Validation** : class-validator sur tous les DTOs
- **Contraintes DB** : Index unique pour éviter les doublons

---

## 📈 Métriques disponibles

### Endpoint bonus (à implémenter côté frontend si besoin)

Le `RatingsService` expose des méthodes supplémentaires :

```typescript
// Obtenir toutes les notations d'un utilisateur
getRatingsForUser(userId: string): Promise<RatingResponseDto[]>

// Obtenir la moyenne et le nombre de notations
getAverageRating(userId: string): Promise<{ average: number; count: number }>
```

Ces méthodes peuvent être utilisées pour afficher le profil du livreur/client.

---

## ✅ Checklist d'intégration

### Backend
- [x] Entity `Rating` créée
- [x] DTOs créés et validés
- [x] Service avec business logic
- [x] Controller avec endpoints
- [x] Module exporté
- [x] Intégration dans `AppModule`
- [x] Champ `delivery_code` ajouté à `Delivery`
- [x] Génération automatique du code 4 chiffres
- [x] Migration SQL créée

### Tests
- [ ] Test création de rating valide
- [ ] Test création rating avec livraison non terminée (doit échouer)
- [ ] Test double notation (doit échouer)
- [ ] Test validation stars (1-5)
- [ ] Test validation comment (max 500 chars)

---

## 🎯 Prochaines étapes

### Fonctionnalités additionnelles possibles

1. **Notifications push** : Notifier l'utilisateur quand il peut noter
2. **SMS code delivery** : Envoyer le code 4 chiffres par SMS au destinataire
3. **Statistiques** : Endpoint pour statistiques de notation par utilisateur
4. **Modération** : Système pour signaler les commentaires inappropriés
5. **Réponses** : Permettre aux utilisateurs notés de répondre aux commentaires

---

## 📞 Support

Pour toute question concernant cette intégration :
- Vérifier la documentation Swagger : `http://localhost:3000/api/docs`
- Consulter les logs en mode développement
- Tester avec Postman ou cURL

---

**Développé avec** ❤️ **par Claude Sonnet 4.5**
**Date** : Décembre 2025
