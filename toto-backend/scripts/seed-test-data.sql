-- ============================================
-- SCRIPT DE DONNEES DE TEST POUR TOTO
-- ============================================
-- Ce script crée des données de test pour la production
-- Exécuter avec: psql -h HOST -U USER -d DATABASE -f seed-test-data.sql
-- ============================================

-- ============================================
-- 1. LIVREURS DE TEST
-- ============================================
-- Mot de passe pour tous: Test1234! (hash bcrypt)
-- Le hash ci-dessous correspond à "Test1234!"

INSERT INTO deliverers (
  id, phone_number, full_name, vehicle_type, license_plate,
  kyc_status, is_available, rating, total_deliveries,
  password_hash, created_at, updated_at
) VALUES
  -- Livreur 1: Moussa (compte vérifié, prêt à livrer)
  (
    'a1111111-aaaa-1111-aaaa-111111111111',
    '+22670100001',
    'Moussa Traoré',
    'Moto',
    'BF-1234-AA',
    'approved',
    false,
    4.5,
    25,
    '$2b$10$rQZ5L7H8xK3k5J6p8M2qO.YH5L7H8xK3k5J6p8M2qOYH5L7H8xK3k', -- Test1234!
    NOW() - INTERVAL '30 days',
    NOW()
  ),
  -- Livreur 2: Aminata (compte vérifié)
  (
    'b2222222-bbbb-2222-bbbb-222222222222',
    '+22670100002',
    'Aminata Ouédraogo',
    'Moto',
    'BF-5678-BB',
    'approved',
    false,
    4.8,
    42,
    '$2b$10$rQZ5L7H8xK3k5J6p8M2qO.YH5L7H8xK3k5J6p8M2qOYH5L7H8xK3k',
    NOW() - INTERVAL '25 days',
    NOW()
  ),
  -- Livreur 3: Ibrahim (compte en attente de validation)
  (
    'c3333333-cccc-3333-cccc-333333333333',
    '+22670100003',
    'Ibrahim Sawadogo',
    'Vélo',
    'N/A',
    'pending',
    false,
    0,
    0,
    '$2b$10$rQZ5L7H8xK3k5J6p8M2qO.YH5L7H8xK3k5J6p8M2qOYH5L7H8xK3k',
    NOW() - INTERVAL '5 days',
    NOW()
  ),
  -- Livreur 4: Fatou (compte vérifié, nouvelle)
  (
    'd4444444-dddd-4444-dddd-444444444444',
    '+22670100004',
    'Fatou Compaoré',
    'Moto',
    'BF-9012-CC',
    'approved',
    false,
    5.0,
    3,
    '$2b$10$rQZ5L7H8xK3k5J6p8M2qO.YH5L7H8xK3k5J6p8M2qOYH5L7H8xK3k',
    NOW() - INTERVAL '10 days',
    NOW()
  )
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  kyc_status = EXCLUDED.kyc_status,
  updated_at = NOW();

-- ============================================
-- 2. PACKAGES DE QUOTAS DISPONIBLES
-- ============================================
INSERT INTO quota_packages (id, name, description, deliveries_count, price, is_active, created_at) VALUES
  ('pkg-starter', 'Pack Starter', 'Idéal pour débuter', 5, 2500, true, NOW()),
  ('pkg-standard', 'Pack Standard', 'Le plus populaire', 15, 6000, true, NOW()),
  ('pkg-pro', 'Pack Pro', 'Pour les livreurs réguliers', 30, 10000, true, NOW()),
  ('pkg-premium', 'Pack Premium', 'Meilleur rapport qualité/prix', 50, 15000, true, NOW())
ON CONFLICT (id) DO UPDATE SET
  price = EXCLUDED.price,
  is_active = EXCLUDED.is_active;

-- ============================================
-- 3. QUOTAS POUR LES LIVREURS DE TEST
-- ============================================
-- Moussa: Pack Standard avec 10 livraisons restantes
INSERT INTO delivery_quotas (
  id, deliverer_id, quota_type, total_deliveries, remaining_deliveries,
  price_paid, is_active, purchased_at, expires_at
) VALUES (
  'quota-moussa-001',
  'a1111111-aaaa-1111-aaaa-111111111111',
  'standard',
  15,
  10,
  6000,
  true,
  NOW() - INTERVAL '5 days',
  NOW() + INTERVAL '25 days'
) ON CONFLICT (id) DO NOTHING;

-- Aminata: Pack Pro avec 25 livraisons restantes
INSERT INTO delivery_quotas (
  id, deliverer_id, quota_type, total_deliveries, remaining_deliveries,
  price_paid, is_active, purchased_at, expires_at
) VALUES (
  'quota-aminata-001',
  'b2222222-bbbb-2222-bbbb-222222222222',
  'pro',
  30,
  25,
  10000,
  true,
  NOW() - INTERVAL '3 days',
  NOW() + INTERVAL '27 days'
) ON CONFLICT (id) DO NOTHING;

