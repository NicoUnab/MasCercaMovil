import 'package:flutter/material.dart';
import 'login_page.dart';
import 'registrar_page.dart';
import 'contrasena_olvidada_page.dart';
import 'home_page.dart';
import 'lista_reportes_page.dart';
import 'reporte_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MasCerca',
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/registrar':
            return MaterialPageRoute(builder: (context) => RegistrarPage());
          case '/contrasenaOlvidada':
            return MaterialPageRoute(builder: (context) => ContrasenaOlvidadaPage());
          case '/home':
            if (settings.arguments is Map<String, dynamic>) {
              final userData = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(builder: (context) => HomePage(userData: userData));
            }
            return MaterialPageRoute(builder: (context) => LoginPage()); // Redirige al login si no hay datos
          case '/lista_reportes_page':
            final userData = settings.arguments as Map<String, dynamic>;
            if (settings.arguments is Map<String, dynamic>) {              
              return MaterialPageRoute(builder: (context) => ListaReportesPage(userData: userData));
            }
            return MaterialPageRoute(builder: (context) => HomePage(userData: userData));
          case '/reporte':
            final userData = settings.arguments as Map<String, dynamic>;
            if (settings.arguments is Map<String, dynamic>) {              
              final reporte = settings.arguments as Map<String, dynamic>;
              final notificaciones = settings.arguments as List<int>;
              return MaterialPageRoute(builder: (context) => ReportePage(userData: userData, reporte: reporte, notificacionIds: notificaciones,));
            }
            return MaterialPageRoute(builder: (context) => ListaReportesPage(userData: userData));
          default:
            return MaterialPageRoute(builder: (context) => LoginPage());
        }
      },
    );
  }
}
