import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

/**
 * Script pour nettoyer les données de test
 *
 * Usage: pnpm run cleanup-test-data
 *
 * IMPORTANT: Exécuter AVANT de créer les nouveaux utilisateurs
 */

// Numéros de téléphone des anciens utilisateurs de test à supprimer
const OLD_TEST_PHONES = {
  clients: ['+22501020304', '+22507080910'],
  deliverers: ['+22598765432'],
};

// Numéros de téléphone des nouveaux utilisateurs de test à supprimer aussi
const NEW_TEST_PHONES = {
  clients: ['+22670200001', '+22670200002'],
  deliverers: ['+22670100001', '+22670100002', '+22670100003', '+22670100004'],
};

// Emails de test
const TEST_EMAILS = {
  clients: ['client@test.com', 'aya@test.com', 'adama@toto.test', 'salamata@toto.test'],
  deliverers: ['deliverer@test.com', 'moussa@toto.test', 'aminata@toto.test', 'ibrahim@toto.test', 'fatou@toto.test'],
};

async function bootstrap() {
  console.log('🧹 Nettoyage des données de test...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  const allClientPhones = [...OLD_TEST_PHONES.clients, ...NEW_TEST_PHONES.clients];
  const allDelivererPhones = [...OLD_TEST_PHONES.deliverers, ...NEW_TEST_PHONES.deliverers];

  try {
    // ==========================================
    // 1. RÉCUPÉRER LES IDS DES UTILISATEURS DE TEST
    // ==========================================
    console.log('🔍 Recherche des utilisateurs de test...\n');

    // Clients (table users)
    const clientsResult = await dataSource.query(
      `SELECT id, phone_number, email FROM users WHERE phone_number = ANY($1) OR email = ANY($2)`,
      [allClientPhones, TEST_EMAILS.clients]
    );
    const clientIds = clientsResult.map((c: any) => c.id);
    console.log(`   📱 ${clientsResult.length} client(s) trouvé(s)`);

    // Deliverers
    const deliverersResult = await dataSource.query(
      `SELECT id, phone_number, email FROM deliverers WHERE phone_number = ANY($1) OR email = ANY($2)`,
      [allDelivererPhones, TEST_EMAILS.deliverers]
    );
    const delivererIds = deliverersResult.map((d: any) => d.id);
    console.log(`   🚗 ${deliverersResult.length} livreur(s) trouvé(s)\n`);

    if (clientIds.length === 0 && delivererIds.length === 0) {
      console.log('✅ Aucune donnée de test à nettoyer.\n');
      await app.close();
      return;
    }

    // ==========================================
    // 2. SUPPRIMER LES LIVRAISONS
    // ==========================================
    console.log('📦 Suppression des livraisons de test...');

    if (clientIds.length > 0) {
      const delByClient = await dataSource.query(
        `DELETE FROM deliveries WHERE client_id = ANY($1) RETURNING id`,
        [clientIds]
      );
      console.log(`   - ${delByClient.length} livraison(s) de clients supprimée(s)`);
    }

    if (delivererIds.length > 0) {
      const delByDeliverer = await dataSource.query(
        `DELETE FROM deliveries WHERE deliverer_id = ANY($1) RETURNING id`,
        [delivererIds]
      );
      console.log(`   - ${delByDeliverer.length} livraison(s) de livreurs supprimée(s)`);
    }

    // ==========================================
    // 3. SUPPRIMER LES RATINGS ORPHELINS
    // ==========================================
    console.log('\n⭐ Suppression des ratings orphelins...');
    const ratingsDeleted = await dataSource.query(
      `DELETE FROM ratings WHERE delivery_id NOT IN (SELECT id FROM deliveries) RETURNING id`
    );
    console.log(`   - ${ratingsDeleted.length} rating(s) supprimé(s)`);

    // ==========================================
    // 4. SUPPRIMER LES QUOTAS
    // ==========================================
    if (delivererIds.length > 0) {
      console.log('\n📊 Suppression des quotas de test...');

      // Quota transactions
      const quotaTransDeleted = await dataSource.query(
        `DELETE FROM quota_transactions WHERE deliverer_id = ANY($1) RETURNING id`,
        [delivererIds]
      );
      console.log(`   - ${quotaTransDeleted.length} transaction(s) de quotas supprimée(s)`);

      // Delivery quotas
      const quotasDeleted = await dataSource.query(
        `DELETE FROM delivery_quotas WHERE user_id = ANY($1) RETURNING id`,
        [delivererIds]
      );
      console.log(`   - ${quotasDeleted.length} quota(s) supprimé(s)`);
    }

    // ==========================================
    // 5. SUPPRIMER LES REFRESH TOKENS
    // ==========================================
    console.log('\n🔑 Suppression des refresh tokens...');

    if (clientIds.length > 0) {
      const clientTokens = await dataSource.query(
        `DELETE FROM refresh_tokens WHERE user_id = ANY($1) RETURNING id`,
        [clientIds]
      );
      console.log(`   - ${clientTokens.length} token(s) client supprimé(s)`);
    }

    if (delivererIds.length > 0) {
      const delivererTokens = await dataSource.query(
        `DELETE FROM refresh_tokens WHERE user_id = ANY($1) RETURNING id`,
        [delivererIds]
      );
      console.log(`   - ${delivererTokens.length} token(s) livreur supprimé(s)`);
    }

    // ==========================================
    // 6. SUPPRIMER LES CLIENTS (table users)
    // ==========================================
    if (clientIds.length > 0) {
      console.log('\n📱 Suppression des clients de test...');
      const clientsDeleted = await dataSource.query(
        `DELETE FROM users WHERE id = ANY($1) RETURNING phone_number, email`,
        [clientIds]
      );
      clientsDeleted.forEach((c: any) => {
        console.log(`   - ${c.phone_number} (${c.email || 'pas d\'email'})`);
      });
    }

    // ==========================================
    // 7. SUPPRIMER LES LIVREURS
    // ==========================================
    if (delivererIds.length > 0) {
      console.log('\n🚗 Suppression des livreurs de test...');
      const deliverersDeleted = await dataSource.query(
        `DELETE FROM deliverers WHERE id = ANY($1) RETURNING phone_number, email`,
        [delivererIds]
      );
      deliverersDeleted.forEach((d: any) => {
        console.log(`   - ${d.phone_number} (${d.email || 'pas d\'email'})`);
      });
    }

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('✅ NETTOYAGE TERMINÉ AVEC SUCCÈS');
    console.log('═══════════════════════════════════════════════════════════\n');

  } catch (error: any) {
    console.error('❌ Erreur lors du nettoyage:', error.message);
    console.error(error.stack);
  }

  await app.close();
  console.log('🎉 Script terminé!\n');
}

bootstrap().catch((error) => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
