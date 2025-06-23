import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serie': serie,
      'tipo': tipo,
      'nombre': nombre,
      'imagenPath': imagenPath,
    };
  }

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

class IngresarFiguraPage extends StatefulWidget {
  @override
  _IngresarFiguraPageState createState() => _IngresarFiguraPageState();
}

class _IngresarFiguraPageState extends State<IngresarFiguraPage> {
  late Database database;
  bool dbInicializada = false;
  final picker = ImagePicker();
  final tipoController = TextEditingController();
  final nombreController = TextEditingController();
  String? selectedSerie;
  String? selectedSubSerie;
  File? _imagen;

  final Map<String, List<String>> series = {
    'Dragonball': [
      'Saga de Pilaf',
      '21° Torneo de las Artes Marciales',
      'Saga de la Patrulla Roja',
      'El Palacio de Uranai Baba',
      '22° Torneo de las Artes Marciales',
      'Saga de Piccolo Daimaku',
      '23° Torneo de las Artes Marciales',
    ],
    'Dragonball Z': [
      'Saga Sayajin',
      'Saga de Freezer',
      'Saga de Garlick Jr.',
      'Saga de Cell',
      'Saga de Majin Buu',
    ],
    'Dragonball Super': [
      'La Batalla de los Dioses de la destrucción',
      'La resurrección de Freezer',
      'El Universo 6 y 7',
      'Trunks del "Futuro" Saga de Goku Black',
      'El Torneo del "Poder"',
    ],
    'Dragonball Daima': [],
    'Dragonball GT': [
      'El Gran Viaje',
      'Saga de Baby',
      'Saga de Súper N.°17',
      'Saga de los Dragones Oscuros',
    ],
  };

  @override
  void initState() {
    super.initState();
    initDb();
  }

  Future<void> initDb() async {
    final dbPath = await getDatabasesPath();
    database = await openDatabase(
      path.join(dbPath, 'figuras.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE figuras(id INTEGER PRIMARY KEY, serie TEXT, tipo TEXT, nombre TEXT, imagenPath TEXT)',
        );
      },
    );
    dbInicializada = true;
  }

  Future<void> pickImage() async {
    if (!dbInicializada) return;
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

    setState(() {
      _imagen = savedImage;
    });

    await compararImagenes(savedImage);
  }

  Future<void> compararImagenes(File nuevaImagen) async {
    if (!dbInicializada) return;
    final List<Map<String, dynamic>> maps = await database.query('figuras');
    final img1 = img.decodeImage(await nuevaImagen.readAsBytes());
    if (img1 == null) return;

    List<Figura> similares = [];
    for (var map in maps) {
      final pathImagen = map['imagenPath'] as String;
      final oldFile = File(pathImagen);
      if (!oldFile.existsSync()) continue;

      final img2 = img.decodeImage(await oldFile.readAsBytes());
      if (img2 == null) continue;

      final similarity = compararPixelAPixel(img1, img2);
      if (similarity < 1000) {
        similares.add(Figura.fromMap(map));
      }
    }

    if (similares.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Figuras similares encontradas'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: similares.length,
              itemBuilder: (context, index) {
                final figura = similares[index];
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => mostrarImagenCompleta(figura.imagenPath),
                    child: Image.file(File(figura.imagenPath), width: 40, height: 40),
                  ),
                  title: Text(figura.nombre),
                  subtitle: Text(figura.serie),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _imagen = null);
              },
              child: Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                final camposCompletos = _imagen != null &&
                    selectedSerie != null &&
                    (series[selectedSerie]!.isEmpty || selectedSubSerie != null) &&
                    tipoController.text.isNotEmpty &&
                    nombreController.text.isNotEmpty;

                if (!camposCompletos) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Completa todos los campos antes de guardar.')),
                  );
                  return;
                }

                Navigator.pop(context);
                await guardarFigura();
              },
              child: Text('Guardar Figura'),
            ),
          ],
        ),
      );
    }
  }

  int compararPixelAPixel(img.Image img1, img.Image img2) {
    final w = img1.width < img2.width ? img1.width : img2.width;
    final h = img1.height < img2.height ? img1.height : img2.height;

    int diff = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p1 = img1.getPixel(x, y);
        final p2 = img2.getPixel(x, y);
        diff += (img.getLuminance(p1) - img.getLuminance(p2)).abs().toInt();
      }
    }
    return diff ~/ (w * h);
  }

  void mostrarImagenCompleta(String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> guardarFigura() async {
    if (!dbInicializada) return;
    if (_imagen == null ||
        selectedSerie == null ||
        (series[selectedSerie]!.isNotEmpty && selectedSubSerie == null) ||
        tipoController.text.trim().isEmpty ||
        nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa todos los campos y toma una foto.')),
      );
      return;
    }

    final serieFinal = series[selectedSerie]!.isEmpty
        ? selectedSerie!
        : '$selectedSerie - $selectedSubSerie';

    await database.insert('figuras', {
      'serie': serieFinal,
      'tipo': tipoController.text.trim(),
      'nombre': nombreController.text.trim(),
      'imagenPath': _imagen!.path,
    });

    setState(() {
      selectedSerie = null;
      selectedSubSerie = null;
      tipoController.clear();
      nombreController.clear();
      _imagen = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Figura guardada exitosamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar Figura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedSerie,
              items: series.keys
                  .map((serie) => DropdownMenuItem(value: serie, child: Text(serie)))
                  .toList(),
              decoration: InputDecoration(labelText: 'Serie'),
              onChanged: (value) {
                setState(() {
                  selectedSerie = value;
                  selectedSubSerie = null;
                });
              },
            ),
            if (selectedSerie != null && series[selectedSerie]!.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedSubSerie,
                items: series[selectedSerie]!
                    .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                    .toList(),
                decoration: InputDecoration(labelText: 'Subserie'),
                onChanged: (value) {
                  setState(() {
                    selectedSubSerie = value;
                  });
                },
              ),
            TextField(
              controller: tipoController,
              decoration: InputDecoration(labelText: 'Tipo'),
            ),
            TextField(
              controller: nombreController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            SizedBox(height: 10),
            _imagen != null
                ? Image.file(_imagen!, height: 200)
                : Text('No se ha tomado ninguna foto'),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: pickImage, child: Text('Tomar Foto')),
                ElevatedButton(onPressed: guardarFigura, child: Text('Guardar Figura')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
