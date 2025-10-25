import 'package:flutter/material.dart';
import '../models/crop_recommendation.dart';

class CropDetailsDialog extends StatelessWidget {
  final CropRecommendation crop;

  const CropDetailsDialog({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      crop.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    _buildSection(
                      'Description',
                      crop.description,
                      Icons.info_outline,
                    ),
                    const SizedBox(height: 16),

                    // Basic Info
                    _buildInfoGrid(),
                    const SizedBox(height: 16),

                    // Benefits
                    _buildSection(
                      'Benefits',
                      crop.benefits.join('\n• '),
                      Icons.check_circle_outline,
                      prefix: '• ',
                    ),
                    const SizedBox(height: 16),

                    // Challenges
                    _buildSection(
                      'Challenges',
                      crop.challenges.join('\n• '),
                      Icons.warning_outlined,
                      prefix: '• ',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon, {
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          prefix != null ? '$prefix$content' : content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow('Season', crop.season, Icons.calendar_today),
          const SizedBox(height: 12),
          _buildInfoRow('Climate', crop.climate, Icons.wb_sunny),
          const SizedBox(height: 12),
          _buildInfoRow('Soil Type', crop.soilType, Icons.landscape),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Water Requirement',
            crop.waterRequirement,
            Icons.water_drop,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Yield Potential',
            crop.yieldPotential,
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Market Value', crop.marketValue, Icons.attach_money),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Color(0xFF6B7280))),
        ),
      ],
    );
  }
}
