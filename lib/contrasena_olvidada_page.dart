import 'package:flutter/material.dart';

class ContrasenaOlvidadaPage extends StatelessWidget {
  const ContrasenaOlvidadaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Contraseña")),
      body: const Center(
        child: Text(
          "Página para Recuperar Contraseña",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
