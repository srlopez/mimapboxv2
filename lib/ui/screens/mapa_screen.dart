import 'dart:math';
import 'dart:typed_data';

import 'package:ami/utils/helpers/location.helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../providers/data_provider.dart';
import '../../services/location_services.dart';
import '../../ui/widgets/direccion_widget.dart';
import '../../utils/helpers/config.helper.dart';
import 'detalle_screen.dart';

// Variables de esta página
bool seguimientoCentrado = true;
bool mostrarDireccion = true;
bool mostrarMarcas = true;

// MapBox
MapboxMapController _mapController;
String apiToken; // Token de MapBox
List<dynamic> styles; // Estilos de mapas
int styleIndex = 0; // Estilo actual
const double ZOOM = 15; // Zoom predefinido 0..20

class MapaScreen extends StatefulWidget {
  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  @override
  void initState() {
    super.initState();
    print('MapaScreen initState');
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var data = Provider.of<Data>(context);
    // var location = Provider.of<UserLocation>(context);
    // var locationServices = Provider.of<LocationServices>(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButton: floatingButtonsWidget(context),
        body: Stack(
          children: [
            if (initMap) tracker(context),
            FutureBuilder(
              future: loadConfigFile(),
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (snapshot.hasData) {
                  apiToken = snapshot.data['mapbox_api_token'];
                  styles = snapshot.data['mapbox_style_url'];
                  return mapBoxWidget(context);
                } else {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        if (snapshot.hasError) ...{
                          SizedBox(height: 16.0),
                          Text(
                              'Oops! Algo no ha funcionado\n${snapshot.error.toString()}')
                        }
                      ],
                    ),
                  );
                }
              },
            ),
            if (mostrarDireccion) ...{direccionPositionedWidget(context)},
            marcaPositionedWidget(context),
          ],
        ),
      ),
    );
  }

  Widget tracker(BuildContext context) {
    var locationServices = Provider.of<LocationServices>(context);
    var data = Provider.of<Data>(context);
    var geometry = Provider.of<LatLng>(context);
    try {
      if (locationServices.status == LocationServicesStatus.Tracking) {
        if (seguimientoCentrado)
          _mapController.animateCamera(
            CameraUpdate.newLatLng(geometry),
          );
      } else {
        geometry = locationServices.currentLocation;
      }
      setSymbolMarcas(data.marcas);
      setSymbolCircle(data.marcas, geometry);
      setSymbolCurrent(geometry);
    } catch (e) {
      print(e.toString());
    }
    return Visibility(child: Placeholder(), visible: false);
  }

  // El Mapa ================================================================
  // Leemos las imagenes que vamos a presentar sobre el mapa

  //LatLng currentOnFuture; //La posición actual capturada por primera vez
  LatLng currentOnTracker; //La posición actual capturada por el tracker
  Symbol miSymbolCenter;
  Circle miCircleCenter;
  String trackString = '';
  bool initMap = false;

  Future<Uint8List> loadAssetImage(String asset) async {
    final ByteData imageBytes = await rootBundle.load(asset);
    final Uint8List bytesList = imageBytes.buffer.asUint8List();
    return bytesList;
  }

  void _onMapCreated(MapboxMapController controller) async {
    print('MapboxMap onMapCreated');
    _mapController = controller;

    await _mapController.moveCamera(
      CameraUpdate.newLatLng(currentOnTracker),
    );

    await _mapController.addImage(
        'place_icon', await loadAssetImage('assets/place_24px.png'));
    await _mapController.addImage(
        'mi_icon', await loadAssetImage('assets/mi_location.png'));

    miSymbolCenter = await _mapController.addSymbol(
      SymbolOptions(
        iconImage: 'mi_icon',
        //iconImage: 'marker-15',
        iconSize: 2.5,
        geometry: currentOnTracker,
        zIndex: 10,
      ),
      {'tipo': 'seguimiento'},
    );

    miCircleCenter = await _mapController.addCircle(
      CircleOptions(
        circleRadius: 100,
        circleColor: '#006992',
        circleBlur: 0,
        circleOpacity: 0,
        geometry: currentOnTracker,
        draggable: false,
      ),
      {'tipo': 'seguimiento'},
    );

    setState(() {
      initMap = true;
    });
  }

  Widget mapBoxWidget(BuildContext context) {
    var data = Provider.of<Data>(context);
    //var location = Provider.of<LatLng>(context);
    var locationServices = Provider.of<LocationServices>(context);

    // return Center(
    //   child: Column(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       Text('Estilo $styleIndex'),
    //       Text('Centrado $seguimientoCentrado'),
    //       Text('${locationServices.status}'),
    //       if (location != null)
    //         Text('${location.latitude}/${location.longitude}'),
    //     ],
    //   ),
    // );

    // return MapboxMap(
    //   styleString: styles[styleIndex],
    //   onMapCreated: _onMapCreated,
    //   initialCameraPosition: CameraPosition(
    //     target: locationServices.currentLocation,
    //     zoom: ZOOM,
    //   ),
    //   logoViewMargins: Point(35, 20),
    //   compassViewMargins: Point(40, 140),
    //   // onMapClick: (Point<double> point, LatLng coordinates) async {
    //   //   //
    //   // },
    //   onMapLongClick: (Point<double> point, LatLng coordinates) async {
    //     await _mapController.addSymbol(
    //       SymbolOptions(
    //         iconImage: 'place_icon',
    //         iconSize: 2.5,
    //         geometry: coordinates,
    //       ),
    //       {'tipo': 'marca'},
    //     );
    //     //Añadir a la lista
    //     data.add(coordinates.latitude, coordinates.longitude);
    //   },
    // );

    return FutureBuilder<LatLng>(
        future: Future<LatLng>.value(locationServices
            .currentLocation), //locationServices.getCurrentPosition(),
        builder: (BuildContext context, AsyncSnapshot<LatLng> snapshot) {
          if (snapshot.hasData) {
            currentOnTracker = snapshot.data;
            return MapboxMap(
              // Config json
              accessToken: apiToken,
              styleString: styles[styleIndex],
              // Config json
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: currentOnTracker,
                zoom: ZOOM,
              ),
              logoViewMargins: Point(35, 20),
              compassViewMargins: Point(40, 140),
              // onMapClick: (Point<double> point, LatLng coordinates) async {
              //   //
              // },
              onMapLongClick: (Point<double> point, LatLng coordinates) {
                setSymbolMarca('', coordinates);
                data.add(coordinates.latitude, coordinates.longitude);
              },
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  void setSymbolCircle(List<Marca> marcas, LatLng geometry) async {
    try {
      var gColor = '#006992';
      var gOpacity = 0.3;
      var cRadius = 100;
      var cBlur = 0.0;

      var count = 0;
      double minDistancia = 1000;

      trackString = '';
      for (var i = 0; i < marcas.length; i++) {
        double distancia = distanciaEntreCoordenadasTerrestres(
            geometry.latitude,
            geometry.longitude,
            marcas[i].latitud,
            marcas[i].longitud);
        minDistancia = min(minDistancia, distancia);
        count += distancia <= cRadius ? 1 : 0;

        if (distancia <= cRadius) {
          trackString += ' ' + marcas[i].nombre;
        }
      }
      // if (minDistancia < cRadius * 2) {
      //   gColor = '#FFFF00';
      //   cBlur = 0.5;
      // }

      if (count > 0) {
        gColor = '#DF0101'; //#04B404'; //'#c53700';
        gOpacity = gOpacity + count / 10;
        cBlur = 0;
        count = 0;
      }

      var mxp =
          await _mapController.getMetersPerPixelAtLatitude(geometry.latitude);

      await _mapController.updateCircle(
          miCircleCenter,
          CircleOptions(
            circleRadius: cRadius / mxp,
            circleColor: gColor,
            circleOpacity: gOpacity,
            circleBlur: cBlur,
            geometry: geometry,
          ));
    } catch (e) {}
  }

  void setSymbolCurrent(LatLng geometry, [bool show = true]) async {
    try {
      _mapController?.updateSymbol(
        miSymbolCenter,
        SymbolOptions(geometry: geometry),
      );
    } catch (e) {
      print(e.toString());
    }
  }

  void setSymbolMarca(String texto, LatLng geometry) {
    _mapController.addSymbol(
      SymbolOptions(
        iconImage: 'place_icon',
        iconSize: 2.5,
        geometry: geometry,
        fontNames: ['DIN Offc Pro Bold', 'Arial Unicode MS Regular'],
        textField: texto,
        textSize: 12.5,
        textOffset: Offset(0, 1.2),
        textAnchor: 'top',
        textColor: '#000000',
        textHaloBlur: 1,
        textHaloColor: '#ffffff',
        textHaloWidth: 0.8,
      ),
      {'tipo': 'marca'},
    );
  }

  Future<void> removeSymbolMarcas() async {
    _mapController.symbols
        .where((s) => s.data['tipo'] == 'marca')
        .forEach((s) async {
      await _mapController.removeSymbol(s);
    });
  }

  void setSymbolMarcas(List<Marca> marcas) async {
    try {
      var nMarcasMostradas =
          _mapController.symbols.where((s) => s.data['tipo'] == 'marca').length;

      //Pintar
      if (nMarcasMostradas == 0 && marcas.length > 0)
        marcas.forEach(
          (element) => setSymbolMarca(
              element.nombre, LatLng(element.latitud, element.longitud)),
        );
    } catch (e) {}
  }

  // ==========================================================

  // Botones Flotantes
  Widget floatingButtonsWidget(BuildContext context) {
    var locationservices = Provider.of<LocationServices>(context);
    var data = Provider.of<Data>(context);

    var popupMenuItems = [
      [0, '${seguimientoCentrado ? "☑" : "☐"} Centrar seguimiento'],
      [3, '↬ ${mostrarDireccion ? "Ocultar" : "Mostrar"} dirección'],
      [1, '⟳ Cambiar estilo Mapa'],
      [2, '↦ Editar Marcas'],
      [4, '${mostrarMarcas ? "☑" : "☐"} Mostrar Marcas ᯽'],
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(height: 20),
        // Menu
        PopupMenuButton(
          onCanceled: () {},
          onSelected: (value) async {
            switch (value) {
              case 0:
                setState(() => seguimientoCentrado = !seguimientoCentrado);
                break;
              case 1:
                setState(() {
                  styleIndex++;
                  styleIndex %= styles.length;
                });
                break;
              case 2:
                var result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleScreen(),
                  ),
                );
                if (result != null) {}
                removeSymbolMarcas().then((_) {
                  setState(() {
                    setSymbolMarcas(data.marcas);
                  });
                });

                break;
              case 3:
                setState(() => mostrarDireccion = !mostrarDireccion);
                break;
              case 4:
                setState(() {
                  mostrarMarcas = !mostrarMarcas;

                  if (mostrarMarcas)
                    setSymbolMarcas(data.marcas);
                  else
                    removeSymbolMarcas();
                });
            }
          },
          icon: Icon(
            Icons.menu,
            size: 35,
            //color: Colors.white,
          ),
          itemBuilder: (BuildContext context) {
            return popupMenuItems.map((link) {
              return PopupMenuItem(
                key: Key('${link[0]}'),
                value: link[0],
                child: Text(link[1]),
              );
            }).toList();
          },
        ),
        // Separación total
        Spacer(),
        // Tracking
        FloatingActionButton(
          heroTag: 'track',
          onPressed: () {
            setState(() {
              var status = locationservices.status.index;
              if (status == 1) locationservices.resume();
              if (status == 2) locationservices.pause();
            });
          },
          child: Icon([
            Icons.stop,
            Icons.play_arrow,
            Icons.pause
          ][locationservices.status.index]),
          backgroundColor: [
            Colors.blue,
            Colors.red,
            Colors.green
          ][locationservices.status.index],
        ),
        //
        SizedBox(height: 10),
        // Centrar Mapa
        FloatingActionButton(
          heroTag: 'centrar',
          child: Icon(Icons.location_on),
          onPressed: () async {
            final geometry = await locationservices.getCurrentPosition();
            await _mapController?.moveCamera(
              CameraUpdate.newLatLngZoom(geometry, ZOOM),
              //CameraUpdate.newLatLng(geometry),
            );
            setSymbolCurrent(geometry);
            setSymbolCircle(data.marcas, geometry);
          },
        ),
      ],
    );
  }

  // Muestra la localización Actual
  Widget direccionPositionedWidget(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: DireccionWidget(context: context),
    );
  }

  Widget marcaPositionedWidget(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 10,
      right: 10,
      child: Text(trackString),
    );
  }
}
