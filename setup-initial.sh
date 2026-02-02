#!/bin/bash

# ========================================
# SCRIPT DE CONFIGURATION INITIALE
# Setup complet du backend TOTO
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CONFIGURATION INITIALE TOTO BACKEND${NC}"
echo -e "${BLUE}========================================${NC}"

# Demander les informations
read -p "Chemin d'installation (défaut: /home/Nycaise/web/toto.tangagroup.com/app/TOTO-APP-DELIVERY/toto-backend): " INSTALL_PATH
INSTALL_PATH=${INSTALL_PATH:-/home/Nycaise/web/toto.tangagroup.com/app/TOTO-APP-DELIVERY/toto-backend}

read -p "Utilisateur système (défaut: appuser): " APP_USER
APP_USER=${APP_USER:-appuser}

read -p "Hôte PostgreSQL (défaut: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Port PostgreSQL (défaut: 5432): " DB_PORT
DB_PORT=${DB_PORT:-5432}

read -p "Utilisateur DB (défaut: toto_user): " DB_USER
DB_USER=${DB_USER:-toto_user}

read -sp "Mot de passe DB: " DB_PASS
echo

read -p "Nom de la base de données (défaut: toto_db): " DB_NAME
DB_NAME=${DB_NAME:-toto_db}

read -p "Port de l'application (défaut: 3000): " APP_PORT
APP_PORT=${APP_PORT:-3000}

read -p "Port WebSocket (défaut: 3001): " WS_PORT
WS_PORT=${WS_PORT:-3001}

# Créer le secret JWT
JWT_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_SECRET=$(openssl rand -base64 32)

echo -e "${BLUE}✓ Configuration en cours...${NC}"

# Créer utilisateur système AVANT d'utiliser chown
if ! id "$APP_USER" &>/dev/null; then
    echo -e "${BLUE}Création de l'utilisateur système '$APP_USER'...${NC}"
    useradd -r -s /bin/bash -d "$INSTALL_PATH" "$APP_USER" || {
        echo -e "${RED}✗ Erreur: Impossible de créer l'utilisateur '$APP_USER'${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Utilisateur système '$APP_USER' créé${NC}"
else
    echo -e "${YELLOW}⚠ Utilisateur '$APP_USER' existe déjà${NC}"
fi

# Créer le fichier .env
cat > "$INSTALL_PATH/.env" << EOF
# Application
NODE_ENV=production
PORT=$APP_PORT

# Database
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USERNAME=$DB_USER
DB_PASSWORD=$DB_PASS
DB_DATABASE=$DB_NAME

# JWT
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=1h
JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET
JWT_REFRESH_EXPIRES_IN=7d

# File Upload
MAX_FILE_SIZE=5242880
UPLOAD_DEST=/var/uploads/toto

# WebSocket
WEBSOCKET_PORT=$WS_PORT

# CORS
CORS_ORIGIN=https://toto.tangagroup.com
EOF

chmod 600 "$INSTALL_PATH/.env"

echo -e "${GREEN}✓ Fichier .env créé${NC}"

# Créer les répertoires nécessaires
mkdir -p /var/uploads/toto
mkdir -p /var/log
chown -R "$APP_USER:$APP_USER" /var/uploads/toto

echo -e "${GREEN}✓ Répertoires créés${NC}"

# Définir les permissions
chown -R "$APP_USER:$APP_USER" "$INSTALL_PATH"

echo -e "${GREEN}✓ Permissions définies${NC}"

# Copier le fichier service systemd
SYSTEMD_PATH="/etc/systemd/system/toto-backend.service"
if [ -f "toto-backend.service" ]; then
    # Adapter le chemin dans le service
    sed "s|/home/Nycaise/web/toto.tangagroup.com/app|$INSTALL_PATH|g" \
        "toto-backend.service" > "$SYSTEMD_PATH"
    
    sed -i "s|User=appuser|User=$APP_USER|g" "$SYSTEMD_PATH"
    sed -i "s|Group=appuser|Group=$APP_USER|g" "$SYSTEMD_PATH"
    
    chmod 644 "$SYSTEMD_PATH"
    echo -e "${GREEN}✓ Service systemd installé${NC}"
else
    echo -e "${YELLOW}⚠ Fichier toto-backend.service non trouvé${NC}"
fi

# Installation des dépendances
echo -e "${BLUE}Installation des dépendances...${NC}"
cd "$INSTALL_PATH"

if command -v pnpm &> /dev/null; then
    pnpm install
    echo -e "${GREEN}✓ Dépendances installées avec pnpm${NC}"
elif command -v npm &> /dev/null; then
    npm install
    echo -e "${GREEN}✓ Dépendances installées avec npm${NC}"
else
    echo -e "${RED}✗ npm ou pnpm non trouvé!${NC}"
    exit 1
fi

# Build
echo -e "${BLUE}Build de l'application...${NC}"
if command -v pnpm &> /dev/null; then
    pnpm run build
else
    npm run build
fi
echo -e "${GREEN}✓ Application buildée${NC}"

# Reload systemd
if command -v systemctl &> /dev/null; then
    systemctl daemon-reload
    echo -e "${GREEN}✓ systemd rechargé${NC}"
fi

# Afficher le résumé
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CONFIGURATION TERMINÉE!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "📍 Chemin d'installation: ${BLUE}$INSTALL_PATH${NC}"
echo -e "👤 Utilisateur: ${BLUE}$APP_USER${NC}"
echo -e "🗄️  Base de données: ${BLUE}$DB_NAME @ $DB_HOST:$DB_PORT${NC}"
echo -e "🔌 Port API: ${BLUE}$APP_PORT${NC}"
echo -e "🔌 Port WebSocket: ${BLUE}$WS_PORT${NC}"
echo ""
echo "Prochaines étapes:"
echo "1. Configurer PostgreSQL:"
echo "   sudo -u postgres psql"
echo "   CREATE DATABASE $DB_NAME;"
echo "   CREATE USER $DB_USER WITH PASSWORD 'votre_mot_de_passe';"
echo "   GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
echo ""
echo "2. Exécuter les migrations:"
echo "   cd $INSTALL_PATH"
echo "   pnpm run migration:run"
echo ""
echo "3. Démarrer le service:"
echo "   systemctl start toto-backend"
echo "   systemctl enable toto-backend"
echo ""
echo "4. Vérifier le statut:"
echo "   systemctl status toto-backend"
echo "   tail -f /var/log/toto-backend.log"
echo ""
echo -e "${YELLOW}⚠  Attention: Conservez le fichier .env en sécurité!${NC}"
echo ""
echo ""
echo -e "${YELLOW}⚠  Attention: Conservez le fichier .env en sécurité!${NC}"
echo ""
