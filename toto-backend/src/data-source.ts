import { DataSource } from 'typeorm';
import { config } from 'dotenv';

// Load environment variables
config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_DATABASE || 'toto_db',

  // Entities
  entities: ['dist/**/*.entity.js'],

  // Migrations
  migrations: ['dist/migrations/*.js'],
  migrationsTableName: 'typeorm_migrations',

  // Options
  synchronize: false, // TOUJOURS false pour les migrations
  logging: process.env.NODE_ENV === 'development',
});
