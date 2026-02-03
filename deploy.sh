#!/bin/bash
set -euo pipefail

#=============================================================================
# TOTO Backend - Script de déploiement production
# Serveur : vps113565 - /home/Nycaise/web/toto.tangagroup.com
#=============================================================================

# --- Configuration -----------------------------------------------------------
APP_NAME="toto-backend"
DEPLOY_DIR="/home/Nycaise/web/toto.tangagroup.com"
REPO_DIR="${DEPLOY_DIR}/app/TOTO-APP-DELIVERY"
BACKEND_DIR="${REPO_DIR}/toto-backend"
BACKUP_DIR="${DEPLOY_DIR}/backups"
LOG_FILE="${DEPLOY_DIR}/logs/deploy.log"
ENV_FILE="${BACKEND_DIR}/.env"
PM2_APP_NAME="toto-backend"
GIT_REPO="https://github.com/LLynx31/TOTO-APP-DELIVERY.git"
GIT_BRANCH="master"
NODE_VERSION="18"
MAX_BACKUPS=5

# --- Couleurs ----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Fonctions utilitaires ---------------------------------------------------
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}]${NC} $1"
    echo "[${timestamp}] $1" >> "${LOG_FILE}" 2>/dev/null || true
}

log_success() {
    log "${GREEN}OK${NC} - $1"
}

log_warn() {
    log "${YELLOW}WARN${NC} - $1"
}

log_error() {
    log "${RED}ERREUR${NC} - $1"
}

die() {
    log_error "$1"
    echo ""
    echo -e "${RED}=== DEPLOIEMENT ECHOUE ===${NC}"
    echo "Consultez le log : ${LOG_FILE}"
    exit 1
}

