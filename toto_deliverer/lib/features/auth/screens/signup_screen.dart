import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Document files
  File? _drivingLicenseImage;
  File? _idPhotoImage;
  File? _vehiclePhotoImage;

  bool _isLoading = false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleSignup() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_drivingLicenseImage == null || _idPhotoImage == null || _vehiclePhotoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez télécharger tous les documents requis'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement signup logic with KYC document upload
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! Votre compte est en cours de vérification.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        // Navigate back to login
        Navigator.pop(context);
      }
    });
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
                    isLoading: _isLoading,
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
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
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
