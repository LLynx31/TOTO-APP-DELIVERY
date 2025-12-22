import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { Delivery } from '../../deliveries/entities/delivery.entity';

@Entity('ratings')
@Index(['delivery_id', 'rated_by_id'], { unique: true }) // Un utilisateur ne peut noter qu'une fois par livraison
export class Rating {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  delivery_id: string;

  @ManyToOne(() => Delivery)
  @JoinColumn({ name: 'delivery_id' })
  delivery: Delivery;

  @Column({ type: 'uuid' })
  rated_by_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'rated_by_id' })
  rated_by: User;

  @Column({ type: 'uuid' })
  rated_user_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'rated_user_id' })
  rated_user: User;

  @Column({ type: 'int' })
  stars: number; // 1-5

  @Column({ type: 'text', nullable: true })
  comment: string;

  @CreateDateColumn()
  created_at: Date;
}
