import { Controller, Post, Body, HttpCode, HttpStatus, UseInterceptors, UploadedFiles, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiConsumes } from '@nestjs/swagger';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { AuthService } from './auth.service';
import { RegisterDto, RegisterDelivererDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { AdminLoginDto } from './dto/admin-login.dto';
import { ConfigService } from '@nestjs/config';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(
    private readonly authService: AuthService,
    private readonly configService: ConfigService,
  ) {}

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
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'driving_license', maxCount: 1 },
        { name: 'id_card', maxCount: 1 },
        { name: 'vehicle_photo', maxCount: 1 },
      ],
      {
        storage: diskStorage({
          destination: './uploads',
          filename: (req, file, cb) => {
            const uniqueSuffix = uuidv4();
            const ext = extname(file.originalname);
            cb(null, `${uniqueSuffix}${ext}`);
          },
        }),
        fileFilter: (req, file, cb) => {
          if (file.mimetype.match(/\/(jpg|jpeg|png|gif|webp)$/)) {
            cb(null, true);
          } else {
            cb(new Error('Seuls les fichiers images sont acceptés'), false);
          }
        },
        limits: {
          fileSize: 5242880, // 5MB
        },
      },
    ),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Inscription d\'un nouveau livreur avec documents KYC',
    description: 'Permet à un livreur de créer un compte avec ses documents KYC (permis, CNI, photo véhicule). Le KYC sera en statut "pending" par défaut.'
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
          driver_license_url: 'http://localhost:3000/uploads/xxx.jpg',
          id_card_front_url: 'http://localhost:3000/uploads/yyy.jpg',
          id_card_back_url: 'http://localhost:3000/uploads/zzz.jpg',
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
  @ApiResponse({ status: 400, description: 'Données invalides ou documents manquants' })
  @ApiResponse({ status: 409, description: 'Numéro de téléphone déjà utilisé' })
  async registerDeliverer(
    @Body() registerDto: RegisterDelivererDto,
    @UploadedFiles()
    files: {
      driving_license?: Express.Multer.File[];
      id_card?: Express.Multer.File[];
      vehicle_photo?: Express.Multer.File[];
    },
  ) {
    this.logger.log('=== INSCRIPTION LIVREUR ===');
    this.logger.log(`Données reçues: ${JSON.stringify(registerDto)}`);
    this.logger.log(`Fichiers reçus: driving_license=${files?.driving_license?.length || 0}, id_card=${files?.id_card?.length || 0}, vehicle_photo=${files?.vehicle_photo?.length || 0}`);

    // Construire les URLs des fichiers
    const baseUrl = this.configService.get('API_BASE_URL') || 'http://localhost:3000';
    const kycFiles = {
      driver_license_url: files?.driving_license?.[0] ? `${baseUrl}/uploads/${files.driving_license[0].filename}` : undefined,
      id_card_front_url: files?.id_card?.[0] ? `${baseUrl}/uploads/${files.id_card[0].filename}` : undefined,
      id_card_back_url: files?.vehicle_photo?.[0] ? `${baseUrl}/uploads/${files.vehicle_photo[0].filename}` : undefined,
    };

    this.logger.log(`URLs KYC: ${JSON.stringify(kycFiles)}`);

    const result = await this.authService.registerDeliverer(registerDto, kycFiles);

    this.logger.log(`Inscription réussie pour: ${result.deliverer.phone_number}`);
    return result;
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
