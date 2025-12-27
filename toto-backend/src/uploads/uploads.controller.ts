import {
  Controller,
  Post,
  Get,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  UploadedFiles,
  Request,
  Param,
  ForbiddenException,
  BadRequestException,
  Res,
} from '@nestjs/common';
import { FileInterceptor, FileFieldsInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import type { Response } from 'express';
import { join } from 'path';
import { existsSync } from 'fs';
import { UploadsService, DocumentType } from './uploads.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ConfigService } from '@nestjs/config';

@ApiTags('uploads')
@Controller('uploads')
export class UploadsController {
  constructor(
    private readonly uploadsService: UploadsService,
    private readonly configService: ConfigService,
  ) {}

  // ==========================================
  // UPLOAD SINGLE KYC DOCUMENT
  // ==========================================
  @Post('kyc/:documentType')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload un document KYC',
    description: 'Upload un document KYC pour le livreur connecté',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Document uploadé avec succès',
    schema: {
      example: {
        url: 'http://localhost:3000/uploads/abc123.jpg',
        documentType: 'driving_license',
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Type de document invalide' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async uploadKycDocument(
    @Request() req,
    @Param('documentType') documentType: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    // Verify it's a deliverer
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    // Validate document type
    const validTypes: DocumentType[] = ['driving_license', 'id_card', 'vehicle_photo'];
    if (!validTypes.includes(documentType as DocumentType)) {
      throw new BadRequestException(
        'Type de document invalide. Types acceptés: driving_license, id_card, vehicle_photo',
      );
    }

    if (!file) {
      throw new BadRequestException('Aucun fichier fourni');
    }

    return this.uploadsService.uploadKycDocument(
      req.user.id,
      documentType as DocumentType,
      file,
    );
  }

  // ==========================================
  // UPLOAD ALL KYC DOCUMENTS AT ONCE
  // ==========================================
  @Post('kyc')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(
    FileFieldsInterceptor([
      { name: 'driving_license', maxCount: 1 },
      { name: 'id_card', maxCount: 1 },
      { name: 'vehicle_photo', maxCount: 1 },
    ]),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload tous les documents KYC',
    description: 'Upload les documents KYC (permis, CNI, photo véhicule) en une seule requête',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        driving_license: {
          type: 'string',
          format: 'binary',
          description: 'Photo du permis de conduire',
        },
        id_card: {
          type: 'string',
          format: 'binary',
          description: 'Photo de la CNI',
        },
        vehicle_photo: {
          type: 'string',
          format: 'binary',
          description: 'Photo du véhicule',
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Documents uploadés avec succès',
    schema: {
      example: {
        driving_license_url: 'http://localhost:3000/uploads/abc123.jpg',
        id_card_url: 'http://localhost:3000/uploads/def456.jpg',
        vehicle_photo_url: 'http://localhost:3000/uploads/ghi789.jpg',
        kyc_status: 'pending',
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async uploadAllKycDocuments(
    @Request() req,
    @UploadedFiles()
    files: {
      driving_license?: Express.Multer.File[];
      id_card?: Express.Multer.File[];
      vehicle_photo?: Express.Multer.File[];
    },
  ) {
    // Verify it's a deliverer
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    if (!files || Object.keys(files).length === 0) {
      throw new BadRequestException('Aucun fichier fourni');
    }

    return this.uploadsService.uploadMultipleKycDocuments(req.user.id, {
      driving_license: files.driving_license?.[0],
      id_card: files.id_card?.[0],
      vehicle_photo: files.vehicle_photo?.[0],
    });
  }

  // ==========================================
  // GET KYC DOCUMENTS STATUS
  // ==========================================
  @Get('kyc')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Obtenir le statut des documents KYC',
    description: 'Retourne les URLs des documents KYC et leur statut de vérification',
  })
  @ApiResponse({
    status: 200,
    description: 'Statut des documents KYC',
    schema: {
      example: {
        driving_license_url: 'http://localhost:3000/uploads/abc123.jpg',
        id_card_url: 'http://localhost:3000/uploads/def456.jpg',
        vehicle_photo_url: 'http://localhost:3000/uploads/ghi789.jpg',
        kyc_status: 'pending',
        kyc_submitted_at: '2024-12-25T10:00:00.000Z',
        kyc_reviewed_at: null,
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 403, description: 'Accès refusé (non livreur)' })
  async getKycDocuments(@Request() req) {
    // Verify it's a deliverer
    if (req.user.type !== 'deliverer') {
      throw new ForbiddenException('Accès réservé aux livreurs');
    }

    return this.uploadsService.getKycDocuments(req.user.id);
  }

  // ==========================================
  // SERVE UPLOADED FILES
  // ==========================================
  @Get(':filename')
  @ApiOperation({
    summary: 'Obtenir un fichier uploadé',
    description: 'Retourne le fichier demandé',
  })
  @ApiResponse({ status: 200, description: 'Fichier retourné' })
  @ApiResponse({ status: 404, description: 'Fichier non trouvé' })
  async getFile(@Param('filename') filename: string, @Res() res: Response) {
    const uploadPath = this.configService.get('UPLOAD_DEST') || './uploads';
    const filePath = join(process.cwd(), uploadPath, filename);

    if (!existsSync(filePath)) {
      return res.status(404).json({ message: 'Fichier non trouvé' });
    }

    return res.sendFile(filePath);
  }
}
