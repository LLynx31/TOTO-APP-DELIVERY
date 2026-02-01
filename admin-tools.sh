#!/bin/bash

# ========================================
# UTILITAIRES D'ADMINISTRATION TOTO BACKEND
# ========================================
# Commandes utiles pour la gestion et maintenance du backend

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DEPLOY_DIR="/home/Nycaise/web/toto.tangagroup.com/app"
SERVICE_NAME="toto-backend"

# ========================================
# FONCTIONS
# ========================================

print_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}ADMINISTRATION TOTO BACKEND${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "SERVICE:"
    echo "  1) Démarrer le service"
    echo "  2) Arrêter le service"
    echo "  3) Redémarrer le service"
    echo "  4) Voir le statut"
    echo "  5) Voir les logs (temps réel)"
    echo ""
    echo "DATABASE:"
    echo "  6) Exécuter les migrations"
    echo "  7) Voir l'état des migrations"
    echo "  8) Revert la dernière migration"
    echo "  9) Backup de la base de données"
    echo " 10) Restore depuis un backup"
    echo ""
    echo "DÉPLOIEMENT:"
    echo " 11) Lancer un redéploiement"
    echo " 12) Vérification prérequis"
    echo ""
    echo "MAINTENANCE:"
    echo " 13) Nettoyer les logs anciens"
    echo " 14) Vérifier l'utilisation disque"
    echo " 15) Voir les erreurs récentes"
    echo ""
    echo "  0) Quitter"
    echo ""
}

start_service() {
    echo -e "${BLUE}Démarrage du service...${NC}"
    systemctl start "$SERVICE_NAME"
    sleep 2
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✓ Service démarré${NC}"
    else
        echo -e "${RED}✗ Erreur au démarrage${NC}"
        systemctl status "$SERVICE_NAME"
    fi
}

stop_service() {
    echo -e "${BLUE}Arrêt du service...${NC}"
    systemctl stop "$SERVICE_NAME"
    echo -e "${GREEN}✓ Service arrêté${NC}"
}

restart_service() {
    echo -e "${BLUE}Redémarrage du service...${NC}"
    systemctl restart "$SERVICE_NAME"
    sleep 2
    echo -e "${GREEN}✓ Service redémarré${NC}"
}

status_service() {
    echo -e "${BLUE}État du service:${NC}"
    systemctl status "$SERVICE_NAME" --no-pager || true
}

logs_service() {
    echo -e "${BLUE}Logs en temps réel (Ctrl+C pour quitter)${NC}"
    journalctl -u "$SERVICE_NAME" -f
}

run_migrations() {
    echo -e "${BLUE}Exécution des migrations...${NC}"
    cd "$DEPLOY_DIR"
    pnpm run migration:run
    echo -e "${GREEN}✓ Migrations exécutées${NC}"
}

show_migrations() {
    echo -e "${BLUE}État des migrations:${NC}"
    cd "$DEPLOY_DIR"
    pnpm run migration:show
}

revert_migration() {
    echo -e "${YELLOW}⚠️  Revert de la dernière migration...${NC}"
    read -p "Êtes-vous sûr? (oui/non): " confirm
    if [ "$confirm" = "oui" ]; then
        cd "$DEPLOY_DIR"
        pnpm run migration:revert
        echo -e "${GREEN}✓ Migration revert${NC}"
    else
        echo "Annulé"
    fi
}

backup_database() {
    source "$DEPLOY_DIR/.env" 2>/dev/null || {
        echo -e "${RED}✗ Impossible de charger .env${NC}"
        return
    }
    
    BACKUP_FILE="/home/Nycaise/web/backups/${DB_DATABASE}_$(date +%Y%m%d_%H%M%S).sql"
    
    echo -e "${BLUE}Backup de la base de données...${NC}"
    mkdir -p "$(dirname $BACKUP_FILE)"
    
    PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$DB_HOST" \
        -U "$DB_USERNAME" \
        -d "$DB_DATABASE" \
        > "$BACKUP_FILE"
    
    echo -e "${GREEN}✓ Backup créé: $BACKUP_FILE${NC}"
    ls -lh "$BACKUP_FILE"
}

