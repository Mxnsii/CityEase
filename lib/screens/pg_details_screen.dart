import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_place/google_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> _favoritePgNames = [];
  bool _isFavorite = false;

  // Mock Gallery Images (Point 18)
  final List<String> _galleryImages = [
    'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=500&q=80',
  ];

  // Mock Room Types (Point 18)
  final List<Map<String, dynamic>> _roomTypes = [
    {'type': 'Single Private Room', 'price': 15000, 'deposit': 30000, 'availability': 'Available'},
    {'type': '2-Sharing Room', 'price': 9500, 'deposit': 19000, 'availability': 'Filling Fast'},
    {'type': '3-Sharing Room', 'price': 7800, 'deposit': 15000, 'availability': 'Available'},
  ];

  // Mock Reviews (Point 18)
  final List<Map<String, dynamic>> _reviews = [
    {'name': 'Anjali Sharma', 'rating': 5, 'comment': 'Clean rooms and delicious food. Highly recommended!', 'date': '2 weeks ago'},
    {'name': 'Rohan Das', 'rating': 4, 'comment': 'Great amenities, Wi-Fi is super fast. Security is top notch.', 'date': '1 month ago'},
  ];

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
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritePgNames = prefs.getStringList('favorite_pg_names') ?? [];
      _isFavorite = _favoritePgNames.contains(widget.pg.name);
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_isFavorite) {
        _favoritePgNames.remove(widget.pg.name);
        _isFavorite = false;
      } else {
        _favoritePgNames.add(widget.pg.name);
        _isFavorite = true;
      }
    });
    await prefs.setStringList('favorite_pg_names', _favoritePgNames);
  }

  void _setupInitialMarkers() {
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
            _googleMarkers.add(
              Marker(
                markerId: MarkerId('amenity_$i'),
                position: LatLng(loc.lat!, loc.lng!),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                infoWindow: InfoWindow(title: _amenities[i].name, snippet: _amenities[i].types?.join(', ')),
              ),
            );
            
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
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Gallery Slideshow Section
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: _galleryImages.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            _galleryImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        },
                      ),
                    ),


                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              _buildInfoCard('Rent From', '₹${widget.pg.rent}/mo', Icons.currency_rupee),
                              const SizedBox(width: 12),
                              _buildInfoCard('Commute', '${GeoUtils.calculateCommuteMinutes(GeoUtils.calculateDistanceKm(widget.officeLat, widget.officeLng, pgLat, pgLng))} min', Icons.schedule),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoCard('Safety', '${widget.pg.safetyScore}/10', Icons.shield_outlined),
                              const SizedBox(width: 12),
                              _buildInfoCard('Rating', '${widget.pg.rating} ⭐', Icons.star_border),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Room Types Options (Point 18)
                          const Text('Available Room Types', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Column(
                            children: _roomTypes.map((room) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF11162D),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF2D3161)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(room['type'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Deposit: ₹${room['deposit']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('₹${room['price']}/mo', style: const TextStyle(color: Color(0xFF8C88FF), fontSize: 15, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(room['availability'], style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
                          
                          // Essentials Checklist (Point 13)
                          const Text('Nearby Essentials', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.8,
                            children: [
                              _buildEssentialGridCard('Metro Station', '🚇 450m away', const Color(0xFF3B82F6)),
                              _buildEssentialGridCard('Bus Stop', '🚌 200m away', const Color(0xFF10B981)),
                              _buildEssentialGridCard('Restaurants', '🍴 120m away', const Color(0xFFF59E0B)),
                              _buildEssentialGridCard('Hospital', '🏥 1.2 km away', const Color(0xFFEF4444)),
                              _buildEssentialGridCard('Grocery Store', '🛒 80m away', const Color(0xFFEC4899)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Reviews Section (Point 18)
                          const Text('User Reviews', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Column(
                            children: _reviews.map((rev) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF11162D),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(rev['name'], style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                        Row(
                                          children: List.generate(rev['rating'], (_) => const Icon(Icons.star, size: 12, color: Color(0xFFFFD43F))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(rev['comment'], style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                                    const SizedBox(height: 6),
                                    Text(rev['date'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          
                          const Text('Nearby Highlights', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (_isLoadingAmenities)
                            const Text('Loading nearby highlights...', style: TextStyle(color: Colors.white54))
                          else if (_amenities.isEmpty)
                            const Text('No notable highlights found nearby.', style: TextStyle(color: Colors.white54))
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
                                  child: Text(amenity.name ?? 'Highlight', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 24),

                          // Maps View Preview Section
                          const Text('Interactive Map Preview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // Map View (Embedded)
                    SizedBox(
                      height: 250,
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
                        ],
                      ),
                    ),

                    // Owner Contacts panel
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131732),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF222855)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Property Manager / Owner Contact', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Zolo Stay Support · Speaks Eng, Hindi', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.phone, size: 16),
                                  label: const Text('Call Owner', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                  label: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white30),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
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

  Widget _buildEssentialGridCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11162D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
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
