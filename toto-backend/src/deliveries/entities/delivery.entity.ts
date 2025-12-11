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
import { Deliverer } from '../../auth/entities/deliverer.entity';

export enum DeliveryStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  PICKUP_IN_PROGRESS = 'pickupInProgress',
  PICKED_UP = 'pickedUp',
  DELIVERY_IN_PROGRESS = 'deliveryInProgress',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled',
}

@Entity('deliveries')
export class Delivery {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  client_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'client_id' })
  client: User;

  @Column({ type: 'uuid', nullable: true })
  deliverer_id: string;

  @ManyToOne(() => Deliverer, { nullable: true })
  @JoinColumn({ name: 'deliverer_id' })
  deliverer: Deliverer;

  // Pickup information
  @Column({ type: 'varchar', length: 500 })
  pickup_address: string;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  pickup_latitude: number;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  pickup_longitude: number;

  @Column({ type: 'varchar', length: 20, nullable: true })
  pickup_phone: string;

  // Delivery information
  @Column({ type: 'varchar', length: 500 })
  delivery_address: string;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  delivery_latitude: number;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  delivery_longitude: number;

  @Column({ type: 'varchar', length: 20 })
  delivery_phone: string;

  @Column({ type: 'varchar', length: 200 })
  receiver_name: string;

  // Package details
  @Column({ type: 'varchar', length: 200, nullable: true })
  package_description: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  package_weight: number;

  // QR Codes
  @Column({ type: 'text', unique: true })
  qr_code_pickup: string;

  @Column({ type: 'text', unique: true })
  qr_code_delivery: string;

  // Status and tracking
  @Column({
    type: 'enum',
    enum: DeliveryStatus,
    default: DeliveryStatus.PENDING,
  })
  status: DeliveryStatus;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  distance_km: number;

  // Special instructions
  @Column({ type: 'text', nullable: true })
  special_instructions: string;

  // Timestamps for status changes
  @Column({ type: 'timestamp', nullable: true })
  accepted_at: Date;

  @Column({ type: 'timestamp', nullable: true })
  picked_up_at: Date;

  @Column({ type: 'timestamp', nullable: true })
  delivered_at: Date;

  @Column({ type: 'timestamp', nullable: true })
  cancelled_at: Date;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
