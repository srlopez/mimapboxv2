import 'package:flutter/material.dart';
import '../controllers/data_controller.dart';

class Marca {
  String nombre;
  final double latitud;
  final double longitud;
  Marca(this.nombre, this.latitud, this.longitud);
}

class Data with ChangeNotifier {
  // Controlador para almacenar localmente la lista
  DataController persistenciaCtrl;

  // <<<<
  // Puntero a las marcas en el controller
  // luego puedo actuar directamente en esta lista
  List<Marca> marcas = <Marca>[];

  // >>>

  Data(this.persistenciaCtrl) {
    persistenciaCtrl.getAll().then((value) => marcas = value);
  }

  void add(double lat, double long) async {
    var nombre = lat.toStringAsPrecision(9).substring(4);
    var data = Marca(nombre, lat, long);
    marcas.add(data);
    notifyListeners();
  }

  void deleteAt(int index) {
    marcas.removeAt(index);
    notifyListeners();
  }

  void deleteAll() {
    marcas.clear();
    notifyListeners();
  }

  void saveAll() {
    persistenciaCtrl.saveAll();
    notifyListeners();
  }
}
