import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';

class DetalleScreen extends StatelessWidget {
  const DetalleScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var data = Provider.of<Data>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Lista de Marcas"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RaisedButton(
                    color: Colors.red[700],
                    textColor: Colors.white,
                    child: Text('¡Borrar todas!'),
                    onPressed: () {
                      data.deleteAll();
                      Navigator.pop(context, "deleted");
                    }),
                RaisedButton(
                    color: Colors.green[700],
                    disabledColor: Colors.grey[700],
                    textColor: Colors.white,
                    child: Text('Guardar'),
                    onPressed: () {
                      data.saveAll();
                      Navigator.pop(context, "saved");
                    }),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: data.marcas.length,
                itemBuilder: (BuildContext context, int index) {
                  final latitudeString =
                      data.marcas[index].latitud.toStringAsPrecision(7);
                  final longitudeString =
                      data.marcas[index].longitud.toStringAsPrecision(7);
                  return ListTile(
                    key: Key(data.marcas[index].nombre +
                        latitudeString +
                        longitudeString),
                    leading: Icon(Icons.location_pin),
                    title: TextFormField(
                      // decoration: const InputDecoration(
                      //     //labelText: 'Nombre',
                      //     ),
                      initialValue: data.marcas[index].nombre,
                      onChanged: (String value) {
                        data.marcas[index].nombre = value;
                      },
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$latitudeString / $longitudeString',
                        style: Theme.of(context).textTheme.bodyText2),
                    trailing: IconButton(
                      color: Colors.red[700],
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        print('delete $index');
                        data.deleteAt(index);
                      },
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
