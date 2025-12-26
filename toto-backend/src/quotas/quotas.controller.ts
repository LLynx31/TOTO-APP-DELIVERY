import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { QuotasService } from './quotas.service';
import { PurchaseQuotaDto } from './dto/purchase-quota.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('quotas')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('quotas')
export class QuotasController {
  constructor(private readonly quotasService: QuotasService) {}

  @Get('packages')
  @ApiOperation({
    summary: 'Obtenir les packs disponibles',
    description: 'Retourne la liste de tous les packs de livraisons disponibles à l\'achat',
  })
  @ApiResponse({
    status: 200,
    description: 'Liste des packs disponibles',
  })
  getPackages() {
    return this.quotasService.getAvailablePackages();
  }

  @Post('purchase')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Acheter un pack de livraisons',
    description: 'Permet à un client d\'acheter un pack de livraisons prépayé',
  })
  @ApiResponse({
    status: 201,
    description: 'Pack acheté avec succès',
  })
  @ApiResponse({ status: 400, description: 'Données invalides' })
  async purchaseQuota(@Body() purchaseDto: PurchaseQuotaDto, @Request() req) {
    const userId = req.user.id;
    return this.quotasService.purchaseQuota(userId, purchaseDto);
  }

  @Get('my-quotas')
  @ApiOperation({
    summary: 'Obtenir mes quotas',
    description: 'Retourne tous les quotas (actifs et expirés) de l\'utilisateur connecté',
  })
  @ApiResponse({
    status: 200,
    description: 'Liste des quotas de l\'utilisateur',
  })
  async getMyQuotas(@Request() req) {
    const userId = req.user.id;
    return this.quotasService.getUserQuotas(userId);
  }

  @Get('active')
  @ApiOperation({
    summary: 'Obtenir le quota actif',
    description: 'Retourne le quota actuellement actif de l\'utilisateur',
  })
  @ApiResponse({
    status: 200,
    description: 'Quota actif',
  })
  async getActiveQuota(@Request() req) {
    const userId = req.user.id;
    return this.quotasService.getActiveQuota(userId);
  }

  @Get('transactions')
  @ApiOperation({
    summary: 'Obtenir l\'historique des achats',
    description: 'Retourne toutes les transactions d\'achat de quotas de l\'utilisateur',
  })
  @ApiResponse({
    status: 200,
    description: 'Historique des achats',
  })
  async getUserTransactions(@Request() req) {
    const userId = req.user.id;
    return this.quotasService.getUserTransactions(userId);
  }

  @Get(':id/history')
  @ApiOperation({
    summary: 'Obtenir l\'historique d\'un quota',
    description: 'Retourne l\'historique des transactions pour un quota spécifique',
  })
  @ApiParam({
    name: 'id',
    description: 'ID du quota',
    type: 'string',
  })
  @ApiResponse({
    status: 200,
    description: 'Historique du quota',
  })
  async getQuotaHistory(@Param('id') id: string, @Request() req) {
    const userId = req.user.id;
    return this.quotasService.getQuotaHistory(userId, id);
  }
}
