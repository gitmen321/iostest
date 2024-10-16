import 'dart:async';
import 'package:fleet_manager_driver_app/service/gmap_service.dart';
import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fleet_manager_driver_app/service/database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationUpdateService {

  late String vehicleNumber;
  Function(LatLng)? onLocationUpdate; 

  LocationUpdateService(this.vehicleNumber,{this.onLocationUpdate});

  Timer? _locationTimer;
  bool _isUpdating = false;

  Future<bool> updateInstantLocation(BuildContext context) async {
     bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the 
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale 
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

   if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately. 
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 


  Position position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high);

  double latitude = position.latitude;
  double longitude = position.longitude;

  await updateLocation(vehicleNumber, latitude, longitude);

  YourMapService.updateMapLocation(latitude, longitude);

   if (onLocationUpdate != null) {
      onLocationUpdate!(LatLng(latitude, longitude)); // Call the callback to update the map
    }

  print({"Instant location updated,longitude:$longitude\n latitude: $latitude"});

   return serviceEnabled;
}


void startPeriodicLocationUpdates() {
  if (!_isUpdating) {
    _isUpdating = true;
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      double latitude = position.latitude;
      double longitude = position.longitude;

      await updateLocation(vehicleNumber, latitude, longitude);
      YourMapService.updateMapLocation(latitude, longitude);

        print({"Periodic location updated,longitude:$longitude\n latitude: $latitude"});

    });
  }
}





  void stopLocationUpdates() {
     if (_locationTimer != null && _locationTimer!.isActive) {
    _locationTimer!.cancel();
  }
  }

 
  void pauseTrip(BuildContext context) {
    updateInstantLocation(context);
  }

  
}
