import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/models/deliverer_model.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'widgets/advanced_stats_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for edit dialog
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Mock data - À remplacer par les données réelles du backend
  final DelivererModel _deliverer = DelivererModel(
    id: 'DLV001',
    firstName: 'Jean',
    lastName: 'Kouassi',
    phone: '+225 07 12 34 56 78',
    email: 'jean.kouassi@example.com',
    isOnline: false,
    isVerified: true,
    rating: 4.8,
    totalDeliveries: 127,
    vehicle: VehicleInfo(
      type: 'Moto',
      plate: 'AB 1234 CI',
    ),
    documents: [
      DocumentInfo(
        type: 'drivingLicense',
        isVerified: true,
        uploadedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      DocumentInfo(
        type: 'idCard',
        isVerified: true,
        uploadedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      DocumentInfo(
        type: 'vehicleRegistration',
        isVerified: true,
        uploadedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ],
    createdAt: DateTime(2024, 1, 15),
  );

  // Mock advanced stats data
  final double _earningsThisMonth = 285000;
  final List<double> _earningsLast7Days = [35000, 42000, 38000, 45000, 40000, 41000, 44000];
  final double _completionRate = 96.5;
  final Duration _averageDeliveryTime = const Duration(minutes: 28);
  final Duration _totalTimeOnline = const Duration(hours: 156, minutes: 30);

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog() {
    // Initialize controllers with current values
    _firstNameController.text = _deliverer.firstName;
    _lastNameController.text = _deliverer.lastName;
    _phoneController.text = _deliverer.phone;
    _emailController.text = _deliverer.email ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le profil'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: _firstNameController,
                    label: 'Prénom',
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Prénom requis' : null,
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  CustomTextField(
                    controller: _lastNameController,
                    label: 'Nom',
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email (optionnel)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _saveProfile(context),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    // Format Côte d'Ivoire: +225 XX XX XX XX XX
    final phoneRegex = RegExp(r'^\+225\s?\d{10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Format invalide. Ex: +225 07 12 34 56 78';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Email invalide';
      }
    }
    return null;
  }

  Future<void> _saveProfile(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      // TODO: API call to save profile
      // Example:
      // final updatedDeliverer = _deliverer.copyWith(
      //   firstName: _firstNameController.text,
      //   lastName: _lastNameController.text,
      //   phone: _phoneController.text,
      //   email: _emailController.text.isEmpty ? null : _emailController.text,
      // );
      // await DelivererService.updateProfile(updatedDeliverer);

      Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement logout
              Navigator.pop(context);
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.profile,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: AppSizes.spacingXl),

            // Advanced Stats Card
            AdvancedStatsCard(
              earningsThisMonth: _earningsThisMonth,
              earningsLast7Days: _earningsLast7Days,
              completionRate: _completionRate,
              averageDeliveryTime: _averageDeliveryTime,
              totalTimeOnline: _totalTimeOnline,
            ),
            const SizedBox(height: AppSizes.spacingLg),

            // Personal Info Section
            _buildSection(
              title: 'Informations personnelles',
              children: [
                _buildInfoTile(
                  icon: Icons.person_outline,
                  label: 'Nom complet',
                  value: '${_deliverer.firstName} ${_deliverer.lastName}',
                ),
                _buildInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: _deliverer.phone,
                ),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _deliverer.email ?? 'Non renseigné',
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Vehicle Info Section
            _buildVehicleSection(),

            const SizedBox(height: AppSizes.spacingLg),

            // Documents Section
            _buildSection(
              title: 'Documents',
              children: _deliverer.documents.map((doc) {
                return _buildDocumentTile(doc);
              }).toList(),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Action Buttons
            _buildActionButton(
              icon: Icons.help_outline,
              label: 'Aide & Support',
              onTap: () {
                // TODO: Navigate to support
              },
            ),
            const SizedBox(height: AppSizes.spacingMd),
            _buildActionButton(
              icon: Icons.info_outline,
              label: 'À propos',
              onTap: () {
                // TODO: Navigate to about
              },
            ),
            const SizedBox(height: AppSizes.spacingMd),
            _buildActionButton(
              icon: Icons.logout_outlined,
              label: 'Déconnexion',
              onTap: _logout,
              isDestructive: true,
            ),

            const SizedBox(height: AppSizes.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Stack(
        children: [
          // Edit button
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: _showEditProfileDialog,
              tooltip: 'Modifier le profil',
            ),
          ),
          // Profile content
          Column(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Text(
                  '${_deliverer.firstName[0]}${_deliverer.lastName[0]}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (_deliverer.isVerified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: AppColors.textWhite,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),

          // Name
          Text(
            '${_deliverer.firstName} ${_deliverer.lastName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.spacingSm),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                icon: Icons.star,
                value: _deliverer.rating.toStringAsFixed(1),
                label: 'Note',
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
              _buildStat(
                icon: Icons.delivery_dining,
                value: '${_deliverer.totalDeliveries}',
                label: 'Livraisons',
              ),
            ],
          ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacingMd),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSection() {
    // Déterminer l'icône et la couleur selon le type de véhicule
    IconData vehicleIcon;
    Color vehicleColor;

    switch (_deliverer.vehicle.type.toLowerCase()) {
      case 'moto':
        vehicleIcon = Icons.two_wheeler;
        vehicleColor = AppColors.primary;
        break;
      case 'voiture':
        vehicleIcon = Icons.directions_car;
        vehicleColor = AppColors.info;
        break;
      case 'vélo':
        vehicleIcon = Icons.pedal_bike;
        vehicleColor = AppColors.express;
        break;
      default:
        vehicleIcon = Icons.two_wheeler;
        vehicleColor = AppColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Véhicule',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.spacingMd),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.two_wheeler_outlined,
                  label: 'Type',
                  value: _deliverer.vehicle.type,
                ),
                _buildInfoTile(
                  icon: Icons.pin_outlined,
                  label: 'Plaque',
                  value: _deliverer.vehicle.plate,
                ),
                const SizedBox(height: AppSizes.spacingMd),
                // Image du véhicule
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Icône du véhicule en grand
                      Icon(
                        vehicleIcon,
                        size: 150,
                        color: vehicleColor.withValues(alpha: 0.3),
                      ),
                      // Boîte sur le véhicule (comme dans le mockup)
                      Positioned(
                        top: 40,
                        right: 80,
                        child: Container(
                          width: 60,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2A679),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFB8956A),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildDocumentTile(DocumentInfo document) {
    IconData icon;
    String label;
    Color iconColor;

    // Use if-else instead of switch since DocumentType is not an enum
    if (document.type == 'drivingLicense') {
      icon = Icons.card_membership;
      label = 'Permis de conduire';
      iconColor = AppColors.primary;
    } else if (document.type == 'idCard') {
      icon = Icons.badge_outlined;
      label = 'Carte d\'identité';
      iconColor = AppColors.info;
    } else if (document.type == 'vehicleRegistration') {
      icon = Icons.description_outlined;
      label = 'Carte grise';
      iconColor = AppColors.express;
    } else {
      icon = Icons.description;
      label = 'Document';
      iconColor = AppColors.textSecondary;
    }

    // Format verification date
    String? verificationDate;
    if (document.uploadedAt != null) {
      verificationDate = DateFormat('dd/MM/yyyy').format(document.uploadedAt!);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSm),
      decoration: BoxDecoration(
        border: Border.all(
          color: document.isVerified
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.paddingMd),
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.paddingSm),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  document.isVerified ? Icons.verified : Icons.pending,
                  size: 14,
                  color: document.isVerified ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  document.isVerified ? 'Vérifié' : 'En attente de vérification',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: document.isVerified ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            if (verificationDate != null && document.isVerified) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vérifié le $verificationDate',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
        onTap: () {
          // TODO: View document details
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDestructive ? AppColors.error : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
