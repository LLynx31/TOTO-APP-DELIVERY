import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { Delivery } from '../../deliveries/entities/delivery.entity';
import { Deliverer } from '../../auth/entities/deliverer.entity';

@Entity('delivery_tracking')
export class DeliveryTracking {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  delivery_id: string;

  @ManyToOne(() => Delivery)
  @JoinColumn({ name: 'delivery_id' })
  delivery: Delivery;

  @Column({ type: 'uuid' })
  deliverer_id: string;

  @ManyToOne(() => Deliverer)
  @JoinColumn({ name: 'deliverer_id' })
  deliverer: Deliverer;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  latitude: number;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  longitude: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  speed: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  heading: number;

  @Column({ type: 'decimal', precision: 6, scale: 2, nullable: true })
  accuracy: number;

  @CreateDateColumn()
  recorded_at: Date;
}
