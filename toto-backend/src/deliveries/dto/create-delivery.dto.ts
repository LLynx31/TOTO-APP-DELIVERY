import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPhoneNumber,
  MaxLength,
  Min,
  Max,
  Matches,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateDeliveryDto {
  // Pickup information
  @ApiProperty({
    example: 'Cocody Riviera, Abidjan',
    description: 'Adresse de récupération du colis',
    maxLength: 500,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  pickup_address: string;

  @ApiProperty({
    example: 5.3599517,
    description: 'Latitude du point de récupération',
    minimum: -90,
    maximum: 90,
  })
  @IsNumber()
  @Min(-90)
  @Max(90)
  pickup_latitude: number;

  @ApiProperty({
    example: -4.0082563,
    description: 'Longitude du point de récupération',
    minimum: -180,
    maximum: 180,
  })
  @IsNumber()
  @Min(-180)
  @Max(180)
  pickup_longitude: number;

  @ApiPropertyOptional({
    example: '+22512345678',
    description: 'Numéro de téléphone au point de récupération (optionnel)',
  })
  @IsOptional()
  @IsString()
  @Matches(/^\+225\d{8,10}$/, {
    message: 'Phone number must be in format +225XXXXXXXX',
  })
  pickup_phone?: string;

  // Delivery information
  @ApiProperty({
    example: 'Yopougon, Abidjan',
    description: 'Adresse de livraison du colis',
    maxLength: 500,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  delivery_address: string;

  @ApiProperty({
    example: 5.3364032,
    description: 'Latitude du point de livraison',
    minimum: -90,
    maximum: 90,
  })
  @IsNumber()
  @Min(-90)
  @Max(90)
  delivery_latitude: number;

  @ApiProperty({
    example: -4.0266334,
    description: 'Longitude du point de livraison',
    minimum: -180,
    maximum: 180,
  })
  @IsNumber()
  @Min(-180)
  @Max(180)
  delivery_longitude: number;

  @ApiProperty({
    example: '+22598765432',
    description: 'Numéro de téléphone du destinataire',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+225\d{8,10}$/, {
    message: 'Phone number must be in format +225XXXXXXXX',
  })
  delivery_phone: string;

  @ApiProperty({
    example: 'Kouadio Aya',
    description: 'Nom complet du destinataire',
    maxLength: 200,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  receiver_name: string;

  // Package details
  @ApiPropertyOptional({
    example: 'Documents importants',
    description: 'Description du colis (optionnel)',
    maxLength: 200,
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  package_description?: string;

  @ApiPropertyOptional({
    example: 2.5,
    description: 'Poids du colis en kg (optionnel)',
    minimum: 0,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  package_weight?: number;

  @ApiPropertyOptional({
    example: 'Livrer entre 14h et 17h',
    description: 'Instructions spéciales pour le livreur (optionnel)',
  })
  @IsOptional()
  @IsString()
  special_instructions?: string;
}
