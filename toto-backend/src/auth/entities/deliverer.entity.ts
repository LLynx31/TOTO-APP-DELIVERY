import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { KycDocument } from './kyc-document.entity';

@Entity('deliverers')
export class Deliverer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, length: 20 })
  phone_number: string;

  @Column({ length: 100 })
  full_name: string;

  @Column({ unique: true, nullable: true, length: 100 })
  email: string;

  @Column({ length: 255 })
  password_hash: string;

  @Column({ nullable: true, length: 255 })
  photo_url: string;

  @Column({ nullable: true, length: 50 })
  vehicle_type: string;

  @Column({ nullable: true, length: 50 })
  license_plate: string;

  // KYC fields
  @Column({ default: 'pending', length: 20 })
  kyc_status: 'pending' | 'approved' | 'rejected';

  @Column({ nullable: true, type: 'timestamp' })
  kyc_submitted_at: Date;

  @Column({ nullable: true, type: 'timestamp' })
  kyc_reviewed_at: Date;

  // Status
  @Column({ default: false })
  is_available: boolean;

  @Column({ default: true })
  is_active: boolean;

  @Column({ default: false })
  is_verified: boolean;

  // Stats
  @Column({ default: 0, type: 'integer' })
  total_deliveries: number;

  @Column({ default: 0.0, type: 'decimal', precision: 3, scale: 2 })
  rating: number;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  @OneToMany(() => KycDocument, (document) => document.deliverer)
  kyc_documents: KycDocument[];
}
