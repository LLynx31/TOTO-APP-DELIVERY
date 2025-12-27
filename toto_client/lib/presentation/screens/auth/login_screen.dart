import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/country_phone_field.dart';

/// Écran de connexion
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFieldKey = GlobalKey<CountryPhoneFieldState>();
  bool _obscurePassword = true;
  Country _selectedCountry = availableCountries.first; // Côte d'Ivoire par défaut

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Utiliser le numéro complet avec indicatif pays
    final phoneNumber = _getFullPhoneNumber();
    final password = _passwordController.text;

    await ref.read(authProvider.notifier).login(
          phoneNumber: phoneNumber,
          password: password,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.spacingXl * 2),

                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingLg),
                      Text(
                        AppStrings.appName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: AppSizes.spacingSm),
                      Text(
                        AppStrings.loginSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.spacingXl * 2),

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

                // Champ mot de passe
                _buildPasswordField(isLoading),

                const SizedBox(height: AppSizes.spacingLg),

                // Bouton de connexion
                CustomButton(
                  text: AppStrings.login,
                  onPressed: isLoading ? null : _handleLogin,
                  isLoading: isLoading,
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Lien vers l'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.noAccount,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.push('/register'),
                      child: Text(
                        AppStrings.register,
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

  Widget _buildPasswordField(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            AppStrings.password,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        TextFormField(
          controller: _passwordController,
          enabled: !isLoading,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: AppStrings.enterPassword,
            filled: true,
            fillColor: !isLoading ? AppColors.surface : AppColors.surfaceVariant,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: Validators.validatePassword,
        ),
      ],
    );
  }
}
