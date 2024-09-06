import 'package:flutter/material.dart';

class AddContentPage extends StatelessWidget {
  const AddContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Content'),
      ),
      body: const Center(
        child: Text('Add new content here'),
      ),
    );
  }
}
