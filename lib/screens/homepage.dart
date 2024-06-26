import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? lat = '0';
  String? long = '0';
  String address = 'Fetching address...';
  Set<Marker> _markers = {};
  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _liveLocation();
  }

  Future<void> getPlacemarks(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      var address = '';

      if (placemarks.isNotEmpty) {
        // Concatenate non-null components of the address
        var streets = placemarks.reversed
            .map((placemark) => placemark.street)
            .where((street) => street != null);

        // Filter out unwanted parts
        streets = streets.where((street) =>
            street!.toLowerCase() !=
            placemarks.reversed.last.locality!
                .toLowerCase()); // Remove city names
        streets = streets
            .where((street) => !street!.contains('+')); // Remove street codes

        // address += streets.join(', ');

        // address += ', ${placemarks.reversed.last.subLocality ?? ''}';
        // address += ', ${placemarks.reversed.last.locality ?? ''}';
        address += ' ${placemarks.reversed.last.subAdministrativeArea ?? ''}';
        address += ', ${placemarks.reversed.last.administrativeArea ?? ''}';
        // address += ', ${placemarks.reversed.last.postalCode ?? ''}';
        address += ', ${placemarks.reversed.last.country ?? ''}';
      }

      print("Your Address for ($lat, $long) is: $address");

      setState(() {
        this.address = address;
      });
    } catch (e) {
      print("Error getting placemarks: $e");
      setState(() {
        address = "No Address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: screenHeight,
            width: screenWidth,
            color: Colors.black26,
            child: Padding(
              padding: const EdgeInsets.all(0.1),
              child: GoogleMap(
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    double.parse(lat ?? '0'), // Use lat and long if available
                    double.parse(long ?? '0'),
                  ),
                  zoom: 100,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0).copyWith(top: 45),
                child: Container(
                  height: screenHeight * 0.06,
                  width: screenWidth - 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.black87,
                  ),
                  child: Center(
                      child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        address,
                        maxLines: 1,
                        // "$lat , $long",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )),
                ),
              ),
              Spacer(),
              // Center(
              //     child: Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Container(
              //       color: Colors.white,
              //       child: Text(
              //         address,
              //         style: TextStyle(fontSize: 17),
              //       )),
              // )),
              // SizedBox(
              //   height: 25,
              // )
            ],
          ),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 10),
          //   child: Center(
          //       child: Container(color: Colors.white, child: Text(address))),
          // ),
        ],
      ),
    );
  }

  void _liveLocation() {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        setState(() {
          lat = position.latitude.toString();
          long = position.longitude.toString();
          _markers.add(
            Marker(
              markerId: MarkerId('userLocation'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: InfoWindow(title: 'My Location'),
            ),
          );
        });
        getPlacemarks(position.latitude, position.longitude);
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location Permissions are denied");
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error("Location Permissions are denied");
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      lat = position.latitude.toString();
      long = position.longitude.toString();
      _markers.add(
        Marker(
          markerId: MarkerId('userLocation'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(title: 'My Location'),
        ),
      );
    });

    getPlacemarks(position.latitude, position.longitude);

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }
}
