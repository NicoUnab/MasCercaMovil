import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'dart:convert';

class ReportePage extends StatefulWidget {
  final Map<String, dynamic> userData; // Información del usuario
  final Map<String, dynamic> reporte; // ID del reporte seleccionado
  final List<int> notificacionIds; // Lista de IDs de notificaciones relacionadas

  const ReportePage({super.key, required this.userData, required this.reporte, required this.notificacionIds});

  @override
  _ReportePageState createState() => _ReportePageState();
}

class _ReportePageState extends State<ReportePage> {
  Map<String, dynamic>? reporteData;

  @override
  void initState() {
    super.initState();
    reporteData = widget.reporte; // Asignar reporte directamente
    _marcarNotificacionesComoLeidas(); // Marcar notificaciones como leídas
  } 

  Future<void> _marcarNotificacionesComoLeidas() async {
    try {
      for (int notificacionId in widget.notificacionIds) {
        final response = await http.post(
          Uri.parse('http://localhost:7780/GestionNotificaciones/api/Notificaciones/$notificacionId/marcar-leida'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.userData['token']}', // Agregar token
          },
        );

        if (response.statusCode != 200) {
          print('Error al marcar notificación $notificacionId como leída');
        }
      }
    } catch (e) {
      print('Error de conexión al marcar notificaciones como leídas: $e');
    }
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return "${fecha.day}-${fecha.month}-${fecha.year}";
    } catch (e) {
      return fechaIso; // Devuelve la fecha original si hay un error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent,
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        backgroundColor: Colors.teal,
      ),
      body: reporteData == null
          ? const Center(child: Text('No se pudo cargar el reporte'))
          : Scrollbar(
              thumbVisibility: true, // Visibilidad de la barra de desplazamiento
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado
                      const Text(
                        'Estado:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: TextEditingController(text: reporteData?['estado']?['nombre']),
                        readOnly: true,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dirección
                      const Text(
                        'Dirección:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: TextEditingController(text: reporteData?['direccion']),
                        readOnly: true,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Fecha de creación
                      const Text(
                        'Fecha del Reporte:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: TextEditingController(text: _formatearFecha(reporteData?['fechaCreacion'])),
                        readOnly: true,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Descripción
                      const Text(
                        'Descripción:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: TextEditingController(text: reporteData?['descripcion']),
                        readOnly: true,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Historial
                      const Text(
                        'Historial:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (reporteData?['historialReportes'] != null &&
                          (reporteData?['historialReportes'] as List).isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true, // Para que se use dentro del ScrollView
                          physics: const NeverScrollableScrollPhysics(), // Evita el desplazamiento interno
                          itemCount: (reporteData?['historialReportes'] as List).length,
                          itemBuilder: (context, index) {
                            final historial = reporteData?['historialReportes'][index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha: ${_formatearFecha(historial?['fecha'])}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Observación: ${historial?['observacion'] ?? "Sin observación"}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Funcionario: ${historial?['funcionario'] ?? "Sin funcionario"}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else
                        const Center(
                          child: Text(
                            'No hay historial disponible',
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Botón Volver
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          ),
                          child: const Text('Volver', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}