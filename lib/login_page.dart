import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'RutInputFormatter.dart';
import 'package:mas_cerca_movil/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _rutController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Controla si se está cargando la autenticación
  // Valida si el RUT ingresado tiene el formato correcto
  bool validateRut(String rut) {
    // Quitar puntos y guiones
    rut = rut.replaceAll('.', '').replaceAll('-', '');

    if (rut.length < 2) return false;

    // Extraer el dígito verificador y los números
    String body = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1).toUpperCase();

    // Verificar que el cuerpo sean solo números
    if (!RegExp(r'^\d+$').hasMatch(body)) return false;

    // Validar el dígito verificador
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

  // Formatear el RUT en el formato 11.111.111-1
  String formatRut(String rut) {
    // Quitar puntos y guiones
    rut = rut.replaceAll('.', '').replaceAll('-', '');

    if (rut.length < 2) return rut;

    String body = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1);

    // Insertar puntos cada 3 dígitos
    final buffer = StringBuffer();
    for (int i = 0; i < body.length; i++) {
      if (i > 0 && (body.length - i) % 3 == 0) buffer.write('.');
      buffer.write(body[i]);
    }

    return '${buffer.toString()}-$dv';
  }
// Formatear el RUT en el formato 11111111
  String rutLogin(String rut) {
    // Quitar puntos y guiones
    rut = rut.replaceAll('.', '').replaceAll('-', '');

    if (rut.length < 2) return rut;

    String body = rut.substring(0, rut.length - 1);
    
    return body;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent,
      body: Stack(
        children: [
          // Botón "Registrarse"
          Positioned(
            top: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/registrar');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Registrarse'),
            ),
          ),
          // Contenido principal
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Campo de RUT
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
                          inputFormatters: [RutInputFormatter()], // Aplica el formateador
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu RUT';
                            }
                            if (!validateRut(value)) {
                              return 'RUT inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Campo de Contraseña
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Botón de Ingresar
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                  textStyle: const TextStyle(fontSize: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Ingresar'),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Enlace "¿Olvidaste tu Contraseña?"
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/contrasenaOlvidada');
                    },
                    child: const Text(
                      '¿Olvidaste tu Contraseña?',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        fontStyle: FontStyle.italic,
                      ),
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

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Mostrar indicador de carga
      });

      try {
        final rut = rutLogin(_rutController.text);
        final password = _passwordController.text;

        final responseData = await _authenticate(rut, password);

        setState(() {
          _isLoading = false; // Ocultar indicador de carga
        });

        if (responseData != null) {
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userData: responseData),
          ),
        );
        } else {
          _showError('RUT o contraseña incorrectos');
        }
      } catch (e) {
        setState(() {
          _isLoading = false; // Asegurarse de ocultar el indicador en caso de error
        });
        _showError('Error de conexión, inténtelo de nuevo');
      }
    }
  }

  Future<Map<String, dynamic>?> _authenticate(String rut, String password) async {
  final response = await http.post(
    Uri.parse('http://localhost:7780/GestionUsuarios/api/Auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'rut': rut, 'contraseña': password, 'tipoAplicacion': "Movil"}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // Devuelve el JSON completo
  } else {
    return null;
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
