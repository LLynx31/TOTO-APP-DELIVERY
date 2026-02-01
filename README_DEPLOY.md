# 🚀 Solution Complète de Déploiement - TOTO Backend

## 📌 Vue Générale

Cette solution fournit un **kit complet et professionnel** pour déployer et gérer le backend TOTO en production.

### ✨ Inclus dans cette solution:

✅ **Script de déploiement robuste** (`deploy-improved.sh`)
✅ **Documentation complète** (`DEPLOYMENT_GUIDE.md`)
✅ **Configuration systemd** (`toto-backend.service`)
✅ **Setup interactif** (`setup-initial.sh`)
✅ **Vérification prérequis** (`pre-deployment-check.sh`)
✅ **Configuration Nginx** (`nginx-config.conf`)
✅ **Outils d'administration** (`admin-tools.sh`)
✅ **Résumé détaillé** (`DEPLOYMENT_SUMMARY.md`)

---

## 🎯 QuickStart (5 minutes)

### 1️⃣ Sur votre serveur, cloner et configurer:

```bash
# Aller sur votre serveur
ssh root@your-server

# Créer le répertoire
mkdir -p /home/Nycaise/web/toto.tangagroup.com/app
cd /home/Nycaise/web/toto.tangagroup.com/app

# Cloner le repository
git clone https://github.com/votre-org/toto.tangagroup.com.git .

# Copier les scripts de déploiement
cp deploy-improved.sh setup-initial.sh pre-deployment-check.sh admin-tools.sh .
chmod +x *.sh
```

### 2️⃣ Setup initial:

```bash
sudo ./setup-initial.sh
# Suivre les prompts interactives
```

### 3️⃣ Vérifier les prérequis:

```bash
./pre-deployment-check.sh
```

### 4️⃣ Déployer:

```bash
sudo ./deploy-improved.sh
```

### 5️⃣ Vérifier:

```bash
systemctl status toto-backend
curl http://localhost:3000/api  # Swagger documentation
```

---

## 📚 Documentation

### Pour les administrateurs systèmes:
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guide complet de 500+ lignes
- **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - Résumé exécutif

### Pour les développeurs:
- [API_DOCUMENTATION.md](toto-backend/API_DOCUMENTATION.md) - Endpoints API
- [FLUTTER_INTEGRATION_GUIDE.md](toto-backend/FLUTTER_INTEGRATION_GUIDE.md) - Intégration mobile

---

## 🛠️ Scripts Disponibles

### Deploy Script (`deploy-improved.sh`)
**Objectif:** Automatiser le déploiement en production

**Étapes:**
1. Vérification des prérequis
2. Mise à jour du repository
3. Configuration d'environnement
4. Installation des dépendances
5. Build de l'application
6. Exécution des migrations DB
7. Redémarrage du service
8. Health checks

**Utilisation:**
```bash
sudo ./deploy-improved.sh
```

**Output:**
```
✅ Système (Node.js, pnpm, git)
✅ Environnement (.env configuré)
✅ Repository (à jour avec origin/master)
✅ Dépendances (pnpm install)
✅ Build (pnpm run build)
✅ Migrations (base de données)
✅ Service redémarré
✅ Health checks passés
```

---

### Setup Script (`setup-initial.sh`)
**Objectif:** Configuration initiale interactive

**Demande:**
- Chemin d'installation
- Utilisateur système
- Paramètres PostgreSQL
- Ports (API et WebSocket)

**Crée:**
- Fichier `.env` avec secrets JWT
- Utilisateur système
- Répertoires nécessaires
- Service systemd

**Utilisation:**
```bash
sudo ./setup-initial.sh
```

---

### Check Script (`pre-deployment-check.sh`)
**Objectif:** Vérifier les prérequis avant déploiement

**Vérifie:**
- Node.js >= 18.x
- pnpm/npm installés
- PostgreSQL client
- Fichiers de configuration
- Permissions d'écriture

**Utilisation:**
```bash
./pre-deployment-check.sh
# Output: ✅ Tous les prérequis OK
# ou    : ❌ X défauts trouvés
```

---

### Admin Tools (`admin-tools.sh`)
**Objectif:** Gestion et maintenance du service

**Menu interactif avec:**
- ✓ Démarrer/arrêter/redémarrer service
- ✓ Voir logs en temps réel
- ✓ Exécuter/voir état des migrations
- ✓ Backup/restore DB
- ✓ Redéploiement rapide
- ✓ Nettoyage des logs
- ✓ Vérification espace disque
- ✓ Voir les erreurs récentes

