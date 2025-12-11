import { IsString, IsNotEmpty, IsEmail, IsOptional, MinLength, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({
    example: '+22512345678',
    description: 'Numéro de téléphone ivoirien au format +225XXXXXXXX',
    pattern: '^\\+225\\d{8,10}$'
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+225\d{8,10}$/, {
    message: 'Phone number must be in format +225XXXXXXXX',
  })
  phone_number: string;

  @ApiProperty({
    example: 'Jean Kouassi',
    description: 'Nom complet de l\'utilisateur'
  })
  @IsString()
  @IsNotEmpty()
  full_name: string;

  @ApiPropertyOptional({
    example: 'jean.kouassi@example.com',
    description: 'Adresse email (optionnel)'
  })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({
    example: 'motdepasse123',
    description: 'Mot de passe (minimum 6 caractères)',
    minLength: 6
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(6, { message: 'Password must be at least 6 characters long' })
  password: string;
}

export class RegisterDelivererDto extends RegisterDto {
  @ApiPropertyOptional({
    example: 'Moto',
    description: 'Type de véhicule du livreur'
  })
  @IsString()
  @IsOptional()
  vehicle_type?: string;

  @ApiPropertyOptional({
    example: 'AB-1234-CI',
    description: 'Plaque d\'immatriculation du véhicule'
  })
  @IsString()
  @IsOptional()
  license_plate?: string;
}
