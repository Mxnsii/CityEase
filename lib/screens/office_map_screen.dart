import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as ll;

import '../services/google_places_service.dart';
import '../utils/google_api_keys.dart';
import 'package:google_place/google_place.dart';

class OfficeSelection {
  final String label;
  final double latitude;
  final double longitude;

  OfficeSelection({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class OfficeMapScreen extends StatefulWidget {
  final String area;
  final String placeName;
  final LatLng initialPosition;

  const OfficeMapScreen({
    super.key,
    required this.area,
    required this.placeName,
    required this.initialPosition,
  });

  @override
  State<OfficeMapScreen> createState() => _OfficeMapScreenState();
}

class _OfficeMapScreenState extends State<OfficeMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late final flutter_map.MapController _flutterMapController;
  late final GooglePlacesService _placesService;
  late LatLng _officePosition;
  final Set<Marker> _markers = {};
  final List<SearchResult> _pgResults = [];
  int? _selectedPgIndex;
  bool _isLoading = true;

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
    _officePosition = widget.initialPosition;
    _flutterMapController = flutter_map.MapController();
    _markers.add(
      Marker(
        markerId: const MarkerId('office_pin'),
        position: _officePosition,
        draggable: !_useFlutterMap,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onDragEnd: _useFlutterMap ? null : _onOfficeMoved,
        infoWindow: InfoWindow(title: 'Your office', snippet: widget.placeName),
      ),
    );
    _loadNearbyPgs(_officePosition);
  }

  Future<void> _onOfficeMoved(LatLng newPosition) async {
    setState(() {
      _officePosition = newPosition;
      _markers.removeWhere((marker) => marker.markerId.value == 'office_pin');
      _markers.add(
        Marker(
          markerId: const MarkerId('office_pin'),
          position: _officePosition,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onDragEnd: _onOfficeMoved,
          infoWindow: InfoWindow(title: 'Your office', snippet: widget.placeName),
        ),
      );
      _isLoading = true;
    });
    await _loadNearbyPgs(_officePosition);
  }

  Future<void> _loadNearbyPgs(LatLng position) async {
    final results = await _placesService.searchNearby(position.latitude, position.longitude, radius: 3000);
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('pg_'));
      _pgResults.clear();
      _pgResults.addAll(results);
      for (var i = 0; i < _pgResults.length; i++) {
        final result = _pgResults[i];
        final location = result.geometry?.location;
        if (location == null || location.lat == null || location.lng == null) continue;
        _markers.add(
          Marker(
            markerId: MarkerId('pg_$i'),
            position: LatLng(location.lat!, location.lng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            infoWindow: InfoWindow(
              title: result.name,
              snippet: result.vicinity,
            ),
            onTap: () => setState(() {
              _selectedPgIndex = i;
            }),
          ),
        );
      }
      _isLoading = false;
    });
  }

  Future<void> _moveCamera(LatLng position) async {
    if (_useFlutterMap) {
      _flutterMapController.move(ll.LatLng(position.latitude, position.longitude), 14.5);
      return;
    }

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _confirmSelection() {
    Navigator.of(context).pop(
      OfficeSelection(
        label: 'Selected location near ${widget.placeName}',
        latitude: _officePosition.latitude,
        longitude: _officePosition.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Pinpoint location'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2D3161)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      if (_useFlutterMap)
                        flutter_map.FlutterMap(
                          mapController: _flutterMapController,
                          options: flutter_map.MapOptions(
                            center: ll.LatLng(widget.initialPosition.latitude, widget.initialPosition.longitude),
                            zoom: 14.5,
                            onTap: (_, point) {
                              _onOfficeMoved(LatLng(point.latitude, point.longitude));
                            },
                          ),
                          children: [
                            flutter_map.TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.cityease',
                            ),
                            flutter_map.MarkerLayer(
                              markers: [
                                flutter_map.Marker(
                                  point: ll.LatLng(_officePosition.latitude, _officePosition.longitude),
                                  width: 48,
                                  height: 48,
                                  builder: (_) => const Icon(Icons.location_on, size: 40, color: Color(0xFF39C5FF)),
                                ),
                                ..._pgResults
                                    .where((item) => item.geometry?.location?.lat != null && item.geometry?.location?.lng != null)
                                    .map(
                                      (item) => flutter_map.Marker(
                                        point: ll.LatLng(item.geometry!.location!.lat!, item.geometry!.location!.lng!),
                                        width: 36,
                                        height: 36,
                                        builder: (_) => const Icon(Icons.location_pin, size: 32, color: Color(0xFFEE6C85)),
                                      ),
                                    ),
                              ],
                            ),
                          ],
                        )
                      else
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: widget.initialPosition,
                            zoom: 14.5,
                          ),
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          markers: _markers,
                          onMapCreated: (controller) {
                            if (!_controller.isCompleted) {
                              _controller.complete(controller);
                            }
                          },
                          onTap: (position) {
                            _onOfficeMoved(position);
                          },
                        ),
                      if (_isLoading)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF6F5CFF)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Tap map to refine your office location. Nearby PG stays update automatically.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                'Selected pin: ${_officePosition.latitude.toStringAsFixed(5)}, ${_officePosition.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Text('Nearby PG stays',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _pgResults.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _pgResults[index];
                    final selected = _selectedPgIndex == index;
                    return InkWell(
                      onTap: () {
                        final location = item.geometry?.location;
                        if (location != null && location.lat != null && location.lng != null) {
                          _moveCamera(LatLng(location.lat!, location.lng!));
                        }
                        setState(() {
                          _selectedPgIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF191F45) : const Color(0xFF11162D),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? const Color(0xFF6F5CFF) : const Color(0xFF2D3161),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(item.name ?? 'Unknown PG',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                                if (item.rating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A3159),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: Color(0xFFFFC857)),
                                        const SizedBox(width: 4),
                                        Text('${item.rating}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.vicinity ?? 'Location not available',
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(item.types?.join(', ') ?? 'PG accommodation',
                                style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF6F5CFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: const Text('Next', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