**Utilisation:**
```bash
sudo ./admin-tools.sh
```

---

## 🔐 Sécurité

### Variables d'environnement sensibles:
```bash
JWT_SECRET          # Généré avec: openssl rand -base64 32
JWT_REFRESH_SECRET  # Idem
DB_PASSWORD         # Changé depuis .env.example
```

### Permissions:
```bash
.env             # 600 (rw-------)
uploads/         # Propriétaire: appuser
logs/            # Propriétaire: appuser
```

### SSL/TLS:
```bash
nginx-config.conf  # Configuration Let's Encrypt intégrée
                   # Redirection HTTP → HTTPS
                   # Security headers
                   # Rate limiting
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────┐
│         Client (Flutter/Web)                     │
└──────────────────┬──────────────────────────────┘
                   │ HTTPS
                   ▼
┌─────────────────────────────────────────────────┐
│    Nginx Reverse Proxy (nginx-config.conf)      │
│    - SSL/TLS                                    │
│    - Compression gzip                           │
│    - Rate limiting                              │
│    - Security headers                           │
└──────────────┬──────────────────┬───────────────┘
               │ :3000            │ :3001 (WebSocket)
               ▼                  ▼
    ┌──────────────────┐  ┌──────────────────┐
    │  NestJS App      │  │  Socket.io       │
    │  dist/src/main.js│  │  Tracking GPS    │
    │  (systemd)       │  │                  │
    └────────┬─────────┘  └──────────────────┘
             │
             ▼
    ┌──────────────────┐
    │  PostgreSQL DB   │
    │  (typeorm)       │
    │  (migrations)    │
    └──────────────────┘
```

---

## 🔄 Flux de Déploiement

### Premier déploiement:
```
1. setup-initial.sh     → Configure tout
2. pre-deployment-check.sh → Vérifie prérequis
3. deploy-improved.sh   → Déploie l'application
```

### Redéploiement:
```
1. git pull           → Récupère le code
2. deploy-improved.sh → Redéploie et redémarre
```

### Maintenance:
```
admin-tools.sh → Menu interactif pour tous les outils
```

---

## 📝 Fichiers de Configuration

### `.env` (Créé par setup-initial.sh)
```env
NODE_ENV=production
PORT=3000
DB_HOST=localhost
DB_DATABASE=toto_db
JWT_SECRET=generated-by-openssl
# ... et plus
```

### `toto-backend.service` (Systemd)
- Auto-redémarrage en cas d'erreur
- Logs centralisés
- Dépendance PostgreSQL

### `nginx-config.conf`
- Reverse proxy vers :3000
- WebSocket vers :3001
- SSL/TLS avec Let's Encrypt
- Security headers
- Rate limiting

---

## 🧪 Tests

### Avant déploiement:
```bash
./pre-deployment-check.sh  # ✅ Tous les tests doivent passer
```

### Après déploiement:
```bash
curl https://api.toto.tangagroup.com/api  # Swagger
curl https://api.toto.tangagroup.com/health  # Si configuré
```

### Vérifier l'application:
```bash
systemctl status toto-backend      # Service actif?
tail -f /var/log/toto-backend.log  # Logs OK?
psql -U toto_user -d toto_db \c    # DB accessible?
```

---

## 🆘 Troubleshooting Rapide

| Problème | Commande |
|----------|----------|
| Service ne démarre pas | `journalctl -u toto-backend -n 50` |
| DB inaccessible | `psql -h localhost -U toto_user -d toto_db -c "SELECT 1;"` |
| Port occupé | `lsof -i :3000 && kill -9 <PID>` |
| Migrations échouent | `pnpm run migration:show` puis `pnpm run migration:revert` |
| Espace disque plein | `df -h` et `du -sh /var/log` |
| Voir les erreurs | `admin-tools.sh` → option 15 |

---

## 📞 Support

### Documentation:
1. **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guide complet (section Troubleshooting)
2. **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - Résumé exécutif
3. **[API_DOCUMENTATION.md](toto-backend/API_DOCUMENTATION.md)** - API endpoints
4. **Swagger UI**: `https://api.toto.tangagroup.com/api`

### Logs:
```bash
/var/log/toto-deploy.log      # Logs de déploiement
/var/log/toto-backend.log     # Logs de l'application
journalctl -u toto-backend    # Logs systemd
```

### Vérification:
```bash
./pre-deployment-check.sh     # Diagnostic systématique
./admin-tools.sh              # Menu d'administration
```

---

