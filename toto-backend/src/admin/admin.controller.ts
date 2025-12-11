import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
  ParseBoolPipe,
  ParseUUIDPipe,
  DefaultValuePipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminRoleGuard } from '../auth/guards/admin-role.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdateDelivererDto } from './dto/update-deliverer.dto';
import { ApproveKycDto } from './dto/approve-kyc.dto';

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, AdminRoleGuard)
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ==========================================
  // DASHBOARD & ANALYTICS
  // ==========================================

  @Get('dashboard')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Tableau de bord administrateur',
    description: 'Récupère les statistiques globales de la plateforme',
  })
  @ApiResponse({
    status: 200,
    description: 'Statistiques du dashboard',
    schema: {
      example: {
        total_users: 1250,
        total_deliverers: 345,
        active_deliveries: 78,
        total_deliveries: 5432,
        total_revenue: 2750000,
        new_users_today: 12,
        deliveries_today: 45,
      },
    },
  })
  async getDashboard() {
    return this.adminService.getDashboardStats();
  }

  @Get('analytics/revenue')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Analyse des revenus',
    description: 'Récupère les statistiques de revenus par période',
  })
  @ApiQuery({ name: 'period', enum: ['day', 'week', 'month', 'year'], required: false })
  @ApiResponse({ status: 200, description: 'Statistiques de revenus' })
  async getRevenueAnalytics(
    @Query('period') period: 'day' | 'week' | 'month' | 'year' = 'week',
  ) {
    return this.adminService.getRevenueAnalytics(period);
  }

  @Get('analytics/deliveries')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Analyse des livraisons',
    description: 'Récupère les statistiques de livraisons par statut et période',
  })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'period', enum: ['day', 'week', 'month'], required: false })
  @ApiResponse({ status: 200, description: 'Statistiques de livraisons' })
  async getDeliveriesAnalytics(
    @Query('status') status?: string,
    @Query('period') period: 'day' | 'week' | 'month' = 'week',
  ) {
    return this.adminService.getDeliveriesAnalytics(status, period);
  }

  // ==========================================
  // USER MANAGEMENT
  // ==========================================

  @Get('users')
  @Roles('super_admin', 'admin', 'moderator')
  @ApiOperation({
    summary: 'Liste des utilisateurs',
    description: 'Récupère la liste paginée des clients',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  @ApiResponse({ status: 200, description: 'Liste paginée des utilisateurs' })
  async getAllUsers(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('search') search?: string,
    @Query('isActive') isActive?: boolean,
  ) {
    return this.adminService.getAllUsers(page, limit, search, isActive);
  }

  @Get('users/:id')
  @Roles('super_admin', 'admin', 'moderator')
  @ApiOperation({
    summary: 'Détails d\'un utilisateur',
    description: 'Récupère les informations détaillées d\'un client',
  })
  @ApiResponse({ status: 200, description: 'Informations de l\'utilisateur' })
  @ApiResponse({ status: 404, description: 'Utilisateur introuvable' })
  async getUserById(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.getUserById(id);
  }

  @Patch('users/:id')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Modifier un utilisateur',
    description: 'Met à jour les informations d\'un client',
  })
  @ApiResponse({ status: 200, description: 'Utilisateur mis à jour' })
  @ApiResponse({ status: 404, description: 'Utilisateur introuvable' })
  async updateUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateDto: UpdateUserDto,
  ) {
    return this.adminService.updateUser(id, updateDto);
  }

  @Get('users/:id/transactions')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Transactions d\'un utilisateur',
    description: 'Récupère l\'historique des transactions de quota d\'un client',
  })
  @ApiResponse({ status: 200, description: 'Liste des transactions' })
  async getUserTransactions(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.getUserTransactions(id);
  }

  // ==========================================
  // DELIVERER MANAGEMENT
  // ==========================================

  @Get('deliverers')
  @Roles('super_admin', 'admin', 'moderator')
  @ApiOperation({
    summary: 'Liste des livreurs',
    description: 'Récupère la liste paginée des livreurs',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'kycStatus', required: false, enum: ['pending', 'approved', 'rejected'] })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  @ApiQuery({ name: 'isAvailable', required: false, type: Boolean })
  @ApiResponse({ status: 200, description: 'Liste paginée des livreurs' })
  async getAllDeliverers(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('kycStatus') kycStatus?: string,
    @Query('isActive') isActive?: boolean,
    @Query('isAvailable') isAvailable?: boolean,
  ) {
    return this.adminService.getAllDeliverers(page, limit, kycStatus, isActive, isAvailable);
  }

  @Get('deliverers/:id')
  @Roles('super_admin', 'admin', 'moderator')
  @ApiOperation({
    summary: 'Détails d\'un livreur',
    description: 'Récupère les informations détaillées d\'un livreur avec ses statistiques',
  })
  @ApiResponse({ status: 200, description: 'Informations du livreur' })
  @ApiResponse({ status: 404, description: 'Livreur introuvable' })
  async getDelivererById(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.getDelivererById(id);
  }

  @Patch('deliverers/:id')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Modifier un livreur',
    description: 'Met à jour les informations d\'un livreur',
  })
  @ApiResponse({ status: 200, description: 'Livreur mis à jour' })
  @ApiResponse({ status: 404, description: 'Livreur introuvable' })
  async updateDeliverer(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateDto: UpdateDelivererDto,
  ) {
    return this.adminService.updateDeliverer(id, updateDto);
  }

  @Post('deliverers/:id/kyc')
  @Roles('super_admin', 'admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Approuver/Rejeter KYC',
    description: 'Approuve ou rejette la vérification KYC d\'un livreur',
  })
  @ApiResponse({ status: 200, description: 'KYC traité avec succès' })
  @ApiResponse({ status: 404, description: 'Livreur introuvable' })
  async approveKyc(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() approveDto: ApproveKycDto,
  ) {
    return this.adminService.approveKyc(id, approveDto);
  }

  @Get('deliverers/:id/earnings')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Gains d\'un livreur',
    description: 'Récupère les statistiques de gains d\'un livreur',
  })
  @ApiQuery({ name: 'startDate', required: false, type: Date })
  @ApiQuery({ name: 'endDate', required: false, type: Date })
  @ApiResponse({ status: 200, description: 'Statistiques de gains' })
  async getDelivererEarnings(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('startDate') startDate?: Date,
    @Query('endDate') endDate?: Date,
  ) {
    return this.adminService.getDelivererEarnings(id, startDate, endDate);
  }

  // ==========================================
  // DELIVERY MANAGEMENT
  // ==========================================

  @Get('deliveries')
  @Roles('super_admin', 'admin', 'moderator')
  @ApiOperation({
    summary: 'Liste des livraisons',
    description: 'Récupère la liste paginée de toutes les livraisons',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false, type: String })
  @ApiQuery({ name: 'startDate', required: false, type: Date })
  @ApiQuery({ name: 'endDate', required: false, type: Date })
  @ApiResponse({ status: 200, description: 'Liste paginée des livraisons' })
  async getAllDeliveries(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: string,
    @Query('startDate') startDate?: Date,
    @Query('endDate') endDate?: Date,
  ) {
    return this.adminService.getAllDeliveries(page, limit, status, startDate, endDate);
  }

  @Get('deliveries/:id')
  @Roles('super_admin', 'admin', 'moderator')
  @ApiOperation({
    summary: 'Détails d\'une livraison',
    description: 'Récupère les informations détaillées d\'une livraison',
  })
  @ApiResponse({ status: 200, description: 'Informations de la livraison' })
  @ApiResponse({ status: 404, description: 'Livraison introuvable' })
  async getDeliveryById(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.getDeliveryById(id);
  }

  @Post('deliveries/:id/cancel')
  @Roles('super_admin', 'admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Annuler une livraison',
    description: 'Permet à un admin d\'annuler une livraison avec une raison',
  })
  @ApiResponse({ status: 200, description: 'Livraison annulée' })
  @ApiResponse({ status: 404, description: 'Livraison introuvable' })
  async cancelDelivery(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('reason') reason: string,
  ) {
    return this.adminService.cancelDeliveryAsAdmin(id, reason);
  }

  // ==========================================
  // QUOTA MANAGEMENT
  // ==========================================

  @Get('quotas/purchases')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Historique des achats de quotas',
    description: 'Récupère l\'historique des achats de quotas par les utilisateurs',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'startDate', required: false, type: Date })
  @ApiQuery({ name: 'endDate', required: false, type: Date })
  @ApiQuery({ name: 'userType', required: false, enum: ['client', 'deliverer'] })
  @ApiResponse({ status: 200, description: 'Liste paginée des achats de quotas' })
  async getQuotaPurchases(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('startDate') startDate?: Date,
    @Query('endDate') endDate?: Date,
    @Query('userType') userType?: 'client' | 'deliverer',
  ) {
    return this.adminService.getQuotaPurchases(page, limit, startDate, endDate, userType);
  }

  @Get('quotas/revenue')
  @Roles('super_admin', 'admin')
  @ApiOperation({
    summary: 'Revenus des quotas',
    description: 'Récupère les statistiques de revenus des ventes de quotas',
  })
  @ApiQuery({ name: 'period', enum: ['day', 'week', 'month', 'year'], required: false })
  @ApiResponse({ status: 200, description: 'Statistiques de revenus des quotas' })
  async getQuotaRevenue(
    @Query('period') period: 'day' | 'week' | 'month' | 'year' = 'month',
  ) {
    return this.adminService.getQuotaRevenue(period);
  }
}
