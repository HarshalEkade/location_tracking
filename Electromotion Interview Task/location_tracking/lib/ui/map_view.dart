import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../controllers/tracking_controller.dart';

class Console {
  static void log(dynamic message) {
    print(message);
  }
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  double _currentZoom = 15.0;
  LatLng? _currentPosition;
  bool _mapInitialized = false;

  @override
  void initState() {
    super.initState();
    Console.log('🔵 [MAP_DEBUG] MapView widget initialized');
    Console.log('🔵 [MAP_DEBUG] Initial zoom: $_currentZoom');
  }

  @override
  void dispose() {
    Console.log('🔴 [MAP_DEBUG] MapView disposing, cleaning up controller');
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) async {
    Console.log('🟢 [MAP_DEBUG] ========== MAP CREATED ==========');
    _mapController = controller;
    _mapInitialized = true;
    Console.log('✅ [MAP_DEBUG] Map controller created successfully');
    Console.log('🔑 [MAP_DEBUG] API Key: AIzaSyCImmVkf-piVOy_bMLNGhorv70t79XGECQ');
    Console.log('📱 [MAP_DEBUG] Package name: com.example.location_tracking');
    Console.log('🔐 [MAP_DEBUG] SHA-1 (should be in Google Console): 52:E2:41:CF:C5:D8:3A:DF:78:B8:F8:31:52:04:4E:98:1E:C6:AF:6A');
    
    try {
      final trackingController = Get.find<TrackingController>();
      final position = trackingController.currentPosition.value;
      
      Console.log('📍 [MAP_DEBUG] Current position from controller: ${position != null ? "${position.latitude}, ${position.longitude}" : "NULL"}');
      
      if (position != null) {
        _currentPosition = LatLng(position.latitude, position.longitude);
        Console.log('📍 [MAP_DEBUG] Setting camera to: ${position.latitude}, ${position.longitude}, zoom: $_currentZoom');
        
        try {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition!,
                zoom: _currentZoom,
              ),
            ),
          );
          Console.log('✅ [MAP_DEBUG] Camera animated successfully');
          
          final currentCamera = await controller.getVisibleRegion();
          Console.log('✅ [MAP_DEBUG] Visible region: ${currentCamera.northeast.latitude}, ${currentCamera.northeast.longitude} to ${currentCamera.southwest.latitude}, ${currentCamera.southwest.longitude}');
        } catch (e, stackTrace) {
          Console.log('❌ [MAP_DEBUG] ERROR positioning camera: $e');
          Console.log('❌ [MAP_DEBUG] Stack trace: $stackTrace');
        }
      } else {
        Console.log('⚠️ [MAP_DEBUG] No position available, using default coordinates: 18.463775, 73.837742');
        _currentPosition = const LatLng(18.463775, 73.837742);
        
        try {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition!,
                zoom: _currentZoom,
              ),
            ),
          );
          Console.log('✅ [MAP_DEBUG] Camera set to default position');
        } catch (e) {
          Console.log('❌ [MAP_DEBUG] ERROR setting default camera: $e');
        }
      }
    } catch (e, stackTrace) {
      Console.log('❌ [MAP_DEBUG] ERROR in _onMapCreated: $e');
      Console.log('❌ [MAP_DEBUG] Stack trace: $stackTrace');
    }
    
    Console.log('🔍 [MAP_DEBUG] ========== DIAGNOSTIC INFO ==========');
    Console.log('🔍 [MAP_DEBUG] If map tiles are blank, check:');
    Console.log('🔍 [MAP_DEBUG]   1. Google Cloud Console → API Key Restrictions');
    Console.log('🔍 [MAP_DEBUG]   2. SHA-1 must be configured: 52:E2:41:CF:C5:D8:3A:DF:78:B8:F8:31:52:04:4E:98:1E:C6:AF:6A');
    Console.log('🔍 [MAP_DEBUG]   3. Maps SDK for Android must be enabled');
    Console.log('🔍 [MAP_DEBUG]   4. Check logcat for "API key" errors');
    Console.log('🔍 [MAP_DEBUG] ====================================');
  }

  Future<void> _centerOnLocation() async {
    Console.log('🟡 [MAP_DEBUG] Center location button tapped');
    try {
      final controller = Get.find<TrackingController>();
      final position = controller.currentPosition.value;
      
      Console.log('🟡 [MAP_DEBUG] Current position: ${position != null ? "${position.latitude}, ${position.longitude}" : "NULL"}');
      Console.log('🟡 [MAP_DEBUG] Map controller: ${_mapController != null ? "EXISTS" : "NULL"}');
      
      if (_mapController != null && position != null) {
        Console.log('🟡 [MAP_DEBUG] Centering camera on: ${position.latitude}, ${position.longitude}');
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
        Console.log('✅ [MAP_DEBUG] Camera centered successfully');
      } else {
        Console.log('⚠️ [MAP_DEBUG] Cannot center: ${_mapController == null ? "Map controller is null" : "Position is null"}');
      }
    } catch (e, stackTrace) {
      Console.log('❌ [MAP_DEBUG] ERROR centering location: $e');
      Console.log('❌ [MAP_DEBUG] Stack trace: $stackTrace');
    }
  }

  Future<void> _zoomIn() async {
    Console.log('🟡 [MAP_DEBUG] Zoom in button tapped');
    try {
      if (_mapController != null) {
        _currentZoom = (_currentZoom + 1).clamp(2.0, 20.0);
        Console.log('🟡 [MAP_DEBUG] Zooming to: $_currentZoom');
        await _mapController!.animateCamera(
          CameraUpdate.zoomTo(_currentZoom),
        );
        Console.log('✅ [MAP_DEBUG] Zoom in successful');
      } else {
        Console.log('⚠️ [MAP_DEBUG] Cannot zoom: Map controller is null');
      }
    } catch (e) {
      Console.log('❌ [MAP_DEBUG] ERROR zooming in: $e');
    }
  }

  Future<void> _zoomOut() async {
    Console.log('🟡 [MAP_DEBUG] Zoom out button tapped');
    try {
      if (_mapController != null) {
        _currentZoom = (_currentZoom - 1).clamp(2.0, 20.0);
        Console.log('🟡 [MAP_DEBUG] Zooming to: $_currentZoom');
        await _mapController!.animateCamera(
          CameraUpdate.zoomTo(_currentZoom),
        );
        Console.log('✅ [MAP_DEBUG] Zoom out successful');
      } else {
        Console.log('⚠️ [MAP_DEBUG] Cannot zoom: Map controller is null');
      }
    } catch (e) {
      Console.log('❌ [MAP_DEBUG] ERROR zooming out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Console.log('🟡 [MAP_DEBUG] build() called');
    
    try {
      final controller = Get.find<TrackingController>();

      return Obx(() {
        final position = controller.currentPosition.value;
        Console.log('🟡 [MAP_DEBUG] Obx rebuild - position: ${position != null ? "${position.latitude}, ${position.longitude}" : "NULL"}');
        
        const defaultLat = 18.463775;
        const defaultLng = 73.837742;
        
        final lat = position?.latitude ?? defaultLat;
        final lng = position?.longitude ?? defaultLng;
        final mapPosition = LatLng(lat, lng);
        
        Console.log('🟡 [MAP_DEBUG] Using map position: $lat, $lng');
        Console.log('🟡 [MAP_DEBUG] Map initialized: $_mapInitialized');
        Console.log('🟡 [MAP_DEBUG] Map controller: ${_mapController != null ? "EXISTS" : "NULL"}');
        
        if (_currentPosition == null || 
            (_currentPosition!.latitude != lat || _currentPosition!.longitude != lng)) {
          Console.log('🟡 [MAP_DEBUG] Position changed, updating camera');
          _currentPosition = mapPosition;
          
          if (_mapInitialized && _mapController != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Console.log('🟡 [MAP_DEBUG] PostFrameCallback - updating camera to: $lat, $lng');
              try {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(mapPosition),
                ).then((_) {
                  Console.log('✅ [MAP_DEBUG] Camera updated successfully in callback');
                }).catchError((e) {
                  Console.log('❌ [MAP_DEBUG] ERROR updating camera in callback: $e');
                });
              } catch (e) {
                Console.log('❌ [MAP_DEBUG] EXCEPTION updating camera in callback: $e');
              }
            });
          }
        }

        final initialCameraPosition = CameraPosition(
          target: mapPosition,
          zoom: _currentZoom,
        );
        
        Console.log('🟡 [MAP_DEBUG] Initial camera position: ${initialCameraPosition.target.latitude}, ${initialCameraPosition.target.longitude}, zoom: ${initialCameraPosition.zoom}');
        
        if (position == null) {
          Console.log('🟡 [MAP_DEBUG] Position is NULL - showing map with default position');
          return Stack(
            children: [
              GoogleMap(
                key: const ValueKey('map_default'),
                initialCameraPosition: initialCameraPosition,
                mapType: MapType.normal,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: false,
                onMapCreated: _onMapCreated,
                onCameraMove: (CameraPosition pos) {
                  _currentZoom = pos.zoom;
                  Console.log('🟡 [MAP_DEBUG] Camera moved, new zoom: $_currentZoom');
                },
                onCameraIdle: () {
                  Console.log('✅ [MAP_DEBUG] Camera idle');
                },
                onTap: (LatLng location) {
                  Console.log('🟡 [MAP_DEBUG] Map tapped at: ${location.latitude}, ${location.longitude}');
                },
              ),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Waiting for location...'),
                ],
              ),
            ),
            _buildMapControls(),
          ],
        );
      }

        Console.log('🟡 [MAP_DEBUG] Position is available - showing map with marker');
        return Stack(
          children: [
            GoogleMap(
              key: ValueKey('map_${lat}_${lng}'),
              initialCameraPosition: initialCameraPosition,
              markers: <Marker>{
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: LatLng(position.latitude, position.longitude),
                  infoWindow: InfoWindow(
                    title: 'Current Location',
                    snippet: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
                  ),
                  icon: BitmapDescriptor.defaultMarker,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: _onMapCreated,
              onCameraMove: (CameraPosition pos) {
                _currentZoom = pos.zoom;
                Console.log('🟡 [MAP_DEBUG] Camera moved, new zoom: $_currentZoom');
              },
              onCameraIdle: () {
                Console.log('✅ [MAP_DEBUG] Camera idle');
              },
              onTap: (LatLng location) {
                Console.log('🟡 [MAP_DEBUG] Map tapped at: ${location.latitude}, ${location.longitude}');
              },
            ),
            _buildMapControls(),
          ],
        );
      });
    } catch (e, stackTrace) {
      Console.log('❌ [MAP_DEBUG] CRITICAL ERROR in build(): $e');
      Console.log('❌ [MAP_DEBUG] Stack trace: $stackTrace');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Error loading map'),
            Text('Check console for details'),
          ],
        ),
      );
    }
  }

  Widget _buildMapControls() {
    return Stack(
      children: [
        Positioned(
          top: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: InkWell(
              onTap: _centerOnLocation,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.my_location,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              Material(
                elevation: 4,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                color: Colors.white,
                child: InkWell(
                  onTap: _zoomIn,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.grey.shade700,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300, thickness: 1),
              Material(
                elevation: 4,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                color: Colors.white,
                child: InkWell(
                  onTap: _zoomOut,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: Colors.grey.shade700,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}





