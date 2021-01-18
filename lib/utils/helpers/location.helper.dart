// Obtiene la lat y long actual
import 'dart:math';

// aritméticas
double degreesToRadians(degrees) {
  return degrees * pi / 180;
}

double distanciaEntreCoordenadasTerrestres(
    double lat1, double lon1, double lat2, double lon2) {
  // Multiplico por 1000 resultado en metros
  // Multiplico por 1 resultado en Km
  var earthRadiusKm = 6371 * 1000;

  var dLat = degreesToRadians(lat2 - lat1);
  var dLon = degreesToRadians(lon2 - lon1);

  lat1 = degreesToRadians(lat1);
  lat2 = degreesToRadians(lat2);

  var a = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
  var c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

// import 'package:location/location.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';

// Future<LatLng> acquireCurrentLocation() async {
//   Location location = new Location();

//   bool serviceEnabled;
//   PermissionStatus permissionGranted;

//   serviceEnabled = await location.serviceEnabled();
//   if (!serviceEnabled) {
//     serviceEnabled = await location.requestService();
//     if (!serviceEnabled) {
//       return null;
//     }
//   }

//   permissionGranted = await location.hasPermission();
//   if (permissionGranted == PermissionStatus.denied) {
//     permissionGranted = await location.requestPermission();
//     if (permissionGranted != PermissionStatus.granted) {
//       return null;
//     }
//   }

//   final LocationData locationData = await location.getLocation();
//   return LatLng(locationData.latitude, locationData.longitude);
// }
