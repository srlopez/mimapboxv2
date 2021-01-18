import '../providers/data_provider.dart' show Marca;

abstract class DataServices {
  Future<DataServices> init();

  Future<List<Marca>> getAll();

  Future<bool> saveAll(List<Marca> lista);

  Future<bool> save(Marca element);

  Future<bool> delete(Marca element);
}