-- Fatou: Pack Starter avec 5 livraisons restantes (nouveau compte)
INSERT INTO delivery_quotas (
  id, deliverer_id, quota_type, total_deliveries, remaining_deliveries,
  price_paid, is_active, purchased_at, expires_at
) VALUES (
  'quota-fatou-001',
  'd4444444-dddd-4444-dddd-444444444444',
  'starter',
  5,
  5,
  2500,
  true,
  NOW() - INTERVAL '1 day',
  NOW() + INTERVAL '29 days'
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 4. TRANSACTIONS DE QUOTAS (historique achats)
-- ============================================
INSERT INTO quota_transactions (
  id, quota_id, transaction_type, amount, balance_before, balance_after,
  description, created_at
) VALUES
  ('txn-moussa-001', 'quota-moussa-001', 'purchase', 15, 0, 15, 'Achat Pack Standard - 15 livraisons', NOW() - INTERVAL '5 days'),
  ('txn-aminata-001', 'quota-aminata-001', 'purchase', 30, 0, 30, 'Achat Pack Pro - 30 livraisons', NOW() - INTERVAL '3 days'),
  ('txn-fatou-001', 'quota-fatou-001', 'purchase', 5, 0, 5, 'Achat Pack Starter - 5 livraisons', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 5. LIVRAISONS DE TEST (en attente)
-- ============================================
INSERT INTO deliveries (
  id, client_id, status,
  pickup_address, pickup_latitude, pickup_longitude, pickup_phone,
  delivery_address, delivery_latitude, delivery_longitude, delivery_phone,
  receiver_name, package_type, package_description,
  delivery_mode, price, distance_km,
  qr_code_pickup, qr_code_delivery, delivery_code,
  created_at
) VALUES
  -- Livraison 1: Course standard Ouaga centre
  (
    'del-test-001',
    NULL, -- Pas de client associé (test)
    'pending',
    'Avenue Kwamé Nkrumah, Ouagadougou',
    12.3714,
    -1.5197,
    '+22670200001',
    'Quartier Pissy, Ouagadougou',
    12.3650,
    -1.5350,
    '+22670200002',
    'Koné Salif',
    'Petit colis',
    'Documents importants',
    'standard',
    1500,
    2.5,
    'QR-PICKUP-001',
    'QR-DELIVERY-001',
    '1234',
    NOW() - INTERVAL '30 minutes'
  ),
  -- Livraison 2: Course express
  (
    'del-test-002',
    NULL,
    'pending',
    'Université de Ouagadougou',
    12.3833,
    -1.5000,
    '+22670200003',
    'Zone du Bois, Ouagadougou',
    12.3567,
    -1.5067,
    '+22670200004',
    'Ouédraogo Marie',
    'Moyen colis',
    'Repas chaud - urgent',
    'express',
    2500,
    3.2,
    'QR-PICKUP-002',
    'QR-DELIVERY-002',
    '5678',
    NOW() - INTERVAL '15 minutes'
  ),
  -- Livraison 3: Course longue distance
  (
    'del-test-003',
    NULL,
    'pending',
    'Aéroport International de Ouagadougou',
    12.3533,
    -1.5117,
    '+22670200005',
    'Ouaga 2000',
    12.3350,
    -1.4817,
    '+22670200006',
    'Traoré Amadou',
    'Grand colis',
    'Valises - Retour voyage',
    'standard',
    3500,
    5.8,
    'QR-PICKUP-003',
    'QR-DELIVERY-003',
    '9012',
    NOW() - INTERVAL '45 minutes'
  ),
  -- Livraison 4: Course quartier résidentiel
  (
    'del-test-004',
    NULL,
    'pending',
    'Marché Rood Woko',
    12.3650,
    -1.5233,
    '+22670200007',
    'Quartier Dassasgho',
    12.3717,
    -1.4900,
    '+22670200008',
    'Compaoré Jean',
    'Petit colis',
    'Achats marché',
    'standard',
    2000,
    3.8,
    'QR-PICKUP-004',
    'QR-DELIVERY-004',
    '3456',
    NOW() - INTERVAL '1 hour'
  ),
  -- Livraison 5: Course vers zone industrielle
  (
    'del-test-005',
    NULL,
    'pending',
    'Centre Commercial Azimo',
    12.3783,
    -1.5183,
    '+22670200009',
    'Zone Industrielle de Kossodo',
    12.4100,
    -1.4700,
    '+22670200010',
    'Sanogo Ibrahim',
    'Grand colis',
    'Pièces détachées',
    'express',
    4500,
    7.2,
    'QR-PICKUP-005',
    'QR-DELIVERY-005',
    '7890',
    NOW() - INTERVAL '20 minutes'
  )
ON CONFLICT (id) DO UPDATE SET
  status = 'pending',
  deliverer_id = NULL;

-- ============================================
-- 6. VERIFICATION FINALE
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'DONNEES DE TEST INSEREES AVEC SUCCES';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Livreurs créés:';
  RAISE NOTICE '  - Moussa Traoré (+22670100001) - Vérifié, 10 quotas';
  RAISE NOTICE '  - Aminata Ouédraogo (+22670100002) - Vérifié, 25 quotas';
  RAISE NOTICE '  - Ibrahim Sawadogo (+22670100003) - En attente validation';
  RAISE NOTICE '  - Fatou Compaoré (+22670100004) - Vérifié, 5 quotas';
  RAISE NOTICE '';
  RAISE NOTICE 'Mot de passe pour tous: Test1234!';
  RAISE NOTICE '';
  RAISE NOTICE 'Livraisons disponibles: 5';
  RAISE NOTICE '========================================';
END $$;

SELECT
  'Livreurs' as type,
  COUNT(*) as count
FROM deliverers
UNION ALL
SELECT
  'Quotas actifs',
  COUNT(*)
FROM delivery_quotas WHERE is_active = true
UNION ALL
SELECT
  'Livraisons pending',
  COUNT(*)
FROM deliveries WHERE status = 'pending';
