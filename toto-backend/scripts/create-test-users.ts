import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

/**
 * Script pour créer les utilisateurs de test selon le README
 *
 * Usage:
 *   1. pnpm run cleanup-test-data  (nettoyer les anciennes données)
 *   2. pnpm run create-test-users  (créer les nouveaux utilisateurs)
 */

// Configuration des utilisateurs de test selon le README
const TEST_PASSWORD = 'Test1234!';

// Livreurs de test
const DELIVERERS = [
  {
    phone_number: '+22670100001',
    full_name: 'Moussa Ouédraogo',
    email: 'moussa@toto.test',
    vehicle_type: 'Moto',
    license_plate: 'A-1234-BF',
    is_verified: true,
    is_available: true,
    is_active: true,
    rating: 4.8,
    total_deliveries: 156,
    kyc_status: 'approved',
  },
  {
    phone_number: '+22670100002',
    full_name: 'Aminata Sawadogo',
    email: 'aminata@toto.test',
    vehicle_type: 'Vélo',
    license_plate: null,
    is_verified: true,
    is_available: true,
    is_active: true,
    rating: 4.9,
    total_deliveries: 89,
    kyc_status: 'approved',
  },
  {
    phone_number: '+22670100003',
    full_name: 'Ibrahim Traoré',
    email: 'ibrahim@toto.test',
    vehicle_type: 'Moto',
    license_plate: 'B-5678-BF',
    is_verified: true,
    is_available: false,
    is_active: true,
    rating: 4.5,
    total_deliveries: 234,
    kyc_status: 'approved',
  },
  {
    phone_number: '+22670100004',
    full_name: 'Fatou Compaoré',
    email: 'fatou@toto.test',
    vehicle_type: 'Voiture',
    license_plate: 'C-9012-BF',
    is_verified: false,
    is_available: false,
    is_active: true,
    rating: 0,
    total_deliveries: 0,
    kyc_status: 'pending',
  },
];

// Clients de test (table users)
const CLIENTS = [
  {
    phone_number: '+22670200001',
    full_name: 'Adama Kaboré',
    email: 'adama@toto.test',
  },
  {
    phone_number: '+22670200002',
    full_name: 'Salamata Zongo',
    email: 'salamata@toto.test',
  },
];

// Packages de quotas (pour référence dans les logs)
const QUOTA_PACKAGES = {
  starter: { name: 'Starter', quotas: 10, price: 5000, bonus: 0 },
  standard: { name: 'Standard', quotas: 25, price: 10000, bonus: 5 },
  pro: { name: 'Pro', quotas: 50, price: 18000, bonus: 10 },
  premium: { name: 'Premium', quotas: 100, price: 30000, bonus: 25 },
} as const;

// Livraisons de test à Ouagadougou
const TEST_DELIVERIES = [
  {
    pickup_address: 'Marché Rood Woko, Ouagadougou',
    pickup_lat: 12.3686,
    pickup_lng: -1.5275,
    pickup_phone: '+22670400001',
    delivery_address: 'Quartier Pissy, Ouagadougou',
    delivery_lat: 12.3456,
    delivery_lng: -1.5123,
    delivery_phone: '+22670300001',
    receiver_name: 'Mamadou Diallo',
    package_description: 'Documents administratifs',
    price: 1500,
    status: 'delivered',
    distance_km: 3.2,
  },
  {
    pickup_address: 'Pharmacie Centrale, Avenue Kwame Nkrumah',
    pickup_lat: 12.3721,
    pickup_lng: -1.5196,
    pickup_phone: '+22670400002',
    delivery_address: 'Hôpital Yalgado, Ouagadougou',
    delivery_lat: 12.3634,
    delivery_lng: -1.5089,
    delivery_phone: '+22670300002',
    receiver_name: 'Dr. Ousmane Kéré',
    package_description: 'Médicaments urgents',
    price: 2000,
    status: 'delivered',
    distance_km: 2.1,
  },
  {
    pickup_address: 'Zone Commerciale de Ouaga 2000',
    pickup_lat: 12.3312,
    pickup_lng: -1.4856,
    pickup_phone: '+22670400003',
    delivery_address: 'Université Joseph Ki-Zerbo',
    delivery_lat: 12.3823,
    delivery_lng: -1.4978,
    delivery_phone: '+22670300003',
    receiver_name: 'Prof. Aïcha Traoré',
    package_description: 'Livres et fournitures',
    price: 3500,
    status: 'accepted',
    distance_km: 5.8,
  },
  {
    pickup_address: 'Supermarché Marina Market',
    pickup_lat: 12.3654,
    pickup_lng: -1.5234,
    pickup_phone: '+22670400004',
    delivery_address: 'Quartier Tampouy, Ouagadougou',
    delivery_lat: 12.3912,
    delivery_lng: -1.5456,
    delivery_phone: '+22670300004',
    receiver_name: 'Famille Compaoré',
    package_description: 'Courses alimentaires',
    price: 2500,
    status: 'pending',
    distance_km: 4.5,
  },
  {
    pickup_address: 'Artisanat de Ouagadougou',
    pickup_lat: 12.3698,
    pickup_lng: -1.5312,
    pickup_phone: '+22670400005',
    delivery_address: 'Aéroport International de Ouagadougou',
    delivery_lat: 12.3532,
    delivery_lng: -1.5123,
    delivery_phone: '+22670300005',
    receiver_name: 'M. Jean-Pierre Dubois',
    package_description: 'Souvenirs et artisanat',
    price: 4000,
    status: 'pending',
    distance_km: 6.2,
  },
];

