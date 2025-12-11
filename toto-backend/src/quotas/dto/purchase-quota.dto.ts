import { IsEnum, IsOptional, IsString, IsNumber, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { QuotaType } from '../entities/delivery-quota.entity';

export class PurchaseQuotaDto {
  @ApiProperty({
    enum: QuotaType,
    example: QuotaType.STANDARD,
    description: 'Type de pack de livraisons',
  })
  @IsEnum(QuotaType)
  quota_type: QuotaType;

  @ApiPropertyOptional({
    example: 50,
    description: 'Nombre de livraisons (pour pack custom)',
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  custom_quantity?: number;

  @ApiProperty({
    example: 'mobile_money',
    description: 'Méthode de paiement',
  })
  @IsString()
  payment_method: string;

  @ApiProperty({
    example: 'REF-123456',
    description: 'Référence de paiement',
  })
  @IsString()
  payment_reference: string;
}
