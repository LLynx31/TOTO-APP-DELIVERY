import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Deliverer } from './deliverer.entity';

export enum KycDocumentType {
  ID_CARD = 'id_card',
  PROOF_OF_ADDRESS = 'proof_of_address',
  RIB = 'rib',
}

@Entity('kyc_documents')
export class KycDocument {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  file_name: string;

  @Column()
  file_path: string;

  @Column()
  file_type: string;

  @Column({
    type: 'enum',
    enum: KycDocumentType,
  })
  document_type: KycDocumentType;

  @CreateDateColumn()
  created_at: Date;

  @ManyToOne(() => Deliverer, (deliverer) => deliverer.kyc_documents)
  @JoinColumn({ name: 'deliverer_id' })
  deliverer: Deliverer;

  @Column({ type: 'uuid' })
  deliverer_id: string;
}