// Générer un code QR unique
function generateQRCode(): string {
  return `QR-${uuidv4()}`;
}

// Générer un code de livraison à 4 chiffres
function generateDeliveryCode(): string {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

async function bootstrap() {
  console.log('🚀 Création des utilisateurs de test selon le README...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  // Hash du mot de passe
  const hashedPassword = await bcrypt.hash(TEST_PASSWORD, 10);

  // ==========================================
  // 1. CRÉER LES LIVREURS
  // ==========================================
  console.log('🚗 Création des livreurs de test...\n');

  const delivererIds: string[] = [];

  for (const deliverer of DELIVERERS) {
    const id = uuidv4();
    delivererIds.push(id);

    try {
      await dataSource.query(
        `INSERT INTO deliverers (
          id, phone_number, full_name, email, password_hash,
          vehicle_type, license_plate, is_verified, is_available, is_active,
          rating, total_deliveries, kyc_status, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW(), NOW())`,
        [
          id,
          deliverer.phone_number,
          deliverer.full_name,
          deliverer.email,
          hashedPassword,
          deliverer.vehicle_type,
          deliverer.license_plate,
          deliverer.is_verified,
          deliverer.is_available,
          deliverer.is_active,
          deliverer.rating,
          deliverer.total_deliveries,
          deliverer.kyc_status,
        ],
      );

      console.log(`✅ Livreur créé: ${deliverer.full_name}`);
      console.log(`   📱 ${deliverer.phone_number} | 📧 ${deliverer.email}`);
      console.log(`   🚗 ${deliverer.vehicle_type} | KYC: ${deliverer.kyc_status}`);
      console.log(
        `   ⭐ ${deliverer.rating} | 📦 ${deliverer.total_deliveries} livraisons\n`,
      );
    } catch (error: any) {
      if (error.code === '23505') {
        console.log(`ℹ️  Livreur ${deliverer.full_name} déjà existant\n`);
        // Récupérer l'ID existant
        const existing = await dataSource.query(
          `SELECT id FROM deliverers WHERE phone_number = $1`,
          [deliverer.phone_number],
        );
        if (existing.length > 0) {
          delivererIds[delivererIds.length - 1] = existing[0].id;
        }
      } else {
        console.log(
          `❌ Erreur pour ${deliverer.full_name}:`,
          error.message,
          '\n',
        );
      }
    }
  }

  // ==========================================
  // 2. CRÉER LES QUOTAS POUR LES LIVREURS VÉRIFIÉS
  // ==========================================
  console.log('📊 Attribution des quotas aux livreurs vérifiés...\n');

  // Structure de delivery_quotas: user_id, quota_type, total_deliveries, used_deliveries, remaining_deliveries, price_paid
  const quotaAssignments = [
    {
      delivererId: delivererIds[0],
      name: 'Moussa',
      quotaType: 'premium',
      total: 60,
      used: 12,
      price: 18000,
    },
    {
      delivererId: delivererIds[1],
      name: 'Aminata',
      quotaType: 'standard',
      total: 30,
      used: 5,
      price: 10000,
    },
    {
      delivererId: delivererIds[2],
      name: 'Ibrahim',
      quotaType: 'premium',
      total: 125,
      used: 87,
      price: 30000,
    },
  ];

  for (const quota of quotaAssignments) {
    if (quota.delivererId) {
      try {
        const quotaId = uuidv4();
        await dataSource.query(
          `INSERT INTO delivery_quotas (
            id, user_id, quota_type, total_deliveries, used_deliveries, remaining_deliveries,
            price_paid, is_active, expires_at, purchased_at, updated_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, true, $8, NOW(), NOW())`,
          [
            quotaId,
            quota.delivererId,
            quota.quotaType,
            quota.total,
            quota.used,
            quota.total - quota.used,
            quota.price,
            new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          ],
        );
        console.log(
          `✅ Quotas ${quota.name}: ${quota.total} total, ${quota.used} utilisés (${quota.total - quota.used} restants)`,
        );
      } catch (error: any) {
        console.log(`❌ Erreur quotas ${quota.name}:`, error.message);
      }
    }
  }

  console.log('');

  // ==========================================
  // 3. CRÉER LES CLIENTS (table users)
  // ==========================================
  console.log('📱 Création des clients de test...\n');

  const clientIds: string[] = [];

  for (const client of CLIENTS) {
    const id = uuidv4();
    clientIds.push(id);

    try {
      await dataSource.query(
        `INSERT INTO users (
          id, phone_number, full_name, email, password_hash, is_verified, is_active, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, true, true, NOW(), NOW())`,
        [id, client.phone_number, client.full_name, client.email, hashedPassword],
      );

      console.log(`✅ Client créé: ${client.full_name}`);
      console.log(`   📱 ${client.phone_number} | 📧 ${client.email}\n`);
    } catch (error: any) {
      if (error.code === '23505') {
        console.log(`ℹ️  Client ${client.full_name} déjà existant\n`);
        // Récupérer l'ID existant
        const existing = await dataSource.query(
          `SELECT id FROM users WHERE phone_number = $1`,
          [client.phone_number],
        );
        if (existing.length > 0) {
          clientIds[clientIds.length - 1] = existing[0].id;
        }
      } else {
        console.log(`❌ Erreur pour ${client.full_name}:`, error.message, '\n');
      }
    }
  }

  // ==========================================
  // 4. CRÉER LES LIVRAISONS DE TEST
  // ==========================================
  console.log('📦 Création des livraisons de test à Ouagadougou...\n');

  for (let i = 0; i < TEST_DELIVERIES.length; i++) {
    const delivery = TEST_DELIVERIES[i];
    const deliveryId = uuidv4();
    const clientId = clientIds[i % clientIds.length];

    // Assigner un livreur aux livraisons acceptées ou livrées
    let delivererId: string | null = null;
    if (delivery.status === 'delivered' || delivery.status === 'accepted') {
      delivererId = delivererIds[i % 3]; // Moussa, Aminata, ou Ibrahim (pas Fatou car non vérifiée)
    }

    // Générer les codes QR et le code de livraison
    const qrCodePickup = generateQRCode();
    const qrCodeDelivery = generateQRCode();
    const deliveryCode = generateDeliveryCode();

    try {
      await dataSource.query(
        `INSERT INTO deliveries (
          id, client_id, deliverer_id, status,
          pickup_address, pickup_latitude, pickup_longitude, pickup_phone,
          delivery_address, delivery_latitude, delivery_longitude, delivery_phone,
          receiver_name, package_description, price, distance_km,
          qr_code_pickup, qr_code_delivery, delivery_code,
          created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, NOW(), NOW())`,
        [
          deliveryId,
          clientId,
          delivererId,
          delivery.status,
          delivery.pickup_address,
          delivery.pickup_lat,
          delivery.pickup_lng,
          delivery.pickup_phone,
          delivery.delivery_address,
          delivery.delivery_lat,
          delivery.delivery_lng,
          delivery.delivery_phone,
          delivery.receiver_name,
          delivery.package_description,
          delivery.price,
          delivery.distance_km,
          qrCodePickup,
          qrCodeDelivery,
          deliveryCode,
        ],
      );

      console.log(`✅ Livraison créée: ${delivery.package_description}`);
      console.log(`   📍 ${delivery.pickup_address.substring(0, 35)}...`);
      console.log(`   🎯 ${delivery.delivery_address.substring(0, 35)}...`);
      console.log(
        `   💰 ${delivery.price} FCFA | Status: ${delivery.status}\n`,
      );
    } catch (error: any) {
      console.log(`❌ Erreur livraison:`, error.message, '\n');
    }
  }

  // ==========================================
  // RÉSUMÉ
  // ==========================================
  console.log(
    '\n═══════════════════════════════════════════════════════════════════',
  );
  console.log('✅ UTILISATEURS DE TEST CRÉÉS SELON LE README');
  console.log(
    '═══════════════════════════════════════════════════════════════════\n',
  );

  console.log('🔐 MOT DE PASSE UNIVERSEL: Test1234!\n');

  console.log('🚗 LIVREURS (4):');
  console.log(
    '┌─────────────────────────────────────────────────────────────────┐',
  );
  console.log(
    '│ Nom              │ Téléphone     │ Véhicule │ KYC      │ Rating │',
  );
  console.log(
    '├─────────────────────────────────────────────────────────────────┤',
  );
  console.log(
    '│ Moussa Ouédraogo │ +22670100001  │ Moto     │ approved │ 4.8    │',
  );
  console.log(
    '│ Aminata Sawadogo │ +22670100002  │ Vélo     │ approved │ 4.9    │',
  );
  console.log(
    '│ Ibrahim Traoré   │ +22670100003  │ Moto     │ approved │ 4.5    │',
  );
  console.log(
    '│ Fatou Compaoré   │ +22670100004  │ Voiture  │ pending  │ 0      │',
  );
  console.log(
    '└─────────────────────────────────────────────────────────────────┘\n',
  );

  console.log('📱 CLIENTS (2):');
  console.log(
    '┌─────────────────────────────────────────────────────────────────┐',
  );
  console.log(
    '│ Nom              │ Téléphone     │ Email                        │',
  );
  console.log(
    '├─────────────────────────────────────────────────────────────────┤',
  );
  console.log(
    '│ Adama Kaboré     │ +22670200001  │ adama@toto.test              │',
  );
  console.log(
    '│ Salamata Zongo   │ +22670200002  │ salamata@toto.test           │',
  );
  console.log(
    '└─────────────────────────────────────────────────────────────────┘\n',
  );

  console.log('📦 LIVRAISONS (5): À Ouagadougou');
  console.log('   - 2 livrées');
  console.log('   - 1 acceptée (en cours)');
  console.log('   - 2 en attente\n');

  console.log('📊 PACKAGES QUOTAS:');
  console.log(
    `   - ${QUOTA_PACKAGES.starter.name}:  ${QUOTA_PACKAGES.starter.quotas} quotas à ${QUOTA_PACKAGES.starter.price.toLocaleString()} FCFA`,
  );
  console.log(
    `   - ${QUOTA_PACKAGES.standard.name}: ${QUOTA_PACKAGES.standard.quotas} quotas à ${QUOTA_PACKAGES.standard.price.toLocaleString()} FCFA (+${QUOTA_PACKAGES.standard.bonus} bonus)`,
  );
  console.log(
    `   - ${QUOTA_PACKAGES.pro.name}:      ${QUOTA_PACKAGES.pro.quotas} quotas à ${QUOTA_PACKAGES.pro.price.toLocaleString()} FCFA (+${QUOTA_PACKAGES.pro.bonus} bonus)`,
  );
  console.log(
    `   - ${QUOTA_PACKAGES.premium.name}: ${QUOTA_PACKAGES.premium.quotas} quotas à ${QUOTA_PACKAGES.premium.price.toLocaleString()} FCFA (+${QUOTA_PACKAGES.premium.bonus} bonus)\n`,
  );

  console.log('💡 UTILISATION:');
  console.log(
    '   1. App Client: Se connecter avec adama@toto.test ou +22670200001',
  );
  console.log(
    '   2. App Livreur: Se connecter avec moussa@toto.test ou +22670100001',
  );
  console.log('   3. Mot de passe: Test1234!\n');

  await app.close();
  console.log('🎉 Script terminé avec succès!\n');
}

bootstrap().catch((error) => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
