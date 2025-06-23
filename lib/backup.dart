import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';

class BackupPage extends StatefulWidget {
  @override
  _BackupPageState createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  String? status;
  bool cargando = false;
  double progreso = 0;
  String? zipPath;

  Future<void> crearBackup() async {
    setState(() {
      cargando = true;
      progreso = 0;
      status = 'Creando backup...';
    });

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(await getDatabasesPath(), 'figuras.db'));
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        setState(() {
          cargando = false;
          status = 'No se pudo acceder al almacenamiento externo.';
        });
        return;
      }

      final backupDir = Directory(p.join(externalDir.path, 'backups'));
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }
      zipPath = p.join(backupDir.path, 'figuras_backup.zip');

      final encoder = ZipFileEncoder();
      encoder.create(zipPath!);

      final archivos = <File>[];
      if (dbFile.existsSync()) archivos.add(dbFile);
      final files = docDir.listSync();
      for (var file in files) {
        if (file is File && p.extension(file.path).toLowerCase() == '.jpg') {
          archivos.add(file);
        }
      }

      for (int i = 0; i < archivos.length; i++) {
        encoder.addFile(archivos[i]);
        setState(() => progreso = (i + 1) / archivos.length);
        await Future.delayed(Duration(milliseconds: 100));
      }

      encoder.close();

      // Copiar a carpeta pública de Descargas
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (downloadsDir.existsSync()) {
        final destino = File(p.join(downloadsDir.path, 'figuras_backup.zip'));
        await File(zipPath!).copy(destino.path);
      }

      setState(() {
        cargando = false;
        status = 'Backup guardado en: $zipPath (y copiado a Descargas)';
        progreso = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup creado y copiado a Descargas')),
      );
    } catch (e) {
      setState(() {
        cargando = false;
        progreso = 0;
        status = 'Error al crear backup: $e';
      });
    }
  }

  Future<void> restaurarBackup() async {
    setState(() {
      cargando = true;
      progreso = 0;
      status = 'Seleccionando archivo...';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null) {
        setState(() {
          cargando = false;
          status = 'Restauración cancelada.';
        });
        return;
      }

      final zipFile = File(result.files.single.path!);
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();

      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (int i = 0; i < archive.length; i++) {
        final file = archive[i];
        final filename = file.name;
        final isDatabase = filename.endsWith('.db');
        final outputPath =
            isDatabase
                ? p.join(dbPath, 'figuras.db')
                : p.join(docDir.path, filename);

        final outFile = File(outputPath);
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);

        setState(() => progreso = (i + 1) / archive.length);
        await Future.delayed(Duration(milliseconds: 100));
      }

      setState(() {
        cargando = false;
        progreso = 0;
        status = 'Backup restaurado correctamente.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup restaurado correctamente')),
      );
    } catch (e) {
      setState(() {
        cargando = false;
        progreso = 0;
        status = 'Error al restaurar backup: $e';
      });
    }
  }

  void compartirBackup() {
    if (zipPath != null && File(zipPath!).existsSync()) {
      Share.shareXFiles([
        XFile(zipPath!),
      ], text: 'Aquí está mi backup de figuras.');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Primero debes crear un backup.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = (progreso * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: Text('Backup & Restaurar')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: cargando ? null : crearBackup,
              icon: Icon(Icons.backup),
              label: Text('Crear Backup'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: cargando ? null : restaurarBackup,
              icon: Icon(Icons.restore),
              label: Text('Restaurar desde ZIP'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: compartirBackup,
              icon: Icon(Icons.share),
              label: Text('Compartir Backup'),
            ),
            SizedBox(height: 30),
            if (cargando)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: progreso,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$porcentaje%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            if (!cargando && status != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(status!, style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