# --- Vérification des prérequis ----------------------------------------------
check_prerequisites() {
    log "Vérification des prérequis..."

    # Node.js via NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if ! command -v node &> /dev/null; then
        die "Node.js n'est pas installé. Installez NVM et Node ${NODE_VERSION}."
    fi

    local node_major
    node_major=$(node -v | cut -d'.' -f1 | tr -d 'v')
    if [ "$node_major" -lt "$NODE_VERSION" ]; then
        log "Passage à Node ${NODE_VERSION}..."
        nvm use "$NODE_VERSION" || die "Impossible de passer à Node ${NODE_VERSION}"
    fi
    log_success "Node.js $(node -v)"

    # pnpm
    if ! command -v pnpm &> /dev/null; then
        log "Installation de pnpm..."
        npm install -g pnpm || die "Impossible d'installer pnpm"
    fi
    log_success "pnpm $(pnpm -v)"

    # PM2
    if ! command -v pm2 &> /dev/null; then
        log "Installation de PM2..."
        npm install -g pm2 || die "Impossible d'installer PM2"
    fi
    log_success "PM2 $(pm2 -v)"

    # Vérifier que le repo existe, sinon le cloner
    if [ ! -d "$REPO_DIR" ]; then
        log "Repo introuvable, clonage initial..."
        mkdir -p "$(dirname "$REPO_DIR")"
        git clone -b "$GIT_BRANCH" "$GIT_REPO" "$REPO_DIR" || die "Échec du clonage du repo"
        log_success "Repo cloné dans ${REPO_DIR}"
    fi

    # Vérifier que le backend existe dans le repo
    if [ ! -d "$BACKEND_DIR" ]; then
        die "Répertoire toto-backend introuvable dans : ${REPO_DIR}"
    fi

    # Vérifier le fichier .env de production
    if [ ! -f "$ENV_FILE" ]; then
        die "Fichier .env manquant dans ${BACKEND_DIR}. Créez-le à partir de .env.example avec les valeurs de production."
    fi

    # Vérifier les variables critiques dans .env
    local missing_vars=()
    for var in DB_HOST DB_USERNAME DB_DATABASE JWT_SECRET; do
        if ! grep -q "^${var}=" "$ENV_FILE" 2>/dev/null; then
            missing_vars+=("$var")
        fi
    done
    if [ ${#missing_vars[@]} -gt 0 ]; then
        die "Variables manquantes dans .env : ${missing_vars[*]}"
    fi

    # Avertir si JWT_SECRET est encore la valeur par défaut
    if grep -q "dev-secret-key" "$ENV_FILE" 2>/dev/null; then
        log_warn "JWT_SECRET contient encore une valeur de développement. Changez-la en production !"
    fi

    log_success "Tous les prérequis sont satisfaits"
}

# --- Sauvegarde avant déploiement --------------------------------------------
create_backup() {
    log "Création d'un backup..."

    mkdir -p "$BACKUP_DIR"

    # Backup du dist actuel (si existe)
    if [ -d "${BACKEND_DIR}/dist" ]; then
        local backup_name="backup_$(date '+%Y%m%d_%H%M%S')"
        local backup_path="${BACKUP_DIR}/${backup_name}"

        mkdir -p "$backup_path"
        cp -r "${BACKEND_DIR}/dist" "$backup_path/"
        cp "${ENV_FILE}" "$backup_path/.env.backup" 2>/dev/null || true

        # Sauvegarder le package.json pour connaître la version
        cp "${BACKEND_DIR}/package.json" "$backup_path/" 2>/dev/null || true

        log_success "Backup créé : ${backup_path}"

        # Nettoyer les anciens backups (garder les N derniers)
        local backup_count
        backup_count=$(ls -1d "${BACKUP_DIR}"/backup_* 2>/dev/null | wc -l)
        if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
            local to_delete=$((backup_count - MAX_BACKUPS))
            ls -1d "${BACKUP_DIR}"/backup_* | head -n "$to_delete" | xargs rm -rf
            log "Nettoyage : ${to_delete} ancien(s) backup(s) supprimé(s)"
        fi
    else
        log_warn "Pas de dist/ existant à sauvegarder (premier déploiement ?)"
    fi
}

# --- Récupération du code ----------------------------------------------------
pull_code() {
    log "Récupération du code depuis Git..."

    cd "$REPO_DIR"

    # Sauvegarder les modifications locales éventuelles (uploads, etc.)
    git stash 2>/dev/null || true

    git fetch origin || die "Impossible de fetch depuis origin"

    local current_commit
    current_commit=$(git rev-parse HEAD)

    git reset --hard "origin/${GIT_BRANCH}" || die "Impossible de reset sur origin/${GIT_BRANCH}"

    local new_commit
    new_commit=$(git rev-parse HEAD)

    if [ "$current_commit" = "$new_commit" ]; then
        log "Aucun nouveau commit détecté"
    else
        log_success "Mis à jour : ${current_commit:0:8} -> ${new_commit:0:8}"
    fi

    # Afficher le dernier commit
    log "Dernier commit : $(git log --oneline -1)"
}

# --- Installation des dépendances -------------------------------------------
install_dependencies() {
    log "Installation des dépendances..."

    cd "$BACKEND_DIR"

    # Installation en mode production (sans devDependencies sauf pour le build)
    pnpm install --frozen-lockfile 2>/dev/null || pnpm install || die "Échec de pnpm install"

    log_success "Dépendances installées"
}

# --- Build de l'application --------------------------------------------------
build_app() {
    log "Build de l'application..."

    cd "$BACKEND_DIR"

    # Nettoyer l'ancien build
    rm -rf dist/

    # Build TypeScript
    pnpm run build || die "Échec du build. Vérifiez les erreurs TypeScript."

    # Vérifier que le build a produit le fichier principal
    if [ ! -f "dist/src/main.js" ]; then
        die "Le build n'a pas produit dist/src/main.js"
    fi

    log_success "Build terminé avec succès"
}

# --- Exécution des migrations ------------------------------------------------
run_migrations() {
    log "Vérification des migrations de base de données..."

    cd "$BACKEND_DIR"

    # Exécuter les migrations TypeORM
    if npx typeorm migration:show -d dist/src/data-source.js 2>/dev/null | grep -q "\[ \]"; then
        log "Migrations en attente détectées, exécution..."
        npx typeorm migration:run -d dist/src/data-source.js || die "Échec des migrations"
        log_success "Migrations exécutées"
    else
        log "Aucune migration en attente"
    fi
}

# --- Gestion du dossier uploads ----------------------------------------------
setup_uploads() {
    log "Vérification du dossier uploads..."

    local uploads_dir="${BACKEND_DIR}/uploads"
    mkdir -p "$uploads_dir"

    # Permissions correctes
    chmod 755 "$uploads_dir"

    log_success "Dossier uploads prêt"
}

# --- Démarrage / Redémarrage avec PM2 ---------------------------------------
restart_app() {
    log "Redémarrage de l'application avec PM2..."

    cd "$BACKEND_DIR"

    # Vérifier si l'app tourne déjà sous PM2
    if pm2 describe "$PM2_APP_NAME" &> /dev/null; then
        log "Redémarrage de ${PM2_APP_NAME}..."
        pm2 restart "$PM2_APP_NAME" --update-env || die "Échec du redémarrage PM2"
    else
        log "Premier démarrage de ${PM2_APP_NAME}..."
        pm2 start dist/src/main.js \
            --name "$PM2_APP_NAME" \
            --cwd "$BACKEND_DIR" \
            --max-memory-restart "512M" \
            --log "${DEPLOY_DIR}/logs/app.log" \
            --error "${DEPLOY_DIR}/logs/app-error.log" \
            --time \
            || die "Échec du démarrage PM2"
    fi

    # Sauvegarder la config PM2 pour le redémarrage auto au boot
    pm2 save || log_warn "Impossible de sauvegarder la config PM2"

    # Attendre que l'app démarre
    sleep 3

    # Vérifier que l'app est bien en ligne
    if pm2 describe "$PM2_APP_NAME" | grep -q "online"; then
        log_success "Application démarrée et en ligne"
    else
        log_error "L'application ne semble pas être en ligne"
        log "Logs récents :"
        pm2 logs "$PM2_APP_NAME" --lines 20 --nostream
        die "L'application n'a pas démarré correctement"
    fi
}

# --- Health check ------------------------------------------------------------
health_check() {
    log "Vérification de santé de l'application..."

    local port
    port=$(grep "^PORT=" "$ENV_FILE" | cut -d'=' -f2)
    port=${port:-3000}

    local max_retries=5
    local retry=0

    while [ $retry -lt $max_retries ]; do
        if curl -sf "http://localhost:${port}/api" > /dev/null 2>&1; then
            log_success "L'API répond sur le port ${port} (Swagger accessible)"
            return 0
        fi
        retry=$((retry + 1))
        log "Tentative ${retry}/${max_retries}..."
        sleep 2
    done

    log_warn "L'API ne répond pas sur http://localhost:${port}/api (peut nécessiter quelques secondes supplémentaires)"
    log "Vérifiez manuellement : curl http://localhost:${port}/api"
}

# --- Affichage du résumé ----------------------------------------------------
print_summary() {
    local port
    port=$(grep "^PORT=" "$ENV_FILE" | cut -d'=' -f2)
    port=${port:-3000}

    local ws_port
    ws_port=$(grep "^WEBSOCKET_PORT=" "$ENV_FILE" | cut -d'=' -f2)
    ws_port=${ws_port:-3001}

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}   DEPLOIEMENT REUSSI${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "  Application  : ${PM2_APP_NAME}"
    echo -e "  API          : http://localhost:${port}"
    echo -e "  Swagger      : http://localhost:${port}/api"
    echo -e "  WebSocket    : ws://localhost:${ws_port}/tracking"
    echo -e "  Commit       : $(cd "$REPO_DIR" && git log --oneline -1)"
    echo -e "  Node         : $(node -v)"
    echo ""
    echo -e "  Commandes utiles :"
    echo -e "    pm2 status                    # Statut"
    echo -e "    pm2 logs ${PM2_APP_NAME}      # Logs temps réel"
    echo -e "    pm2 restart ${PM2_APP_NAME}   # Redémarrer"
    echo -e "    pm2 stop ${PM2_APP_NAME}      # Arrêter"
    echo ""
}

# --- Rollback (en cas de besoin) --------------------------------------------
rollback() {
    log "Rollback vers le dernier backup..."

    local latest_backup
    latest_backup=$(ls -1d "${BACKUP_DIR}"/backup_* 2>/dev/null | tail -1)

    if [ -z "$latest_backup" ]; then
        die "Aucun backup disponible pour le rollback"
    fi

    if [ -d "${latest_backup}/dist" ]; then
        rm -rf "${BACKEND_DIR}/dist"
        cp -r "${latest_backup}/dist" "${BACKEND_DIR}/"
        restart_app
        log_success "Rollback effectué depuis : ${latest_backup}"
    else
        die "Le backup ne contient pas de dossier dist/"
    fi
}

# --- Point d'entrée principal ------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}   TOTO Backend - Déploiement Production${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # Créer le dossier de logs si nécessaire
    mkdir -p "${DEPLOY_DIR}/logs"

    log "Début du déploiement..."

    check_prerequisites
    create_backup
    pull_code
    install_dependencies
    build_app
    run_migrations
    setup_uploads
    restart_app
    health_check
    print_summary

    log "Déploiement terminé avec succès"
}

# --- Gestion des arguments ---------------------------------------------------
case "${1:-deploy}" in
    deploy)
        main
        ;;
    rollback)
        rollback
        ;;
    status)
        pm2 describe "$PM2_APP_NAME" 2>/dev/null || echo "Application non trouvée dans PM2"
        ;;
    logs)
        pm2 logs "$PM2_APP_NAME" --lines "${2:-50}"
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|status|logs [N]}"
        echo ""
        echo "  deploy    Déployer la dernière version (défaut)"
        echo "  rollback  Revenir au dernier backup"
        echo "  status    Voir le statut de l'application"
        echo "  logs [N]  Voir les N dernières lignes de logs"
        exit 1
        ;;
esac
