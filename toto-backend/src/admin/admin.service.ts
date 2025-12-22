import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, In, ILike } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../auth/entities/user.entity';
import { Deliverer } from '../auth/entities/deliverer.entity';
import { Delivery, DeliveryStatus } from '../deliveries/entities/delivery.entity';
import { DeliveryQuota } from '../quotas/entities/delivery-quota.entity';
import { QuotaTransaction } from '../quotas/entities/quota-transaction.entity';
import { Admin } from '../auth/entities/admin.entity';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdateDelivererDto } from './dto/update-deliverer.dto';
import { ApproveKycDto } from './dto/approve-kyc.dto';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Deliverer)
    private delivererRepository: Repository<Deliverer>,
    @InjectRepository(Delivery)
    private deliveryRepository: Repository<Delivery>,
    @InjectRepository(DeliveryQuota)
    private quotaRepository: Repository<DeliveryQuota>,
    @InjectRepository(QuotaTransaction)
    private transactionRepository: Repository<QuotaTransaction>,
    @InjectRepository(Admin)
    private adminRepository: Repository<Admin>,
  ) {}

  // ==========================================
  // DASHBOARD & ANALYTICS
  // ==========================================

  async getDashboardStats() {
    const [
      totalUsers,
      totalDeliverers,
      activeDeliveries,
      totalDeliveries,
      newUsersToday,
      deliveriesToday,
    ] = await Promise.all([
      this.userRepository.count(),
      this.delivererRepository.count(),
      this.deliveryRepository.count({
        where: { status: In([DeliveryStatus.ACCEPTED, DeliveryStatus.PICKUP_IN_PROGRESS, DeliveryStatus.PICKED_UP, DeliveryStatus.DELIVERY_IN_PROGRESS]) },
      }),
      this.deliveryRepository.count(),
      this.userRepository.count({
        where: {
          created_at: Between(
            new Date(new Date().setHours(0, 0, 0, 0)),
            new Date(new Date().setHours(23, 59, 59, 999)),
          ),
        },
      }),
      this.deliveryRepository.count({
        where: {
          created_at: Between(
            new Date(new Date().setHours(0, 0, 0, 0)),
            new Date(new Date().setHours(23, 59, 59, 999)),
          ),
        },
      }),
    ]);

    // Calculate total revenue from completed deliveries
    const deliveries = await this.deliveryRepository.find({
      where: { status: DeliveryStatus.DELIVERED },
    });
    const totalRevenue = deliveries.reduce((sum, d) => sum + parseFloat(d.price.toString()), 0);

    return {
      total_users: totalUsers,
      total_deliverers: totalDeliverers,
      active_deliveries: activeDeliveries,
      total_deliveries: totalDeliveries,
      total_revenue: totalRevenue,
      new_users_today: newUsersToday,
      deliveries_today: deliveriesToday,
    };
  }

  async getRevenueAnalytics(period: 'day' | 'week' | 'month' | 'year' = 'week') {
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'day':
        startDate = new Date(now.setHours(0, 0, 0, 0));
        break;
      case 'week':
        startDate = new Date(now.setDate(now.getDate() - 7));
        break;
      case 'month':
        startDate = new Date(now.setMonth(now.getMonth() - 1));
        break;
      case 'year':
        startDate = new Date(now.setFullYear(now.getFullYear() - 1));
        break;
    }

    const deliveries = await this.deliveryRepository.find({
      where: {
        status: DeliveryStatus.DELIVERED,
        created_at: Between(startDate, new Date()),
      },
      order: { created_at: 'ASC' },
    });

    return {
      period,
      start_date: startDate,
      end_date: new Date(),
      total_revenue: deliveries.reduce((sum, d) => sum + parseFloat(d.price.toString()), 0),
      total_deliveries: deliveries.length,
      deliveries: deliveries.map(d => ({
        date: d.created_at,
        price: d.price,
      })),
    };
  }

  async getDeliveriesAnalytics(status?: string, period: 'day' | 'week' | 'month' = 'week') {
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'day':
        startDate = new Date(now.setHours(0, 0, 0, 0));
        break;
      case 'week':
        startDate = new Date(now.setDate(now.getDate() - 7));
        break;
      case 'month':
        startDate = new Date(now.setMonth(now.getMonth() - 1));
        break;
    }

    const where: any = {
      created_at: Between(startDate, new Date()),
    };

    if (status) {
      where.status = status;
    }

    const deliveries = await this.deliveryRepository.find({
      where,
      order: { created_at: 'ASC' },
    });

    // Group by status
    const byStatus = deliveries.reduce((acc, d) => {
      acc[d.status] = (acc[d.status] || 0) + 1;
      return acc;
    }, {});

    return {
      period,
      start_date: startDate,
      end_date: new Date(),
      total: deliveries.length,
      by_status: byStatus,
    };
  }

  // ==========================================
  // USER MANAGEMENT
  // ==========================================

  async getAllUsers(page = 1, limit = 20, search?: string, isActive?: boolean) {
    const queryBuilder = this.userRepository.createQueryBuilder('user');

    if (search) {
      queryBuilder.where(
        '(user.phone_number ILIKE :search OR user.full_name ILIKE :search OR user.email ILIKE :search)',
        { search: `%${search}%` }
      );
    }

    if (isActive !== undefined) {
      queryBuilder.andWhere('user.is_active = :isActive', { isActive });
    }

    queryBuilder
      .skip((page - 1) * limit)
      .take(limit)
      .orderBy('user.created_at', 'DESC');

    const [users, total] = await queryBuilder.getManyAndCount();

    return {
      data: users,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getUserById(id: string) {
    const user = await this.userRepository.findOne({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get user's deliveries
    const deliveries = await this.deliveryRepository.find({
      where: { client_id: id },
      order: { created_at: 'DESC' },
      take: 10,
    });

    return {
      user,
      deliveries_count: deliveries.length,
      recent_deliveries: deliveries,
    };
  }

  async updateUser(id: string, updateDto: UpdateUserDto) {
    const user = await this.userRepository.findOne({ where: { id } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    Object.assign(user, updateDto);
    return this.userRepository.save(user);
  }

  async getUserTransactions(id: string) {
    // Find transactions through quota relation (quota.user_id = id)
    const transactions = await this.transactionRepository
      .createQueryBuilder('transaction')
      .leftJoinAndSelect('transaction.quota', 'quota')
      .where('quota.user_id = :id', { id })
      .orderBy('transaction.created_at', 'DESC')
      .getMany();

    return transactions;
  }

  // ==========================================
  // DELIVERER MANAGEMENT
  // ==========================================

  async getAllDeliverers(
    page = 1,
    limit = 20,
    kycStatus?: string,
    isActive?: boolean,
    isAvailable?: boolean,
    search?: string,
  ) {
    const queryBuilder = this.delivererRepository.createQueryBuilder('deliverer');

    if (search) {
      queryBuilder.where(
        '(deliverer.phone_number ILIKE :search OR deliverer.full_name ILIKE :search OR deliverer.email ILIKE :search OR deliverer.license_plate ILIKE :search)',
        { search: `%${search}%` }
      );
    }

    if (kycStatus) {
      queryBuilder.andWhere('deliverer.kyc_status = :kycStatus', { kycStatus });
    }

    if (isActive !== undefined) {
      queryBuilder.andWhere('deliverer.is_active = :isActive', { isActive });
    }

    if (isAvailable !== undefined) {
      queryBuilder.andWhere('deliverer.is_available = :isAvailable', { isAvailable });
    }

    queryBuilder
      .skip((page - 1) * limit)
      .take(limit)
      .orderBy('deliverer.created_at', 'DESC');

    const [deliverers, total] = await queryBuilder.getManyAndCount();

    return {
      data: deliverers,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getDelivererById(id: string) {
    const deliverer = await this.delivererRepository.findOne({ where: { id } });

    if (!deliverer) {
      throw new NotFoundException('Deliverer not found');
    }

    // Get deliverer's deliveries
    const deliveries = await this.deliveryRepository.find({
      where: { deliverer_id: id },
      order: { created_at: 'DESC' },
      take: 10,
    });

    // Calculate earnings
    const completedDeliveries = deliveries.filter(d => d.status === DeliveryStatus.DELIVERED);
    const totalEarnings = completedDeliveries.reduce(
      (sum, d) => sum + parseFloat(d.price.toString()),
      0,
    );

    return {
      deliverer,
      total_deliveries: deliveries.length,
      completed_deliveries: completedDeliveries.length,
      total_earnings: totalEarnings,
      recent_deliveries: deliveries,
    };
  }

  async updateDeliverer(id: string, updateDto: UpdateDelivererDto) {
    const deliverer = await this.delivererRepository.findOne({ where: { id } });

    if (!deliverer) {
      throw new NotFoundException('Deliverer not found');
    }

    Object.assign(deliverer, updateDto);
    return this.delivererRepository.save(deliverer);
  }

  async approveKyc(id: string, approveDto: ApproveKycDto) {
    const deliverer = await this.delivererRepository.findOne({ where: { id } });

    if (!deliverer) {
      throw new NotFoundException('Deliverer not found');
    }

    deliverer.kyc_status = approveDto.kyc_status;
    deliverer.kyc_reviewed_at = new Date();

    if (approveDto.kyc_status === 'approved') {
      deliverer.is_verified = true;
    }

    return this.delivererRepository.save(deliverer);
  }

  async getDelivererEarnings(id: string, startDate?: Date, endDate?: Date) {
    const where: any = {
      deliverer_id: id,
      status: DeliveryStatus.DELIVERED,
    };

    if (startDate && endDate) {
      where.created_at = Between(startDate, endDate);
    }

    const deliveries = await this.deliveryRepository.find({
      where,
      order: { created_at: 'DESC' },
    });

    const totalEarnings = deliveries.reduce(
      (sum, d) => sum + parseFloat(d.price.toString()),
      0,
    );

    return {
      total_earnings: totalEarnings,
      total_deliveries: deliveries.length,
      deliveries: deliveries.map(d => ({
        id: d.id,
        date: d.created_at,
        price: d.price,
      })),
    };
  }

  // ==========================================
  // DELIVERY MANAGEMENT
  // ==========================================

  async getAllDeliveries(
    page = 1,
    limit = 20,
    status?: string,
    startDate?: Date,
    endDate?: Date,
    search?: string,
  ) {
    const queryBuilder = this.deliveryRepository.createQueryBuilder('delivery');

    if (search) {
      queryBuilder.where(
        '(delivery.receiver_name ILIKE :search OR delivery.pickup_address ILIKE :search OR delivery.delivery_address ILIKE :search OR delivery.delivery_phone ILIKE :search OR delivery.pickup_phone ILIKE :search)',
        { search: `%${search}%` }
      );
    }

    if (status) {
      if (search) {
        queryBuilder.andWhere('delivery.status = :status', { status });
      } else {
        queryBuilder.where('delivery.status = :status', { status });
      }
    }

    if (startDate && endDate) {
      if (search || status) {
        queryBuilder.andWhere('delivery.created_at BETWEEN :startDate AND :endDate', {
          startDate,
          endDate,
        });
      } else {
        queryBuilder.where('delivery.created_at BETWEEN :startDate AND :endDate', {
          startDate,
          endDate,
        });
      }
    }

    queryBuilder
      .skip((page - 1) * limit)
      .take(limit)
      .orderBy('delivery.created_at', 'DESC');

    const [deliveries, total] = await queryBuilder.getManyAndCount();

    return {
      data: deliveries,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getDeliveryById(id: string) {
    const delivery = await this.deliveryRepository.findOne({ where: { id } });

    if (!delivery) {
      throw new NotFoundException('Delivery not found');
    }

    return delivery;
  }

  async cancelDeliveryAsAdmin(id: string, reason: string) {
    const delivery = await this.deliveryRepository.findOne({ where: { id } });

    if (!delivery) {
      throw new NotFoundException('Delivery not found');
    }

    delivery.status = DeliveryStatus.CANCELLED;
    await this.deliveryRepository.save(delivery);

    // TODO: Refund quota automatically (implement in DeliveriesService)
    // For now, return the updated delivery
    return delivery;
  }

  // ==========================================
  // QUOTA MANAGEMENT
  // ==========================================

  async getQuotaPurchases(
    page = 1,
    limit = 20,
    startDate?: Date,
    endDate?: Date,
    userType?: 'client' | 'deliverer',
  ) {
    const where: any = {
      transaction_type: 'purchase',
    };

    if (startDate && endDate) {
      where.created_at = Between(startDate, endDate);
    }

    const [transactions, total] = await this.transactionRepository.findAndCount({
      where,
      skip: (page - 1) * limit,
      take: limit,
      order: { created_at: 'DESC' },
    });

    return {
      data: transactions,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getQuotaRevenue(period: 'day' | 'week' | 'month' | 'year' = 'month') {
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'day':
        startDate = new Date(now.setHours(0, 0, 0, 0));
        break;
      case 'week':
        startDate = new Date(now.setDate(now.getDate() - 7));
        break;
      case 'month':
        startDate = new Date(now.setMonth(now.getMonth() - 1));
        break;
      case 'year':
        startDate = new Date(now.setFullYear(now.getFullYear() - 1));
        break;
    }

    // Get purchase transactions with quota relation to access price_paid and quota_type
    const transactions = await this.transactionRepository
      .createQueryBuilder('transaction')
      .leftJoinAndSelect('transaction.quota', 'quota')
      .where('transaction.transaction_type = :type', { type: 'purchase' })
      .andWhere('transaction.created_at BETWEEN :startDate AND :endDate', {
        startDate,
        endDate: new Date(),
      })
      .orderBy('transaction.created_at', 'DESC')
      .getMany();

    // Calculate total revenue from quota price_paid
    const totalRevenue = transactions.reduce(
      (sum, t) => sum + (t.quota ? parseFloat(t.quota.price_paid.toString()) : 0),
      0,
    );

    // Group by quota type
    const byType = transactions.reduce((acc, t) => {
      const type = t.quota?.quota_type || 'unknown';
      const price = t.quota ? parseFloat(t.quota.price_paid.toString()) : 0;
      acc[type] = (acc[type] || 0) + price;
      return acc;
    }, {} as Record<string, number>);

    return {
      period,
      start_date: startDate,
      end_date: new Date(),
      total_revenue: totalRevenue,
      total_purchases: transactions.length,
      revenue_by_type: byType,
    };
  }

  // ==========================================
  // ADMIN MANAGEMENT
  // ==========================================

  async getAllAdmins(page: number = 1, limit: number = 20, search?: string) {
    const queryBuilder = this.adminRepository.createQueryBuilder('admin');

    if (search) {
      queryBuilder.where(
        '(admin.email ILIKE :search OR admin.full_name ILIKE :search)',
        { search: `%${search}%` }
      );
    }

    queryBuilder
      .skip((page - 1) * limit)
      .take(limit)
      .orderBy('admin.created_at', 'DESC');

    const [admins, total] = await queryBuilder.getManyAndCount();

    return {
      data: admins.map(admin => {
        const { password, ...adminWithoutPassword } = admin;
        return adminWithoutPassword;
      }),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getAdminById(id: string) {
    const admin = await this.adminRepository.findOne({ where: { id } });
    if (!admin) {
      throw new NotFoundException('Admin introuvable');
    }
    const { password, ...adminWithoutPassword } = admin;
    return adminWithoutPassword;
  }

  async createAdmin(data: {
    email: string;
    password: string;
    full_name: string;
    role: 'super_admin' | 'admin' | 'moderator';
  }) {
    const existingAdmin = await this.adminRepository.findOne({
      where: { email: data.email },
    });

    if (existingAdmin) {
      throw new ConflictException('Un admin avec cet email existe déjà');
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    const admin = this.adminRepository.create({
      ...data,
      password: hashedPassword,
    });

    const savedAdmin = await this.adminRepository.save(admin);
    const { password, ...adminWithoutPassword } = savedAdmin;
    return adminWithoutPassword;
  }

  async updateAdmin(id: string, data: {
    full_name?: string;
    role?: 'super_admin' | 'admin' | 'moderator';
    is_active?: boolean;
    password?: string;
  }) {
    const admin = await this.adminRepository.findOne({ where: { id } });
    if (!admin) {
      throw new NotFoundException('Admin introuvable');
    }

    if (data.password) {
      data.password = await bcrypt.hash(data.password, 10);
    }

    Object.assign(admin, data);
    const updatedAdmin = await this.adminRepository.save(admin);
    const { password, ...adminWithoutPassword } = updatedAdmin;
    return adminWithoutPassword;
  }

  async deleteAdmin(id: string) {
    const admin = await this.adminRepository.findOne({ where: { id } });
    if (!admin) {
      throw new NotFoundException('Admin introuvable');
    }

    await this.adminRepository.remove(admin);
    return { message: 'Admin supprimé avec succès' };
  }
}
