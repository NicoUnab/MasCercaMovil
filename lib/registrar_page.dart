import 'dart:convert';
import 'package:flutter/material.dart';
import 'RutInputFormatter.dart';
import 'package:http/http.dart' as http;

class RegistrarPage extends StatefulWidget {
  const RegistrarPage({super.key});

  @override
  _RegistrarPageState createState() => _RegistrarPageState();
}

class _RegistrarPageState extends State<RegistrarPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rutController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Método para registrar usuario
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Datos para enviar a la API
    final userData = {
      'rut': onlyRut(_rutController.text),
      'dv': onlyDv(_rutController.text),
      'nombre': _nameController.text,
      'direccion': _addressController.text,
      'telefono': int.parse(_phoneController.text),
      'correo': _emailController.text,
      'contraseña': _passwordController.text,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:7780/GestionUsuarios/api/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado exitosamente')),
        );
        Navigator.pop(context); // Regresar a la página anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión con el servidor')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  //solo rut
  int onlyRut(String rut) {
    // Quitar puntos y guiones
    rut = rut.replaceAll('.', '').replaceAll('-', '');

    if (rut.length < 2) return 0;

    String body = rut.substring(0, rut.length - 1);
    
    // Convertir a entero
    try {
      return int.parse(body);
    } catch (e) {
      throw FormatException('El cuerpo del RUT no es un número válido: $body');
    }
  }
  // Formatear el RUT en el formato 11.111.111-1
  String onlyDv(String rut) {
    // Quitar puntos y guiones
    rut = rut.replaceAll('.', '').replaceAll('-', '');

    if (rut.length < 2) return rut;

    String dv = rut.substring(rut.length - 1);
    
    return dv;
  }
  // Validar el RUT
  bool validateRut(String rut) {
    rut = rut.replaceAll('.', '').replaceAll('-', '');
    if (rut.length < 2) return false;

    String body = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1).toUpperCase();

    if (!RegExp(r'^\d+$').hasMatch(body)) return false;

    int sum = 0;
    int multiplier = 2;
    for (int i = body.length - 1; i >= 0; i--) {
      sum += int.parse(body[i]) * multiplier;
      multiplier = multiplier == 7 ? 2 : multiplier + 1;
    }

    int mod = 11 - (sum % 11);
    String computedDv = mod == 11 ? '0' : (mod == 10 ? 'K' : mod.toString());

    return computedDv == dv;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent,
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingrese su Información',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Campo RUT
                  TextFormField(
                    controller: _rutController,
                    decoration: InputDecoration(
                      hintText: 'RUT',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    inputFormatters: [RutInputFormatter()], // Formateador de RUT
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'El RUT es obligatorio';
                      if (!validateRut(value)) return 'RUT inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTextField('Nombre', _nameController, (value) {
                    if (value == null || value.isEmpty) return 'El nombre es obligatorio';
                    return null;
                  }),
                  const SizedBox(height: 10),
                  _buildTextField('Dirección', _addressController, null),
                  const SizedBox(height: 10),
                  _buildTextField('Teléfono', _phoneController, (value) {
                    if (value == null || value.isEmpty) return 'El teléfono es obligatorio';
                    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Teléfono inválido';
                    return null;
                  }),
                  const SizedBox(height: 10),
                  _buildTextField('Email', _emailController, (value) {
                    if (value == null || value.isEmpty) return 'El email es obligatorio';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email inválido';
                    return null;
                  }),
                  const SizedBox(height: 10),
                  _buildTextField('Contraseña', _passwordController, (value) {
                    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
                    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
                    return null;
                  }, obscureText: true),
                  const SizedBox(height: 10),
                  _buildTextField('Confirmar Contraseña', _confirmPasswordController, (value) {
                    if (value == null || value.isEmpty) return 'Confirme su contraseña';
                    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  }, obscureText: true),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text('Registrar'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método auxiliar para construir campos de texto
  Widget _buildTextField(String hint, TextEditingController controller, String? Function(String?)? validator,
      {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }
}