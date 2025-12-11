import { PartialType } from '@nestjs/swagger';
import { CreateDeliveryDto } from './create-delivery.dto';
import { IsEnum, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { DeliveryStatus } from '../entities/delivery.entity';

export class UpdateDeliveryDto extends PartialType(CreateDeliveryDto) {
  @ApiPropertyOptional({
    enum: DeliveryStatus,
    example: DeliveryStatus.ACCEPTED,
    description: 'Nouveau statut de la livraison',
  })
  @IsOptional()
  @IsEnum(DeliveryStatus)
  status?: DeliveryStatus;
}
