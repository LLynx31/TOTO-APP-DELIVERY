import { config } from 'dotenv';
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

// Load environment variables
config();

async function runSqlMigration() {
  console.log('🔄 Running SQL migrations...\n');

  const migrationsDir = path.join(__dirname, '..', 'migrations');

  // Check if migrations directory exists
  if (!fs.existsSync(migrationsDir)) {
    console.log('❌ Migrations directory not found');
    process.exit(1);
  }

  // Get all SQL files in migrations directory
  const sqlFiles = fs.readdirSync(migrationsDir)
    .filter(file => file.endsWith('.sql'))
    .sort();

  if (sqlFiles.length === 0) {
    console.log('✅ No SQL migrations to run');
    return;
  }

  console.log(`Found ${sqlFiles.length} SQL migration(s):\n`);
  sqlFiles.forEach(file => console.log(`  - ${file}`));
  console.log();

  // Database connection info
  const dbHost = process.env.DB_HOST || 'localhost';
  const dbPort = process.env.DB_PORT || '5432';
  const dbUser = process.env.DB_USERNAME || 'postgres';
  const dbPassword = process.env.DB_PASSWORD || '';
  const dbName = process.env.DB_DATABASE || 'toto_db';

  // Run each SQL migration
  for (const sqlFile of sqlFiles) {
    const filePath = path.join(migrationsDir, sqlFile);

    console.log(`📝 Running migration: ${sqlFile}`);

    try {
      const command = `PGPASSWORD="${dbPassword}" psql -h ${dbHost} -p ${dbPort} -U ${dbUser} -d ${dbName} -f "${filePath}"`;

      execSync(command, { stdio: 'inherit' });
      console.log(`✅ Successfully ran: ${sqlFile}\n`);
    } catch (error) {
      console.error(`❌ Error running migration: ${sqlFile}`);
      console.error(error);
      process.exit(1);
    }
  }

  console.log('\n✅ All SQL migrations completed successfully!');
}

runSqlMigration();
