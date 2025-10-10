// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/analysis_service.dart';
import '../models/crop_analysis.dart';
import 'camera_screen.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final AnalysisService _analysisService = AnalysisService();
  List<CropAnalysis> _analyses = [];
  List<CropAnalysis> _filteredAnalyses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() => _isLoading = true);
    try {
      final analyses = await _analysisService.getAllAnalyses();
      setState(() {
        _analyses = analyses;
        _filteredAnalyses = analyses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ [CropScreen] Error loading analyses: $e');
    }
  }

  void _searchAnalyses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAnalyses = _analyses;
      } else {
        _filteredAnalyses = _analyses
            .where(
              (analysis) =>
                  analysis.cropType.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  analysis.diseaseType.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  analysis.healthStatus.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  Widget _buildAnalysesList() {
    if (_filteredAnalyses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No crop analyses yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start analyzing your crops by taking a photo',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  ).then((_) {
                    // Refresh analyses when returning from camera
                    _loadAnalyses();
                  });
                },
                icon: const Icon(Icons.camera_alt, size: 24),
                label: const Text('Take Photo for Analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  ).then((_) {
                    // Refresh analyses when returning from camera
                    _loadAnalyses();
                  });
                },
                icon: const Icon(Icons.photo_library, size: 20),
                label: const Text('Choose from Gallery'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredAnalyses.length,
      itemBuilder: (context, index) {
        final analysis = _filteredAnalyses[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: analysis.isHealthy
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Icon(
                analysis.isHealthy ? Icons.check_circle : Icons.warning,
                color: analysis.isHealthy ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              '${analysis.cropType} - ${analysis.diseaseType}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health: ${analysis.healthStatus.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: analysis.isHealthy ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Confidence: ${analysis.confidence.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Analyzed: ${analysis.createdAt.toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            onTap: () {
              // todo: Show detailed analysis view
              _showAnalysisDetails(analysis);
            },
          ),
        );
      },
    );
  }

  void _showAnalysisDetails(CropAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analysis Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop: ${analysis.cropType}'),
            Text('Disease: ${analysis.diseaseType}'),
            Text('Health: ${analysis.healthStatus}'),
            Text('Confidence: ${analysis.confidence.toStringAsFixed(1)}%'),
            Text('Model: ${analysis.modelType}'),
            Text('Mode: ${analysis.analysisMode}'),
            if (analysis.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Image.network(
                  analysis.imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor and foregroundColor are now handled by AppBarTheme in main.dart
        title: Text('Crop Analysis'), // Focus on analysis only
        actions: [
          IconButton(
            icon: Icon(
              Icons.camera_alt,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              ).then((_) {
                // Refresh analyses when returning from camera
                _loadAnalyses();
              });
            },
            tooltip: 'Analyze Crop Health',
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _loadAnalyses,
            tooltip: 'Refresh Analyses',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search analyses...',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              onChanged: _searchAnalyses,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : _buildAnalysesList(),
          ),
        ],
      ),
    );
  }
}
