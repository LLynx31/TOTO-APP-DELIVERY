import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('users')
export class User {
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

  @Column({ default: false })
  is_verified: boolean;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
