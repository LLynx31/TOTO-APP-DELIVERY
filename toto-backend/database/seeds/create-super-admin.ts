import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';

export async function createSuperAdmin(dataSource: DataSource) {
  const adminRepository = dataSource.getRepository('admins');

  // Check if super admin already exists
  const existingAdmin = await adminRepository.findOne({
    where: { email: 'admin@toto.com' },
  });

  if (existingAdmin) {
    console.log('ℹ️  Super admin already exists (admin@toto.com)');
    return;
  }

  // Hash password
  const hashedPassword = await bcrypt.hash('Admin@2025', 10);

  // Create super admin
  const superAdmin = adminRepository.create({
    email: 'admin@toto.com',
    password: hashedPassword,
    full_name: 'Super Admin',
    role: 'super_admin',
    is_active: true,
  });

  await adminRepository.save(superAdmin);

  console.log('✅ Super admin created successfully!');
  console.log('   Email: admin@toto.com');
  console.log('   Password: Admin@2025');
  console.log('   Role: super_admin');
}


