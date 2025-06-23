import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class Figura {
  int? id;
  String serie;
  String tipo;
  String nombre;
  String imagenPath;

  Figura({
    this.id,
    required this.serie,
    required this.tipo,
    required this.nombre,
    required this.imagenPath,
  });

  factory Figura.fromMap(Map<String, dynamic> map) {
    return Figura(
      id: map['id'],
      serie: map['serie'],
      tipo: map['tipo'],
      nombre: map['nombre'],
      imagenPath: map['imagenPath'],
    );
  }
}

class ListarTodasPage extends StatefulWidget {
  @override
  _ListarTodasPageState createState() => _ListarTodasPageState();
}

class _ListarTodasPageState extends State<ListarTodasPage> {
  late Database database;
  List<Figura> figuras = [];
  List<Figura> figurasFiltradas = [];
  final filtroController = TextEditingController();

  String? serieSeleccionada = 'Todas';

  final Map<String, List<String>> seriesDisponibles = {
    'Todas': [],
    'Dragonball': [],
    'Dragonball Z': [],
    'Dragonball Super': [],
    'Dragonball Daima': [],
    'Dragonball GT': [],
  };

  @override
  void initState() {
    super.initState();
    initDb();
  }

  Future<void> initDb() async {
    final dbPath = await getDatabasesPath();
    database = await openDatabase(p.join(dbPath, 'figuras.db'), version: 1);
    fetchFiguras();
  }

  Future<void> fetchFiguras() async {
    final List<Map<String, dynamic>> maps = await database.query('figuras');
    setState(() {
      figuras = maps.map((map) => Figura.fromMap(map)).toList();
      figurasFiltradas = List.from(figuras);
    });
  }

  void aplicarFiltro(String texto) {
    setState(() {
      figurasFiltradas =
          figuras.where((figura) {
            final coincideTexto =
                figura.nombre.toLowerCase().contains(texto.toLowerCase()) ||
                figura.serie.toLowerCase().contains(texto.toLowerCase()) ||
                figura.tipo.toLowerCase().contains(texto.toLowerCase());

            final coincideSerie =
                (serieSeleccionada == 'Todas') ||
                figura.serie.toLowerCase().startsWith(
                  serieSeleccionada!.toLowerCase(),
                );

            return coincideTexto && coincideSerie;
          }).toList();
    });
  }

  Future<void> eliminarFigura(int id) async {
    await database.delete('figuras', where: 'id = ?', whereArgs: [id]);
    fetchFiguras();
  }

  void mostrarImagenCompleta(String imagePath) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
    );
  }

  void mostrarDetalles(Figura figura) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(figura.nombre),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => mostrarImagenCompleta(figura.imagenPath),
                  child: Image.file(File(figura.imagenPath), height: 200),
                ),
                SizedBox(height: 10),
                Text('Serie: ${figura.serie}'),
                Text('Tipo: ${figura.tipo}'),
                Text('Nombre: ${figura.nombre}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  mostrarFormularioEdicion(figura);
                },
                child: Text('Editar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  eliminarFigura(figura.id!);
                },
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void mostrarFormularioEdicion(Figura figura) {
    final serieController = TextEditingController(text: figura.serie);
    final tipoController = TextEditingController(text: figura.tipo);
    final nombreController = TextEditingController(text: figura.nombre);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Editar Figura'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: serieController,
                    decoration: InputDecoration(labelText: 'Serie'),
                  ),
                  TextField(
                    controller: tipoController,
                    decoration: InputDecoration(labelText: 'Tipo'),
                  ),
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(labelText: 'Nombre'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  await database.update(
                    'figuras',
                    {
                      'serie': serieController.text,
                      'tipo': tipoController.text,
                      'nombre': nombreController.text,
                    },
                    where: 'id = ?',
                    whereArgs: [figura.id],
                  );
                  Navigator.pop(context);
                  fetchFiguras();
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Todas las Figuras')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: serieSeleccionada,
              decoration: InputDecoration(
                labelText: 'Filtrar por serie',
                border: OutlineInputBorder(),
              ),
              items:
                  seriesDisponibles.keys
                      .map(
                        (serie) =>
                            DropdownMenuItem(value: serie, child: Text(serie)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  serieSeleccionada = value!;
                  aplicarFiltro(filtroController.text);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: filtroController,
              decoration: InputDecoration(
                labelText: 'Filtrar por nombre, serie o tipo',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: aplicarFiltro,
            ),
          ),
          Expanded(
            child:
                figurasFiltradas.isEmpty
                    ? Center(child: Text('No hay figuras guardadas'))
                    : ListView.builder(
                      itemCount: figurasFiltradas.length,
                      itemBuilder: (context, index) {
                        final figura = figurasFiltradas[index];
                        return ListTile(
                          leading: GestureDetector(
                            onTap: () => mostrarDetalles(figura),
                            child: Image.file(
                              File(figura.imagenPath),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(figura.nombre),
                          subtitle: Text('${figura.serie} - ${figura.tipo}'),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
