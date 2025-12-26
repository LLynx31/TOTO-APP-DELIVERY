import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Request,
  Query,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { DeliverersService } from './deliverers.service';
import { UpdateDelivererDto, UpdateAvailabilityDto } from './dto/update-deliverer.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('deliverers')
@Controller('deliverers')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class DeliverersController {
  constructor(private readonly deliverersService: DeliverersService) {}

  @Get('me')
  @ApiOperation({
    summary: 'Obtenir le profil du livreur connecté',
    description: 'Retourne les informations du profil du livreur authentifié',
  })
  @ApiResponse({
    status: 200,
    description: 'Profil du livreur',
    schema: {
      example: {
        id: 'uuid',
        phone_number: '+22507123456',
        full_name: 'Jean Kouassi',
        email: 'jean@example.com',
        photo_url: null,
        vehicle_type: 'Moto',
        license_plate: 'AB-1234-CI',
        kyc_status: 'approved',
        is_available: true,
        is_active: true,
        is_verified: true,
        total_deliveries: 127,
        rating: '4.80',
        created_at: '2024-01-15T10:00:00.000Z',
        updated_at: '2024-12-25T08:00:00.000Z',
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async getProfile(@Request() req) {
    // Vérifier que c'est bien un livreur
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    return this.deliverersService.getProfile(req.user.id);
  }

  @Patch('me')
  @ApiOperation({
    summary: 'Mettre à jour le profil du livreur',
    description: 'Permet au livreur de modifier ses informations personnelles',
  })
  @ApiResponse({
    status: 200,
    description: 'Profil mis à jour',
  })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async updateProfile(@Request() req, @Body() updateDto: UpdateDelivererDto) {
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    return this.deliverersService.updateProfile(req.user.id, updateDto);
  }

  @Patch('me/availability')
  @ApiOperation({
    summary: 'Changer le statut de disponibilité',
    description: 'Permet au livreur de passer en ligne ou hors ligne',
  })
  @ApiResponse({
    status: 200,
    description: 'Statut mis à jour',
    schema: {
      example: {
        is_available: true,
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async updateAvailability(
    @Request() req,
    @Body() updateDto: UpdateAvailabilityDto,
  ) {
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    return this.deliverersService.updateAvailability(
      req.user.id,
      updateDto.is_available,
    );
  }

  @Get('me/stats')
  @ApiOperation({
    summary: 'Obtenir les statistiques du livreur',
    description: 'Retourne les statistiques de performance du livreur',
  })
  @ApiResponse({
    status: 200,
    description: 'Statistiques du livreur',
    schema: {
      example: {
        total_deliveries: 127,
        rating: 4.8,
        is_verified: true,
        kyc_status: 'approved',
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async getStats(@Request() req) {
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    return this.deliverersService.getStats(req.user.id);
  }

  @Get('me/stats/daily')
  @ApiOperation({
    summary: 'Obtenir les statistiques journalières du livreur',
    description: 'Retourne les statistiques du jour (livraisons, gains, en cours)',
  })
  @ApiResponse({
    status: 200,
    description: 'Statistiques journalières',
    schema: {
      example: {
        deliveries_today: 5,
        earnings_today: 12500,
        completed_today: 4,
        in_progress: 1,
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async getDailyStats(@Request() req) {
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    return this.deliverersService.getDailyStats(req.user.id);
  }

  @Get('me/earnings')
  @ApiOperation({
    summary: 'Obtenir les gains du livreur',
    description: 'Retourne les gains sur une période donnée avec détails par livraison',
  })
  @ApiQuery({
    name: 'period',
    required: false,
    enum: ['today', 'week', 'month'],
    description: 'Période des gains (défaut: today)',
  })
  @ApiResponse({
    status: 200,
    description: 'Gains du livreur',
    schema: {
      example: {
        total: 45000,
        period: 'week',
        deliveries_count: 18,
        details: [
          {
            id: 'uuid',
            amount: 2500,
            delivered_at: '2024-12-25T14:30:00.000Z',
            pickup_address: 'Cocody, Rue des Jardins',
            delivery_address: 'Plateau, Avenue de la République',
          },
        ],
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async getEarnings(
    @Request() req,
    @Query('period') period: 'today' | 'week' | 'month' = 'today',
  ) {
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    return this.deliverersService.getEarnings(req.user.id, period);
  }
}
