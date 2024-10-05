import 'package:flutter/material.dart';

class YoloImageScreen extends StatefulWidget {
  const YoloImageScreen({super.key});

  @override
  State<YoloImageScreen> createState() => _YoloImageScreenState();
}

class _YoloImageScreenState extends State<YoloImageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Yolo Static Image'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Pick',
        onPressed: () {},
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
