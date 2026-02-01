import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Modèle représentant un pays avec son indicatif téléphonique
class Country {
  final String name;
  final String code; // Code ISO (CI, FR, etc.)
  final String dialCode; // Indicatif (+225, +33, etc.)
  final String flag; // Emoji drapeau

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

/// Liste des pays disponibles (Afrique de l'Ouest principalement + quelques autres)
const List<Country> availableCountries = [
  Country(name: 'Burkina Faso', code: 'BF', dialCode: '+226', flag: '🇧🇫'),
  Country(name: 'Côte d\'Ivoire', code: 'CI', dialCode: '+225', flag: '🇨🇮'),
  Country(name: 'Sénégal', code: 'SN', dialCode: '+221', flag: '🇸🇳'),
  Country(name: 'Mali', code: 'ML', dialCode: '+223', flag: '🇲🇱'),
  Country(name: 'Guinée', code: 'GN', dialCode: '+224', flag: '🇬🇳'),
  Country(name: 'Bénin', code: 'BJ', dialCode: '+229', flag: '🇧🇯'),
  Country(name: 'Togo', code: 'TG', dialCode: '+228', flag: '🇹🇬'),
  Country(name: 'Niger', code: 'NE', dialCode: '+227', flag: '🇳🇪'),
  Country(name: 'Cameroun', code: 'CM', dialCode: '+237', flag: '🇨🇲'),
  Country(name: 'Gabon', code: 'GA', dialCode: '+241', flag: '🇬🇦'),
  Country(name: 'Congo', code: 'CG', dialCode: '+242', flag: '🇨🇬'),
  Country(name: 'RD Congo', code: 'CD', dialCode: '+243', flag: '🇨🇩'),
  Country(name: 'Maroc', code: 'MA', dialCode: '+212', flag: '🇲🇦'),
  Country(name: 'Algérie', code: 'DZ', dialCode: '+213', flag: '🇩🇿'),
  Country(name: 'Tunisie', code: 'TN', dialCode: '+216', flag: '🇹🇳'),
  Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  Country(name: 'Belgique', code: 'BE', dialCode: '+32', flag: '🇧🇪'),
  Country(name: 'Suisse', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
  Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
  Country(name: 'États-Unis', code: 'US', dialCode: '+1', flag: '🇺🇸'),
];

/// Widget de champ téléphone avec sélecteur de pays
class CountryPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final bool enabled;
  final Country? initialCountry;
  final void Function(Country)? onCountryChanged;

  const CountryPhoneField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.enabled = true,
    this.initialCountry,
    this.onCountryChanged,
  });

  @override
  State<CountryPhoneField> createState() => CountryPhoneFieldState();
}

class CountryPhoneFieldState extends State<CountryPhoneField> {
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    // Par défaut: Côte d'Ivoire
    _selectedCountry = widget.initialCountry ?? availableCountries.first;
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        countries: availableCountries,
        selectedCountry: _selectedCountry,
        onSelect: (country) {
          setState(() {
            _selectedCountry = country;
          });
          widget.onCountryChanged?.call(country);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Retourne le numéro complet avec l'indicatif pays
  String getFullPhoneNumber() {
    final localNumber = widget.controller.text.trim();
    if (localNumber.isEmpty) return '';

    // Supprimer le 0 initial si présent
    final cleanNumber = localNumber.startsWith('0')
        ? localNumber.substring(1)
        : localNumber;

    return '${_selectedCountry.dialCode}$cleanNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteur de pays
            GestureDetector(
              onTap: widget.enabled ? _showCountryPicker : null,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: widget.enabled ? AppColors.surface : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountry.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCountry.dialCode,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: widget.enabled ? AppColors.textSecondary : AppColors.border,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Champ de numéro
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: widget.hint ?? 'Numéro de téléphone',
                  filled: true,
                  fillColor: widget.enabled ? AppColors.surface : AppColors.surfaceVariant,
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
                validator: widget.validator,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sheet de sélection de pays
class _CountryPickerSheet extends StatefulWidget {
  final List<Country> countries;
  final Country selectedCountry;
  final void Function(Country) onSelect;

  const _CountryPickerSheet({
    required this.countries,
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late List<Country> _filteredCountries;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCountries = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = widget.countries;
      } else {
        _filteredCountries = widget.countries
            .where((c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                c.dialCode.contains(query) ||
                c.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sélectionner un pays',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          // Recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              decoration: InputDecoration(
                hintText: 'Rechercher un pays...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Liste des pays
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;

                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(country.dialCode),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => widget.onSelect(country),
                  tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
