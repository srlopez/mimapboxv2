import 'dart:async';

import '../services/data_services.dart';
import '../providers/data_provider.dart' show Marca;

class DataController {
  DataController(this.services);

  final DataServices services;

  List<Marca> _lista = [];
  List<Marca> get lista => _lista;

  Future<List<Marca>> getAll() async {
    // Por referencia la misma lista que el Servicio
    _lista = await services.getAll();
    return _lista;
  }

  Future<bool> saveAll() async {
    services.saveAll(_lista);
    return true;
  }

  Future<bool> save(Marca element) async {
    services.save(element);
    return true;
  }

  Future<bool> delete(Marca element) async {
    services.delete(element);
    return true;
  }
}
