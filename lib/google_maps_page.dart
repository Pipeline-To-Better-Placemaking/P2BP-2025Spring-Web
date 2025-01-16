import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapsPage extends StatefulWidget {
  const GoogleMapsPage({super.key});

  @override
  State<GoogleMapsPage> createState() => _GoogleMapsPageState();
}

class _GoogleMapsPageState extends State<GoogleMapsPage> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(45.521563, -122.677433); // Default location
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAndFetchLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation();
  }

  Future<void> _checkAndFetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission is required to use this feature.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Fetch initial location
      await _getCurrentLocation();

      // Start listening for location changes
      Geolocator.getPositionStream(locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Minimum distance change (in meters) to trigger an update
      )).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _moveToCurrentLocation();
      });
    } catch (e) {
      print('Error checking location permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to retrieve location. Please check your GPS settings.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _moveToCurrentLocation() {
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 14.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 11.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        child: Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
