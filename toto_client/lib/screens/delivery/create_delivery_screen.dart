import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/quota_provider.dart';
import '../../services/delivery_service.dart';

class CreateDeliveryScreen extends ConsumerStatefulWidget {
  const CreateDeliveryScreen({super.key});

  @override
  ConsumerState<CreateDeliveryScreen> createState() =>
      _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends ConsumerState<CreateDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Pickup fields
  final _pickupAddressController = TextEditingController();
  final _pickupPhoneController = TextEditingController();
  double? _pickupLatitude;
  double? _pickupLongitude;

  // Delivery fields
  final _deliveryAddressController = TextEditingController();
  final _deliveryPhoneController = TextEditingController();
  final _receiverNameController = TextEditingController();
  double? _deliveryLatitude;
  double? _deliveryLongitude;

  // Package fields
  final _packageDescriptionController = TextEditingController();
  final _packageWeightController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _pickupPhoneController.dispose();
    _deliveryAddressController.dispose();
    _deliveryPhoneController.dispose();
    _receiverNameController.dispose();
    _packageDescriptionController.dispose();
    _packageWeightController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier le quota
    final quotaState = ref.read(quotasProvider);
    if (!quotaState.hasAvailableDeliveries) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous n\'avez plus de livraisons disponibles. Veuillez acheter un forfait.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pour la démo, utiliser des coordonnées fixes
    // En production, utiliser Google Maps ou un service de géolocalisation
    _pickupLatitude = 14.6928; // Coordonnées de Dakar
    _pickupLongitude = -17.4467;
    _deliveryLatitude = 14.7167;
    _deliveryLongitude = -17.4677;

    final request = CreateDeliveryRequest(
      pickupAddress: _pickupAddressController.text.trim(),
      pickupLatitude: _pickupLatitude!,
      pickupLongitude: _pickupLongitude!,
      pickupPhone: _pickupPhoneController.text.trim().isEmpty
          ? null
          : _pickupPhoneController.text.trim(),
      deliveryAddress: _deliveryAddressController.text.trim(),
      deliveryLatitude: _deliveryLatitude!,
      deliveryLongitude: _deliveryLongitude!,
      deliveryPhone: _deliveryPhoneController.text.trim(),
      receiverName: _receiverNameController.text.trim(),
      packageDescription: _packageDescriptionController.text.trim(),
      packageWeight: _packageWeightController.text.isEmpty
          ? null
          : double.tryParse(_packageWeightController.text),
      specialInstructions: _specialInstructionsController.text.trim().isEmpty
          ? null
          : _specialInstructionsController.text.trim(),
    );

    final success = await ref
        .read(deliveryProvider(null).notifier)
        .createDelivery(request);

    if (!mounted) return;

    if (success) {
      // Rafraîchir la liste des livraisons
      ref.read(deliveryListProvider.notifier).refresh();
      // Rafraîchir le quota
      ref.read(quotasProvider.notifier).loadActiveQuota();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livraison créée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(deliveryProvider(null)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur lors de la création'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider(null));
    final quotaState = ref.watch(quotasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Livraison'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quota warning
            if (!quotaState.hasAvailableDeliveries)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Aucune livraison disponible. Veuillez acheter un forfait.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Section Ramassage
            Text(
              'Point de ramassage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pickupAddressController,
              decoration: const InputDecoration(
                labelText: 'Adresse de ramassage',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer l\'adresse de ramassage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pickupPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone (optionnel)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Section Livraison
            Text(
              'Point de livraison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(
                labelText: 'Adresse de livraison',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer l\'adresse de livraison';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _receiverNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom du destinataire',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nom du destinataire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone du destinataire',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le téléphone';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section Colis
            Text(
              'Informations du colis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _packageDescriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description du colis',
                prefixIcon: Icon(Icons.inventory_2),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez décrire le colis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _packageWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Poids (kg) - optionnel',
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialInstructionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Instructions spéciales (optionnel)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de soumission
            ElevatedButton(
              onPressed: deliveryState.isLoading || !quotaState.hasAvailableDeliveries
                  ? null
                  : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: deliveryState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer la livraison'),
            ),
          ],
        ),
      ),
    );
  }
}
