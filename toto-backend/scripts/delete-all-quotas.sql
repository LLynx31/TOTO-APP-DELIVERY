-- Script pour supprimer tous les quotas et transactions de tous les utilisateurs
-- À utiliser avec précaution !

-- Étape 1: Supprimer toutes les transactions de quotas
DELETE FROM quota_transactions;

-- Étape 2: Supprimer tous les quotas
DELETE FROM delivery_quotas;

-- Afficher le résultat
SELECT 'Tous les quotas et transactions ont été supprimés' as message;
