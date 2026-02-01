# 📋 Analyse du Backend TOTO & Guide de Déploiement

## 🔍 Analyse de l'Application Backend

### Architecture Générale
- **Framework**: NestJS 11.x (TypeScript)
- **Base de données**: PostgreSQL
- **ORM**: TypeORM
- **WebSocket**: Socket.io
- **Authentication**: JWT (Access & Refresh tokens)
- **Package Manager**: pnpm

### Modules Principaux

#### 1. **Auth Module** (`src/auth/`)
- JWT Authentication avec stratégies
- Login (clients & livreurs)
- Refresh tokens
- Decorators pour autorisation (@Roles, @CurrentUser)
- Guards pour protection des routes

#### 2. **Deliveries Module** (`src/deliveries/`)
- CRUD complet des livraisons
- État des livraisons (machine à états)
- Calcul automatique distance (Haversine)
- Calcul automatique prix
- QR codes uniques

#### 3. **Tracking Module** (`src/tracking/`)
- Suivi GPS en temps réel via WebSocket
- Historique de positions
- Rooms Socket.io par livraison

#### 4. **Quotas Module** (`src/quotas/`)
- Gestion packs prépayés (BASIC, STANDARD, PREMIUM, CUSTOM)
- Consommation automatique
- Remboursement en cas d'annulation
- Expiration automatique

#### 5. **Ratings Module** (`src/ratings/`)
- Système d'évaluation des livreurs
- Historique des notes

#### 6. **Admin Module** (`src/admin/`)
- Gestion KYC des livreurs
- Approbation des livreurs
- Gestion utilisateurs

### Scripts NPM Disponibles

```bash
pnpm run build              # Build production
pnpm run start:prod         # Démarrage production
pnpm run start              # Démarrage simple
pnpm run start:dev          # Mode watch dev
pnpm run migration:run      # Exécuter les migrations
pnpm run migration:generate # Générer migrations
pnpm run seed               # Seed base de données
pnpm run test               # Tests unitaires
pnpm run test:e2e           # Tests E2E
```

---

## ⚠️ Problèmes Identifiés dans le Script Original

### 1. **Typo dans la commande build**
```bash
# ❌ MAUVAIS
pnpm run buil

# ✅ CORRECT
pnpm run build
```

### 2. **Pas de gestion d'erreurs**
- Pas de vérification des étapes précédentes
- Pas de rollback en cas d'échec
- Pas de logs structurés

### 3. **Pas de vérification des prérequis**
- Node.js version non vérifiée
- Fichier .env non vérifiée
- Variables d'environnement manquantes

### 4. **Pas de gestion de la base de données**
- Pas de migrations
- Pas de backup avant déploiement
- Connexion DB non vérifiée

### 5. **Pas de gestion du service**
- Pas de redémarrage du service
- Pas de health check
- État du service non vérifié

### 6. **Pas de logs**
- Impossible de debugger les problèmes
- Pas d'historique des déploiements

---

## ✅ Améliorations du Nouveau Script

### 1. **Vérifications Préalables Robustes**
```bash
✓ Node.js >= 18.x
✓ pnpm installé
✓ Git disponible
✓ PostgreSQL CLI (optionnel)
✓ Répertoires existants
```

### 2. **Gestion d'Erreurs Complète**
```bash
✓ Exit on error (set -e)
✓ Trap pour capture d'erreurs
✓ Messages d'erreur détaillés
✓ Rollback de git en cas d'échec
```

### 3. **Gestion de la Base de Données**
```bash
✓ Backup avant déploiement
✓ Exécution des migrations
✓ Vérification des variables DB
✓ Historique des backups (5 derniers gardés)
```

### 4. **Gestion du Service**
```bash
✓ Intégration systemd
✓ Redémarrage du service
✓ Vérification du service actif
✓ Fallback si systemd indisponible
```

