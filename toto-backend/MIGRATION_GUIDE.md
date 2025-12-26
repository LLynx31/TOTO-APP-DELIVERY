# Guide des Migrations - TOTO Backend

Guide complet pour gérer les migrations de base de données avec TypeORM.

## 📋 Table des matières

- [Comprendre les migrations](#comprendre-les-migrations)
- [Configuration](#configuration)
- [Migrations manuelles SQL](#migrations-manuelles-sql)
- [Migrations TypeORM](#migrations-typeorm)
- [Déploiement en production](#déploiement-en-production)
- [Commandes utiles](#commandes-utiles)

---

## 🎯 Comprendre les migrations

### Mode développement vs Production

**Développement** (actuellement configuré):
- `synchronize: true` dans [src/app.module.ts](src/app.module.ts:29)
- TypeORM crée/modifie automatiquement les tables selon les entités
- ⚠️ Dangereux en production (risque de perte de données)

**Production** (recommandé):
- `synchronize: false`
- Utiliser des migrations versionnées
- Contrôle total sur les changements de schéma

---

## ⚙️ Configuration

### 1. Fichier DataSource créé

Le fichier [src/data-source.ts](src/data-source.ts) a été créé pour gérer les migrations.

### 2. Mettre à jour package.json

Ajoutez ces scripts dans votre `package.json`:

```json
{
  "scripts": {
    "typeorm": "typeorm-ts-node-commonjs",
    "migration:generate": "pnpm typeorm migration:generate -d src/data-source.ts",
    "migration:run": "pnpm typeorm migration:run -d src/data-source.ts",
    "migration:revert": "pnpm typeorm migration:revert -d src/data-source.ts",
    "migration:show": "pnpm typeorm migration:show -d src/data-source.ts",
    "migration:create": "pnpm typeorm migration:create"
  }
}
```

---

## 📝 Migrations manuelles SQL

### Migration existante: Rating System

Une migration SQL manuelle existe: [migrations/001_add_rating_system.sql](migrations/001_add_rating_system.sql)

#### Exécuter cette migration manuellement

**Option 1: Via psql**
```bash
# Se connecter à la base de données
psql -U <username> -d toto_db

# Exécuter le fichier SQL
\i migrations/001_add_rating_system.sql

# Vérifier que ça a fonctionné
\dt  # Liste les tables
\d ratings  # Affiche la structure de la table ratings
```

**Option 2: Directement depuis le terminal**
```bash
psql -U <username> -d toto_db -f migrations/001_add_rating_system.sql
```

**Option 3: Avec la variable d'environnement**
```bash
# En utilisant les variables .env
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USERNAME -d $DB_DATABASE -f migrations/001_add_rating_system.sql
```

#### Vérifier que la migration a été appliquée

```bash
psql -U <username> -d toto_db -c "SELECT * FROM ratings LIMIT 1;"
psql -U <username> -d toto_db -c "SELECT delivery_code FROM deliveries LIMIT 5;"
```

---

## 🔄 Migrations TypeORM (Automatiques)

### 1. Générer une migration à partir de changements d'entités

Quand vous modifiez une entité TypeORM:

```bash
# 1. Compiler le code TypeScript
pnpm run build

# 2. Générer la migration
pnpm run migration:generate src/migrations/NomDeLaMigration

# Exemple:
pnpm run migration:generate src/migrations/AddUserProfilePicture
```

TypeORM compare automatiquement les entités avec la base de données et génère le code de migration.

### 2. Créer une migration vide (pour logique custom)

```bash
pnpm run migration:create src/migrations/AddCustomLogic
```

Ensuite, éditez le fichier généré dans `src/migrations/`.

### 3. Exécuter les migrations

```bash
# Compiler d'abord
pnpm run build

# Exécuter toutes les migrations en attente
pnpm run migration:run
```

### 4. Annuler la dernière migration

```bash
pnpm run migration:revert
```

### 5. Voir l'état des migrations

```bash
pnpm run migration:show
```

Affiche:
- ✅ Migrations déjà exécutées
- ⏳ Migrations en attente

---

## 🚀 Déploiement en production

### Workflow recommandé

#### 1. En développement

```bash
# Modifier une entité (ex: src/auth/entities/user.entity.ts)
# Ajouter un nouveau champ par exemple

# Build le projet
pnpm run build

# Générer la migration
pnpm run migration:generate src/migrations/AddUserNewField

# Tester la migration localement
pnpm run migration:run

# Vérifier que tout fonctionne
pnpm run start:dev

# Si problème, rollback
pnpm run migration:revert
```

#### 2. Avant le déploiement

```bash
# Commiter les migrations dans git
git add src/migrations/
git commit -m "feat: Add user new field migration"
git push
```

#### 3. Sur le serveur de production

```bash
# 1. Pull le code
git pull origin main

# 2. Installer les dépendances
pnpm install

# 3. Build le projet
pnpm run build

# 4. BACKUP de la base de données (IMPORTANT!)
pg_dump -U <username> -d toto_db > backup_$(date +%Y%m%d_%H%M%S).sql

# 5. Exécuter les migrations
NODE_ENV=production pnpm run migration:run

# 6. Redémarrer l'application
pm2 restart toto-backend
# ou
systemctl restart toto-backend
```

---

## 📚 Commandes utiles

### Gestion des migrations

| Commande | Description |
|----------|-------------|
| `pnpm run migration:generate src/migrations/Name` | Générer migration depuis changements entités |
| `pnpm run migration:create src/migrations/Name` | Créer migration vide |
| `pnpm run migration:run` | Exécuter migrations en attente |
| `pnpm run migration:revert` | Annuler dernière migration |
| `pnpm run migration:show` | Afficher statut migrations |

### Base de données PostgreSQL

```bash
# Se connecter à la base
psql -U <username> -d toto_db

# Lister les tables
\dt

# Voir la structure d'une table
\d <nom_table>

# Voir les migrations TypeORM exécutées
SELECT * FROM typeorm_migrations ORDER BY timestamp DESC;

# Backup de la base
pg_dump -U <username> -d toto_db > backup.sql

# Restaurer un backup
psql -U <username> -d toto_db < backup.sql

# Créer une nouvelle base (pour test)
createdb -U <username> toto_db_test
```

---

## ⚠️ Bonnes pratiques

### ✅ À FAIRE

1. **Toujours backup** avant migration en production
   ```bash
   pg_dump -U postgres -d toto_db > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Tester les migrations** en environnement de staging d'abord

3. **Commiter les migrations** dans le contrôle de version (git)

4. **Utiliser des noms descriptifs**
   ```bash
   migration:generate src/migrations/AddUserEmailVerification
   ```

5. **Documenter les migrations complexes** avec des commentaires

6. **Vérifier l'état avant migration**
   ```bash
   pnpm run migration:show
   ```

### ❌ À ÉVITER

1. ❌ **NE JAMAIS** utiliser `synchronize: true` en production
2. ❌ **NE JAMAIS** modifier une migration déjà exécutée en production
3. ❌ **NE JAMAIS** supprimer une migration exécutée
4. ❌ **NE PAS** exécuter des migrations sans backup
5. ❌ **NE PAS** éditer manuellement la table `typeorm_migrations`

---

## 🔧 Résolution de problèmes

### Problème: "Migration already exists"

```bash
# Voir les migrations exécutées
pnpm run migration:show

# Si besoin de refaire une migration (DANGER!)
# 1. Revert
pnpm run migration:revert

# 2. Supprimer le fichier de migration
rm src/migrations/MigrationProblematique.ts

# 3. Regénérer
pnpm run migration:generate src/migrations/NewName
```

### Problème: Connexion à la base de données

```bash
# Vérifier les variables d'environnement
cat .env

# Tester la connexion
psql -h $DB_HOST -p $DB_PORT -U $DB_USERNAME -d $DB_DATABASE

# Vérifier que PostgreSQL est lancé
systemctl status postgresql
# ou
ps aux | grep postgres
```

### Problème: Migration échouée

```bash
# 1. Voir l'erreur détaillée
pnpm run migration:run --verbose

# 2. Rollback si nécessaire
pnpm run migration:revert

# 3. Restaurer le backup
psql -U postgres -d toto_db < backup_20251222_120000.sql

# 4. Corriger la migration et réessayer
```

---

## 📖 Exemple complet: Ajouter un champ à User

### 1. Modifier l'entité

Éditer `src/auth/entities/user.entity.ts`:

```typescript
@Column({ nullable: true })
date_of_birth: Date;
```

### 2. Générer la migration

```bash
pnpm run build
pnpm run migration:generate src/migrations/AddUserDateOfBirth
```

### 3. Vérifier le fichier généré

```typescript
// src/migrations/TIMESTAMP-AddUserDateOfBirth.ts
export class AddUserDateOfBirth implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            ALTER TABLE "users"
            ADD "date_of_birth" TIMESTAMP
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            ALTER TABLE "users"
            DROP COLUMN "date_of_birth"
        `);
    }
}
```

### 4. Exécuter

```bash
# En développement
pnpm run migration:run

# En production (avec backup)
pg_dump -U postgres -d toto_db > backup.sql
NODE_ENV=production pnpm run migration:run
```

---

## 🎯 Checklist de migration en production

- [ ] Tester la migration en développement
- [ ] Tester la migration en staging
- [ ] Créer un backup de la base de données
- [ ] Vérifier l'état actuel: `pnpm run migration:show`
- [ ] Build du projet: `pnpm run build`
- [ ] Exécuter: `NODE_ENV=production pnpm run migration:run`
- [ ] Vérifier que l'application fonctionne
- [ ] En cas d'erreur: `pnpm run migration:revert` + restaurer backup
- [ ] Logger la migration exécutée

---

**Version**: 1.0.0
**Dernière mise à jour**: Décembre 2025
**Statut**: ✅ Configuration complète des migrations TypeORM
