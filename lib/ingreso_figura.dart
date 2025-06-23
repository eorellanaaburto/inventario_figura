import 'dart:io';
import 'package:flutter/material.dart';
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
  final picker = ImagePicker();
  final tipoController = TextEditingController();
  final nombreController = TextEditingController();
  String? selectedSerie;
  String? selectedSubSerie;
  File? _imagen;

  final List<String> nombresPersonajes = [
    'Goku',
    'Bulma',
    'Krilin',
    'Yamcha',
    'TenShinHan',
    'Chaoz',
    'MaestroRoshi',
    'Oolong',
    'Puar',
    'Lunch',
    'TortugaMar',
    'MaestroKarin',
    'ShenLong',
    'UranaiBaba',
    'OxSatán',
    'Upa',
    'Bora',
    'Pilaf',
    'Mai',
    'Shu',
    'Tao Pai Pai',
    'General Blue',
    'Comandante Red',
    'Sargento Metallic',
    'Ninja Púrpura',
    'Abuelo Gohan',
    'Raditz',
    'Nappa',
    'Vegeta',
    'Gohan',
    'Piccoro',
    'Yajirobe',
    'Kami-sama',
    'Mr.Popo',
    'Kaio-samadelNorte',
    'Bubbles',
    'Gregory',
    'Saibaiman',
    'Freezer',
    'ReyCold',
    'Zaabon',
    'Dodoria',
    'Kiwi',
    'Malaka',
    'Appole',
    'Banan',
    'Chopsui',
    'Orlen',
    'Blueberry',
    'Raspberry',
    'Soldado Litt',
    'Ginyu',
    'Rikum',
    'Butter',
    'Jis',
    'Gurdo',
    'Gran Patriarca',
    'Porunga',
    'Muri',
    'Nail',
    'Tsuno',
    'Cargo',
    'Garlick Jr.',
    'Spice',
    'Vinegar',
    'Mustard',
    'Salt',
    'Androide N° 20 - Dr. Gero',
    'Androide N° 19',
    'Androide N° 18',
    'Androide N° 17',
    'Androide N° 16',
    'Cell',
    'Cell Jr.',
    'Trunks del futuro',
    'Gohan del futuro',
    'Androide N° 18 del futuro',
    'Androide N° 17 del futuro',
    'Bulma del futuro',
    'Kaio-shin',
    'Supremo Kaio-sama del Este',
    'Kibito',
    'Kaioshin Anciano',
    'MajinBuu / Mr.Buu',
    'Majin Buu malvado',
    'Super Majin Buu',
    'Majin Buu original',
    'Babidi',
    'Dabura',
    'Spopovich',
    'Yam',
    'PuiPui',
    'Yakon',
    'Vegetto',
    'Gotenks',
    'Trunks',
    'Goten',
    'Videl',
    'Mr.Satán',
    'Pan',
    'Bura',
    'Uub',
    'Dr. Myuu',
    'Baby',
    'Super Androide 17',
    'Li Shenlong',
    'Nuova Shenlong',
    'Eis Shenlong',
    'Bills',
    'Whis',
    'Zeno',
    'Champa',
    'Vados',
    'Hit',
    'Jiren',
    'Toppo',
    'Kale',
    'Caulifla',
    'Cabba',
    'Zamasu',
    'Black Goku',
    'Fused Zamasu',
    'Mai del futuro',
    'Daishinkan',
    'Moro',
    'Merus',
    'Granola',
    'Heeter',
    'Elec',
    'Gas',
    'Oil',
    'Maki',
    'Broly (Super)',
    'Cheelai',
    'Lemo',
    'Goku (niño)',
    'Vegeta (niño)',
    'Piccolo (niño)',
    'Bulma (niña)',
    'Kaiosama del Norte (niño)',
    'Dende (niño)',
    'Mr. Satan (niño)',
    'Krilin (niño)',
    'Yamcha (niño)',
    'Goten (niño)',
    'Trunks (niño)',
    'Gohan (niño)',
    'Chi-Chi (niña)',
    'Maestro Roshi (niño)',
    'Oolong (niño)',
    'Puar (niño)',
    'Shenron (mini)',
    'TortugaMar (mini)',
    'Maestro Karin (niño)',
    'Glorio',
    'Panzy',
    'Dr. Arinsu',
    'Gomah',
    'Degesu',
    'Majin Buu (mini)',
    'Majin Kuu',
    'Majin Duu',
    'Marba',
  ];

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

  final List<String> tiposFigura = [
    'Gashapon',
    'SHFiguarts',
    'Figuras de Banpresto',
    'Figuras de colección',
  ];
  String? selectedTipo;
  @override
  void initState() {
    super.initState();
    initDb();
  }

  Future<void> initDb() async {
    final dbPath = await getDatabasesPath();
    database = await openDatabase(
      path.join(dbPath, 'figuras.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE figuras(id INTEGER PRIMARY KEY, serie TEXT, tipo TEXT, nombre TEXT, imagenPath TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(pickedFile.path);
    final savedImage = await File(
      pickedFile.path,
    ).copy('${appDir.path}/$fileName');

    setState(() {
      _imagen = savedImage;
    });
  }

  Future<void> guardarFigura() async {
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

    final nombreIngresado = nombreController.text.trim().toLowerCase();
    final List<Map<String, dynamic>> maps = await database.query('figuras');

    final similares =
        maps
            .where(
              (map) =>
                  (map['nombre'] as String).trim().toLowerCase() ==
                  nombreIngresado,
            )
            .toList();

    if (similares.isNotEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Figuras con nombre similar'),
              content: SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: similares.length,
                  itemBuilder: (context, index) {
                    final figura = Figura.fromMap(similares[index]);
                    return ListTile(
                      leading: Image.file(
                        File(figura.imagenPath),
                        width: 40,
                        height: 40,
                      ),
                      title: Text(figura.nombre),
                      subtitle: Text(figura.serie),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await guardarNuevaFigura();
                  },
                  child: Text('Guardar de todas formas'),
                ),
              ],
            ),
      );
    } else {
      await guardarNuevaFigura();
    }
  }

  Future<void> guardarNuevaFigura() async {
    final serieFinal =
        series[selectedSerie]!.isEmpty
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Figura guardada exitosamente.')));
  }

  void mostrarImagenCompleta(String imagePath) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
          ),
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
              items:
                  series.keys
                      .map(
                        (serie) =>
                            DropdownMenuItem(value: serie, child: Text(serie)),
                      )
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
                items:
                    series[selectedSerie]!
                        .map(
                          (sub) =>
                              DropdownMenuItem(value: sub, child: Text(sub)),
                        )
                        .toList(),
                decoration: InputDecoration(labelText: 'Subserie'),
                onChanged: (value) {
                  setState(() {
                    selectedSubSerie = value;
                  });
                },
              ),
            DropdownButtonFormField<String>(
              value: selectedTipo,
              items:
                  tiposFigura
                      .map(
                        (tipo) =>
                            DropdownMenuItem(value: tipo, child: Text(tipo)),
                      )
                      .toList(),
              decoration: InputDecoration(labelText: 'Tipo'),
              onChanged: (value) {
                setState(() {
                  selectedTipo = value;
                  tipoController.text = value!;
                });
              },
            ),

            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return nombresPersonajes.where((String option) {
                  return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (String selection) {
                nombreController.text = selection;
              },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onEditingComplete,
              ) {
                controller.text = nombreController.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(labelText: 'Nombre'),
                  onEditingComplete: onEditingComplete,
                );
              },
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
                ElevatedButton(
                  onPressed: guardarFigura,
                  child: Text('Guardar Figura'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
