import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/loading_overlay.dart';
import '../../../core/utils/error_messages.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleRegistrationController = TextEditingController();

  // Document files
  File? _drivingLicenseImage;
  File? _idPhotoImage;
  File? _vehiclePhotoImage;

  bool _acceptedTerms = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleTypeController.dispose();
    _vehicleRegistrationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (documentType) {
            case 'drivingLicense':
              _drivingLicenseImage = File(image.path);
              break;
            case 'idPhoto':
              _idPhotoImage = File(image.path);
              break;
            case 'vehiclePhoto':
              _vehiclePhotoImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(
          context,
          'Erreur lors de la prise de photo: $e',
          title: 'Erreur photo',
        );
      }
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ToastUtils.showWarning(
        context,
        'Veuillez accepter les conditions d\'utilisation',
        title: 'Conditions requises',
      );
      return;
    }

    // Note: Les documents sont optionnels pour l'instant
    // L'admin validera le compte après vérification manuelle des documents
    // Les documents seront uploadés via un endpoint séparé (à implémenter)

    LoadingOverlay.show(context, message: 'Inscription en cours...');

    try {
      print('📝 SignupScreen: Tentative d\'inscription...');
      print('📞 Phone: ${_phoneController.text}');

      // Combiner firstName et lastName en fullName
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      // Appeler l'API via AuthProvider
      await ref.read(authProvider.notifier).register(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        fullName: fullName,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        vehicleRegistration: _vehicleRegistrationController.text.trim(),
      );

      if (!mounted) return;

      print('✅ SignupScreen: Inscription réussie!');
      await LoadingOverlay.hide();

      if (!mounted) return;

      // TODO: Upload KYC documents (driving license, ID, vehicle photos) via separate API endpoint
      // For now, documents are captured but will be uploaded in a future implementation

      // Show success dialog with validation info
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 32),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Inscription réussie!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre compte a été créé avec succès.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.hourglass_empty, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Votre compte est en attente de validation par un administrateur. '
                        'Vous recevrez une notification dès que votre compte sera activé.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vous pouvez vous connecter, mais vous ne pourrez pas accepter de courses '
                'avant la validation de votre compte.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Compris'),
            ),
          ],
        ),
      );

    } catch (e) {
      print('❌ SignupScreen: Erreur d\'inscription: $e');

      // Always hide loading overlay first
      await LoadingOverlay.hide();

      if (!mounted) return;

      // Afficher l'erreur avec message user-friendly
      ToastUtils.showError(
        context,
        ErrorMessages.signupError(e),
        title: 'Échec d\'inscription',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.signup),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.spacingMd),

                  // Title
                  Text(
                    AppStrings.createAccount,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  // Personal Info Section
                  Text(
                    AppStrings.personalInfo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // First Name
                  CustomTextField(
                    label: AppStrings.firstName,
                    hint: 'Jean',
                    controller: _firstNameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Last Name
                  CustomTextField(
                    label: AppStrings.lastName,
                    hint: 'Kouassi',
                    controller: _lastNameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Phone
                  CustomTextField(
                    label: AppStrings.phone,
                    hint: '+225 07 00 00 00 00',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      if (!value.contains(RegExp(r'^\+?[0-9]{10,}'))) {
                        return AppStrings.invalidPhone;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Email (optional)
                  CustomTextField(
                    label: AppStrings.email,
                    hint: 'jean.kouassi@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!value.contains('@')) {
                          return AppStrings.invalidEmail;
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Vehicle Type
                  CustomTextField(
                    label: 'Type de véhicule',
                    hint: 'Moto, Voiture, Vélo...',
                    controller: _vehicleTypeController,
                    prefixIcon: const Icon(Icons.two_wheeler_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Vehicle Registration
                  CustomTextField(
                    label: 'Plaque d\'immatriculation',
                    hint: 'AB 1234 CI',
                    controller: _vehicleRegistrationController,
                    prefixIcon: const Icon(Icons.pin_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Password
                  CustomTextField(
                    label: AppStrings.password,
                    hint: 'Min. 6 caractères',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      if (value.length < 6) {
                        return AppStrings.passwordTooShort;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Confirm Password
                  CustomTextField(
                    label: AppStrings.confirmPassword,
                    hint: 'Confirmez votre mot de passe',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      if (value != _passwordController.text) {
                        return AppStrings.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  // KYC Documents Section
                  Text(
                    AppStrings.documents,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Driving License
                  _buildDocumentUpload(
                    title: AppStrings.drivingLicense,
                    file: _drivingLicenseImage,
                    onTap: () => _pickImage('drivingLicense'),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // ID Photo
                  _buildDocumentUpload(
                    title: AppStrings.identityPhoto,
                    file: _idPhotoImage,
                    onTap: () => _pickImage('idPhoto'),
                  ),

                  const SizedBox(height: AppSizes.spacingMd),

                  // Vehicle Photo
                  _buildDocumentUpload(
                    title: AppStrings.vehiclePhoto,
                    file: _vehiclePhotoImage,
                    onTap: () => _pickImage('vehiclePhoto'),
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  // Terms and Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                        },
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.termsAndConditions,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  // Signup Button
                  CustomButton(
                    text: AppStrings.signup,
                    onPressed: _handleSignup,
                  ),

                  const SizedBox(height: AppSizes.spacingLg),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppStrings.alreadyHaveAccount} ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          AppStrings.login,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.spacingXl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: file != null ? AppColors.success.withValues(alpha: 0.1) : AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: file != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        child: kIsWeb
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 32,
                              )
                            : Image.file(
                                file,
                                fit: BoxFit.cover,
                              ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file != null ? AppStrings.verified : AppStrings.uploadDocument,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: file != null ? AppColors.success : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                file != null ? Icons.check_circle : Icons.upload_outlined,
                color: file != null ? AppColors.success : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
