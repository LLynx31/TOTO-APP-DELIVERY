import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

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

  Future<void> _changeProfilePhoto() async {
    // Show bottom sheet to choose between camera and gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Changer la photo de profil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.spacingLg),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                  title: const Text('Prendre une photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.secondary),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: AppSizes.spacingSm),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 90,
        );

        if (image != null) {
          setState(() {
            _user = _user.copyWith(photoUrl: image.path);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo de profil mise à jour avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la sélection de l\'image: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          NotificationBell(
            unreadCount: 3, // TODO: Get from provider
          ),
        ],
      ),
      backgroundColor: AppColors.background,
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
                                child: _user.photoUrl!.startsWith('http')
                                    ? Image.network(
                                        _user.photoUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_user.photoUrl!),
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
                          onTap: _changeProfilePhoto,
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

            // Activity Summary (NEW)
            _buildActivitySummary(),

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
                    onTap: () => _copyToClipboard(_user.phone, 'Numéro copié'),
                  ),

                  if (_user.email != null) ...[
                    const Divider(),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: AppStrings.email,
                      value: _user.email!,
                      onTap: () => _copyToClipboard(_user.email!, 'Email copié'),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Favorite Addresses (ENHANCED)
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

            const SizedBox(height: AppSizes.spacingMd),

            // Legal & Support Section (NEW)
            _buildLegalSection(),

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

  // NEW: Activity Summary Widget
  Widget _buildActivitySummary() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Livraisons',
                  value: '$_totalDeliveries',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending_actions,
                  label: 'En cours',
                  value: '$_activeDeliveries',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_outline,
                  label: 'Note moyenne',
                  value: _averageRating.toStringAsFixed(1),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Membre depuis',
                  value: '$_memberSinceDays j',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // NEW: Legal & Support Section
  Widget _buildLegalSection() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aide & Légal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.spacingMd),

          // WhatsApp Support Button (prominent)
          CustomButton(
            text: 'Contacter le support',
            onPressed: () => _launchWhatsApp(),
            icon: const Icon(Icons.chat, color: AppColors.textWhite),
            variant: ButtonVariant.primary,
          ),

          const SizedBox(height: AppSizes.spacingLg),

          _buildLegalTile(
            icon: Icons.help_outline,
            title: 'Centre d\'aide',
            onTap: () => _launchURL('https://toto-delivery.app/help'),
          ),
          const Divider(),
          _buildLegalTile(
            icon: Icons.article_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () => _launchURL('https://toto-delivery.app/terms'),
          ),
          const Divider(),
          _buildLegalTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            onTap: () => _launchURL('https://toto-delivery.app/privacy'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSizes.spacingMd),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
            if (onTap != null)
              const Icon(
                Icons.content_copy,
                size: 16,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }

  // ENHANCED: Address Tile with edit, delete, and default badge
  Widget _buildAddressTile(AddressModel address) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: address.isDefault
            ? Border.all(color: AppColors.primary, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
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
                    Row(
                      children: [
                        if (address.label != null)
                          Text(
                            address.label!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        if (address.isDefault) ...[
                          const SizedBox(width: AppSizes.spacingSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              'Par défaut',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textWhite,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingXs),
                    Text(
                      address.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditAddressDialog(address),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Modifier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteAddress(address),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (!address.isDefault) ...[
                const SizedBox(width: AppSizes.spacingSm),
                IconButton(
                  onPressed: () => _setDefaultAddress(address),
                  icon: const Icon(Icons.star_outline, size: 20),
                  tooltip: 'Définir par défaut',
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le lien'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    // Numéro WhatsApp du support TOTO (format international sans +)
    const phoneNumber = '22507123456789'; // Remplacer par le vrai numéro
    const message = 'Bonjour, j\'ai besoin d\'aide avec l\'application TOTO';

    // URL WhatsApp avec message pré-rempli
    final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir WhatsApp. Assurez-vous qu\'il est installé.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _setDefaultAddress(AddressModel address) {
    setState(() {
      // Remove default from all addresses
      final updatedAddresses = _user.favoriteAddresses
          .map((addr) => addr.copyWith(isDefault: false))
          .toList();

      // Set new default
      final index = updatedAddresses.indexWhere((a) => a.id == address.id);
      if (index != -1) {
        updatedAddresses[index] = updatedAddresses[index].copyWith(isDefault: true);
      }

      _user = _user.copyWith(favoriteAddresses: updatedAddresses);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adresse par défaut modifiée'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // ENHANCED: Confirm before deleting address
  void _confirmDeleteAddress(AddressModel address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'adresse'),
        content: Text(
          'Voulez-vous vraiment supprimer "${address.label ?? address.address}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAddress(address);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deleteAddress(AddressModel address) {
    setState(() {
      _user = _user.copyWith(
        favoriteAddresses: _user.favoriteAddresses
            .where((a) => a.id != address.id)
            .toList(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adresse supprimée'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // ENHANCED: Edit Profile Dialog with validation
  void _showEditProfileDialog() {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: _user.firstName);
    final lastNameController = TextEditingController(text: _user.lastName);
    final phoneController = TextEditingController(text: _user.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: AppStrings.firstName,
                  controller: firstNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prénom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.spacingMd),
                CustomTextField(
                  label: AppStrings.lastName,
                  controller: lastNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.spacingMd),
                CustomTextField(
                  label: AppStrings.phone,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le numéro de téléphone est requis';
                    }
                    // Simple validation for Côte d'Ivoire phone numbers
                    if (!RegExp(r'^\+225\s?\d{10}$').hasMatch(value.trim())) {
                      return 'Format invalide (+225 XXXXXXXXXX)';
                    }
                    return null;
                  },
                ),
              ],
            ),
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
              if (formKey.currentState!.validate()) {
                setState(() {
                  _user = _user.copyWith(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                });
                firstNameController.dispose();
                lastNameController.dispose();
                phoneController.dispose();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil modifié avec succès'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // ENHANCED: Edit Address Dialog with validation
  void _showEditAddressDialog(AddressModel address) {
    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController(text: address.address);
    final labelController = TextEditingController(text: address.label);
    bool isDefault = address.isDefault;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier l\'adresse'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'adresse est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  CheckboxListTile(
                    title: const Text('Adresse par défaut'),
                    value: isDefault,
                    onChanged: (value) {
                      setState(() {
                        isDefault = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                addressController.dispose();
                labelController.dispose();
              },
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final updatedAddresses = _user.favoriteAddresses.map((addr) {
                    if (addr.id == address.id) {
                      return addr.copyWith(
                        address: addressController.text.trim(),
                        label: labelController.text.trim().isEmpty
                            ? null
                            : labelController.text.trim(),
                        isDefault: isDefault,
                      );
                    } else if (isDefault) {
                      // Remove default from other addresses
                      return addr.copyWith(isDefault: false);
                    }
                    return addr;
                  }).toList();

                  this.setState(() {
                    _user = _user.copyWith(favoriteAddresses: updatedAddresses);
                  });

                  Navigator.pop(context);
                  addressController.dispose();
                  labelController.dispose();

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Adresse modifiée avec succès'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // ENHANCED: Add Address Dialog with validation
  void _showAddAddressDialog() {
    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController();
    final labelController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter une adresse'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'adresse est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  CheckboxListTile(
                    title: const Text('Adresse par défaut'),
                    value: isDefault,
                    onChanged: (value) {
                      setState(() {
                        isDefault = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Future.microtask(() {
                  addressController.dispose();
                  labelController.dispose();
                });
              },
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newAddress = AddressModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    address: addressController.text.trim(),
                    label: labelController.text.trim().isEmpty
                        ? null
                        : labelController.text.trim(),
                    latitude: 0,
                    longitude: 0,
                    isDefault: isDefault,
                  );

                  var updatedAddresses = [..._user.favoriteAddresses, newAddress];

                  // If this is set as default, remove default from others
                  if (isDefault) {
                    updatedAddresses = updatedAddresses.map((addr) {
                      if (addr.id != newAddress.id) {
                        return addr.copyWith(isDefault: false);
                      }
                      return addr;
                    }).toList();
                  }

                  this.setState(() {
                    _user = _user.copyWith(favoriteAddresses: updatedAddresses);
                  });

                  Navigator.pop(context);
                  Future.microtask(() {
                    addressController.dispose();
                    labelController.dispose();
                  });

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Adresse ajoutée avec succès'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
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
