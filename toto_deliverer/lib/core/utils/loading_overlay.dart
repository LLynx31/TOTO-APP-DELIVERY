import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class LoadingOverlay {
  static OverlayEntry? _currentOverlay;
  static DateTime? _showTime;
  static bool _isHiding = false;
  static const Duration _minimumDisplayTime = Duration(milliseconds: 500);
  static const Duration _fadeInDuration = Duration(milliseconds: 200);

  static void show(
    BuildContext context, {
    String? message,
  }) {
    // Remove existing overlay if any
    forceHide();

    _showTime = DateTime.now();
    _isHiding = false;

    try {
      final overlay = Overlay.of(context);

      final overlayEntry = OverlayEntry(
        builder: (context) => _LoadingWidget(
          message: message,
          fadeInDuration: _fadeInDuration,
        ),
      );

      _currentOverlay = overlayEntry;
      overlay.insert(overlayEntry);
    } catch (e) {
      print('⚠️ LoadingOverlay.show error: $e');
      _currentOverlay = null;
    }
  }

  static Future<void> hide() async {
    if (_currentOverlay == null || _isHiding) return;

    _isHiding = true;

    try {
      // Calculate how long to wait before hiding
      if (_showTime != null) {
        final elapsed = DateTime.now().difference(_showTime!);
        final remaining = _minimumDisplayTime - elapsed;

        if (remaining > Duration.zero) {
          // Wait for minimum display time before hiding
          await Future.delayed(remaining);
        }
      }

      _removeOverlay();
    } catch (e) {
      print('⚠️ LoadingOverlay.hide error: $e');
      _removeOverlay();
    } finally {
      _isHiding = false;
    }
  }

  static void _removeOverlay() {
    try {
      if (_currentOverlay != null) {
        _currentOverlay!.remove();
      }
    } catch (e) {
      print('⚠️ LoadingOverlay._removeOverlay error: $e');
    } finally {
      _currentOverlay = null;
      _showTime = null;
    }
  }

  /// Force hide without waiting for minimum display time
  static void forceHide() {
    _isHiding = false;
    _removeOverlay();
  }
}

class _LoadingWidget extends StatefulWidget {
  final String? message;
  final Duration fadeInDuration;

  const _LoadingWidget({
    this.message,
    required this.fadeInDuration,
  });

  @override
  State<_LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<_LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeInDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Pulse animation for the spinner container
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: AppSizes.spacingMd),
                    Text(
                      widget.message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
