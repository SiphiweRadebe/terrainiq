import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const TerrainIQApp());
}

class TerrainIQApp extends StatelessWidget {
  const TerrainIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1923),
      ),
      home: const MapScreen(),
    );
  }
}

