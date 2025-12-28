-- ============================================
-- Script de nettoyage des données de test
-- À exécuter AVANT de créer les nouveaux utilisateurs
-- ============================================

-- 1. Supprimer les livraisons de test (dépendances d'abord)
DELETE FROM deliveries WHERE client_id IN (
    SELECT id FROM clients WHERE phone_number IN ('+22501020304', '+22507080910')
);
DELETE FROM deliveries WHERE deliverer_id IN (
    SELECT id FROM deliverers WHERE phone_number = '+22598765432'
);

-- 2. Supprimer les ratings associés
DELETE FROM ratings WHERE delivery_id NOT IN (SELECT id FROM deliveries);

-- 3. Supprimer les transactions de quotas des anciens livreurs
DELETE FROM quota_transactions WHERE deliverer_id IN (
    SELECT id FROM deliverers WHERE phone_number = '+22598765432'
);

-- 4. Supprimer les quotas des anciens livreurs
DELETE FROM delivery_quotas WHERE deliverer_id IN (
    SELECT id FROM deliverers WHERE phone_number = '+22598765432'
);

-- 5. Supprimer les refresh tokens
DELETE FROM refresh_tokens WHERE user_id IN (
    SELECT id FROM clients WHERE phone_number IN ('+22501020304', '+22507080910')
);
DELETE FROM refresh_tokens WHERE user_id IN (
    SELECT id FROM deliverers WHERE phone_number = '+22598765432'
);

-- 6. Supprimer les anciens clients de test
DELETE FROM clients WHERE phone_number IN ('+22501020304', '+22507080910');
DELETE FROM clients WHERE email IN ('client@test.com', 'aya@test.com');

-- 7. Supprimer les anciens livreurs de test
DELETE FROM deliverers WHERE phone_number = '+22598765432';
DELETE FROM deliverers WHERE email = 'deliverer@test.com';

-- Confirmer le nettoyage
SELECT 'Nettoyage terminé' AS status;
