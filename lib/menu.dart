import 'package:flutter/material.dart';
import 'package:inventario_figuras/backup.dart';
import 'package:inventario_figuras/ingreso_figura.dart';
import 'package:inventario_figuras/listar_todas.dart';

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/fondo_2.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)), // filtro oscuro para contraste
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _animeButton(
                    context,
                    text: 'Ingresar Figura',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => IngresarFiguraPage()),
                    ),
                  ),
                  SizedBox(height: 30),
                  _animeButton(
                    context,
                    text: 'Ver Todas las Figuras',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ListarTodasPage()),
                    ),
                  ),
                                    SizedBox(height: 30),
                 _animeButton(
  context,
  text: 'Backup y Restaurar',
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BackupPage()),
  ),
),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animeButton(BuildContext context,
      {required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orangeAccent.shade700,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 36),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // Puedes usar una fuente tipo anime si la incluyes
        ),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
