import 'package:flutter/material.dart';
import '../../models/inmueble_model.dart';
import '../components/image_profile_inmueble.dart';
class InmuebleCard extends StatelessWidget {
  final InmuebleModel inmueble;
  final VoidCallback? onContractRequest;

  const InmuebleCard({
    Key? key,
    required this.inmueble,
    this.onContractRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image placeholder
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: ImageProfileInmueble(
              imageUrl: "",
              isIcon: false,
              inmuebleId: inmueble.id,
            )
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inmueble.nombre,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  inmueble.detalle ?? "",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.hotel, size: 16),
                    const SizedBox(width: 4),
                    Text('Habitaciones: ${inmueble.numHabitacion}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.stairs, size: 16),
                    const SizedBox(width: 4),
                    Text('Piso: ${inmueble.numPiso}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Precio: \$${inmueble.precio.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: inmueble.isOcupado ? null : onContractRequest,
                  child: Text(
                    inmueble.isOcupado ? 'No disponible' : 'Solicitar contrato',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
