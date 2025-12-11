import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { User } from './entities/user.entity';
import { Deliverer } from './entities/deliverer.entity';
import { RefreshToken } from './entities/refresh-token.entity';
import { Admin } from './entities/admin.entity';
import { RegisterDto, RegisterDelivererDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AdminLoginDto } from './dto/admin-login.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Deliverer)
    private delivererRepository: Repository<Deliverer>,
    @InjectRepository(RefreshToken)
    private refreshTokenRepository: Repository<RefreshToken>,
    @InjectRepository(Admin)
    private adminRepository: Repository<Admin>,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  // ==========================================
  // CLIENT REGISTRATION
  // ==========================================
  async registerClient(registerDto: RegisterDto) {
    const { phone_number, email, password, full_name } = registerDto;

    // Check if phone number already exists
    const existingUser = await this.userRepository.findOne({
      where: { phone_number },
    });
    if (existingUser) {
      throw new ConflictException('Phone number already registered');
    }

    // Check if email already exists
    if (email) {
      const existingEmail = await this.userRepository.findOne({
        where: { email },
      });
      if (existingEmail) {
        throw new ConflictException('Email already registered');
      }
    }

    // Hash password
    const password_hash = await bcrypt.hash(password, 10);

    // Create user
    const user = this.userRepository.create({
      phone_number,
      email,
      full_name,
      password_hash,
    });

    await this.userRepository.save(user);

    // Generate tokens
    const tokens = await this.generateTokens(user.id, 'client');

    return {
      user: this.sanitizeUser(user),
      ...tokens,
    };
  }

  // ==========================================
  // DELIVERER REGISTRATION
  // ==========================================
  async registerDeliverer(registerDto: RegisterDelivererDto) {
    const { phone_number, email, password, full_name, vehicle_type, license_plate } = registerDto;

    // Check if phone number already exists
    const existingDeliverer = await this.delivererRepository.findOne({
      where: { phone_number },
    });
    if (existingDeliverer) {
      throw new ConflictException('Phone number already registered');
    }

    // Check if email already exists
    if (email) {
      const existingEmail = await this.delivererRepository.findOne({
        where: { email },
      });
      if (existingEmail) {
        throw new ConflictException('Email already registered');
      }
    }

    // Hash password
    const password_hash = await bcrypt.hash(password, 10);

    // Create deliverer
    const deliverer = this.delivererRepository.create({
      phone_number,
      email,
      full_name,
      password_hash,
      vehicle_type,
      license_plate,
    });

    await this.delivererRepository.save(deliverer);

    // Generate tokens
    const tokens = await this.generateTokens(deliverer.id, 'deliverer');

    return {
      deliverer: this.sanitizeDeliverer(deliverer),
      ...tokens,
    };
  }

  // ==========================================
  // CLIENT LOGIN
  // ==========================================
  async loginClient(loginDto: LoginDto) {
    const { phone_number, password } = loginDto;

    // Find user
    const user = await this.userRepository.findOne({
      where: { phone_number },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if user is active
    if (!user.is_active) {
      throw new UnauthorizedException('Account is deactivated');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate tokens
    const tokens = await this.generateTokens(user.id, 'client');

    return {
      user: this.sanitizeUser(user),
      ...tokens,
    };
  }

  // ==========================================
  // DELIVERER LOGIN
  // ==========================================
  async loginDeliverer(loginDto: LoginDto) {
    const { phone_number, password } = loginDto;

    // Find deliverer
    const deliverer = await this.delivererRepository.findOne({
      where: { phone_number },
    });

    if (!deliverer) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if deliverer is active
    if (!deliverer.is_active) {
      throw new UnauthorizedException('Account is deactivated');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, deliverer.password_hash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate tokens
    const tokens = await this.generateTokens(deliverer.id, 'deliverer');

    return {
      deliverer: this.sanitizeDeliverer(deliverer),
      ...tokens,
    };
  }

  // ==========================================
  // REFRESH TOKEN
  // ==========================================
  async refreshToken(refreshTokenString: string) {
    // Find refresh token in database
    const refreshToken = await this.refreshTokenRepository.findOne({
      where: { token: refreshTokenString },
    });

    if (!refreshToken || refreshToken.is_revoked) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    // Check if token is expired
    if (new Date() > refreshToken.expires_at) {
      throw new UnauthorizedException('Refresh token expired');
    }

    // Generate new tokens
    const userId = refreshToken.user_type === 'client'
      ? refreshToken.user_id
      : refreshToken.deliverer_id;

    const tokens = await this.generateTokens(userId, refreshToken.user_type);

    // Revoke old refresh token
    refreshToken.is_revoked = true;
    await this.refreshTokenRepository.save(refreshToken);

    return tokens;
  }

  // ==========================================
  // LOGOUT
  // ==========================================
  async logout(refreshTokenString: string) {
    const refreshToken = await this.refreshTokenRepository.findOne({
      where: { token: refreshTokenString },
    });

    if (refreshToken) {
      refreshToken.is_revoked = true;
      await this.refreshTokenRepository.save(refreshToken);
    }

    return { message: 'Logged out successfully' };
  }

  // ==========================================
  // GENERATE TOKENS
  // ==========================================
  private async generateTokens(userId: string, userType: 'client' | 'deliverer' | 'admin') {
    // Generate access token
    const accessToken = this.jwtService.sign(
      { sub: userId, type: userType },
      {
        secret: this.configService.get('JWT_SECRET'),
        expiresIn: this.configService.get('JWT_EXPIRES_IN'),
      },
    );

    // Generate refresh token
    const refreshTokenString = this.jwtService.sign(
      { sub: userId, type: userType },
      {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
        expiresIn: this.configService.get('JWT_REFRESH_EXPIRES_IN'),
      },
    );

    // Save refresh token to database
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    const refreshToken = this.refreshTokenRepository.create();
    refreshToken.token = refreshTokenString;
    refreshToken.user_type = userType;
    if (userType === 'client') {
      refreshToken.user_id = userId;
    } else if (userType === 'deliverer') {
      refreshToken.deliverer_id = userId;
    } else if (userType === 'admin') {
      refreshToken.admin_id = userId;
    }
    refreshToken.expires_at = expiresAt;

    await this.refreshTokenRepository.save(refreshToken);

    return {
      access_token: accessToken,
      refresh_token: refreshTokenString,
      token_type: 'Bearer',
      expires_in: 3600, // 1 hour in seconds
    };
  }

  // ==========================================
  // SANITIZE USER (remove password)
  // ==========================================
  private sanitizeUser(user: User) {
    const { password_hash, ...sanitized } = user;
    return sanitized;
  }

  private sanitizeDeliverer(deliverer: Deliverer) {
    const { password_hash, ...sanitized } = deliverer;
    return sanitized;
  }

  // ==========================================
  // ADMIN LOGIN
  // ==========================================
  async loginAdmin(adminLoginDto: AdminLoginDto) {
    const { email, password } = adminLoginDto;

    // Find admin by email
    const admin = await this.adminRepository.findOne({
      where: { email },
    });

    if (!admin) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check if admin is active
    if (!admin.is_active) {
      throw new UnauthorizedException('Account is deactivated');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, admin.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Update last login
    admin.last_login_at = new Date();
    await this.adminRepository.save(admin);

    // Generate tokens with admin role included
    const tokens = await this.generateAdminTokens(admin.id, admin.role);

    return {
      admin: this.sanitizeAdmin(admin),
      ...tokens,
    };
  }

  // ==========================================
  // GENERATE ADMIN TOKENS
  // ==========================================
  private async generateAdminTokens(adminId: string, role: string) {
    // Generate access token with role
    const accessToken = this.jwtService.sign(
      { sub: adminId, type: 'admin', role },
      {
        secret: this.configService.get('JWT_SECRET'),
        expiresIn: this.configService.get('JWT_EXPIRES_IN'),
      },
    );

    // Generate refresh token
    const refreshTokenString = this.jwtService.sign(
      { sub: adminId, type: 'admin', role },
      {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
        expiresIn: this.configService.get('JWT_REFRESH_EXPIRES_IN'),
      },
    );

    // Save refresh token to database
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    const refreshToken = this.refreshTokenRepository.create();
    refreshToken.token = refreshTokenString;
    refreshToken.user_type = 'admin';
    refreshToken.admin_id = adminId;
    refreshToken.expires_at = expiresAt;

    await this.refreshTokenRepository.save(refreshToken);

    return {
      access_token: accessToken,
      refresh_token: refreshTokenString,
      token_type: 'Bearer',
      expires_in: 3600, // 1 hour in seconds
    };
  }

  // ==========================================
  // SANITIZE ADMIN (remove password)
  // ==========================================
  private sanitizeAdmin(admin: Admin) {
    const { password, ...sanitized } = admin;
    return sanitized;
  }

  // ==========================================
  // VALIDATE USER (for JWT strategy)
  // ==========================================
  async validateUser(userId: string, userType: 'client' | 'deliverer' | 'admin') {
    if (userType === 'client') {
      const user = await this.userRepository.findOne({ where: { id: userId } });
      if (!user || !user.is_active) {
        throw new UnauthorizedException('User not found or inactive');
      }
      return this.sanitizeUser(user);
    } else if (userType === 'deliverer') {
      const deliverer = await this.delivererRepository.findOne({ where: { id: userId } });
      if (!deliverer || !deliverer.is_active) {
        throw new UnauthorizedException('Deliverer not found or inactive');
      }
      return this.sanitizeDeliverer(deliverer);
    } else if (userType === 'admin') {
      const admin = await this.adminRepository.findOne({ where: { id: userId } });
      if (!admin || !admin.is_active) {
        throw new UnauthorizedException('Admin not found or inactive');
      }
      return this.sanitizeAdmin(admin);
    }
  }
}
