-- Migration: Changer la foreign key de delivery_quotas de users vers deliverers
-- Cela permet aux livreurs (table deliverers) d'avoir des quotas

-- Étape 0a: Supprimer les transactions liées aux quotas orphelins
DELETE FROM quota_transactions
WHERE quota_id IN (
  SELECT id FROM delivery_quotas
  WHERE user_id NOT IN (SELECT id FROM deliverers)
);

-- Étape 0b: Supprimer les enregistrements orphelins (quotas de clients au lieu de deliverers)
-- Ces quotas ne sont pas valides car seuls les deliverers doivent avoir des quotas
DELETE FROM delivery_quotas
WHERE user_id NOT IN (SELECT id FROM deliverers);

-- Étape 1: Supprimer l'ancienne foreign key constraint vers users
ALTER TABLE delivery_quotas
DROP CONSTRAINT IF EXISTS "FK_7396a26611d792606e3f5586381";

-- Étape 2: Ajouter la nouvelle foreign key constraint vers deliverers
ALTER TABLE delivery_quotas
ADD CONSTRAINT "FK_delivery_quotas_deliverers"
FOREIGN KEY (user_id)
REFERENCES deliverers(id)
ON DELETE CASCADE;

-- Vérifier la contrainte
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'delivery_quotas';
