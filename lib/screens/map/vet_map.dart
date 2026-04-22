import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class VetMapScreen extends StatefulWidget {
  @override
  _VetMapScreenState createState() => _VetMapScreenState();
}

class _VetMapScreenState extends State<VetMapScreen> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = LatLng(14.5995, 120.9842); // Default to Manila
  final Set<Marker> _markers = {};
  bool _loading = true;
  final String _apiKey = 'AIzaSyCVXZXGK5qC0Jy66Rn3_E9xG2GFONq7z70';

  TextEditingController _searchController = TextEditingController();
  List<dynamic> _placePredictions = [];

  @override
  void initState() {
    super.initState();
    _initLocationAndFetchVets();
  }

  Future<void> _initLocationAndFetchVets() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    await _getNearbyVetClinics();
  }

  Future<void> _getNearbyVetClinics() async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${_currentPosition.latitude},${_currentPosition.longitude}'
      '&radius=5000&type=veterinary_care&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final List results = data['results'];
        final newMarkers = <Marker>{
          Marker(
            markerId: MarkerId("current"),
            position: _currentPosition,
            infoWindow: InfoWindow(title: "You are here"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        };

        for (var place in results) {
          final loc = place['geometry']['location'];
          newMarkers.add(
            Marker(
              markerId: MarkerId(place['place_id']),
              position: LatLng(loc['lat'], loc['lng']),
              infoWindow: InfoWindow(
                title: place['name'],
                snippet: place['vicinity'],
              ),
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
        }

        setState(() {
          _markers.clear();
          _markers.addAll(newMarkers);
          _loading = false;
        });
      } else {
        print("Google Places API error: ${data['status']}");
      }
    } catch (e) {
      print("API call failed: $e");
    }
  }

  void _onMapTap(LatLng tappedPoint) async {
    setState(() {
      _currentPosition = tappedPoint;
      _loading = true;
      _searchController.clear();
      _placePredictions.clear();
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(tappedPoint, 14),
    );

    await _getNearbyVetClinics();
  }

  Future<void> _searchPlace(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&key=$_apiKey'
      '&types=geocode', // limit to addresses
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      setState(() {
        _placePredictions = data['predictions'];
      });
    } else {
      print("Autocomplete API error: ${data['status']}");
    }
  }

  Future<void> _selectPrediction(String placeId, String description) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      final newPosition = LatLng(location['lat'], location['lng']);

      setState(() {
        _currentPosition = newPosition;
        _markers.clear();
        _placePredictions = [];
        _searchController.text = description;
        _loading = true;
      });

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 14),
      );

      await _getNearbyVetClinics();
    } else {
      print("Place Details API error: ${data['status']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _loading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _markers,
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onMapTap,
                ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(10),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _searchPlace,
                  ),
                ),
                if (_placePredictions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _placePredictions[index];
                        return ListTile(
                          title: Text(prediction['description']),
                          onTap: () => _selectPrediction(
                              prediction['place_id'], prediction['description']),
                        );
                      },
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
