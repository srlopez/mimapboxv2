import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:miMapGeo/ui/screens/detalle_screen.dart';
import 'package:provider/provider.dart';

import '../../utils/helpers/config.helper.dart';
import '../../providers/data_provider.dart';

class MapBoxScreen extends StatefulWidget {
  @override
  _MapBoxScreenState createState() => _MapBoxScreenState();
}

class _MapBoxScreenState extends State<MapBoxScreen> {
  // Variables de esta página
  bool seguimientoCentrado;
  LatLng posicionActual;

  // MapBox
  MapboxMapController _mapController;
  MapboxMap _map;
  String apiToken;
  List<dynamic> styles;
  int styleIndex;
  final double defZoom = 15;

  // Geolocator Stream de posición
  StreamSubscription<Position> _positionStreamSubscription;

  @override
  void initState() {
    super.initState();

    print('MapBoxScreen initState');
    styleIndex = 0;
    seguimientoCentrado = true;
    posicionActual = LatLng(43.34867565860261, -1.7937616145170816); //Plaiaundi
    getCurrentPosition().then((value) {
      //setState(() {
      posicionActual = value;
      _showSeguimiento(posicionActual);
      //});
    });
  }

  @override
  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription.cancel();
      _positionStreamSubscription = null;
    }
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // provider de Lista de marcas
    var data = Provider.of<Data>(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButton: showMisBotonesWidget(context),
        body: Stack(
          children: [
            FutureBuilder(
              future: loadConfigFile(),
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (snapshot.hasData) {
                  apiToken = snapshot.data['mapbox_api_token'];
                  styles = snapshot.data['mapbox_style_url'];
                  var map = showMapaWidget(context, data);
                  return map;
                } else {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        if (snapshot.hasError) ...{
                          SizedBox(height: 16.0),
                          Text('Error: ${snapshot.error.toString()}')
                        }
                      ],
                    ),
                  );
                }
              },
            ),
            showDireccionActualWidget(context),
          ],
        ),
      ),
    );
  }

  // Gestion del stream de posicion ==========================================
  int getStreamStatus() {
    if (_positionStreamSubscription == null) return 0;
    if (_positionStreamSubscription.isPaused) return 1;
    return 2; //listening
  }

  Color _getColorStream() =>
      [Colors.blue, Colors.red, Colors.green][getStreamStatus()];

  Icon _getIconStream() => [
        Icon(Icons.stop),
        Icon(Icons.play_arrow),
        Icon(Icons.pause)
      ][getStreamStatus()];

  void _toggleListeningStream(Data data) {
    if (_positionStreamSubscription == null) {
      final positionStream = Geolocator.getPositionStream();
      _positionStreamSubscription = positionStream.handleError((error) {
        _positionStreamSubscription.cancel();
        _positionStreamSubscription = null;
      }).listen((position) {
        if (!data.marcasVisibles) _showMarcas(data);
        posicionActual = LatLng(position.latitude, position.longitude);
        _showSeguimiento(posicionActual, data);
        //setState(() {});
      });
      _positionStreamSubscription.pause();
    }

    setState(() {
      if (_positionStreamSubscription != null) {
        if (_positionStreamSubscription.isPaused)
          // Listening
          _positionStreamSubscription.resume();
        else
          // pause
          _positionStreamSubscription.pause();
      }
    });
  }

  double degreesToRadians(degrees) {
    return degrees * pi / 180;
  }

  double distanceInMetersBetweenEarthCoordinates(
      double lat1, double lon1, double lat2, double lon2) {
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

  void _showMarcas(Data data) async {
    print('_showMarcas ${_mapController == null} ${data.forzarRepintado}');
    if (_mapController == null) return;
    //_mapController.clearSymbols();

    if (data.forzarRepintado) {
      _mapController.symbols
          .where((s) => s.data['tipo'] == 'milugar')
          .forEach((s) => _mapController.removeSymbol(s));

      data.forzarRepintado = false;
    }

    data.marcas.forEach((element) {
      var geometry = LatLng(element.latitud, element.longitud);
      _mapController.addSymbol(
        SymbolOptions(
          iconImage: 'place_icon',
          iconSize: 2.5,
          geometry: geometry,
          fontNames: ['DIN Offc Pro Bold', 'Arial Unicode MS Regular'],
          textField: element.nombre,
          textSize: 12.5,
          textOffset: Offset(0, 1.2),
          textAnchor: 'top',
          textColor: '#000000',
          textHaloBlur: 1,
          textHaloColor: '#ffffff',
          textHaloWidth: 0.8,
        ),
        {'tipo': 'milugar'},
      );
    });

    data.marcasVisibles = true;
  }

  void _showSeguimiento(LatLng geometry, [Data data]) async {
    if (_mapController == null) return;
    if (_mapController.symbols == null) return;
    _mapController.symbols
        .where((s) => s.data['tipo'] == 'seguimiento')
        .forEach((s) => _mapController.removeSymbol(s));

    _mapController.clearCircles();

    //var mxp = (cos(geometry.latitude * pi / 180) * 2 * pi * 6378137) /(256 * pow(2, pp));
    //http://blog.madebylotus.com/blog/creating-static-distance-circles-in-map-box-how-many-miles-are-in-a-pixel

    var mxp =
        await _mapController.getMetersPerPixelAtLatitude(geometry.latitude);

    await _mapController.addSymbol(
      SymbolOptions(
        iconImage: 'mi_icon',
        //iconImage: 'marker-15',
        iconSize: 2.5,
        geometry: geometry,
      ),
      {'tipo': 'seguimiento'},
    );

    var gColor = '#006992';
    var gOpacity = 0.3;
    var cRadius = 100;

    if (data != null) {
      var count = 0;
      double distancia = 0;
      for (var i = 0; i < data.marcas.length; i++) {
        distancia = distanceInMetersBetweenEarthCoordinates(
            geometry.latitude,
            geometry.longitude,
            data.marcas[i].latitud,
            data.marcas[i].longitud);
        //print(distancia);

        if (cRadius >= distancia) count++;
      }
      if (count > 0) {
        gColor = '#c53700';
        gOpacity = 0.4 + count / 10;
        count = 0;
      }
    }

    await _mapController.addCircle(
      CircleOptions(
        circleRadius: cRadius / mxp,
        circleColor: gColor,
        circleOpacity: gOpacity,
        geometry: geometry,
        draggable: false,
      ),
      {'tipo': 'seguimiento'},
    );

    if (seguimientoCentrado == true) animateCamera(geometry);
  }

  // El Mapa ================================================================
  // Leemos las imagenes que vamos a presentar sobre el mapa
  Future<Uint8List> loadAssetImage(String asset) async {
    final ByteData imageBytes = await rootBundle.load(asset);
    final Uint8List bytesList = imageBytes.buffer.asUint8List();
    return bytesList;
  }

  // Obtiene la lat y long actual
  Future<LatLng> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  void animateCamera(LatLng geometry, [double zoom]) async {
    await _mapController.animateCamera(
      CameraUpdate.newLatLng(geometry),
    );
    if (zoom != null) _mapController.animateCamera(CameraUpdate.zoomTo(zoom));
  }

  void moveCamera(LatLng geometry, zoom) async {
    await _mapController.moveCamera(
      CameraUpdate.newLatLngZoom(geometry, zoom),
    );
    _showSeguimiento(geometry);
  }

  // Obtiene la dirección de una latLng
  Future<String> getAddressFromLatLng(LatLng xy) async {
    try {
      List<Placemark> p =
          await placemarkFromCoordinates(xy.latitude, xy.longitude);
      Placemark place = p[0];

      return """${place.street}, ${place.locality}
${place.postalCode} ${place.subAdministrativeArea}
${place.administrativeArea}""";
    } catch (e) {
      return """getAddressFromLatLng ...
${xy.latitude} / ${xy.longitude}""";
    }
  }

  void _onMapCreated(MapboxMapController controller) async {
    print('MapboxMap onMapCreated');
    _mapController = controller;

    final result = await getCurrentPosition();
    animateCamera(result, defZoom);

    await _mapController.addImage(
        'place_icon', await loadAssetImage('assets/place_24px.png'));
    await _mapController.addImage(
        'mi_icon', await loadAssetImage('assets/mi_location.png'));
  }

  Widget showMapaWidget(BuildContext context, Data data) {
    _map = MapboxMap(
      styleString: styles[styleIndex],
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: posicionActual,
        zoom: defZoom,
      ),
      onMapClick: (Point<double> point, LatLng coordinates) async {
        String address = await getAddressFromLatLng(coordinates);
        _setupBottomModalSheet(context, coordinates, address);
      },
      onMapLongClick: (Point<double> point, LatLng coordinates) async {
        await _mapController.addSymbol(
          SymbolOptions(
            iconImage: 'place_icon',
            iconSize: 2.5,
            geometry: coordinates,
          ),
          {'dato': 23},
        );
        //Añadir a la lista
        data.add(coordinates.latitude, coordinates.longitude);
      },
    );
    _showMarcas(data);

    return _map;
  }

  // Botones Flotantes ======================================================
  Widget showMisBotonesWidget(BuildContext context) {
    var data = Provider.of<Data>(context);

    var navTitles = [
      [0, 'Centrar seguimiento ${seguimientoCentrado ? "✔" : "✘"}'],
      [1, 'Cambiar estilo Mapa'],
      [2, 'Mostrar lista de Marcas']
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PopupMenuButton(
          onCanceled: () {},
          onSelected: (value) async {
            print('$value $seguimientoCentrado');
            switch (value) {
              case 0:
                setState(() {
                  seguimientoCentrado = !seguimientoCentrado;
                });
                break;
              case 1:
                setState(() {
                  styleIndex++;
                  styleIndex %= styles.length;
                });
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleScreen(),
                  ),
                );
                break;
            }
          },
          icon: Icon(
            Icons.more_vert,
            //size: 35,
            //color: Colors.white,
          ),
          itemBuilder: (BuildContext context) {
            return navTitles.map((link) {
              return PopupMenuItem(
                key: Key('${link[0]}'),
                value: link[0],
                child: Text(link[1]),
              );
            }).toList();
          },
        ),
        FloatingActionButton(
          heroTag: 'track',
          onPressed: () {
            _toggleListeningStream(data);
          },
          child: _getIconStream(),
          backgroundColor: _getColorStream(),
        ),
        SizedBox(height: 10),
        //CVentrar Mapa
        FloatingActionButton(
          heroTag: 'centrar',
          child: Icon(Icons.location_on_sharp),
          onPressed: () async {
            posicionActual = await getCurrentPosition();
            moveCamera(posicionActual, defZoom);
            if (!data.marcasVisibles) _showMarcas(data);

            //_showSeguimiento(posicionActual, data);
          },
        ),
      ],
    );
  }

  // Muestra la localización Actual =========================================
  Positioned showDireccionActualWidget(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          //color: Theme.of(context).canvasColor.withOpacity(0.57),
          gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, Colors.white.withOpacity(0)]),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.location_on),
                SizedBox(
                  width: 8,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Ubicación actual',
                        style: Theme.of(context).textTheme.caption),
                    FutureBuilder<String>(
                      future: getAddressFromLatLng(
                          posicionActual), // a previously-obtained Future<String> or null
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<String> snapshot,
                      ) {
                        return Text(
                            snapshot.hasData ? snapshot.data : 'Cargando ...',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyText2);
                      },
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Dialogo Modal al Pie de Pagina
  Future<void> _setupBottomModalSheet(
      BuildContext buildContext, LatLng coordenadas, String direccion) async {
    showModalBottomSheet(
        backgroundColor:
            Theme.of(context).bottomAppBarColor, //.withOpacity(0.57),
        context: buildContext,
        isScrollControlled: true,
        builder: (BuildContext context) {
          final latitudeString = coordenadas.latitude.toStringAsPrecision(7);
          final longitudeString = coordenadas.longitude.toStringAsPrecision(7);
          return Container(
            height: 125,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Dirección', style: Theme.of(context).textTheme.caption),
                Text(direccion, style: Theme.of(context).textTheme.bodyText2),
                SizedBox(height: 8),
                Text('Coordenadas', style: Theme.of(context).textTheme.caption),
                Text('$latitudeString / $longitudeString',
                    style: Theme.of(context).textTheme.bodyText2),
                // Expanded(
                //   child: ListView(
                //     children: [
                //       ..._mapController.symbols
                //           .where((s) => s.data != null)
                //           .map((s) => Text(s.data.toString())),
                //     ],
                //   ),
                // )
              ],
            ),
          );
        });
  }
}
