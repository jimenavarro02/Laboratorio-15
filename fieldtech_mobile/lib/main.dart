// lib/main.dart
import 'package:flutter/material.dart';

import 'screens/incidencias_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FieldTechApp());
}

class FieldTechApp extends StatelessWidget {
  const FieldTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldTech Móvil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
      ),
      home: const IncidenciasScreen(),
    );
  }
}