restore_database() {
    source "$DEPLOY_DIR/.env" 2>/dev/null || {
        echo -e "${RED}✗ Impossible de charger .env${NC}"
        return
    }
    
    BACKUP_DIR="/home/Nycaise/web/backups"
    
    echo -e "${BLUE}Fichiers de backup disponibles:${NC}"
    ls -lh "$BACKUP_DIR"/${DB_DATABASE}_*.sql 2>/dev/null || {
        echo -e "${RED}Aucun backup trouvé${NC}"
        return
    }
    
    read -p "Fichier à restaurer (chemin complet): " BACKUP_FILE
    
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}✗ Fichier non trouvé${NC}"
        return
    fi
    
    echo -e "${YELLOW}⚠️  Attention: Cela écrasera la base de données!${NC}"
    read -p "Êtes-vous sûr? (oui/non): " confirm
    
    if [ "$confirm" = "oui" ]; then
        echo -e "${BLUE}Restauration...${NC}"
        PGPASSWORD="$DB_PASSWORD" psql \
            -h "$DB_HOST" \
            -U "$DB_USERNAME" \
            -d "$DB_DATABASE" \
            < "$BACKUP_FILE"
        
        echo -e "${GREEN}✓ Base de données restaurée${NC}"
    else
        echo "Annulé"
    fi
}

redeploy() {
    echo -e "${BLUE}Lancement du redéploiement...${NC}"
    
    if [ ! -f "$DEPLOY_DIR/deploy-improved.sh" ]; then
        echo -e "${RED}✗ Script de déploiement non trouvé${NC}"
        return
    fi
    
    cd "$DEPLOY_DIR"
    sudo "$DEPLOY_DIR/deploy-improved.sh"
}

check_requirements() {
    echo -e "${BLUE}Vérification des prérequis...${NC}"
    
    if [ -f "$DEPLOY_DIR/pre-deployment-check.sh" ]; then
        cd "$DEPLOY_DIR"
        bash "$DEPLOY_DIR/pre-deployment-check.sh"
    else
        echo -e "${RED}✗ Script de vérification non trouvé${NC}"
    fi
}

cleanup_logs() {
    echo -e "${BLUE}Nettoyage des logs...${NC}"
    
    # Archiver les logs de journalctl > 30 jours
    journalctl --vacuum=30d
    
    # Compresser les vieux logs
    find /var/log -name "*.log" -mtime +30 -exec gzip {} \;
    
    echo -e "${GREEN}✓ Nettoyage terminé${NC}"
    df -h /var/log
}

disk_usage() {
    echo -e "${BLUE}Utilisation disque:${NC}"
    echo ""
    echo "Répertoire de déploiement:"
    du -sh "$DEPLOY_DIR"
    echo ""
    echo "Backups:"
    du -sh /home/Nycaise/web/backups 2>/dev/null || echo "Aucun backup"
    echo ""
    echo "Logs:"
    du -sh /var/log/toto* 2>/dev/null || echo "Aucun log"
    echo ""
    echo "Uploads:"
    du -sh /var/uploads/toto 2>/dev/null || echo "Aucun upload"
    echo ""
    echo "Espace global:"
    df -h /
}

recent_errors() {
    echo -e "${BLUE}Erreurs récentes:${NC}"
    echo ""
    echo "Logs du service:"
    journalctl -u "$SERVICE_NAME" --since "1 hour ago" --priority err
    echo ""
    echo "Logs d'application:"
    grep -i "error\|exception" /var/log/toto-backend.log 2>/dev/null | tail -20 || echo "Aucune erreur"
}

# ========================================
# MAIN
# ========================================

main() {
    while true; do
        print_menu
        read -p "Sélectionner une option: " choice
        
        case $choice in
            1) start_service ;;
            2) stop_service ;;
            3) restart_service ;;
            4) status_service ;;
            5) logs_service ;;
            6) run_migrations ;;
            7) show_migrations ;;
            8) revert_migration ;;
            9) backup_database ;;
            10) restore_database ;;
            11) redeploy ;;
            12) check_requirements ;;
            13) cleanup_logs ;;
            14) disk_usage ;;
            15) recent_errors ;;
            0) echo "Bye!"; exit 0 ;;
            *) echo -e "${RED}Option invalide${NC}" ;;
        esac
        
        echo ""
        read -p "Appuyez sur Entrée pour continuer..."
        clear
    done
}

# Vérifier si exécuté avec les bonnes permissions
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Ce script nécessite les permissions root (sudo)${NC}"
    exit 1
fi

main
