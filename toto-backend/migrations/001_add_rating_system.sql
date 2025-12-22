-- Migration: Add Rating System and Delivery Code
-- Date: 2025-12-20
-- Description: Ajoute le système de notation bidirectionnel et le code de validation 4 chiffres

-- ==========================================
-- 1. Ajouter le champ delivery_code à la table deliveries
-- ==========================================
ALTER TABLE deliveries
ADD COLUMN IF NOT EXISTS delivery_code VARCHAR(4) UNIQUE;

-- Créer un index pour améliorer les performances de recherche
CREATE INDEX IF NOT EXISTS idx_deliveries_delivery_code ON deliveries(delivery_code);

-- ==========================================
-- 2. Créer la table ratings
-- ==========================================
CREATE TABLE IF NOT EXISTS ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id UUID NOT NULL,
  rated_by_id UUID NOT NULL,
  rated_user_id UUID NOT NULL,
  stars INTEGER NOT NULL CHECK (stars >= 1 AND stars <= 5),
  comment TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  -- Contraintes de clés étrangères
  CONSTRAINT fk_ratings_delivery FOREIGN KEY (delivery_id) REFERENCES deliveries(id) ON DELETE CASCADE,
  CONSTRAINT fk_ratings_rated_by FOREIGN KEY (rated_by_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ratings_rated_user FOREIGN KEY (rated_user_id) REFERENCES users(id) ON DELETE CASCADE,

  -- Un utilisateur ne peut noter qu'une fois par livraison
  CONSTRAINT unique_rating_per_user_delivery UNIQUE (delivery_id, rated_by_id)
);

-- Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_ratings_delivery_id ON ratings(delivery_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rated_by_id ON ratings(rated_by_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rated_user_id ON ratings(rated_user_id);

-- ==========================================
-- 3. Générer des codes de livraison pour les livraisons existantes (si nécessaire)
-- ==========================================
-- Cette partie génère des codes aléatoires pour les livraisons qui n'en ont pas encore
DO $$
DECLARE
  delivery_record RECORD;
  new_code VARCHAR(4);
  code_exists BOOLEAN;
BEGIN
  FOR delivery_record IN SELECT id FROM deliveries WHERE delivery_code IS NULL
  LOOP
    -- Générer un code unique
    LOOP
      new_code := LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');

      SELECT EXISTS(SELECT 1 FROM deliveries WHERE delivery_code = new_code) INTO code_exists;

      EXIT WHEN NOT code_exists;
    END LOOP;

    -- Mettre à jour la livraison avec le nouveau code
    UPDATE deliveries SET delivery_code = new_code WHERE id = delivery_record.id;
  END LOOP;
END $$;

-- ==========================================
-- 4. Rendre le champ delivery_code obligatoire
-- ==========================================
-- Après avoir généré les codes pour les livraisons existantes, on peut le rendre NOT NULL
ALTER TABLE deliveries
ALTER COLUMN delivery_code SET NOT NULL;

COMMIT;
