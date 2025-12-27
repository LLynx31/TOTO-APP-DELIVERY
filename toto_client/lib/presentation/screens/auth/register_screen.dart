import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/country_phone_field.dart';

/// Écran d'inscription
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneFieldKey = GlobalKey<CountryPhoneFieldState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Country _selectedCountry = availableCountries.first; // Côte d'Ivoire par défaut

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Récupère le numéro complet avec indicatif pays
  String _getFullPhoneNumber() {
    final localNumber = _phoneController.text.trim();
    if (localNumber.isEmpty) return '';

    // Supprimer le 0 initial si présent
    final cleanNumber = localNumber.startsWith('0')
        ? localNumber.substring(1)
        : localNumber;

    return '${_selectedCountry.dialCode}$cleanNumber';
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    // Utiliser le numéro complet avec indicatif pays
    final phoneNumber = _getFullPhoneNumber();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref.read(authProvider.notifier).register(
          phoneNumber: phoneNumber,
          fullName: fullName,
          password: password,
          email: email.isEmpty ? null : email,
        );

    // Check for errors
    final state = ref.read(authProvider);
    if (state is AuthError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else if (state is AuthAuthenticated) {
      // Navigation handled by router
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titre
                Text(
                  AppStrings.createAccount,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSizes.spacingSm),
                Text(
                  'Créez votre compte pour commencer',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: AppSizes.spacingXl),

                // Champ nom complet
                CustomTextField(
                  controller: _fullNameController,
                  label: AppStrings.fullName,
                  hint: AppStrings.fullNameHint,
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.fullName,
                  enabled: !isLoading,
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Champ numéro de téléphone avec sélecteur de pays
                CountryPhoneField(
                  key: _phoneFieldKey,
                  controller: _phoneController,
                  label: AppStrings.phoneNumber,
                  hint: '07 00 00 00 00',
                  enabled: !isLoading,
                  initialCountry: _selectedCountry,
                  onCountryChanged: (country) {
                    setState(() {
                      _selectedCountry = country;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    // Validation basique: au moins 8 chiffres
                    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                    if (digitsOnly.length < 8) {
                      return 'Numéro de téléphone invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Champ email (optionnel)
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  hint: AppStrings.emailHint,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                  enabled: !isLoading,
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Champ mot de passe
                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: AppStrings.enterPassword,
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: Validators.validatePassword,
                  enabled: !isLoading,
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Champ confirmation mot de passe
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: AppStrings.confirmPassword,
                  hint: AppStrings.enterPassword,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) =>
                      Validators.confirmPassword(value, _passwordController.text),
                  enabled: !isLoading,
                ),

                const SizedBox(height: AppSizes.spacingLg),

                // Bouton d'inscription
                CustomButton(
                  text: AppStrings.register,
                  onPressed: isLoading ? null : _handleRegister,
                  isLoading: isLoading,
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Lien vers la connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.hasAccount,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      child: Text(
                        AppStrings.login,
                        style: TextStyle(
                          color: isLoading
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
