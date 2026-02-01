#!/bin/bash

# ========================================
# SCRIPT DE VÉRIFICATION PRE-DÉPLOIEMENT
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_FAILED=0

check_item() {
    local name=$1
    local command=$2
    
    echo -n "  ✓ Vérification: $name... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}ÉCHOUÉ${NC}"
        ((CHECKS_FAILED++))
    fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}VÉRIFICATION PRÉ-DÉPLOIEMENT${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Prérequis système
echo -e "${BLUE}📋 Système:${NC}"
check_item "Linux/Unix" "[ -f /etc/os-release ] || [ -f /etc/lsb-release ]"
check_item "curl" "command -v curl"
check_item "wget" "command -v wget"
check_item "git" "command -v git"

echo ""
echo -e "${BLUE}📦 Node.js & Package Manager:${NC}"
check_item "Node.js >= 18" "node -v | grep -E 'v(1[8-9]|[2-9][0-9])'"
check_item "npm" "command -v npm"
check_item "pnpm" "command -v pnpm"

echo ""
echo -e "${BLUE}🗄️  Base de Données:${NC}"
check_item "PostgreSQL client" "command -v psql"

# Vérifier la connexion DB si .env existe
if [ -f ".env" ]; then
    source .env 2>/dev/null || true
    if [ ! -z "$DB_HOST" ]; then
        echo -n "  ✓ Connexion PostgreSQL... "
        if psql -h "$DB_HOST" -U "${DB_USERNAME:-postgres}" -d "postgres" -c "SELECT 1" > /dev/null 2>&1; then
            echo -e "${GREEN}OK${NC}"
            ((CHECKS_PASSED++))
        else
            echo -e "${YELLOW}IMPOSSIBLE (credentials manquantes?)${NC}"
            ((CHECKS_FAILED++))
        fi
    fi
fi

echo ""
echo -e "${BLUE}🔧 Fichiers de Configuration:${NC}"
check_item "package.json existe" "[ -f package.json ]"
check_item "tsconfig.json existe" "[ -f tsconfig.json ]"
check_item ".env existe ou .env.example" "[ -f .env ] || [ -f .env.example ]"
check_item "nest-cli.json existe" "[ -f nest-cli.json ]"

echo ""
echo -e "${BLUE}📂 Répertoires:${NC}"
check_item "Répertoire src/" "[ -d src ]"
check_item "Répertoire dist/" "[ -d dist ] || [ ! -d dist ]"  # dist peut ne pas exister
check_item "Permissions d'écriture" "[ -w . ]"

echo ""
echo -e "${BLUE}🔐 Sécurité:${NC}"
check_item "Git configuré" "git config user.email > /dev/null 2>&1 || [ -n '$GIT_AUTHOR_EMAIL' ]"
check_item ".gitignore existe" "[ -f .gitignore ]"

# Vérification Node modules
if [ -d "node_modules" ]; then
    echo ""
    echo -e "${BLUE}📚 Dépendances:${NC}"
    check_item "node_modules installé" "[ -d node_modules ] && [ $(ls -1 node_modules | wc -l) -gt 0 ]"
fi

# Afficher le résumé
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "Résultats: ${GREEN}$CHECKS_PASSED réussis${NC}, ${RED}$CHECKS_FAILED échoués${NC}"
echo -e "${BLUE}========================================${NC}"

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Tous les prérequis sont satisfaits!${NC}"
    echo -e "${GREEN}Vous pouvez procéder au déploiement.${NC}"
    exit 0
else
    echo -e "${RED}✗ Certains prérequis ne sont pas satisfaits.${NC}"
    echo -e "${YELLOW}Veuillez corriger les erreurs avant de déployer.${NC}"
    exit 1
fi
