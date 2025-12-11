import { IsString, IsNotEmpty, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({
    example: '+22512345678',
    description: 'Numéro de téléphone ivoirien',
    pattern: '^\\+225\\d{8,10}$'
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+225\d{8,10}$/, {
    message: 'Phone number must be in format +225XXXXXXXX',
  })
  phone_number: string;

  @ApiProperty({
    example: 'motdepasse123',
    description: 'Mot de passe'
  })
  @IsString()
  @IsNotEmpty()
  password: string;
}
