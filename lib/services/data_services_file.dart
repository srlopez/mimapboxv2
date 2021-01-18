import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/data_provider.dart' show Marca;

import 'data_services.dart';

class DataServicesFile extends DataServices {
  Directory _directory;
  final String _fileName = 'marcas.txt';
  final _separator = '︲';
  var _lista = <Marca>[];

  DataServicesFile();

  // DTO ========================================================
  String dataToString(Marca data) =>
      '${data.nombre}$_separator${data.latitud}$_separator${data.longitud}';

  Marca dataFromString(String s) {
    var member = s.split(_separator);
    var data =
        Marca(member[0], double.parse(member[1]), double.parse(member[2]));
    return data;
  }
  // Fin DTO

  // Funciones específicas de este Servicio =======================
  Future<String> get _localPath async {
    _directory = _directory ?? await getApplicationDocumentsDirectory();
    return _directory.path;
  }

  Future<File> get _localFile async {
    final path = _directory?.path ?? await _localPath;
    return File('$path/$_fileName').create(recursive: true);
  }
  // Fin Funciones

  @override
  Future<DataServices> init() async {
    print('DataServicesFile init');
    _directory = await getApplicationDocumentsDirectory();
    return this;
  }

  @override
  Future<List<Marca>> getAll() async {
    try {
      final file = await _localFile;

      List<String> lines = file.readAsLinesSync();
      lines.forEach((line) => _lista.add(dataFromString(line)));
      return _lista;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  @override
  Future<bool> saveAll(List<Marca> lista) async {
    final file = await _localFile;
    var sb = StringBuffer();
    lista.forEach((element) => sb.writeln(dataToString(element)));
    file.writeAsString(sb.toString());
    return true;
  }

  @override
  Future<bool> delete(Marca element) {
    return saveAll(_lista);
  }

  @override
  Future<bool> save(Marca element) {
    return saveAll(_lista);
  }
}
