#!/bin/bash

# ========================================
# SCRIPT DE DEPLOIEMENT TOTO BACKEND
# ========================================
# Améliorations:
# - Gestion d'erreurs robuste
# - Vérification des prérequis
# - Gestion des variables d'environnement
# - Backup de la base de données
# - Migrations de base de données
# - Gestion du service systemd
# - Logs détaillés

set -e  # Exit on error

# Configuration
DEPLOY_DIR="/home/Nycaise/web/toto.tangagroup.com/app/TOTO-APP-DELIVERY/toto-backend"
BACKUP_DIR="/home/Nycaise/web/backups"
ENV_BACKUP_DIR="/home/Nycaise/web/backups/env"
LOG_FILE="/var/log/toto-deploy.log"
APP_USER="appuser"  # À adapter selon votre config
SYSTEMD_SERVICE="toto-backend"  # À adapter selon votre config
NODE_VERSION="18"
MAX_RETRIES=3

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ========================================
# FONCTIONS UTILITAIRES
# ========================================

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}]${NC} [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
}

log_success() {
    log "${GREEN}SUCCESS${NC}" "$@"
}

log_warning() {
    log "${YELLOW}WARNING${NC}" "$@"
}

log_error() {
    log "${RED}ERROR${NC}" "$@"
}

check_error() {
    if [ $? -ne 0 ]; then
        log_error "$1"
        exit 1
    fi
}

save_env_file() {
    log_info "💾 Sauvegarde du fichier .env avant modification..."
    
    if [ ! -f "$DEPLOY_DIR/.env" ]; then
        log_warning "Fichier .env non trouvé, création du répertoire de backup"
        return
    fi
    
    mkdir -p "$ENV_BACKUP_DIR"
    
    ENV_BACKUP_FILE="$ENV_BACKUP_DIR/.env_$(date +%Y%m%d_%H%M%S).backup"
    cp "$DEPLOY_DIR/.env" "$ENV_BACKUP_FILE"
    
    log_success "✅ .env sauvegardé: $ENV_BACKUP_FILE"
    
    # Garder seulement les 10 derniers backups
    ls -t "$ENV_BACKUP_DIR"/.env_*.backup 2>/dev/null | tail -n +11 | xargs -r rm
}

restore_env_file() {
    log_info "♻️  Restauration du fichier .env après git reset..."
    
    # Trouver le plus récent backup de .env
    LATEST_ENV_BACKUP=$(ls -t "$ENV_BACKUP_DIR"/.env_*.backup 2>/dev/null | head -1)
    
    if [ -z "$LATEST_ENV_BACKUP" ]; then
        log_warning "Aucun backup .env trouvé, utilisant .env.example si disponible"
        if [ -f "$DEPLOY_DIR/.env.example" ]; then
            cp "$DEPLOY_DIR/.env.example" "$DEPLOY_DIR/.env"
            log_warning "⚠️  .env créé depuis .env.example - À reconfigurer!"
        fi
        return
    fi
    
    # Restaurer le .env sauvegardé
    cp "$LATEST_ENV_BACKUP" "$DEPLOY_DIR/.env"
    log_success "✅ .env restauré depuis: $LATEST_ENV_BACKUP"
}

# ========================================
# VÉRIFICATIONS PRÉALABLES
# ========================================

verify_requirements() {
    log_info "🔍 Vérification des prérequis..."
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js n'est pas installé"
        exit 1
    fi
    
    NODE_INSTALLED=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ "$NODE_INSTALLED" -lt 18 ]; then
        log_error "Node.js >= 18 requis, version actuelle: $(node -v)"
        exit 1
    fi
    log_success "✅ Node.js $(node -v)"
    
    # Vérifier pnpm
    if ! command -v pnpm &> /dev/null; then
        log_warning "pnpm n'est pas installé, installation en cours..."
        npm install -g pnpm
    fi
    log_success "✅ pnpm $(pnpm -v)"
    
    # Vérifier git
    if ! command -v git &> /dev/null; then
        log_error "git n'est pas installé"
        exit 1
    fi
    log_success "✅ git $(git -v)"
    
    # Vérifier PostgreSQL CLI
    if ! command -v psql &> /dev/null; then
        log_warning "psql n'est pas installé, les tests de DB seront ignorés"
    else
        log_success "✅ PostgreSQL client"
    fi
    
    # Vérifier les répertoires
    if [ ! -d "$DEPLOY_DIR" ]; then
        log_error "Le répertoire de déploiement n'existe pas: $DEPLOY_DIR"
        exit 1
    fi
    
    # Créer les répertoires necessaires
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$ENV_BACKUP_DIR"
    mkdir -p "$(dirname $LOG_FILE)"
}

