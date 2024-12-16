import 'dart:io' show File, Platform;
import 'dart:html' as html; // Solo para Flutter Web
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mas_cerca_movil/lista_reportes_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData; // Datos del usuario

  const HomePage({super.key, required this.userData});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MapController _mapController;
  LatLng? currentLocation;
  LatLng? selectedLocation;
  String? selectedAddress; // Dirección seleccionada o ingresada
  bool isManualAddressEnabled = false;
  List<Map<String, dynamic>> reportTypes = []; // Cambia a lista de mapas
  int? selectedReportType;
  TextEditingController addressController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  bool _isLoading = false;
  bool _isDropdownLoading = true; // Indicador para cargar el dropdown
  late String userName;
  late int userId;
  late String token;
  dynamic _selectedImage; // Imagen seleccionada desde la cámara
  bool notificacion = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadCurrentLocation();
    _tiposReporte();
    userName = widget.userData['usuario']['nombre'];
    userId = widget.userData['usuario']['id'];
    token = widget.userData['token'];
    _validaNotificaciones();
  }

  //VERIFICAR SI HAY NOTIFICACIONES NO LEIDAS
  Future<void> _validaNotificaciones() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:7780/GestionNotificaciones/api/Notificaciones/vecino/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Agregar token al encabezado
        },
      );

      if (response.statusCode == 200) {
        final bool hasUnread = jsonDecode(response.body) as bool;
        setState(() {
          notificacion = hasUnread;
        });
      } else {
        print('Error al verificar notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión al verificar notificaciones: $e');
    }
  }

  // Obtener ubicación en tiempo real
  Future<void> _loadCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    LocationData locationData = await location.getLocation();
    setState(() {
      currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      selectedLocation = currentLocation;
    });
  }

  // Consumir la API para obtener tipos de reporte
  Future<void> _tiposReporte() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:7780/Mantenedor/api/Mantenedor/tipos-reporte'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          reportTypes = data.map((item) {
            return {
              'id': item['id'], // Asume que el ID se llama "id" en el JSON
              'nombre': item['nombre'], // Asume que el nombre se llama "nombre" en el JSON
            };
          }).toList();
          _isDropdownLoading = false; // Indicar que se completó la carga
        });
      } else {
        _showError('Error al cargar tipos de reporte');
      }
    } catch (e) {
      _showError('Error de conexión al cargar tipos de reporte');
    }
  }

  // Capturar la dirección seleccionada o ingresada
  Future<String?> _captureAddress() async {
    if (isManualAddressEnabled && addressController.text.isNotEmpty) {
      return addressController.text; // Usar la dirección ingresada
    } else if (selectedLocation != null) {
      return await _reverseGeocode(selectedLocation!); // Obtener dirección desde coordenadas
    }
    _showError('Por favor, selecciona o ingresa una dirección válida');
    return null;
  }

  // Función para obtener una dirección a partir de coordenadas (Reverse Geocoding)
  Future<String?> _reverseGeocode(LatLng location) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] as String?;
      } else {
        _showError('Error al obtener la dirección');
        return null;
      }
    } catch (e) {
      _showError('Error al procesar la dirección');
      return null;
    }
  }

  // Seleccionar imagen desde la cámara
  Future<void> _takePhoto({bool fromCamera = true}) async {
    if (kIsWeb) {
      // En Web, usamos un selector de archivos
      _selectedImage = await _pickImageWeb();
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // En móviles/escritorio, usamos ImagePicker
      _selectedImage = await _pickImageMobileOrDesktop(fromCamera: fromCamera);
    } else {
      print('Plataforma no soportada');
      return;
    }
    
  }
  /// Método para Web
  Future<html.File?> _pickImageWeb() async {
    final completer = Completer<html.File?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((event) {
      if (input.files!.isNotEmpty) {
        completer.complete(input.files!.first);
      } else {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Método para móviles/escritorio
  Future<File?> _pickImageMobileOrDesktop({bool fromCamera = true}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  /// Subir imagen detectando la plataforma
  Future<int?> _uploadImage(dynamic image) async {
  try {
    if (kIsWeb) {
      if (image is html.File) {
        final id = await uploadImageWeb(image); // Llama a la función para Web
        print('ID del documento retornado desde uploadImageWeb: $id');
        return id;
      } else {
        print('Error: Tipo de archivo no compatible con Web');
        return null;
      }
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final id = await uploadImageMobileOrDesktop(image);
      print('ID del documento retornado desde uploadImageMobileOrDesktop: $id');
      return id;
    } else {
      print('Plataforma no soportada');
      return null;
    }
  } catch (e) {
    print('Error al subir la imagen: $e');
    return null;
  }
}


  /// Método para subir imágenes en Flutter Web
  Future<int?> uploadImageWeb(html.File image) async {
    try {
      final uri = Uri.parse('http://localhost:7780/GestionReportes/api/Reporte/subir-documento');

      // Crear un formulario con el archivo
      final formData = html.FormData();
      formData.appendBlob('archivo', image, image.name);

      // Crear y enviar la solicitud HTTP
      final xhr = html.HttpRequest();
      xhr.open('POST', uri.toString());

      // Configurar la respuesta como texto para depuración inicial
      xhr.responseType = 'text'; 

      // Agregar encabezado para aceptar JSON
      xhr.setRequestHeader('Accept', 'application/json');

      // Crear un completer para manejar el flujo asíncrono
      final completer = Completer<int?>();

      // Escuchar cuando la solicitud se carga
      xhr.onLoad.listen((event) {
        print('Estado de la solicitud: ${xhr.status}');
        if (xhr.status == 200) {
          print('Respuesta cruda del servidor: ${xhr.responseText}');
          try {
            // Decodificar la respuesta como JSON
            final responseJson = jsonDecode(xhr.responseText ?? '');
            print('Respuesta JSON parseada: $responseJson');
            if (responseJson is Map<String, dynamic> && responseJson.containsKey('documentoId')) {
              final documentoId = int.tryParse(responseJson['documentoId'].toString());
              print('DocumentoId obtenido: $documentoId');
              completer.complete(documentoId);
            } else {
              print('Error: La respuesta no contiene "documentoId" o no es un Map<String, dynamic>');
              completer.complete(null);
            }
          } catch (e) {
            print('Error al interpretar la respuesta como JSON: $e');
            completer.complete(null);
          }
        } else {
          print('Error al subir la imagen. Código de estado: ${xhr.status}');
          print('Texto del error: ${xhr.statusText}');
          completer.complete(null);
        }
      });

      // Escuchar errores en la solicitud
      xhr.onError.listen((event) {
        print('Error en la solicitud. Mensaje: ${xhr.statusText}');
        completer.complete(null);
      });

      // Enviar la solicitud con el formulario
      print('Enviando la solicitud...');
      xhr.send(formData);

      // Retornar el resultado del completer
      return completer.future;
    } catch (e) {
      print('Error general al subir la imagen en Web: $e');
      return null;
    }
  }

  /// Método para subir imágenes en Móvil o Escritorio
  Future<int?> uploadImageMobileOrDesktop(File image) async {
    try {
      final uri = Uri.parse('http://localhost:7780/GestionReportes/api/Reporte/subir-documento');
      final request = http.MultipartRequest('POST', uri);

      // Adjuntar el archivo a la solicitud
      request.files.add(
        http.MultipartFile.fromBytes(
          'archivo',
          await image.readAsBytes(),
          filename: image.path.split('/').last,
        ),
      );

      // Enviar la solicitud
      final response = await request.send();

      // Manejar la respuesta
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> json = jsonDecode(responseData);
        return json['DocumentoId']; // Devolver el ID del documento
      } else {
        print('Error al subir la imagen. Código: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al subir la imagen en Móvil/Escritorio: $e');
      return null;
    }
  }


  // Registrar reporte
  Future<void> _registrarReporte() async {
    final address = await _captureAddress();
    if (address == null || selectedReportType == null) return;

    int? documentoId;
    if (_selectedImage != null) {
      documentoId = await _uploadImage(_selectedImage!);
      if (documentoId == null) {
        _showError('Error al subir la imagen');
        return;
      }
    }

    final reportData = {
      'Ubicacion': address,
      'TipoId': selectedReportType,
      'Descripcion': messageController.text,
      'Imagen': documentoId ?? 0,//se debe llamar el endpoint que subira el documento
      'VecinoId' :userId //se debe colocar el id del vecino que este conectado
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:7780/GestionReportes/api/Reporte/crear-reporte'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Incluye el token aquí
        },
        body: jsonEncode(reportData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte registrado exitosamente')),
        );
        setState(() {
        _selectedImage = null; // Limpiar imagen seleccionada
        messageController.clear(); // Limpiar el mensaje
        addressController.clear(); // Limpiar la dirección
      });
      } else {
        _showError('Error al registrar el reporte');
      }
    } catch (e) {
      _showError('Error de conexión con el servidor');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mostrar un mensaje de error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent,
      body: Stack(
        children: [
          Scrollbar( // Barra de desplazamiento
            thumbVisibility: true, // Hace visible la barra de desplazamiento
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Contenedor del mapa con el botón de cámara flotante dentro
                  Stack(
                    children: [
                      SizedBox(
                        height: 400,
                        child: currentLocation == null
                            ? const Center(child: CircularProgressIndicator())
                            : FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  center: currentLocation,
                                  zoom: 15.0,
                                  onTap: (tapPosition, point) async {
                                    setState(() {
                                      selectedLocation = point;
                                    });
                                    selectedAddress = await _reverseGeocode(point);
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    subdomains: const ['a', 'b', 'c'],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      if (selectedLocation != null)
                                        Marker(
                                          point: selectedLocation!,
                                          builder: (ctx) => const Icon(
                                            Icons.location_pin,
                                            size: 40,
                                            color: Colors.red,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      // Botón de cámara en la esquina inferior derecha del mapa
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _takePhoto,
                          child: const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.camera_alt, size: 30, color: Colors.teal),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Formulario debajo del mapa
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => setState(() {
                                  isManualAddressEnabled = !isManualAddressEnabled;
                                }),
                                child: const Text('¿Te es complejo usar el mapa? Escribe la dirección'),
                              ),
                            ),
                          ],
                        ),
                        if (isManualAddressEnabled)
                          TextField(
                            controller: addressController,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        const SizedBox(height: 10),
                        _isDropdownLoading
                            ? const Center(child: CircularProgressIndicator()) // Indicador de carga
                            : DropdownButtonFormField<int>(
                                value: selectedReportType,
                                items: reportTypes.map((type) {
                                  return DropdownMenuItem<int>(
                                    value: type['id'], // Usa el ID como valor,
                                    child: Text(type['nombre']), // Muestra el nombre en el menú
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedReportType = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: '¿Qué tipo de reporte quiere realizar?',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Mensaje',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _registrarReporte,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Registrar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón de notificaciones flotando en la parte superior derecha de la pantalla
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                // Navegar a la página de lista de reportes
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListaReportesPage(userData: widget.userData),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(Icons.notifications, color: notificacion ? Colors.red : Colors.teal),
              ),
            ),
          ),
        ],
      ),
    );
  }

}