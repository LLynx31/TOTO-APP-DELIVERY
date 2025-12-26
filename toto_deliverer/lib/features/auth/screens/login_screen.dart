import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../../home/main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hideError = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Réinitialiser le flag pour montrer l'erreur
    setState(() {
      _hideError = false;
    });

    print('🔐 Tentative de connexion...');

    try {
      await ref.read(authProvider.notifier).login(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      print('✅ Connexion réussie');

      if (!mounted) return;

      // Succès - navigation vers le dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      print('📝 L\'erreur sera affichée via le provider state');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.error;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSizes.spacingXxl),

                    // Logo - Icône de moto/livraison avec vert
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        size: 56,
                        color: AppColors.textWhite,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Title
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSizes.spacingSm),

                    Text(
                      AppStrings.login,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Message d'erreur visible
                    if (errorMessage != null && !_hideError)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                        padding: const EdgeInsets.all(AppSizes.paddingMd),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connexion échouée',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ErrorMessages.loginError(errorMessage),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.error,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: AppColors.error,
                              onPressed: () {
                                setState(() {
                                  _hideError = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    // Phone Field
                    CustomTextField(
                      label: AppStrings.phone,
                      hint: '+225 07 00 00 00 00',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.requiredField;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Password Field
                    CustomTextField(
                      label: AppStrings.password,
                      hint: 'Entrez votre mot de passe',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      enabled: !isLoading,
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

                    const SizedBox(height: AppSizes.spacingXl),

                    // Login Button
                    CustomButton(
                      text: AppStrings.login,
                      onPressed: isLoading ? null : _handleLogin,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: AppSizes.spacingLg),

                    // Forgot Password
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: Navigate to forgot password
                            },
                      child: Text(
                        AppStrings.forgotPassword,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isLoading
                                  ? AppColors.textSecondary
                                  : AppColors.secondary,
                            ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingXxl),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${AppStrings.noAccount} ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignupScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            AppStrings.signup,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        ),
      ),
    );
  }
}
