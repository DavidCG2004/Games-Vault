import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'package:games_vault/core/theme/app_theme.dart';
import 'package:games_vault/core/database/mongo_database.dart';
import 'package:games_vault/features/collection/providers/collection_provider.dart';
import 'package:games_vault/features/api_explorer/providers/api_explorer_provider.dart';
import 'package:games_vault/features/home/home_page.dart';
import 'package:games_vault/features/collection/collection_page.dart';
import 'package:games_vault/features/collection/detail_page.dart';
import 'package:games_vault/features/collection/form_page.dart';
import 'package:games_vault/features/api_explorer/api_explorer_page.dart';
import 'package:games_vault/features/about/about_page.dart';

Future<void> main() async {
  // 1. Inicializar binding y preservar el splash nativo mientras
  //    se completan las inicializaciones asíncronas.
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Inicializar MongoDB
  try {
    await MongoDatabase().connect();
    log('[App] MongoDB conectado exitosamente.');
  } catch (e) {
    log('[App] No se pudo conectar a MongoDB: $e');
    // La app seguirá funcionando pero las operaciones CRUD fallarán.
  }

  // 3. Retirar el splash — Flutter toma el control de la pantalla.
  //    Llamar siempre, incluso si algo falló, para no bloquear la app.
  FlutterNativeSplash.remove();

  runApp(const GamesApp());
}

/// Aplicación principal con inyección de Providers y rutas.
class GamesApp extends StatelessWidget {
  const GamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CollectionProvider()..fetchLocalGames(),
        ),
        ChangeNotifierProvider(
          create: (_) => ApiExplorerProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Games Vault',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/':           (_) => const HomePage(),
          '/collection': (_) => const CollectionPage(),
          '/detail':     (_) => const DetailPage(),
          '/form':       (_) => const FormPage(),
          '/explorer':   (_) => const ApiExplorerPage(),
          '/about':      (_) => const AboutPage(),
        },
      ),
    );
  }
}