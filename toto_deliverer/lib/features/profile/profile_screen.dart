import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/loading_overlay.dart';
import '../../shared/models/deliverer_model.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/screens/login_screen.dart';
import 'providers/deliverer_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Numéro WhatsApp pour le support
  static const String _whatsappNumber = '+2250700000000'; // À remplacer par le vrai numéro

  @override
  void initState() {
    super.initState();
    Future(_loadProfile);
  }

  Future<void> _loadProfile() async {
    try {
      await ref.read(delivererProvider.notifier).loadProfile();
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(
        context,
        ErrorMessages.fromException(e),
        title: 'Erreur de chargement',
      );
    }
  }

  String _getInitials(DelivererModel deliverer) {
    final firstInitial = deliverer.firstName.isNotEmpty ? deliverer.firstName[0] : '';
    final lastInitial = deliverer.lastName.isNotEmpty ? deliverer.lastName[0] : '';
    final initials = '$firstInitial$lastInitial'.toUpperCase();
    return initials.isNotEmpty ? initials : 'L';
  }

  void _showEditProfileDialog() {
    final deliverer = ref.read(delivererProvider).deliverer;
    if (deliverer == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(
        deliverer: deliverer,
        onSave: _saveProfile,
      ),
    );
  }

  Future<void> _saveProfile({
    required String firstName,
    required String lastName,
    required String vehicleType,
    required String licensePlate,
  }) async {
    LoadingOverlay.show(context, message: 'Mise à jour du profil...');

    try {
      final fullName = '$firstName $lastName';

      await ref.read(delivererProvider.notifier).updateProfile(
        fullName: fullName,
        vehicleType: vehicleType,
        licensePlate: licensePlate,
      );

      LoadingOverlay.forceHide();

      if (!mounted) return;

      ToastUtils.showSuccess(
        context,
        'Vos informations ont été mises à jour',
        title: 'Profil mis à jour',
      );
    } catch (e) {
      LoadingOverlay.forceHide();

      if (!mounted) return;

      ToastUtils.showError(
        context,
        ErrorMessages.fromException(e),
        title: 'Erreur de mise à jour',
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/$_whatsappNumber?text=Bonjour, j\'ai besoin d\'aide avec l\'application TOTO Livreur.');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ToastUtils.showError(
          context,
          'Impossible d\'ouvrir WhatsApp',
          title: 'Erreur',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(
        context,
        'Erreur lors de l\'ouverture de WhatsApp',
        title: 'Erreur',
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delivery_dining, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('TOTO Livreur'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'TOTO est une application de livraison qui met en relation des livreurs indépendants avec des clients.',
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 TOTO. Tous droits réservés.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref.read(authProvider.notifier).logout();

                if (!mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ToastUtils.showError(
                  context,
                  ErrorMessages.fromException(e),
                  title: 'Erreur de déconnexion',
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delivererState = ref.watch(delivererProvider);
    final deliverer = delivererState.deliverer;

    if (delivererState.isLoading || deliverer == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mon Profil'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              if (delivererState.error != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Erreur: ${delivererState.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Réessayer'),
                ),
              ],
            ],
          ),
        ),
      );
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfileDialog,
            tooltip: 'Modifier le profil',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(deliverer),
              const SizedBox(height: AppSizes.spacingMd),

              // Statut de validation
              _buildValidationStatusBanner(deliverer),
              const SizedBox(height: AppSizes.spacingLg),

              // Informations personnelles
              _buildInfoSection(
                title: 'Informations personnelles',
                icon: Icons.person_outline,
                children: [
                  _buildInfoRow('Prénom', deliverer.firstName),
                  _buildInfoRow('Nom', deliverer.lastName),
                  _buildInfoRow('Téléphone', deliverer.phone, isLocked: true),
                ],
              ),
              const SizedBox(height: AppSizes.spacingMd),

              // Informations véhicule
              _buildInfoSection(
                title: 'Véhicule',
                icon: Icons.two_wheeler_outlined,
                children: [
                  _buildInfoRow('Type', deliverer.vehicle.type),
                  _buildInfoRow('Plaque', deliverer.vehicle.plate),
                ],
              ),
              const SizedBox(height: AppSizes.spacingMd),

              // Documents
              _buildDocumentsSection(deliverer),
              const SizedBox(height: AppSizes.spacingLg),

              // Aide & Support
              _buildActionButton(
                icon: Icons.support_agent,
                label: 'Aide & Support',
                subtitle: 'Contactez-nous sur WhatsApp',
                onTap: _openWhatsApp,
              ),
              const SizedBox(height: AppSizes.spacingSm),

              // À propos
              _buildActionButton(
                icon: Icons.info_outline,
                label: 'À propos',
                subtitle: 'Version 1.0.0',
                onTap: _showAboutDialog,
              ),
              const SizedBox(height: AppSizes.spacingLg),

              // Bouton déconnexion
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_outlined, color: Colors.white),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(DelivererModel deliverer) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Text(
                  _getInitials(deliverer),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (deliverer.kycStatus == KycStatus.approved)
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
          Text(
            deliverer.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            deliverer.phone,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.star,
                value: deliverer.rating.toStringAsFixed(1),
                label: 'Note',
                color: AppColors.warning,
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              _buildStatItem(
                icon: Icons.delivery_dining,
                value: '${deliverer.totalDeliveries}',
                label: 'Livraisons',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
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

  Widget _buildValidationStatusBanner(DelivererModel deliverer) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    switch (deliverer.kycStatus) {
      case KycStatus.pending:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        borderColor = AppColors.warning.withValues(alpha: 0.3);
        textColor = AppColors.warning;
        icon = Icons.hourglass_empty;
        break;
      case KycStatus.approved:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        borderColor = AppColors.success.withValues(alpha: 0.3);
        textColor = AppColors.success;
        icon = Icons.verified;
        break;
      case KycStatus.rejected:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        borderColor = AppColors.error.withValues(alpha: 0.3);
        textColor = AppColors.error;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 24),
          ),
          const SizedBox(width: AppSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deliverer.kycStatus.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  deliverer.kycStatus.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(DelivererModel deliverer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildDocumentRow(
            icon: Icons.badge_outlined,
            label: 'Carte d\'identité',
            isUploaded: deliverer.documents.any((d) => d.type == 'idCard'),
          ),
          _buildDocumentRow(
            icon: Icons.card_membership,
            label: 'Permis de conduire',
            isUploaded: deliverer.documents.any((d) => d.type == 'drivingLicense'),
          ),
          _buildDocumentRow(
            icon: Icons.directions_bike,
            label: 'Photo du véhicule',
            isUploaded: deliverer.documents.any((d) => d.type == 'vehiclePhoto'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow({
    required IconData icon,
    required String label,
    required bool isUploaded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUploaded
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUploaded ? Icons.check_circle : Icons.pending,
                  size: 14,
                  color: isUploaded ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  isUploaded ? 'Uploadé' : 'En attente',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUploaded ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSecondary = false, bool isLocked = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ],
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSecondary ? AppColors.textTertiary : AppColors.textPrimary,
                    fontStyle: isSecondary ? FontStyle.italic : FontStyle.normal,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog pour modifier le profil - widget séparé pour gérer correctement les controllers
class _EditProfileDialog extends StatefulWidget {
  final DelivererModel deliverer;
  final Future<void> Function({
    required String firstName,
    required String lastName,
    required String vehicleType,
    required String licensePlate,
  }) onSave;

  const _EditProfileDialog({
    required this.deliverer,
    required this.onSave,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _vehicleTypeController;
  late final TextEditingController _licensePlateController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.deliverer.firstName);
    _lastNameController = TextEditingController(text: widget.deliverer.lastName);
    _vehicleTypeController = TextEditingController(text: widget.deliverer.vehicle.type);
    _licensePlateController = TextEditingController(text: widget.deliverer.vehicle.plate);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _vehicleTypeController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Modifier le profil'),
        ],
      ),
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
                controller: _vehicleTypeController,
                label: 'Type de véhicule',
                prefixIcon: const Icon(Icons.two_wheeler_outlined),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Type de véhicule requis' : null,
              ),
              const SizedBox(height: AppSizes.spacingMd),
              CustomTextField(
                controller: _licensePlateController,
                label: 'Plaque d\'immatriculation',
                prefixIcon: const Icon(Icons.pin_outlined),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Plaque requise' : null,
              ),
              const SizedBox(height: AppSizes.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le numéro de téléphone ne peut pas être modifié',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              await widget.onSave(
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                vehicleType: _vehicleTypeController.text.trim(),
                licensePlate: _licensePlateController.text.trim(),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
