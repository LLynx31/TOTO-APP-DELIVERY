import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  final String deliveryId;

  const TrackingScreen({super.key, required this.deliveryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi')),
      body: Center(child: Text('TrackingScreen - ID: $deliveryId')),
    );
  }
}
