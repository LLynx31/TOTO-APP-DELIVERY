import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import { createSuperAdmin } from './seeds/create-super-admin';

// Load environment variables
config();

async function runSeeds() {
  console.log('🌱 Starting database seeding...\n');

  // Create TypeORM data source
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    username: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_DATABASE || 'toto_db',
    entities: ['src/**/*.entity.ts'],
    synchronize: false,
  });

  try {
    // Initialize connection
    await dataSource.initialize();
    console.log('📦 Database connected\n');

    // Run seeds
    await createSuperAdmin(dataSource);

    console.log('\n✅ All seeds completed successfully!');
  } catch (error) {
    console.error('❌ Error during seeding:', error);
    process.exit(1);
  } finally {
    // Close connection
    await dataSource.destroy();
    console.log('\n📦 Database connection closed');
  }
}

runSeeds();


