import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/di/injection.dart' as di;
import '../../../data/repositories/auth_repository_impl.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phoneNumber;
      _emailController.text = user.email ?? '';
      _photoUrl = user.photoUrl;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier le profil'),
        ),
        body: const Center(
          child: Text('Vous devez être connecté'),
        ),
      );
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo de profil
              _buildProfilePhoto(user),

              const SizedBox(height: AppSizes.spacingXl),

              // Formulaire
              _buildFormFields(user),

              const SizedBox(height: AppSizes.spacingXl),

              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(dynamic user) {
    return Center(
      child: Stack(
        children: [
          // Photo actuelle
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: _photoUrl == null
                ? Text(
                    user.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),

          // Bouton de modification
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: _handlePhotoChange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(dynamic user) {
    return Column(
      children: [
        // Nom complet
        CustomTextField(
          controller: _fullNameController,
          label: 'Nom complet',
          hint: 'Entrez votre nom complet',
          prefixIcon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le nom est requis';
            }
            if (value.length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),

        const SizedBox(height: AppSizes.spacingMd),

        // Numéro de téléphone (non modifiable)
        CustomTextField(
          controller: _phoneController,
          label: 'Numéro de téléphone',
          prefixIcon: Icons.phone,
          enabled: false,
        ),

        const SizedBox(height: AppSizes.spacingMd),

        // Email
        CustomTextField(
          controller: _emailController,
          label: 'Email (optionnel)',
          hint: 'exemple@email.com',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(value)) {
                return 'Email invalide';
              }
            }
            return null;
          },
        ),

        const SizedBox(height: AppSizes.spacingMd),

        // Information sur le numéro
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(color: AppColors.info),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Expanded(
                child: Text(
                  'Votre numéro de téléphone ne peut pas être modifié car il est utilisé pour vous identifier',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Enregistrer les modifications',
          onPressed: _isLoading ? null : _handleSave,
          isLoading: _isLoading,
        ),
        const SizedBox(height: AppSizes.spacingMd),
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.paddingMd,
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Future<void> _handlePhotoChange() async {
    // TODO: Implémenter la sélection et l'upload de photo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer la photo'),
        content: const Text(
          'La fonctionnalité de changement de photo sera disponible prochainement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Appeler l'API pour mettre à jour le profil
      final updateProfileUsecase = ref.read(di.updateProfileUsecaseProvider);
      final result = await updateProfileUsecase(
        fullName: _fullNameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );

      if (!mounted) return;

      switch (result) {
        case Success(:final data):
          // Mettre à jour l'état d'authentification avec le nouvel utilisateur
          ref.read(authProvider.notifier).updateUser(data);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: AppColors.success,
            ),
          );

          // Retourner à l'écran précédent
          Navigator.pop(context);

        case Failure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
