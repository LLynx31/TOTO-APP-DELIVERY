import { IsString, IsEmail, IsOptional, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateDelivererDto {
  @ApiPropertyOptional({ description: 'Nom complet du livreur', example: 'Jean Kouassi' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  full_name?: string;

  @ApiPropertyOptional({ description: 'Email du livreur', example: 'jean@example.com' })
  @IsOptional()
  @IsEmail()
  @MaxLength(100)
  email?: string;

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
  @ApiPropertyOptional({ description: 'Statut de disponibilité', example: true })
  is_available: boolean;
}