### 5. **Logs Structurés et Colorisés**
```bash
✓ Timestamps sur chaque ligne
✓ Couleurs pour les niveaux (INFO, SUCCESS, WARNING, ERROR)
✓ Fichier log persistant
✓ Affichage console + fichier
```

### 6. **Health Check**
```bash
✓ Vérification que l'API répond
✓ 30 tentatives avec delai
✓ Endpoint /health (si disponible)
```

---

## 🚀 Instructions de Déploiement

### Prérequis Serveur

1. **Installer Node.js 18+**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

2. **Installer pnpm**
```bash
npm install -g pnpm
# ou
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

3. **PostgreSQL installé et configuré**
```bash
# Créer la base de données et l'utilisateur
psql -U postgres
CREATE DATABASE toto_db;
CREATE USER toto_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE toto_db TO toto_user;
\q
```

4. **Cloner le repository**
```bash
cd /home/Nycaise/web/
git clone https://github.com/votre-org/toto.tangagroup.com.git
cd toto.tangagroup.com/app
```

### Configuration du Fichier .env

```bash
cp .env.example .env
# Éditer avec vos valeurs de production
nano .env
```

**Variables critiques**:
```env
NODE_ENV=production
PORT=3000
WEBSOCKET_PORT=3001

# Database - DOIT ÊTRE CORRECTEMENT CONFIGURÉE
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=toto_user
DB_PASSWORD=your_secure_password
DB_DATABASE=toto_db

# JWT - CHANGE CES VALEURS!
JWT_SECRET=your-very-long-and-random-secret-string-change-in-production
JWT_EXPIRES_IN=1h
JWT_REFRESH_SECRET=another-very-long-and-random-secret
JWT_REFRESH_EXPIRES_IN=7d

# Upload
MAX_FILE_SIZE=5242880
UPLOAD_DEST=/var/uploads/toto
```

### Configuration Systemd (Recommandé)

Créer `/etc/systemd/system/toto-backend.service`:

```ini
[Unit]
Description=TOTO Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=appuser
WorkingDirectory=/home/Nycaise/web/toto.tangagroup.com/app
Environment="PATH=/home/appuser/.nvm/versions/node/v18.x.x/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
EnvironmentFile=/home/Nycaise/web/toto.tangagroup.com/app/.env
ExecStart=/home/appuser/.nvm/versions/node/v18.x.x/bin/node dist/src/main.js
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/toto-backend.log
StandardError=append:/var/log/toto-backend.log

[Install]
WantedBy=multi-user.target
```

Activer le service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable toto-backend
sudo systemctl start toto-backend
```

### Utilisation du Script de Déploiement

1. **Rendre le script exécutable**
```bash
chmod +x deploy-improved.sh
```

2. **Adapter les variables du script**
Éditer les variables de configuration au début du script:
```bash
DEPLOY_DIR="/home/Nycaise/web/toto.tangagroup.com/app"
BACKUP_DIR="/home/Nycaise/web/backups"
LOG_FILE="/var/log/toto-deploy.log"
APP_USER="appuser"
SYSTEMD_SERVICE="toto-backend"
```

3. **Exécuter le déploiement**
```bash
# Depuis n'importe quel répertoire
sudo ./deploy-improved.sh

# Ou avec bash explicite
sudo bash deploy-improved.sh
```

4. **Vérifier les logs**
```bash
tail -f /var/log/toto-deploy.log
tail -f /var/log/toto-backend.log
```

---

## 📊 Flux de Déploiement Détaillé

```
START
  ↓
[1] Vérifier les prérequis (Node, pnpm, git, DB)
  ↓
[2] Mettre à jour le repository Git
  ↓
[3] Configurer l'environnement (.env, variables)
  ↓
[4] Sauvegarder la base de données (backup)
  ↓
[5] Installer les dépendances (pnpm install)
  ↓
[6] Build l'application (pnpm run build)
  ↓
[7] Exécuter les migrations DB
  ↓
[8] Nettoyer (cleanup)
  ↓
[9] Redémarrer le service systemd
  ↓
[10] Vérifier la santé (health check)
  ↓
SUCCESS ✅
```

