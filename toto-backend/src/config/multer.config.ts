import { diskStorage } from 'multer';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { HttpException, HttpStatus } from '@nestjs/common';

export const kycStorage = diskStorage({
  destination: './uploads/kyc',
  filename: (req, file, cb) => {
    const randomName = uuidv4();
    cb(null, `${randomName}${extname(file.originalname)}`);
  },
});

export const kycFileFilter = (req, file, cb) => {
  if (!file.originalname.match(/\.(jpg|jpeg|png|pdf)$/)) {
    return cb(
      new HttpException(
        'Only JPG, JPEG, PNG, and PDF files are allowed',
        HttpStatus.BAD_REQUEST,
      ),
      false,
    );
  }
  cb(null, true);
};
