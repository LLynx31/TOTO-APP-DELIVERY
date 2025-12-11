import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../notifications/screens/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data
  late UserModel _user;

  // Mock activity stats
  final int _totalDeliveries = 28;
  final int _activeDeliveries = 2;
  final double _averageRating = 4.7;
  final int _memberSinceDays = 90;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    _user = UserModel(
      id: 'user123',
      firstName: 'Jean',
      lastName: 'Dupont',
      phone: '+225 07 12 34 56 78',
      email: 'jean.dupont@example.com',
      createdAt: DateTime.now().subtract(Duration(days: _memberSinceDays)),
      favoriteAddresses: [
        AddressModel(
          id: '1',
          address: '123, Rue des Fleurs, Abidjan',
          latitude: 5.3600,
          longitude: -4.0083,
          label: 'Maison',
          isDefault: true,
        ),
        AddressModel(
          id: '2',
          address: '456, Boulevard de la Liberté, Yamoussoukro',
          latitude: 6.8276,
          longitude: -5.2893,
          label: 'Bureau',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundGrey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.backgroundGrey,
                        child: _user.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _user.photoUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.textSecondary,
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Change photo
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.paddingSm),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Name
                  Text(
                    _user.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: AppSizes.spacingXs),

                  // Phone
                  Text(
                    _user.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Personal Information
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.personalInfo,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          _showEditProfileDialog();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  _buildInfoTile(
                    icon: Icons.person_outline,
                    label: AppStrings.lastName,
                    value: _user.lastName,
                  ),

                  const Divider(),

                  _buildInfoTile(
                    icon: Icons.person_outline,
                    label: AppStrings.firstName,
                    value: _user.firstName,
                  ),

                  const Divider(),

                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    label: AppStrings.phone,
                    value: _user.phone,
                  ),

                  if (_user.email != null) ...[
                    const Divider(),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: AppStrings.email,
                      value: _user.email!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Favorite Addresses
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.favoriteAddresses,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  ..._user.favoriteAddresses.map((address) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
                      child: _buildAddressTile(address),
                    );
                  }),

                  const SizedBox(height: AppSizes.spacingSm),

                  OutlinedButton.icon(
                    onPressed: () {
                      _showAddAddressDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addAddress),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: CustomButton(
                text: AppStrings.logout,
                onPressed: () {
                  _showLogoutDialog();
                },
                variant: ButtonVariant.outline,
                icon: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.iconSizeSm,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSizes.spacingXs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile(AddressModel address) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: AppSizes.iconSizeMd,
            ),
          ),
          const SizedBox(width: AppSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.label != null)
                  Text(
                    address.label!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                Text(
                  address.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
            ),
            onPressed: () {
              // TODO: Delete address
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final firstNameController = TextEditingController(text: _user.firstName);
    final lastNameController = TextEditingController(text: _user.lastName);
    final phoneController = TextEditingController(text: _user.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: AppStrings.firstName,
                controller: firstNameController,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: AppSizes.spacingMd),
              CustomTextField(
                label: AppStrings.lastName,
                controller: lastNameController,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: AppSizes.spacingMd),
              CustomTextField(
                label: AppStrings.phone,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              firstNameController.dispose();
              lastNameController.dispose();
              phoneController.dispose();
              Navigator.pop(context);
            },
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              // TODO: Save profile changes
              setState(() {
                _user = _user.copyWith(
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  phone: phoneController.text,
                );
              });
              firstNameController.dispose();
              lastNameController.dispose();
              phoneController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog() {
    final addressController = TextEditingController();
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une adresse'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Libellé (optionnel)',
                hint: 'Maison, Bureau, etc.',
                controller: labelController,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              const SizedBox(height: AppSizes.spacingMd),
              CustomTextField(
                label: 'Adresse',
                hint: 'Entrez l\'adresse complète',
                controller: addressController,
                prefixIcon: const Icon(Icons.location_on_outlined),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Dispose controllers after dialog is closed to avoid "used after disposed" error
              Future.microtask(() {
                addressController.dispose();
                labelController.dispose();
              });
            },
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              if (addressController.text.isNotEmpty) {
                // TODO: Save address
                setState(() {
                  final newAddress = AddressModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    address: addressController.text,
                    label: labelController.text.isEmpty ? null : labelController.text,
                    latitude: 0,
                    longitude: 0,
                  );
                  _user = _user.copyWith(
                    favoriteAddresses: [..._user.favoriteAddresses, newAddress],
                  );
                });
              }
              Navigator.pop(context);
              // Dispose controllers after dialog is closed to avoid "used after disposed" error
              Future.microtask(() {
                addressController.dispose();
                labelController.dispose();
              });
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Logout
            },
            child: Text(
              AppStrings.logout,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
