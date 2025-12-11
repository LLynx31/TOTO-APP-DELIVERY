import { SetMetadata } from '@nestjs/common';

export const UserType = (...types: string[]) => SetMetadata('userType', types);
