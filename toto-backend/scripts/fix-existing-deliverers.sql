-- Script pour créer des entrées users pour les deliverers existants
-- Cela permet au système de quotas (qui a une FK vers users) de fonctionner pour les deliverers

-- Insérer dans users tous les deliverers qui n'ont pas encore d'entrée correspondante
INSERT INTO users (id, phone_number, full_name, email, password_hash, photo_url, is_verified, is_active, created_at, updated_at)
SELECT
  d.id,
  d.phone_number,
  d.full_name,
  d.email,
  d.password_hash,
  d.photo_url,
  d.is_verified,
  d.is_active,
  d.created_at,
  d.updated_at
FROM deliverers d
WHERE NOT EXISTS (
  SELECT 1 FROM users u WHERE u.id = d.id
)
ON CONFLICT (id) DO NOTHING;

-- Vérifier le résultat
SELECT
  'deliverers' as table_name, COUNT(*) as count FROM deliverers
UNION ALL
SELECT
  'users (from deliverers)' as table_name, COUNT(*) as count
FROM users u
WHERE EXISTS (SELECT 1 FROM deliverers d WHERE d.id = u.id);
