import 'package:flutter/material.dart';

import '../models/animal_report.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
  });

  final AnimalReport report;

  String get _animalLabel {
    switch (report.animalType) {
      case 'dog':
        return 'Perro';
      case 'cat':
        return 'Gato';
      default:
        return 'Otro';
    }
  }

  String get _categoryLabel {
    switch (report.category) {
      case 'lost':
        return 'Perdido';
      case 'seen':
        return 'Visto';
      case 'abandoned':
        return 'Abandonado';
      case 'rescued':
        return 'Resguardado';
      case 'adoption':
        return 'En adopción';
      case 'injured':
        return 'Herido';
      default:
        return report.category;
    }
  }

  String get _urgencyLabel {
    switch (report.urgency) {
      case 'low':
        return 'Baja';
      case 'medium':
        return 'Media';
      case 'high':
        return 'Alta';
      default:
        return report.urgency;
    }
  }

  IconData get _icon {
    switch (report.animalType) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.cruelty_free;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.mainImageUrl != null && report.mainImageUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                report.mainImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 42),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Icon(_icon)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('$_animalLabel · $_categoryLabel · Urgencia $_urgencyLabel'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(report.description),
                const SizedBox(height: 12),
                if (report.approximateAddress != null &&
                    report.approximateAddress!.isNotEmpty)
                  Text('📍 ${report.approximateAddress}'),
                Text(
                  'Coordenadas: ${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
