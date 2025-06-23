import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

class BuscarFiguraPage extends StatefulWidget {
  @override
  _BuscarFiguraPageState createState() => _BuscarFiguraPageState();
}

class _BuscarFiguraPageState extends State<BuscarFiguraPage> {
  late Database database;
  List<Figura> resultados = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initDb();
  }

  Future<void> initDb() async {
    final dbPath = await getDatabasesPath();
    database = await openDatabase(join(dbPath, 'figuras.db'), version: 1);
  }

  Future<void> buscarFigura(String query) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'figuras',
      where: 'nombre LIKE ?',
      whereArgs: ['%$query%'],
    );
    setState(() {
      resultados = maps.map((map) => Figura.fromMap(map)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar Figura')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => buscarFigura(searchController.text),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: resultados.length,
                itemBuilder: (context, index) {
                  final figura = resultados[index];
                  return ListTile(
                    leading: Image.file(
                      File(figura.imagenPath),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(figura.nombre),
                    subtitle: Text('${figura.serie} - ${figura.tipo}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