## 📋 Checklist de Déploiement

### Avant:
- [ ] Repository cloné
- [ ] Node.js 18+ installé
- [ ] PostgreSQL configuré
- [ ] Pre-deployment check passé
- [ ] Backup initial fait

### Pendant:
- [ ] `sudo ./setup-initial.sh` réussi
- [ ] `sudo ./deploy-improved.sh` réussi
- [ ] Service en state "active"
- [ ] Health check réussi

### Après:
- [ ] API répond (GET /api)
- [ ] Swagger documenté
- [ ] Logs sans erreurs
- [ ] DB migrations appliquées
- [ ] SSL/TLS fonctionne (pour prod)

---

## 🎓 Architecture Modulaire Backend

```
src/
├── auth/          # Authentification JWT
├── deliveries/    # Gestion des livraisons
├── tracking/      # Suivi GPS WebSocket
├── quotas/        # Packs prépayés
├── ratings/       # Évaluations
└── admin/         # Gestion administrateurs
```

**Chaque module est indépendant et testable.**

---

## 📈 Performance & Monitoring

### Monitoring recommandé:
```bash
# Service
systemctl status toto-backend

# Ressources
htop | grep node

# DB
psql -d toto_db -c "SELECT * FROM typeorm_migrations;"

# Logs
tail -f /var/log/toto-backend.log
```

### Alertes recommandées:
- Service down → Redémarrage automatique (systemd)
- Espace disque > 80% → Email
- Erreurs DB → Notification
- Latence API > 1s → Monitoring

---

## 🔐 Secrets & Configuration

### Où placer les secrets:
```bash
.env file (600 permissions)          # JWT secrets, DB password
/etc/systemd/system/...             # Env variables du service
Environment= dans le service file   # Variables d'environnement
```

### Jamais committer:
```
.env              # ✅ Dans .gitignore
*.key, *.pem      # ✅ Dans .gitignore
node_modules/     # ✅ Dans .gitignore
dist/             # ✅ Dans .gitignore
```

---

## 🚀 Prochaines Étapes

1. **Adapter les chemins** dans tous les scripts selon votre serveur
2. **Exécuter setup-initial.sh** pour configuration
3. **Tester pre-deployment-check.sh** pour validation
4. **Lancer deploy-improved.sh** pour déploiement
5. **Configurer Nginx** avec nginx-config.conf
6. **Configurer SSL** avec Let's Encrypt
7. **Mettre en place monitoring** (Datadog, New Relic, etc.)

---

## 📄 Fichiers Livrés

| Fichier | Type | Lignes | Description |
|---------|------|--------|-------------|
| `deploy-improved.sh` | Bash | 400+ | Script déploiement production |
| `setup-initial.sh` | Bash | 200+ | Configuration initiale interactive |
| `pre-deployment-check.sh` | Bash | 150+ | Vérification prérequis |
| `admin-tools.sh` | Bash | 300+ | Menu d'administration |
| `toto-backend.service` | Systemd | 50+ | Configuration service |
| `nginx-config.conf` | Nginx | 200+ | Reverse proxy & SSL |
| `DEPLOYMENT_GUIDE.md` | Markdown | 500+ | Documentation complète |
| `DEPLOYMENT_SUMMARY.md` | Markdown | 300+ | Résumé exécutif |
| `README_DEPLOY.md` | Markdown | - | Ce fichier |

**Total:** ~2000 lignes de configuration et documentation professionnelles

---

## ⭐ Points Forts

✅ **Production-Ready**: Toutes les meilleures pratiques respectées
✅ **Sécurisé**: Secrets, permissions, SSL configurés
✅ **Robuste**: Gestion d'erreurs, rollback, backups
✅ **Documenté**: Guides complets et détaillés
✅ **Automatisé**: Scripts paramétrables et réutilisables
✅ **Observable**: Logs structurés et monitoring intégré
✅ **Scalable**: Prêt pour évolutions et haute disponibilité
✅ **Maintenable**: Code clean, commenté, avec exemples

---

## 📞 Contact & Support

Pour toute question:
1. Consulter la [documentation complète](DEPLOYMENT_GUIDE.md)
2. Vérifier les [FAQ et troubleshooting](DEPLOYMENT_GUIDE.md#️-troubleshooting)
3. Exécuter `pre-deployment-check.sh` pour diagnostic
4. Vérifier les logs: `/var/log/toto-deploy.log`

---

**Créé le:** 1 février 2026
**Version:** 1.0
**État:** ✅ Production Ready

Happy Deploying! 🚀
