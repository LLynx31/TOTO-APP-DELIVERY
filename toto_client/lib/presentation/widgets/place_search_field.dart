import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Résultat de recherche d'adresse
class PlaceSearchResult {
  final String address;
  final LatLng location;
  final String? street;
  final String? locality;
  final String? country;

  PlaceSearchResult({
    required this.address,
    required this.location,
    this.street,
    this.locality,
    this.country,
  });
}

/// Champ de recherche d'adresse avec suggestions
class PlaceSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final Color iconColor;
  final String? initialValue;
  final Function(PlaceSearchResult) onPlaceSelected;
  final VoidCallback? onTapMap;

  const PlaceSearchField({
    super.key,
    required this.label,
    required this.hint,
    required this.iconColor,
    this.initialValue,
    required this.onPlaceSelected,
    this.onTapMap,
  });

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  List<PlaceSearchResult> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(PlaceSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != null &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showSuggestions = true);
  }

  void _hideOverlay() {
    _removeOverlay();
    setState(() => _showSuggestions = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.paddingMd),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.textTertiary,
              size: 32,
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (widget.onTapMap != null) ...[
              const SizedBox(height: AppSizes.spacingMd),
              TextButton.icon(
                onPressed: () {
                  _hideOverlay();
                  widget.onTapMap?.call();
                },
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Choisir sur la carte'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingSm),
      itemCount: _suggestions.length + (widget.onTapMap != null ? 1 : 0),
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: AppColors.border,
      ),
      itemBuilder: (context, index) {
        // Option "Choisir sur la carte" en dernier
        if (widget.onTapMap != null && index == _suggestions.length) {
          return ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.map,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: const Text(
              'Choisir sur la carte',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            onTap: () {
              _hideOverlay();
              widget.onTapMap?.call();
            },
          );
        }

        final suggestion = _suggestions[index];
        return ListTile(
          dense: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              color: widget.iconColor,
              size: 20,
            ),
          ),
          title: Text(
            suggestion.address,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: suggestion.locality != null
              ? Text(
                  suggestion.locality!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }

  void _selectSuggestion(PlaceSearchResult suggestion) {
    _controller.text = suggestion.address;
    _hideOverlay();
    _focusNode.unfocus();
    widget.onPlaceSelected(suggestion);
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      _overlayEntry?.markNeedsBuild();
      return;
    }

    setState(() => _isSearching = true);
    _overlayEntry?.markNeedsBuild();

    try {
      // Rechercher avec le geocoding
      final locations = await locationFromAddress(
        query,
        localeIdentifier: 'fr_FR',
      );

      if (!mounted) return;

      final suggestions = <PlaceSearchResult>[];

      for (final location in locations.take(5)) {
        try {
          // Obtenir l'adresse complète depuis les coordonnées
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final addressParts = [
              place.street,
              place.locality,
              place.subAdministrativeArea,
              place.country,
            ].where((e) => e != null && e.isNotEmpty).toList();

            suggestions.add(PlaceSearchResult(
              address: addressParts.join(', '),
              location: LatLng(location.latitude, location.longitude),
              street: place.street,
              locality: place.locality,
              country: place.country,
            ));
          }
        } catch (_) {
          // Ignorer les erreurs de reverse geocoding
        }
      }

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isSearching = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    }
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();

    if (value.isEmpty) {
      _hideOverlay();
      return;
    }

    if (!_showSuggestions) {
      _showOverlay();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.location_on,
                  color: widget.iconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingSm),
          // Champ de texte
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        _controller.clear();
                        _hideOverlay();
                        setState(() {});
                      },
                    )
                  : (widget.onTapMap != null
                      ? IconButton(
                          icon: Icon(
                            Icons.map_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: widget.onTapMap,
                          tooltip: 'Choisir sur la carte',
                        )
                      : null),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMd,
                vertical: AppSizes.paddingMd,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                borderSide: BorderSide(
                  color: widget.iconColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
