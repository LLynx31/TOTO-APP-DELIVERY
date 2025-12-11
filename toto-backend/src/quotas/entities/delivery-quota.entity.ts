import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';

export enum QuotaType {
  BASIC = 'basic',
  STANDARD = 'standard',
  PREMIUM = 'premium',
  CUSTOM = 'custom',
}

@Entity('delivery_quotas')
export class DeliveryQuota {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  user_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({
    type: 'enum',
    enum: QuotaType,
    default: QuotaType.BASIC,
  })
  quota_type: QuotaType;

  @Column({ type: 'int' })
  total_deliveries: number;

  @Column({ type: 'int', default: 0 })
  used_deliveries: number;

  @Column({ type: 'int' })
  remaining_deliveries: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price_paid: number;

  @Column({ type: 'varchar', length: 50, nullable: true })
  payment_method: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  payment_reference: string;

  @Column({ type: 'timestamp', nullable: true })
  expires_at: Date;

  @Column({ type: 'boolean', default: true })
  is_active: boolean;

  @CreateDateColumn()
  purchased_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
