import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

enum LocationServicesStatus { Stoped, Paused, Tracking }

class LocationServices {
  // Singleton
  static final LocationServices _instance = LocationServices._internal();

  factory LocationServices() {
    return _instance;
  }

  LocationServices._internal();

  // Mantiene la posicion actual y coordenadas en curso
  LatLng _currentLocation;
  LatLng get currentLocation => _currentLocation;

  Future<LatLng> getCurrentPosition() async {
    try {
      var current = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(current.latitude, current.longitude);
    } catch (e) {
      print('Oops! Algo no ha funcionado');

      throw (e);
    }
    return _currentLocation;
  }

  // Stream de UserLocation
  StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;

  // Wraper Stream de Geolocator, para poder pausarlo y reanudarlo
  StreamSubscription<Position> _positionStreamSubscription;
  Stream<Position> _positionStream;

  void init() async {
    _currentLocation = await getCurrentPosition();
    _positionStream = Geolocator.getPositionStream();

    _positionStreamSubscription = _positionStream.handleError((error) {
      _positionStreamSubscription.cancel();
      _positionStreamSubscription = null;
    }).listen((position) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      //print(_currentLocation);
      _locationController.add(_currentLocation);
    });

    pause();
    print('LocationServices init');
  }

  LocationServicesStatus get status {
    if (_positionStreamSubscription == null)
      return LocationServicesStatus.Stoped;
    if (_positionStreamSubscription.isPaused)
      return LocationServicesStatus.Paused;
    return LocationServicesStatus.Tracking;
  }

  void pause() => _positionStreamSubscription?.pause();
  void resume() => _positionStreamSubscription?.resume();

  // La dirección postal
  Future<String> getUserAddress(LatLng xy) async {
    var direccion = 'Obteniendo ...\n${xy.latitude} / ${xy.longitude}';
    try {
      List<Placemark> p =
          await placemarkFromCoordinates(xy.latitude, xy.longitude);
      Placemark place = p[0];

      direccion = """${place.street}, ${place.locality}
${place.postalCode} ${place.subAdministrativeArea}
${place.administrativeArea}""";
    } catch (e) {
      direccion = e.toString();
      throw (e);
    }
    return direccion;
  }
}
