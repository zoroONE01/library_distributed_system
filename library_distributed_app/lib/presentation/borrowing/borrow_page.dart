import 'package:flutter/material.dart';

class BorrowPage extends StatelessWidget {
  const BorrowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow a Book')),
      body: const Center(child: Text('Borrowing Page')),
    );
  }
}
