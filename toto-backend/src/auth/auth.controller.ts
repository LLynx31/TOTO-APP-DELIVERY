import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterDto, RegisterDelivererDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { AdminLoginDto } from './dto/admin-login.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // ==========================================
  // CLIENT ENDPOINTS
  // ==========================================

  @Post('client/register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Inscription d\'un nouveau client',
    description: 'Permet à un utilisateur de créer un compte client avec son numéro de téléphone ivoirien (+225)'
  })
  @ApiResponse({
    status: 201,
    description: 'Client créé avec succès. Retourne les informations du client et les tokens JWT.',
    schema: {
      example: {
        user: {
          id: 'uuid',
          phone_number: '+22512345678',
          full_name: 'Jean Kouassi',
          email: 'jean@example.com',
          is_verified: false,
          is_active: true,
          created_at: '2025-11-28T19:15:41.376Z'
        },
        access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        refresh_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        token_type: 'Bearer',
        expires_in: 3600
      }
    }
  })
  @ApiResponse({ status: 400, description: 'Données invalides (numéro de téléphone, mot de passe, etc.)' })
  @ApiResponse({ status: 409, description: 'Numéro de téléphone ou email déjà utilisé' })
  async registerClient(@Body() registerDto: RegisterDto) {
    return this.authService.registerClient(registerDto);
  }

  @Post('client/login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Connexion client',
    description: 'Authentifie un client existant avec son numéro de téléphone et mot de passe'
  })
  @ApiResponse({
    status: 200,
    description: 'Connexion réussie. Retourne les informations du client et les tokens.',
  })
  @ApiResponse({ status: 401, description: 'Identifiants invalides ou compte désactivé' })
  async loginClient(@Body() loginDto: LoginDto) {
    return this.authService.loginClient(loginDto);
  }

  // ==========================================
  // DELIVERER ENDPOINTS
  // ==========================================

  @Post('deliverer/register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Inscription d\'un nouveau livreur',
    description: 'Permet à un livreur de créer un compte. Le KYC sera en statut "pending" par défaut.'
  })
  @ApiResponse({
    status: 201,
    description: 'Livreur créé avec succès. Retourne les informations du livreur et les tokens JWT.',
    schema: {
      example: {
        deliverer: {
          id: 'uuid',
          phone_number: '+22598765432',
          full_name: 'Mamadou Traoré',
          vehicle_type: 'Moto',
          license_plate: 'AB-1234-CI',
          kyc_status: 'pending',
          is_available: false,
          total_deliveries: 0,
          rating: '0.00',
          created_at: '2025-11-28T19:15:54.259Z'
        },
        access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        refresh_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        token_type: 'Bearer',
        expires_in: 3600
      }
    }
  })
  @ApiResponse({ status: 400, description: 'Données invalides' })
  @ApiResponse({ status: 409, description: 'Numéro de téléphone ou email déjà utilisé' })
  async registerDeliverer(@Body() registerDto: RegisterDelivererDto) {
    return this.authService.registerDeliverer(registerDto);
  }

  @Post('deliverer/login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Connexion livreur',
    description: 'Authentifie un livreur existant avec son numéro de téléphone et mot de passe'
  })
  @ApiResponse({ status: 200, description: 'Connexion réussie' })
  @ApiResponse({ status: 401, description: 'Identifiants invalides ou compte désactivé' })
  async loginDeliverer(@Body() loginDto: LoginDto) {
    return this.authService.loginDeliverer(loginDto);
  }

  // ==========================================
  // ADMIN ENDPOINTS
  // ==========================================

  @Post('admin/login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Connexion administrateur',
    description: 'Authentifie un administrateur avec son email et mot de passe'
  })
  @ApiResponse({
    status: 200,
    description: 'Connexion admin réussie. Retourne les informations de l\'admin et les tokens JWT.',
    schema: {
      example: {
        admin: {
          id: 'uuid',
          email: 'admin@toto.com',
          full_name: 'Super Admin',
          role: 'super_admin',
          is_active: true,
          created_at: '2025-12-01T12:00:00.000Z',
          last_login_at: '2025-12-01T12:30:00.000Z'
        },
        access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        refresh_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        token_type: 'Bearer',
        expires_in: 3600
      }
    }
  })
  @ApiResponse({ status: 401, description: 'Identifiants invalides ou compte désactivé' })
  async loginAdmin(@Body() adminLoginDto: AdminLoginDto) {
    return this.authService.loginAdmin(adminLoginDto);
  }

  // ==========================================
  // TOKEN MANAGEMENT
  // ==========================================

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Rafraîchir le token d\'accès',
    description: 'Obtient un nouveau access token en utilisant le refresh token. L\'ancien refresh token sera révoqué.'
  })
  @ApiResponse({
    status: 200,
    description: 'Token rafraîchi avec succès',
    schema: {
      example: {
        access_token: 'nouveau_access_token',
        refresh_token: 'nouveau_refresh_token',
        token_type: 'Bearer',
        expires_in: 3600
      }
    }
  })
  @ApiResponse({ status: 401, description: 'Refresh token invalide, révoqué ou expiré' })
  async refresh(@Body() refreshTokenDto: RefreshTokenDto) {
    return this.authService.refreshToken(refreshTokenDto.refresh_token);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Déconnexion',
    description: 'Révoque le refresh token pour déconnecter l\'utilisateur'
  })
  @ApiResponse({
    status: 200,
    description: 'Déconnexion réussie',
    schema: {
      example: {
        message: 'Logged out successfully'
      }
    }
  })
  async logout(@Body() refreshTokenDto: RefreshTokenDto) {
    return this.authService.logout(refreshTokenDto.refresh_token);
  }
}
