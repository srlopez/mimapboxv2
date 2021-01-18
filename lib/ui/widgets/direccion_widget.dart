import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

import '../../services/location_services.dart';

class DireccionWidget extends StatelessWidget {
  DireccionWidget({Key key, this.context}) : super(key: key);
  final BuildContext context;

  Future<Map<String, Object>> getAddress(BuildContext context) async {
    var locationServices = Provider.of<LocationServices>(context);

    var loc = LatLng(0, 0);
    String address = 'Oops! Parece que no nos encontramos.';
    IconData icon = Icons.location_off;
    if (locationServices.status == LocationServicesStatus.Tracking) {
      loc = locationServices.currentLocation;
      try {
        address = await locationServices.getUserAddress(loc);
        icon = Icons.location_on;
      } catch (e) {}
    } else
      try {
        loc = await locationServices.getCurrentPosition();
        address = await locationServices.getUserAddress(loc);
        icon = Icons.location_pin;
      } catch (e) {}

    return {'icon': icon, 'address': address, 'location': loc};
  }

  @override
  Widget build(BuildContext context) {
    // var data = Provider.of<Data>(context);
    // var locationServices = Provider.of<LocationServices>(context);
    // var location = Provider.of<LatLng>(context);
    // Aunque no lo usemos fuerza repintar el Widget

    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(7)),
        color: Theme.of(context).canvasColor.withOpacity(0.57),
        gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white,
              Colors.white,
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0)
            ]),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FutureBuilder<Map<String, Object>>(
        future: getAddress(context),
        builder: (
          BuildContext context,
          AsyncSnapshot<Map<String, Object>> snapshot,
        ) {
          return Row(
            children: <Widget>[
              Icon(snapshot.hasData ? snapshot.data['icon'] : Icons.search),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Dirección:',
                      style: Theme.of(context).textTheme.caption),
                  Text(
                      snapshot.hasData
                          ? snapshot.data['address']
                          : 'Cargando ...',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyText1),
                  // if (snapshot.hasData)
                  //   Text(snapshot.data['location'].toString()),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
