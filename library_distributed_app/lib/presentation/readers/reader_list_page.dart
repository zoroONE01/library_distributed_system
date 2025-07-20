import 'package:flutter/material.dart';

class ReaderListPage extends StatelessWidget {
  const ReaderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Readers')),
      body: const Center(child: Text('List of Readers')),
    );
  }
}
