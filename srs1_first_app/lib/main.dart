import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Лабораторная работа 1'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          // Column располагает текст и прямоугольник друг под другом.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Моё первое приложение!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Container(width: 200, height: 100, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