# ========================================
# GIT OPERATIONS
# ========================================

update_repository() {
    log_info "📥 Récupération des dernières modifications depuis Git..."
    # Sauvegarder le .env AVANT de faire git fetch
    save_env_file
    
    
    cd "$DEPLOY_DIR"
    
    # Sauvegarder l'état actuel
    log_info "Sauvegarde de l'état git local..."
    git status > /tmp/git-status-before.txt
    
    # Récupérer les mises à jour
    git fetch origin
    check_error "Erreur lors de git fetch"
    
    # Vérifier les changements locaux
    UNCOMMITTED=$(git status --porcelain)
    if [ ! -z "$UNCOMMITTED" ]; then
        log_warning "Changements locaux détectés, stash en cours..."
        git stash
    fi
    
    # Reset hard
    log_info "Réinitialisation vers origin/master..."
    git reset --hard origin/master
    check_error "Erreur lors de git reset"
    
    # Restaurer le .env sauvegardé APRÈS git reset
    restore_env_file
    
    log_success "✅ Repository à jour"
}

# ========================================
# ENVIRONMENT SETUP
# ========================================

setup_environment() {
    log_info "⚙️  Configuration de l'environnement Node.js..."
    
    # NVM setup (optionnel, si NVM est installé)
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        . "$HOME/.nvm/nvm.sh"
        nvm use $NODE_VERSION || {
            log_warning "Impossible d'utiliser Node.js $NODE_VERSION via NVM"
        }
    fi
    
    # Vérifier le fichier .env
    if [ ! -f "$DEPLOY_DIR/.env" ]; then
        log_error "Fichier .env manquant! Copie depuis .env.example..."
        if [ -f "$DEPLOY_DIR/.env.example" ]; then
            cp "$DEPLOY_DIR/.env.example" "$DEPLOY_DIR/.env"
            log_warning "⚠️  ATTENTION: Veuillez éditer .env avec vos configurations de production!"
            log_warning "   Fichier créé depuis le template."
            read -p "Appuyez sur Entrée pour continuer une fois .env configuré..."
        else
            log_error "Fichier .env.example aussi manquant!"
            exit 1
        fi
    fi
    
    # Sourcer les variables d'environnement
    export $(cat "$DEPLOY_DIR/.env" | grep -v '^#' | xargs)
    
    # Vérifications de configuration
    if [ -z "$DB_HOST" ] || [ -z "$DB_PASSWORD" ] || [ -z "$JWT_SECRET" ]; then
        log_error "Variables d'environnement manquantes dans .env"
        exit 1
    fi
    
    log_success "✅ Environnement configuré"
}

# ========================================
# DEPENDENCIES
# ========================================

install_dependencies() {
    log_info "📦 Installation des dépendances..."
    
    cd "$DEPLOY_DIR"
    
    # Nettoyer le cache pnpm ancien
    pnpm store prune 2>/dev/null || true
    
    # Installer les dépendances
    pnpm install --frozen-lockfile
    check_error "Erreur lors de pnpm install"
    
    log_success "✅ Dépendances installées"
}

# ========================================
# DATABASE OPERATIONS
# ========================================

