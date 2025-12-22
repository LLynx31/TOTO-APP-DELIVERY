import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AuthService } from '../src/auth/auth.service';
import { RegisterDto, RegisterDelivererDto } from '../src/auth/dto/register.dto';

/**
 * Script pour créer des utilisateurs de test
 *
 * Usage: npx ts-node scripts/create-test-users.ts
 */

async function bootstrap() {
  console.log('🚀 Création des utilisateurs de test...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const authService = app.get(AuthService);

  // ==========================================
  // 1. CRÉER CLIENT DE TEST
  // ==========================================
  console.log('📱 Création du client de test...');

  const clientDto: RegisterDto = {
    phone_number: '+22501020304',
    full_name: 'Jean Dupont',
    email: 'client@test.com',
    password: 'Password123!',
  };

  try {
    const client = await authService.registerClient(clientDto);
    console.log('✅ Client créé avec succès:');
    console.log(`   Email: ${clientDto.email}`);
    console.log(`   Phone: ${clientDto.phone_number}`);
    console.log(`   Password: ${clientDto.password}`);
    console.log(`   ID: ${(client as any).client?.id || 'N/A'}\n`);
  } catch (error: any) {
    if (error.status === 409) {
      console.log('ℹ️  Client déjà existant\n');
    } else {
      console.log('❌ Erreur:', error.message, '\n');
    }
  }

  // ==========================================
  // 2. CRÉER LIVREUR DE TEST
  // ==========================================
  console.log('🚗 Création du livreur de test...');

  const delivererDto: RegisterDelivererDto = {
    phone_number: '+22598765432',
    full_name: 'Kouadio Yao',
    email: 'deliverer@test.com',
    password: 'Password123!',
    vehicle_type: 'Moto',
    license_plate: 'AB-1234-CI',
  };

  try {
    const deliverer = await authService.registerDeliverer(delivererDto);
    console.log('✅ Livreur créé avec succès:');
    console.log(`   Email: ${delivererDto.email}`);
    console.log(`   Phone: ${delivererDto.phone_number}`);
    console.log(`   Password: ${delivererDto.password}`);
    console.log(`   ID: ${(deliverer as any).deliverer?.id || 'N/A'}\n`);
  } catch (error: any) {
    if (error.status === 409) {
      console.log('ℹ️  Livreur déjà existant\n');
    } else {
      console.log('❌ Erreur:', error.message, '\n');
    }
  }

  // ==========================================
  // 3. CRÉER CLIENT SUPPLÉMENTAIRE
  // ==========================================
  console.log('📱 Création d\'un second client...');

  const client2Dto: RegisterDto = {
    phone_number: '+22507080910',
    full_name: 'Aya Kouassi',
    email: 'aya@test.com',
    password: 'Password123!',
  };

  try {
    const client2 = await authService.registerClient(client2Dto);
    console.log('✅ Client 2 créé avec succès:');
    console.log(`   Email: ${client2Dto.email}`);
    console.log(`   Phone: ${client2Dto.phone_number}`);
    console.log(`   Password: ${client2Dto.password}`);
    console.log(`   ID: ${(client2 as any).client?.id || 'N/A'}\n`);
  } catch (error: any) {
    if (error.status === 409) {
      console.log('ℹ️  Client 2 déjà existant\n');
    } else {
      console.log('❌ Erreur:', error.message, '\n');
    }
  }

  // ==========================================
  // RÉSUMÉ
  // ==========================================
  console.log('═══════════════════════════════════════════════════════════');
  console.log('✅ UTILISATEURS DE TEST CRÉÉS');
  console.log('═══════════════════════════════════════════════════════════\n');

  console.log('📱 CLIENTS:');
  console.log('   1. client@test.com / Password123!');
  console.log('   2. aya@test.com / Password123!\n');

  console.log('🚗 LIVREURS:');
  console.log('   1. deliverer@test.com / Password123!\n');

  console.log('💡 UTILISATION:');
  console.log('   - Ouvrir l\'app Flutter');
  console.log('   - Se connecter avec un des comptes ci-dessus');
  console.log('   - Tester le workflow de livraison\n');

  console.log('🔗 ENDPOINTS À TESTER:');
  console.log('   POST http://localhost:3000/auth/client/login');
  console.log('   POST http://localhost:3000/deliveries');
  console.log('   POST http://localhost:3000/deliveries/:id/rate\n');

  await app.close();
  console.log('🎉 Script terminé avec succès!\n');
}

bootstrap().catch((error) => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
