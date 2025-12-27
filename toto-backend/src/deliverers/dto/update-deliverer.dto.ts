import { IsString, IsOptional, MaxLength, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * DTO pour la mise à jour du profil livreur
 *
 * Note: Le numéro de téléphone n'est PAS modifiable car il sert d'identifiant unique
 * L'email a été retiré du système d'inscription livreur
 */
export class UpdateDelivererDto {
  @ApiPropertyOptional({ description: 'Nom complet du livreur', example: 'Jean Kouassi' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  full_name?: string;

  @ApiPropertyOptional({ description: 'URL de la photo de profil' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  photo_url?: string;

  @ApiPropertyOptional({ description: 'Type de véhicule', example: 'Moto' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  vehicle_type?: string;

  @ApiPropertyOptional({ description: 'Plaque d\'immatriculation', example: 'AB-1234-CI' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  license_plate?: string;
}

export class UpdateAvailabilityDto {
  @ApiProperty({ description: 'Statut de disponibilité', example: true })
  @IsBoolean()
  is_available: boolean;
}
