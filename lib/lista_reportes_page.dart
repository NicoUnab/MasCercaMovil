import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mas_cerca_movil/reporte_page.dart';
import 'package:mas_cerca_movil/home_page.dart';

class ListaReportesPage extends StatefulWidget {
  final Map<String, dynamic> userData; // Datos del usuario

  const ListaReportesPage({super.key, required this.userData});

  @override
  _ListaReportesPageState createState() => _ListaReportesPageState();
}

class _ListaReportesPageState extends State<ListaReportesPage> {
  List<dynamic> reportes = [];
  Map<int, List<int>> reporteNotificaciones = {}; // IDs de notificaciones por reporte
  Map<int, bool> reporteTieneNoLeidas = {}; // Estado de notificaciones no leídas
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReportes();
  }

  Future<void> _fetchReportes() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:7780/GestionReportes/api/Reporte/lista-reportes?vecinoId=${widget.userData['usuario']['id']}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedReportes = jsonDecode(response.body);

        setState(() {
          reportes = fetchedReportes;
        });

        // Verificar notificaciones para cada reporte
        for (var reporte in fetchedReportes) {
          final int reporteId = reporte['id'];
          _checkNotificaciones(reporteId);
        }
      } else {
        _showError('Error al cargar los reportes.');
      }
    } catch (e) {
      _showError('Error de conexión.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkNotificaciones(int reporteId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:7780/GestionNotificaciones/api/Notificaciones/reporte/$reporteId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> notificaciones = jsonDecode(response.body);
        // Filtrar IDs de notificaciones no leídas
        final List<int> notificacionIdsNoLeidas = notificaciones
            .where((n) => n['leido'] == false)
            .map<int>((n) => n['id'] as int)
            .toList();

        setState(() {
          reporteNotificaciones[reporteId] = notificacionIdsNoLeidas;
          reporteTieneNoLeidas[reporteId] = notificacionIdsNoLeidas.isNotEmpty;
        });
      } else {
        print('Error al verificar notificaciones para reporte $reporteId.');
      }
    } catch (e) {
      print('Error de conexión al verificar notificaciones: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent,
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: reportes.length,
                    itemBuilder: (context, index) {
                      final reporte = reportes[index];
                      final int reporteId = reporte['id'];
                      final bool tieneNoLeidas =
                          reporteTieneNoLeidas[reporteId] ?? false;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tieneNoLeidas ? Colors.red : Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(
                              'Reporte ${reporte['id']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportePage(
                                    userData: widget.userData,
                                    reporte: reporte,
                                    notificacionIds:
                                        reporteNotificaciones[reporteId] ?? [],
                                  ),
                                ),
                              );
                              // Actualizar estado de notificaciones al regresar
                              await _checkNotificaciones(reporteId);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(userData: widget.userData), // Pasa los datos correctos
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Volver'),
                  ),
                ),
              ],
            ),
    );
  }
}
