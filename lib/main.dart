import 'services/location_services.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'controllers/data_controller.dart';
import 'providers/data_provider.dart';
import 'services/data_services_file.dart';
import 'ui/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var localDataService = DataServicesFile();
  await localDataService.init();
  var dataCtrl = DataController(localDataService);

  var locationServices = LocationServices();
  locationServices.init();

  runApp(MultiProvider(
    providers: [
      Provider<LocationServices>.value(value: locationServices),
      StreamProvider<LatLng>(
        create: (_) => locationServices.locationStream,
      ),
      ChangeNotifierProvider<Data>(
        create: (_) => Data(dataCtrl),
      ),
    ],
    child: MyApp(),
  ));
}