---

## 🔄 Rollback en Cas d'Erreur

Si le déploiement échoue:

1. **Vérifier les logs**
```bash
tail -f /var/log/toto-deploy.log
```

2. **Vérifier l'état du service**
```bash
systemctl status toto-backend
journalctl -u toto-backend -n 50 --no-pager
```

3. **Restaurer une sauvegarde DB (si nécessaire)**
```bash
PGPASSWORD="password" psql -h localhost -U toto_user -d toto_db < /home/Nycaise/web/backups/toto_db_20260201_150000.sql
```

4. **Redémarrer le service**
```bash
systemctl restart toto-backend
```

---

## 🧪 Tests Avant Production

### 1. Test Local
```bash
cd /home/lynx/Documents/TANGA/APP_toto_test/toto-backend
pnpm install
pnpm run build
NODE_ENV=test pnpm run test
```

### 2. Test E2E
```bash
pnpm run test:e2e
```

### 3. Vérifier les endpoints
```bash
# Swagger UI
http://localhost:3000/api

# Health check (si configuré)
curl http://localhost:3000/health

# Login test
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'
```

---

## 📈 Monitoring Post-Déploiement

### Logs
```bash
# Logs de l'application
sudo journalctl -u toto-backend -f

# Logs du déploiement
tail -f /var/log/toto-deploy.log

# Logs complets
tail -f /var/log/syslog | grep toto
```

### Vérifications
```bash
# État du service
systemctl status toto-backend

# Connexion DB
psql -h localhost -U toto_user -d toto_db -c "SELECT count(*) FROM typeorm_migrations;"

# Ports actifs
netstat -tlnp | grep -E '3000|3001'

# Utilisation ressources
ps aux | grep "node"
```

---

## 🛠️ Maintenance

### Logs de Déploiement
```bash
# Voir l'historique des déploiements
ls -lh /var/log/toto-deploy.log*

# Archiver les anciens logs
gzip /var/log/toto-deploy.log.1
```

### Backups
```bash
# Localisation des backups
ls -lh /home/Nycaise/web/backups/

# Taille des backups
du -sh /home/Nycaise/web/backups/

# Restaurer un backup spécifique
PGPASSWORD="password" psql -h localhost -U toto_user -d toto_db < /chemin/au/backup.sql
```

### Mise à jour de dépendances
```bash
pnpm outdated
pnpm upgrade --interactive
```

---

## ❓ Troubleshooting

### Problème: Service ne démarre pas
```bash
# Vérifier les logs
journalctl -u toto-backend -n 100 --no-pager

# Vérifier les variables d'environnement
cat /home/Nycaise/web/toto.tangagroup.com/app/.env

# Vérifier la connexion DB
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -c "SELECT 1;"
```

### Problème: Migration échoue
```bash
# Vérifier l'état des migrations
pnpm run migration:show

# Vérifier les fichiers de migration
ls -la dist/migrations/

# Révert et retry
pnpm run migration:revert
pnpm run migration:run
```

### Problème: Port déjà utilisé
```bash
# Trouver le processus
lsof -i :3000

# Tuer le processus
kill -9 <PID>

# Ou changer le port dans .env
echo "PORT=3001" >> .env
```

### Problème: Espace disque insuffisant
```bash
# Vérifier l'espace disque
df -h

# Nettoyer les anciens backups
find /home/Nycaise/web/backups/ -mtime +30 -delete

# Nettoyer les modules
rm -rf node_modules/ && pnpm install
```

---

## 📞 Support & Contacts

Pour plus d'informations:
- [Documentation NestJS](https://docs.nestjs.com)
- [Documentation TypeORM](https://typeorm.io)
- [API Documentation Swagger](http://localhost:3000/api)

---

**Document généré le**: 1 février 2026
**Version**: 1.0