backup_database() {
    log_info "💾 Sauvegarde de la base de données..."
    
    if [ -z "$DB_HOST" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_DATABASE" ]; then
        log_warning "Variables de base de données manquantes, backup ignoré"
        return
    fi
    
    BACKUP_FILE="$BACKUP_DIR/${DB_DATABASE}_$(date +%Y%m%d_%H%M%S).sql"
    
    PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$DB_HOST" \
        -U "$DB_USERNAME" \
        -d "$DB_DATABASE" \
        > "$BACKUP_FILE" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "✅ Base de données sauvegardée: $BACKUP_FILE"
        # Garder seulement les 5 derniers backups
        ls -t "$BACKUP_DIR"/${DB_DATABASE}_*.sql 2>/dev/null | tail -n +6 | xargs -r rm
    else
        log_warning "⚠️  Sauvegarde de base de données échouée (continuant...)"
    fi
}

run_migrations() {
    log_info "🔄 Exécution des migrations de base de données..."
    
    cd "$DEPLOY_DIR"
    
    # Vérifier les migrations en attente
    if pnpm run migration:show 2>/dev/null | grep -q "pending"; then
        log_info "Migrations en attente détectées, exécution..."
        pnpm run migration:run
        check_error "Erreur lors de l'exécution des migrations"
        log_success "✅ Migrations exécutées"
    else
        log_info "Aucune migration en attente"
    fi
}

# ========================================
# BUILD
# ========================================

build_application() {
    log_info "🔨 Build de l'application..."
    
    cd "$DEPLOY_DIR"
    
    # Nettoyer les anciens builds
    rm -rf dist/
    
    # Build
    pnpm run build
    check_error "Erreur lors du build"
    
    log_success "✅ Build réussi"
}

# ========================================
# SERVICE MANAGEMENT
# ========================================

restart_service() {
    log_info "🔄 Redémarrage du service..."
    
    if command -v systemctl &> /dev/null; then
        # Vérifier si le service existe
        if systemctl list-unit-files | grep -q "^${SYSTEMD_SERVICE}"; then
            systemctl stop "$SYSTEMD_SERVICE" || true
            sleep 2
            systemctl start "$SYSTEMD_SERVICE"
            check_error "Erreur lors du démarrage du service"
            
            # Attendre que le service soit prêt
            sleep 3
            if systemctl is-active --quiet "$SYSTEMD_SERVICE"; then
                log_success "✅ Service redémarré avec succès"
            else
                log_error "Service n'est pas actif après le redémarrage"
                systemctl status "$SYSTEMD_SERVICE"
                exit 1
            fi
        else
            log_warning "Service systemd '$SYSTEMD_SERVICE' non trouvé"
            log_info "Pour démarrer l'application manuellement:"
            log_info "  cd $DEPLOY_DIR && PORT=3000 pnpm run start:prod"
        fi
    else
        log_warning "systemd non disponible"
    fi
}

# ========================================
# HEALTH CHECKS
# ========================================

health_check() {
    log_info "🏥 Vérification de la santé de l'application..."
    
    PORT=${PORT:-3000}
    HEALTH_URL="http://localhost:$PORT/health"
    
    for i in {1..30}; do
        if curl -s "$HEALTH_URL" > /dev/null 2>&1; then
            log_success "✅ Application en bonne santé"
            return 0
        fi
        log_info "Tentative $i/30 - Attente du démarrage..."
        sleep 2
    done
    
    log_warning "⚠️  Impossible de vérifier la santé (endpoint peut ne pas exister)"
    return 0
}

# ========================================
# CLEANUP
# ========================================

cleanup() {
    log_info "🧹 Nettoyage..."
    
    cd "$DEPLOY_DIR"
    
    # Nettoyer les anciens modules
    find node_modules -name ".npmrc" -o -name ".yarnrc" | xargs rm -f 2>/dev/null || true
    
    log_info "✅ Nettoyage terminé"
}

# ========================================
# MAIN DEPLOYMENT FLOW
# ========================================

main() {
    log_info "========================================="
    log_info "🚀 DÉPLOIEMENT TOTO BACKEND"
    log_info "========================================="
    log_info "Répertoire: $DEPLOY_DIR"
    log_info "Timestamp: $(date)"
    log_info "========================================="
    
    verify_requirements
    update_repository
    setup_environment
    backup_database
    install_dependencies
    build_application
    run_migrations
    cleanup
    restart_service
    health_check
    
    log_info "========================================="
    log_success "🎉 DÉPLOIEMENT RÉUSSI!"
    log_info "========================================="
    log_info "Logs complets disponibles à: $LOG_FILE"
}

# Handle errors
trap 'log_error "Déploiement échoué à la ligne $LINENO"; exit 1' ERR

# Run main
main "$@"
