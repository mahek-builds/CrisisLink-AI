import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/sos_api_service.dart';
import '../theme/app_theme.dart';

class MapIncidentsPage extends StatefulWidget {
  const MapIncidentsPage({super.key, required this.sosApiService});

  final SosApiService sosApiService;

  @override
  State<MapIncidentsPage> createState() => _MapIncidentsPageState();
}

class _MapIncidentsPageState extends State<MapIncidentsPage> {
  late MapController _mapController;
  List<IncidentSummary> _incidents = const [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _error;
  IncidentSummary? _selectedIncident;

  // Default location: India (New Delhi)
  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);

  // Priority colors for markers
  static const Map<String, Color> _priorityColors = {
    'CRITICAL': Color(0xFFFF0000), // Red
    'HIGH': Color(0xFFFFA500), // Orange
    'MEDIUM': Color(0xFFFFFF00), // Yellow
    'LOW': Color(0xFF00FF00), // Green
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final incidents = await widget.sosApiService.fetchActiveIncidents();

      if (!mounted) return;

      setState(() {
        _incidents = incidents;
        _generateMarkers();
        _isLoading = false;
      });
    } on SosApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load incidents on map.';
        _isLoading = false;
      });
    }
  }

  void _generateMarkers() {
    final newMarkers = <Marker>[];

    for (final incident in _incidents) {
      final position = LatLng(incident.latitude, incident.longitude);
      final color = _priorityColors[incident.priority] ?? Colors.blue;

      newMarkers.add(
        Marker(
          point: position,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIncident = incident;
              });
              _showIncidentDetails(incident);
            },
            child: Tooltip(
              message: incident.type.toUpperCase(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${incident.reporterCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      incident.priority.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _showIncidentDetails(IncidentSummary incident) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkTheme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Incident Details',
                      style: AppTheme.darkTheme.textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Incident Type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Type: ',
                        style: AppTheme.darkTheme.textTheme.labelMedium,
                      ),
                      Text(
                        incident.type.toUpperCase(),
                        style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _priorityColors[incident.priority] ?? Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Priority: ${incident.priority}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: AppTheme.darkTheme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${incident.latitude.toStringAsFixed(4)}',
                        style: AppTheme.darkTheme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Lng: ${incident.longitude.toStringAsFixed(4)}',
                        style: AppTheme.darkTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Reporters Count
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reporters:',
                        style: AppTheme.darkTheme.textTheme.labelMedium,
                      ),
                      Text(
                        incident.reporterCount.toString(),
                        style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(incident.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Status: ${incident.status.toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to incident details page
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to responder assignment
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Assign'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'in-progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _centerMapOnIncident(IncidentSummary incident) {
    _mapController.move(
      LatLng(incident.latitude, incident.longitude),
      15.0,
    );
  }

  void _fitAllMarkers() {
    if (_incidents.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final incident in _incidents) {
      minLat = incident.latitude < minLat ? incident.latitude : minLat;
      maxLat = incident.latitude > maxLat ? incident.latitude : maxLat;
      minLng = incident.longitude < minLng ? incident.longitude : minLng;
      maxLng = incident.longitude > maxLng ? incident.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(100)),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Incidents Map'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map View
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading incidents...'),
                ],
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadIncidents,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _defaultLocation,
                zoom: 12.0,
                maxZoom: 18.0,
                minZoom: 2.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.crisislink_ai_app',
                  maxZoom: 19.0,
                ),
                MarkerLayer(markers: _markers),
              ],
            ),

          // Incidents List (Bottom Sheet)
          if (!_isLoading && _error == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.darkTheme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Incidents (${_incidents.length})',
                            style: AppTheme.darkTheme.textTheme.labelLarge,
                          ),
                          Text(
                            'Tap to select',
                            style: AppTheme.darkTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _incidents.length,
                        itemBuilder: (context, index) {
                          final incident = _incidents[index];
                          final isSelected = _selectedIncident?.id == incident.id;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIncident = incident;
                                });
                                _centerMapOnIncident(incident);
                                _showIncidentDetails(incident);
                              },
                              child: Container(
                                width: 140,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _priorityColors[incident.priority]
                                      : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      incident.type.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${incident.reporterCount} reports',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        incident.priority,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fitAllMarkers();
        },
        tooltip: 'Fit all markers',
        child: const Icon(Icons.fit_screen),
      ),
    );
  }
}
