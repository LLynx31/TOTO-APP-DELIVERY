import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { DeliveryQuota } from './delivery-quota.entity';
import { Delivery } from '../../deliveries/entities/delivery.entity';

export enum TransactionType {
  PURCHASE = 'purchase',
  USAGE = 'usage',
  REFUND = 'refund',
  EXPIRATION = 'expiration',
}

@Entity('quota_transactions')
export class QuotaTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  quota_id: string;

  @ManyToOne(() => DeliveryQuota)
  @JoinColumn({ name: 'quota_id' })
  quota: DeliveryQuota;

  @Column({ type: 'uuid', nullable: true })
  delivery_id: string;

  @ManyToOne(() => Delivery, { nullable: true })
  @JoinColumn({ name: 'delivery_id' })
  delivery: Delivery;

  @Column({
    type: 'enum',
    enum: TransactionType,
  })
  transaction_type: TransactionType;

  @Column({ type: 'int' })
  amount: number;

  @Column({ type: 'int' })
  balance_before: number;

  @Column({ type: 'int' })
  balance_after: number;

  @Column({ type: 'text', nullable: true })
  description: string;

  @CreateDateColumn()
  created_at: Date;
}
