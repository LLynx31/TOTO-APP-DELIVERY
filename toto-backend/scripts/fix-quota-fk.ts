import { DataSource } from 'typeorm';
import * as path from 'path';
import * as fs from 'fs';

// Import de la configuration TypeORM
import { AppDataSource } from '../src/data-source';

async function fixQuotaFK() {
  console.log('🔄 Fixing delivery_quotas foreign key...\n');

  try {
    // Initialiser la connexion
    await AppDataSource.initialize();
    console.log('✅ Database connection initialized\n');

    // Lire le fichier SQL
    const sqlFile = path.join(__dirname, 'change-quotas-fk-to-deliverers.sql');
    const sqlContent = fs.readFileSync(sqlFile, 'utf8');

    console.log('📝 Executing SQL migration:\n');
    console.log(sqlContent);
    console.log('\n');

    // Exécuter le SQL
    await AppDataSource.query(sqlContent);

    console.log('✅ Foreign key successfully updated!\n');
    console.log('   delivery_quotas.user_id now references deliverers(id) instead of users(id)\n');

  } catch (error) {
    console.error('❌ Error during migration:', error.message);
    throw error;
  } finally {
    await AppDataSource.destroy();
  }
}

fixQuotaFK()
  .then(() => {
    console.log('✅ Migration completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  });
