import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/widgets.dart';

class EnhancedProblemReporter extends StatefulWidget {
  final String deliveryId;

  const EnhancedProblemReporter({
    super.key,
    required this.deliveryId,
  });

  @override
  State<EnhancedProblemReporter> createState() =>
      _EnhancedProblemReporterState();
}

class _EnhancedProblemReporterState extends State<EnhancedProblemReporter> {
  String? _selectedProblem;
  final _descriptionController = TextEditingController();
  File? _problemPhoto;
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  // Problem categories
  final List<Map<String, dynamic>> _problems = [
    {
      'id': 'absent',
      'label': AppStrings.customerAbsent,
      'icon': Icons.cancel,
      'color': AppColors.error
    },
    {
      'id': 'address',
      'label': AppStrings.addressNotFound,
      'icon': Icons.location_off,
      'color': AppColors.error
    },
    {
      'id': 'package',
      'label': AppStrings.packageIssue,
      'icon': Icons.warning,
      'color': AppColors.warning
    },
    {
      'id': 'other',
      'label': AppStrings.otherProblem,
      'icon': Icons.more_horiz,
      'color': AppColors.info
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _problemPhoto = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la capture de photo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de problème'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // TODO: Replace with actual API call
    // final formData = FormData.fromMap({
    //   'deliveryId': widget.deliveryId,
    //   'problemType': _selectedProblem,
    //   'description': _descriptionController.text,
    //   if (_problemPhoto != null)
    //     'photo': await MultipartFile.fromFile(_problemPhoto!.path),
    // });
    //
    // final response = await dio.post(
    //   '/deliveries/${widget.deliveryId}/report-problem',
    //   data: formData,
    // );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.problemReported),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reportProblem),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Problem type selection
            Text(
              'Type de problème *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingMd),

            // Problem categories
            ..._problems.map((problem) {
              final isSelected = _selectedProblem == problem['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedProblem = problem['id'] as String;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          problem['icon'] as IconData,
                          color: isSelected
                              ? AppColors.primary
                              : problem['color'] as Color,
                        ),
                        const SizedBox(width: AppSizes.spacingMd),
                        Expanded(
                          child: Text(
                            problem['label'] as String,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSizes.spacingLg),

            // Description field
            Text(
              AppStrings.describeProb,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Décrivez le problème en détail (optionnel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                filled: true,
                fillColor: AppColors.surfaceGrey,
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Photo upload
            Text(
              'Photo (optionnel)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.spacingSm),

            if (_problemPhoto == null)
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(AppStrings.addPhoto),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 56),
                ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: Image.file(
                      _problemPhoto!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingSm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: const Text('Changer la photo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _problemPhoto = null;
                            });
                          },
                          icon: const Icon(Icons.delete, size: 20),
                          label: const Text('Supprimer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: AppSizes.spacingXl),

            // Submit button
            CustomButton(
              text: AppStrings.submitReport,
              onPressed: _submitReport,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
