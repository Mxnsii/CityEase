import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_place/google_place.dart';

import '../models/pg_listing.dart';
import '../services/google_places_service.dart';
import '../utils/google_api_keys.dart';
import '../utils/geo_utils.dart';

class PgDetailsScreen extends StatefulWidget {
  final PGListing pg;
  final double officeLat;
  final double officeLng;

  const PgDetailsScreen({
    super.key,
    required this.pg,
    required this.officeLat,
    required this.officeLng,
  });

  @override
  State<PgDetailsScreen> createState() => _PgDetailsScreenState();
}

class _PgDetailsScreenState extends State<PgDetailsScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late final flutter_map.MapController _flutterMapController;
  late final GooglePlacesService _placesService;
  
  final Set<Marker> _googleMarkers = {};
  final List<flutter_map.Marker> _flutterMarkers = [];
  
  bool _isLoadingAmenities = true;
  List<SearchResult> _amenities = [];

  bool get _useFlutterMap {
    return kIsWeb || <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    ].contains(defaultTargetPlatform);
  }

  @override
  void initState() {
    super.initState();
    _placesService = GooglePlacesService(kGoogleMapsApiKey);
    _flutterMapController = flutter_map.MapController();
    
    _setupInitialMarkers();
    _fetchAmenities();
  }

  void _setupInitialMarkers() {
    // PG Marker
    final pgLat = widget.pg.lat;
    final pgLng = widget.pg.lng;

    _googleMarkers.add(
      Marker(
        markerId: const MarkerId('pg_pin'),
        position: LatLng(pgLat, pgLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(title: widget.pg.name, snippet: 'Selected PG'),
      ),
    );

    _flutterMarkers.add(
      flutter_map.Marker(
        point: ll.LatLng(pgLat, pgLng),
        width: 40,
        height: 40,
        builder: (context) => Tooltip(
          message: widget.pg.name,
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: false,
          child: const Icon(Icons.home, size: 36, color: Color(0xFFEE6C85)),
        ),
      ),
    );

    // Office Marker
    _googleMarkers.add(
      Marker(
        markerId: const MarkerId('office_pin'),
        position: LatLng(widget.officeLat, widget.officeLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Office'),
      ),
    );

    _flutterMarkers.add(
      flutter_map.Marker(
        point: ll.LatLng(widget.officeLat, widget.officeLng),
        width: 40,
        height: 40,
        builder: (context) => const Tooltip(
          message: 'Your Office',
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: false,
          child: Icon(Icons.work, size: 36, color: Color(0xFF39C5FF)),
        ),
      ),
    );
  }

  Future<void> _fetchAmenities() async {
    final pgLat = widget.pg.lat;
    final pgLng = widget.pg.lng;
    
    final results = await _placesService.searchNearbyAmenities(pgLat, pgLng, radius: 2000);
    
    if (mounted) {
      setState(() {
        _amenities = results;
        _isLoadingAmenities = false;
        
        for (var i = 0; i < _amenities.length; i++) {
          final loc = _amenities[i].geometry?.location;
          if (loc != null && loc.lat != null && loc.lng != null) {
            // Add to Google Maps
            _googleMarkers.add(
              Marker(
                markerId: MarkerId('amenity_$i'),
                position: LatLng(loc.lat!, loc.lng!),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                infoWindow: InfoWindow(title: _amenities[i].name, snippet: _amenities[i].types?.join(', ')),
              ),
            );
            
            // Add to Flutter Map
            _flutterMarkers.add(
              flutter_map.Marker(
                point: ll.LatLng(loc.lat!, loc.lng!),
                width: 40,
                height: 40,
                builder: (context) => Tooltip(
                  message: _amenities[i].name ?? 'Cafe',
                  triggerMode: TooltipTriggerMode.tap,
                  preferBelow: false,
                  child: const Icon(Icons.local_cafe, size: 28, color: Colors.orangeAccent),
                ),
              ),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pgLat = widget.pg.lat;
    final pgLng = widget.pg.lng;
    final centerLat = (pgLat + widget.officeLat) / 2;
    final centerLng = (pgLng + widget.officeLng) / 2;
    
    // Calculate Bounds
    double minLat = pgLat < widget.officeLat ? pgLat : widget.officeLat;
    double maxLat = pgLat > widget.officeLat ? pgLat : widget.officeLat;
    double minLng = pgLng < widget.officeLng ? pgLng : widget.officeLng;
    double maxLng = pgLng > widget.officeLng ? pgLng : widget.officeLng;
    
    for (var a in _amenities) {
      final lat = a.geometry?.location?.lat;
      final lng = a.geometry?.location?.lng;
      if (lat != null && lng != null) {
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
    }
    
    // Add some padding to bounds
    final bounds = flutter_map.LatLngBounds(
      ll.LatLng(minLat - 0.005, minLng - 0.005),
      ll.LatLng(maxLat + 0.005, maxLng + 0.005),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF090B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(widget.pg.name),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Section
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  if (_useFlutterMap)
                    flutter_map.FlutterMap(
                      mapController: _flutterMapController,
                      options: flutter_map.MapOptions(
                        bounds: bounds,
                        boundsOptions: const flutter_map.FitBoundsOptions(padding: EdgeInsets.all(32)),
                      ),
                      children: [
                        flutter_map.TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.cityease',
                        ),
                        flutter_map.MarkerLayer(markers: _flutterMarkers),
                      ],
                    )
                  else
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(centerLat, centerLng),
                        zoom: 14.0,
                      ),
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      markers: _googleMarkers,
                      onMapCreated: (controller) {
                        if (!_controller.isCompleted) {
                          _controller.complete(controller);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            controller.animateCamera(CameraUpdate.newLatLngBounds(
                              LatLngBounds(
                                southwest: LatLng(minLat - 0.005, minLng - 0.005),
                                northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
                              ),
                              32,
                            ));
                          });
                        }
                      },
                    ),
                  if (_isLoadingAmenities)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF6F5CFF)),
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xE611162D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(Icons.home, const Color(0xFFEE6C85), 'PG Location'),
                          const SizedBox(height: 4),
                          _buildLegendItem(Icons.work, const Color(0xFF39C5FF), 'Office'),
                          const SizedBox(height: 4),
                          _buildLegendItem(Icons.local_cafe, Colors.orangeAccent, 'Cafes/Clubs'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Section
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.pg.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(widget.pg.location, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        if (widget.pg.verified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A3159),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('Verified', style: TextStyle(color: Color(0xFF8C88FF), fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Info Grid
                    Row(
                      children: [
                        _buildInfoCard('Rent', '₹${widget.pg.rent}/mo', Icons.currency_rupee),
                        const SizedBox(width: 12),
                        // Commute is computed directly in results_screen and passed if needed,
                        // but here we can compute it on the fly:
                        _buildInfoCard('Commute', '${GeoUtils.calculateCommuteMinutes(GeoUtils.calculateDistanceKm(widget.officeLat, widget.officeLng, pgLat, pgLng))} min', Icons.schedule),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoCard('Safety', '${widget.pg.safetyScore}/10', Icons.shield_outlined),
                        const SizedBox(width: 12),
                        _buildInfoCard('Rating', '${widget.pg.rating} (${widget.pg.source})', Icons.star_border),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Vibe & Lifestyle', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11162D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2D3161)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.nightlife, color: Color(0xFF8C88FF), size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(widget.pg.vibe, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Nearby Highlights', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_isLoadingAmenities)
                      const Text('Loading nearby amenities...', style: TextStyle(color: Colors.white54))
                    else if (_amenities.isEmpty)
                      const Text('No notable amenities found nearby.', style: TextStyle(color: Colors.white54))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _amenities.take(6).map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF191F45),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(amenity.name ?? 'Amenity', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          );
                        }).toList(),
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

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF11162D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D3161)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF8C88FF)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
