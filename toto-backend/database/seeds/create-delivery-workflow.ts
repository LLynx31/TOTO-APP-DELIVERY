import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

/**
 * Seed pour créer un workflow complet de livraison avec des données réalistes
 *
 * SCÉNARIO: L'utilisateur test (Amadou Ouédraogo) est le DESTINATAIRE
 * D'autres utilisateurs (commerces) lui envoient des colis
 *
 * WORKFLOW DE LIVRAISON:
 * 1. Client crée une livraison → statut: pending
 * 2. Livreur accepte → statut: accepted
 * 3. Livreur en route vers pickup → statut: pickupInProgress
 * 4. Livreur récupère le colis (scan QR) → statut: pickedUp
 * 5. Livreur en route vers destination → statut: deliveryInProgress
 * 6. Livreur livre (scan QR ou code) → statut: delivered
 */
export async function createDeliveryWorkflow(dataSource: DataSource) {
  console.log('📦 Création du workflow de livraison...\n');

  const userRepository = dataSource.getRepository('users');
  const delivererRepository = dataSource.getRepository('deliverers');
  const deliveryRepository = dataSource.getRepository('deliveries');

  // ============================================
  // 1. CRÉER/RÉCUPÉRER L'UTILISATEUR DESTINATAIRE (qui reçoit les colis)
  // ============================================
  const recipientPhone = '+22670123456';
  let recipient = await userRepository.findOne({ where: { phone_number: recipientPhone } });

  if (!recipient) {
    const hashedPassword = await bcrypt.hash('Test@1234', 10);
    recipient = userRepository.create({
      phone_number: recipientPhone,
      full_name: 'Amadou Ouédraogo',
      email: 'amadou.ouedraogo@test.com',
      password_hash: hashedPassword,
      is_verified: true,
      is_active: true,
    });
    await userRepository.save(recipient);
    console.log('✅ Destinataire créé:');
  } else {
    console.log('ℹ️  Destinataire existant:');
  }
  console.log('   Nom: Amadou Ouédraogo');
  console.log('   Téléphone: +22670123456');
  console.log('   Mot de passe: Test@1234');
  console.log('   RÔLE: DESTINATAIRE (reçoit des colis)\n');

  // ============================================
  // 2. CRÉER LES EXPÉDITEURS (clients qui envoient des colis)
  // ============================================
  const senders: any[] = [];

  // Expéditeur 1: Boutique de vêtements
  let sender1 = await userRepository.findOne({ where: { phone_number: '+22670111001' } });
  if (!sender1) {
    const hashedPassword = await bcrypt.hash('Sender@1234', 10);
    sender1 = userRepository.create({
      phone_number: '+22670111001',
      full_name: 'Boutique Mode Ouaga',
      email: 'boutique.mode@test.com',
      password_hash: hashedPassword,
      is_verified: true,
      is_active: true,
    });
    await userRepository.save(sender1);
  }
  senders.push(sender1);
  console.log('✅ Expéditeur 1: Boutique Mode Ouaga (+22670111001)');

  // Expéditeur 2: Restaurant
  let sender2 = await userRepository.findOne({ where: { phone_number: '+22670111002' } });
  if (!sender2) {
    const hashedPassword = await bcrypt.hash('Sender@1234', 10);
    sender2 = userRepository.create({
      phone_number: '+22670111002',
      full_name: 'Restaurant Le Délice',
      email: 'restaurant.delice@test.com',
      password_hash: hashedPassword,
      is_verified: true,
      is_active: true,
    });
    await userRepository.save(sender2);
  }
  senders.push(sender2);
  console.log('✅ Expéditeur 2: Restaurant Le Délice (+22670111002)');

  // Expéditeur 3: Pharmacie
  let sender3 = await userRepository.findOne({ where: { phone_number: '+22670111003' } });
  if (!sender3) {
    const hashedPassword = await bcrypt.hash('Sender@1234', 10);
    sender3 = userRepository.create({
      phone_number: '+22670111003',
      full_name: 'Pharmacie du Centre',
      email: 'pharmacie.centre@test.com',
      password_hash: hashedPassword,
      is_verified: true,
      is_active: true,
    });
    await userRepository.save(sender3);
  }
  senders.push(sender3);
  console.log('✅ Expéditeur 3: Pharmacie du Centre (+22670111003)');

  // Expéditeur 4: Librairie
  let sender4 = await userRepository.findOne({ where: { phone_number: '+22670111004' } });
  if (!sender4) {
    const hashedPassword = await bcrypt.hash('Sender@1234', 10);
    sender4 = userRepository.create({
      phone_number: '+22670111004',
      full_name: 'Librairie Jeunesse',
      email: 'librairie.jeunesse@test.com',
      password_hash: hashedPassword,
      is_verified: true,
      is_active: true,
    });
    await userRepository.save(sender4);
  }
  senders.push(sender4);
  console.log('✅ Expéditeur 4: Librairie Jeunesse (+22670111004)\n');

  // ============================================
  // 3. CRÉER UN LIVREUR DE TEST
  // ============================================
  const delivererPhone = '+22676543210';
  const delivererEmail = 'ibrahim.sawadogo@test.com';
  let deliverer = await delivererRepository.findOne({
    where: [
      { phone_number: delivererPhone },
      { email: delivererEmail }
    ]
  });

  if (!deliverer) {
    const hashedPassword = await bcrypt.hash('Livreur@1234', 10);
    deliverer = delivererRepository.create({
      phone_number: delivererPhone,
      full_name: 'Ibrahim Sawadogo',
      email: delivererEmail,
      password_hash: hashedPassword,
      vehicle_type: 'Moto',
      license_plate: '1234 BF A',
      kyc_status: 'approved',
      is_available: true,
      is_active: true,
      is_verified: true,
      total_deliveries: 127,
      rating: 4.8,
    });
    await delivererRepository.save(deliverer);
    console.log('✅ Livreur créé: Ibrahim Sawadogo (+22676543210)\n');
  } else {
    console.log('ℹ️  Livreur existant: Ibrahim Sawadogo (+22676543210)\n');
  }

  // ============================================
  // 4. SUPPRIMER LES ANCIENNES LIVRAISONS DE TEST
  // ============================================
  console.log('📦 Création des livraisons vers Amadou Ouédraogo...\n');

  // Supprimer les anciennes livraisons où il est destinataire (par téléphone)
  await deliveryRepository
    .createQueryBuilder()
    .delete()
    .where('delivery_phone = :phone', { phone: recipientPhone })
    .execute();

  // Supprimer aussi celles où il était client (ancien scénario)
  await deliveryRepository.delete({ client_id: recipient.id });

  // Supprimer les livraisons des expéditeurs de test
  for (const sender of senders) {
    await deliveryRepository.delete({ client_id: sender.id });
  }

  console.log('🗑️  Anciennes livraisons de test supprimées\n');

  // Fonction helper pour générer un code de livraison à 4 chiffres unique
  const generateDeliveryCode = async () => {
    let code: string = '';
    let exists = true;
    while (exists) {
      code = Math.floor(1000 + Math.random() * 9000).toString();
      const existing = await deliveryRepository.findOne({ where: { delivery_code: code } });
      exists = !!existing;
    }
    return code;
  };

  // Adresse du destinataire (Amadou) - sa maison
  const recipientAddress = {
    address: 'Ouaga 2000, Résidence Les Palmiers, Villa 12',
    lat: 12.3356,
    lng: -1.4891,
  };

  // Adresses des expéditeurs (points de pickup)
  const senderLocations = {
    boutique: {
      address: 'Avenue Kwamé Nkrumah, Centre Commercial',
      lat: 12.3714,
      lng: -1.5197,
    },
    restaurant: {
      address: 'Zone du Bois, Restaurant Le Délice',
      lat: 12.3686,
      lng: -1.5275,
    },
    pharmacie: {
      address: 'Rond-point des Nations Unies, Pharmacie du Centre',
      lat: 12.3589,
      lng: -1.5089,
    },
    librairie: {
      address: 'Secteur 4, Librairie Jeunesse',
      lat: 12.3812,
      lng: -1.5156,
    },
  };

  // ============================================
  // LIVRAISON 1: EN ATTENTE DE LIVREUR (pending)
  // La boutique envoie des vêtements à Amadou
  // ============================================
  const delivery1Id = uuidv4();
  const delivery1Code = await generateDeliveryCode();

  const delivery1 = deliveryRepository.create({
    id: delivery1Id,
    client_id: sender1.id, // Boutique Mode Ouaga est l'expéditeur
    deliverer_id: null,
    pickup_address: senderLocations.boutique.address,
    pickup_latitude: senderLocations.boutique.lat,
    pickup_longitude: senderLocations.boutique.lng,
    pickup_phone: sender1.phone_number,
    delivery_address: recipientAddress.address,
    delivery_latitude: recipientAddress.lat,
    delivery_longitude: recipientAddress.lng,
    delivery_phone: recipientPhone, // Amadou est le destinataire
    receiver_name: 'Amadou Ouédraogo',
    package_description: 'Commande vêtements - 2 chemises et 1 pantalon',
    package_weight: 1.5,
    qr_code_pickup: `PICKUP-${delivery1Id}`,
    qr_code_delivery: `DELIVERY-${delivery1Id}`,
    delivery_code: delivery1Code,
    status: 'pending',
    price: 1500,
    distance_km: 4.2,
    special_instructions: 'Appeler 5 minutes avant l\'arrivée',
    created_at: new Date(),
  });
  await deliveryRepository.save(delivery1);
  console.log('📍 Livraison 1 (PENDING - En attente de livreur):');
  console.log(`   Expéditeur: Boutique Mode Ouaga`);
  console.log(`   Destinataire: Amadou Ouédraogo`);
  console.log(`   Colis: Commande vêtements`);
  console.log(`   Code de validation: ${delivery1Code}`);
  console.log(`   Prix: 1500 FCFA\n`);

  // ============================================
  // LIVRAISON 2: ACCEPTÉE PAR LIVREUR (accepted)
  // Le restaurant envoie un repas à Amadou
  // ============================================
  const delivery2Id = uuidv4();
  const delivery2Code = await generateDeliveryCode();

  const delivery2 = deliveryRepository.create({
    id: delivery2Id,
    client_id: sender2.id, // Restaurant Le Délice est l'expéditeur
    deliverer_id: deliverer.id,
    pickup_address: senderLocations.restaurant.address,
    pickup_latitude: senderLocations.restaurant.lat,
    pickup_longitude: senderLocations.restaurant.lng,
    pickup_phone: sender2.phone_number,
    delivery_address: recipientAddress.address,
    delivery_latitude: recipientAddress.lat,
    delivery_longitude: recipientAddress.lng,
    delivery_phone: recipientPhone,
    receiver_name: 'Amadou Ouédraogo',
    package_description: 'Commande repas - Menu Africain Complet',
    package_weight: 2.0,
    qr_code_pickup: `PICKUP-${delivery2Id}`,
    qr_code_delivery: `DELIVERY-${delivery2Id}`,
    delivery_code: delivery2Code,
    status: 'accepted',
    price: 2000,
    distance_km: 3.8,
    special_instructions: 'Repas chaud - livrer rapidement',
    created_at: new Date(Date.now() - 15 * 60 * 1000),
    accepted_at: new Date(Date.now() - 10 * 60 * 1000),
  });
  await deliveryRepository.save(delivery2);
  console.log('📍 Livraison 2 (ACCEPTED - Livreur en route vers pickup):');
  console.log(`   Expéditeur: Restaurant Le Délice`);
  console.log(`   Destinataire: Amadou Ouédraogo`);
  console.log(`   Colis: Menu Africain Complet`);
  console.log(`   Code de validation: ${delivery2Code}`);
  console.log(`   Livreur assigné: Ibrahim Sawadogo`);
  console.log(`   Prix: 2000 FCFA\n`);

  // ============================================
  // LIVRAISON 3: COLIS RÉCUPÉRÉ (pickedUp)
  // La pharmacie envoie des médicaments à Amadou
  // ============================================
  const delivery3Id = uuidv4();
  const delivery3Code = await generateDeliveryCode();

  const delivery3 = deliveryRepository.create({
    id: delivery3Id,
    client_id: sender3.id, // Pharmacie du Centre est l'expéditeur
    deliverer_id: deliverer.id,
    pickup_address: senderLocations.pharmacie.address,
    pickup_latitude: senderLocations.pharmacie.lat,
    pickup_longitude: senderLocations.pharmacie.lng,
    pickup_phone: sender3.phone_number,
    delivery_address: recipientAddress.address,
    delivery_latitude: recipientAddress.lat,
    delivery_longitude: recipientAddress.lng,
    delivery_phone: recipientPhone,
    receiver_name: 'Amadou Ouédraogo',
    package_description: 'Commande pharmacie - Médicaments sur ordonnance',
    package_weight: 0.5,
    qr_code_pickup: `PICKUP-${delivery3Id}`,
    qr_code_delivery: `DELIVERY-${delivery3Id}`,
    delivery_code: delivery3Code,
    status: 'pickedUp',
    price: 1000,
    distance_km: 2.5,
    special_instructions: 'Fragile - Médicaments à garder au frais',
    created_at: new Date(Date.now() - 45 * 60 * 1000),
    accepted_at: new Date(Date.now() - 35 * 60 * 1000),
    picked_up_at: new Date(Date.now() - 10 * 60 * 1000),
  });
  await deliveryRepository.save(delivery3);
  console.log('📍 Livraison 3 (PICKED_UP - Colis récupéré, en route vers vous):');
  console.log(`   Expéditeur: Pharmacie du Centre`);
  console.log(`   Destinataire: Amadou Ouédraogo`);
  console.log(`   Colis: Médicaments sur ordonnance`);
  console.log(`   Code de validation: ${delivery3Code}`);
  console.log(`   Livreur: Ibrahim Sawadogo (en route)`);
  console.log(`   Prix: 1000 FCFA\n`);

  // ============================================
  // LIVRAISON 4: LIVRÉE (delivered)
  // La librairie a envoyé des livres à Amadou (hier)
  // ============================================
  const delivery4Id = uuidv4();
  const delivery4Code = await generateDeliveryCode();

  const delivery4 = deliveryRepository.create({
    id: delivery4Id,
    client_id: sender4.id, // Librairie Jeunesse est l'expéditeur
    deliverer_id: deliverer.id,
    pickup_address: senderLocations.librairie.address,
    pickup_latitude: senderLocations.librairie.lat,
    pickup_longitude: senderLocations.librairie.lng,
    pickup_phone: sender4.phone_number,
    delivery_address: recipientAddress.address,
    delivery_latitude: recipientAddress.lat,
    delivery_longitude: recipientAddress.lng,
    delivery_phone: recipientPhone,
    receiver_name: 'Amadou Ouédraogo',
    package_description: 'Commande livres - 3 romans et 1 dictionnaire',
    package_weight: 3.0,
    qr_code_pickup: `PICKUP-${delivery4Id}`,
    qr_code_delivery: `DELIVERY-${delivery4Id}`,
    delivery_code: delivery4Code,
    status: 'delivered',
    price: 1800,
    distance_km: 3.2,
    special_instructions: null,
    created_at: new Date(Date.now() - 24 * 60 * 60 * 1000), // Hier
    accepted_at: new Date(Date.now() - 23 * 60 * 60 * 1000),
    picked_up_at: new Date(Date.now() - 22 * 60 * 60 * 1000),
    delivered_at: new Date(Date.now() - 21 * 60 * 60 * 1000),
  });
  await deliveryRepository.save(delivery4);
  console.log('📍 Livraison 4 (DELIVERED - Livrée hier):');
  console.log(`   Expéditeur: Librairie Jeunesse`);
  console.log(`   Destinataire: Amadou Ouédraogo`);
  console.log(`   Colis: 3 romans et 1 dictionnaire`);
  console.log(`   ✅ Livrée avec succès`);
  console.log(`   Prix: 1800 FCFA\n`);

  // ============================================
  // RÉSUMÉ
  // ============================================
  console.log('═══════════════════════════════════════════════════════════');
  console.log('                    RÉSUMÉ DU WORKFLOW');
  console.log('═══════════════════════════════════════════════════════════\n');

  console.log('👤 COMPTE DESTINATAIRE (pour tester la réception de colis):');
  console.log('   Téléphone: +22670123456');
  console.log('   Mot de passe: Test@1234');
  console.log('   Nom: Amadou Ouédraogo');
  console.log('   RÔLE: Reçoit des colis de différents commerces\n');

  console.log('🏪 EXPÉDITEURS (commerces qui envoient à Amadou):');
  console.log('   1. Boutique Mode Ouaga (+22670111001) - Sender@1234');
  console.log('   2. Restaurant Le Délice (+22670111002) - Sender@1234');
  console.log('   3. Pharmacie du Centre (+22670111003) - Sender@1234');
  console.log('   4. Librairie Jeunesse (+22670111004) - Sender@1234\n');

  console.log('🛵 COMPTE LIVREUR:');
  console.log('   Téléphone: +22676543210');
  console.log('   Mot de passe: Livreur@1234\n');

  console.log('📦 LIVRAISONS EN ATTENTE POUR AMADOU:');
  console.log('   1. PENDING   → Vêtements de la Boutique (code: ' + delivery1Code + ')');
  console.log('   2. ACCEPTED  → Repas du Restaurant (code: ' + delivery2Code + ')');
  console.log('   3. PICKED_UP → Médicaments de la Pharmacie (code: ' + delivery3Code + ')');
  console.log('   4. DELIVERED → Livres de la Librairie (code: ' + delivery4Code + ')\n');

  console.log('═══════════════════════════════════════════════════════════\n');
}
