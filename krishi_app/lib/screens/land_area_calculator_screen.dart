import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:geolocator/geolocator.dart';

class LandAreaCalculatorScreen extends StatefulWidget {
  const LandAreaCalculatorScreen({super.key});

  @override
  State<LandAreaCalculatorScreen> createState() =>
      _LandAreaCalculatorScreenState();
}

class _LandAreaCalculatorScreenState extends State<LandAreaCalculatorScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _polygonPoints = [];
  double _calculatedArea = 0.0;
  bool _isDrawingMode = true;
  String _selectedUnit = 'acres';

  // Default location (can be changed to user's current location)
  LatLng _currentLocation = const LatLng(26.1445, 91.7362); // Assam, India

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation, 15.0);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Keep default location
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isDrawingMode) return;

    setState(() {
      _polygonPoints.add(point);
      _calculateArea();
    });
  }

  void _calculateArea() {
    if (_polygonPoints.length < 3) {
      setState(() {
        _calculatedArea = 0.0;
      });
      return;
    }

    try {
      // Convert LatLng to maps_toolkit LatLng
      List<mp.LatLng> mpPoints = _polygonPoints
          .map((point) => mp.LatLng(point.latitude, point.longitude))
          .toList();

      // Close the polygon by adding the first point at the end
      if (mpPoints.isNotEmpty && mpPoints.first != mpPoints.last) {
        mpPoints.add(mpPoints.first);
      }

      // Calculate area using maps_toolkit
      double areaInSquareMeters = mp.SphericalUtil.computeArea(
        mpPoints,
      ).toDouble();

      setState(() {
        _calculatedArea = areaInSquareMeters;
      });
    } catch (e) {
      debugPrint('Error calculating area: $e');
      setState(() {
        _calculatedArea = 0.0;
      });
    }
  }

  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
      _calculatedArea = 0.0;
    });
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
        _calculateArea();
      });
    }
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
    });
  }

  String _formatArea(double areaInSquareMeters) {
    switch (_selectedUnit) {
      case 'm²':
        return '${areaInSquareMeters.toStringAsFixed(2)} m²';
      case 'km²':
        return '${(areaInSquareMeters / 1000000).toStringAsFixed(2)} km²';
      case 'acres':
        return '${(areaInSquareMeters * 0.000247105).toStringAsFixed(2)} acres';
      case 'hectares':
        return '${(areaInSquareMeters / 10000).toStringAsFixed(2)} hectares';
      default:
        return '${areaInSquareMeters.toStringAsFixed(2)} m²';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Land Area Calculator'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.edit : Icons.edit_off),
            onPressed: _toggleDrawingMode,
            tooltip: _isDrawingMode ? 'Disable Drawing' : 'Enable Drawing',
          ),
        ],
      ),
      body: Column(
        children: [
          // Area Display Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calculated Area',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedUnit,
                      items: const [
                        DropdownMenuItem(value: 'm²', child: Text('m²')),
                        DropdownMenuItem(value: 'km²', child: Text('km²')),
                        DropdownMenuItem(value: 'acres', child: Text('Acres')),
                        DropdownMenuItem(
                          value: 'hectares',
                          child: Text('Hectares'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedUnit = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatArea(_calculatedArea),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
                if (_polygonPoints.length >= 3)
                  Text(
                    '${_polygonPoints.length} points plotted',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15.0,
                onTap: _onMapTap,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.krishi.sahayak',
                ),

                // Polygon layer
                if (_polygonPoints.length >= 2)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _polygonPoints,
                        color: const Color(0xFF16A34A).withOpacity(0.3),
                        borderColor: const Color(0xFF16A34A),
                        borderStrokeWidth: 2.0,
                        isFilled: true,
                      ),
                    ],
                  ),

                // Marker layer for points
                if (_polygonPoints.isNotEmpty)
                  MarkerLayer(
                    markers: _polygonPoints.asMap().entries.map((entry) {
                      int index = entry.key;
                      LatLng point = entry.value;
                      return Marker(
                        point: point,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Control Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _undoLastPoint,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearPolygon,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Location'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
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
