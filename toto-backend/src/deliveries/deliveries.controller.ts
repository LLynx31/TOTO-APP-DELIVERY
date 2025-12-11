import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { DeliveriesService } from './deliveries.service';
import { CreateDeliveryDto } from './dto/create-delivery.dto';
import { UpdateDeliveryDto } from './dto/update-delivery.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeliveryStatus } from './entities/delivery.entity';

@ApiTags('deliveries')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('deliveries')
export class DeliveriesController {
  constructor(private readonly deliveriesService: DeliveriesService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Créer une nouvelle livraison',
    description: 'Permet à un client de créer une demande de livraison. Les QR codes sont générés automatiquement.',
  })
  @ApiResponse({
    status: 201,
    description: 'Livraison créée avec succès',
    schema: {
      example: {
        id: 'uuid',
        client_id: 'uuid',
        pickup_address: 'Cocody Riviera, Abidjan',
        pickup_latitude: 5.3599517,
        pickup_longitude: -4.0082563,
        delivery_address: 'Yopougon, Abidjan',
        delivery_latitude: 5.3364032,
        delivery_longitude: -4.0266334,
        delivery_phone: '+22598765432',
        receiver_name: 'Kouadio Aya',
        qr_code_pickup: 'TOTO-PICKUP-1234567890-abc123...',
        qr_code_delivery: 'TOTO-DELIVERY-1234567890-def456...',
        status: 'pending',
        price: 3500,
        distance_km: 5.2,
        created_at: '2025-11-28T20:00:00.000Z',
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Données invalides' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  async create(@Body() createDeliveryDto: CreateDeliveryDto, @Request() req) {
    const clientId = req.user.id;
    return this.deliveriesService.create(createDeliveryDto, clientId);
  }

  @Get()
  @ApiOperation({
    summary: 'Obtenir toutes les livraisons de l\'utilisateur',
    description: 'Retourne toutes les livraisons pour l\'utilisateur connecté (client ou livreur)',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: DeliveryStatus,
    description: 'Filtrer par statut de livraison',
  })
  @ApiResponse({
    status: 200,
    description: 'Liste des livraisons',
  })
  async findAll(@Request() req, @Query('status') status?: DeliveryStatus) {
    return this.deliveriesService.findAll(req.user.id, req.user.type, status);
  }

  @Get('available')
  @ApiOperation({
    summary: 'Obtenir les livraisons disponibles',
    description: 'Retourne toutes les livraisons en attente (pour les livreurs)',
  })
  @ApiResponse({
    status: 200,
    description: 'Liste des livraisons disponibles',
  })
  async getAvailable() {
    return this.deliveriesService.getAvailableDeliveries();
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Obtenir les détails d\'une livraison',
    description: 'Retourne les informations détaillées d\'une livraison spécifique',
  })
  @ApiParam({
    name: 'id',
    description: 'ID de la livraison',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Détails de la livraison',
  })
  @ApiResponse({ status: 404, description: 'Livraison non trouvée' })
  @ApiResponse({ status: 403, description: 'Accès refusé' })
  async findOne(@Param('id') id: string, @Request() req) {
    return this.deliveriesService.findOne(id, req.user.id, req.user.type);
  }

  @Patch(':id')
  @ApiOperation({
    summary: 'Mettre à jour une livraison',
    description: 'Permet de modifier les informations d\'une livraison ou son statut',
  })
  @ApiParam({
    name: 'id',
    description: 'ID de la livraison',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Livraison mise à jour avec succès',
  })
  @ApiResponse({ status: 400, description: 'Transition de statut invalide' })
  @ApiResponse({ status: 404, description: 'Livraison non trouvée' })
  async update(
    @Param('id') id: string,
    @Body() updateDeliveryDto: UpdateDeliveryDto,
    @Request() req,
  ) {
    return this.deliveriesService.update(id, updateDeliveryDto, req.user.id, req.user.type);
  }

  @Post(':id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Accepter une livraison (Livreur)',
    description: 'Permet à un livreur d\'accepter une livraison en attente',
  })
  @ApiParam({
    name: 'id',
    description: 'ID de la livraison',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Livraison acceptée avec succès',
  })
  @ApiResponse({ status: 400, description: 'Livraison déjà acceptée ou statut invalide' })
  @ApiResponse({ status: 404, description: 'Livraison non trouvée' })
  async accept(@Param('id') id: string, @Request() req) {
    return this.deliveriesService.acceptDelivery(id, req.user.id);
  }

  @Post(':id/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Annuler une livraison',
    description: 'Permet d\'annuler une livraison (client ou livreur)',
  })
  @ApiParam({
    name: 'id',
    description: 'ID de la livraison',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Livraison annulée avec succès',
  })
  @ApiResponse({ status: 400, description: 'Impossible d\'annuler une livraison déjà livrée' })
  @ApiResponse({ status: 404, description: 'Livraison non trouvée' })
  async cancel(@Param('id') id: string, @Request() req) {
    return this.deliveriesService.cancel(id, req.user.id, req.user.type);
  }

  @Post(':id/verify-qr')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Vérifier un QR code',
    description: 'Vérifie le QR code pour confirmer le pickup ou la delivery',
  })
  @ApiParam({
    name: 'id',
    description: 'ID de la livraison',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'QR code vérifié avec succès',
  })
  @ApiResponse({ status: 400, description: 'QR code invalide' })
  @ApiResponse({ status: 404, description: 'Livraison non trouvée' })
  async verifyQR(
    @Param('id') id: string,
    @Body() body: { qr_code: string; type: 'pickup' | 'delivery' },
  ) {
    return this.deliveriesService.verifyQRCode(id, body.qr_code, body.type);
  }
}
