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
    // La app seguirá funcionando pero las operaciones CRUD fallarán
    // hasta que se recupere la conexión (ver _ensureConnected).
  }

  // 3. Retirar el splash — Flutter toma el control de la pantalla.
  //    Llamar siempre, incluso si algo falló, para no bloquear la app.
  FlutterNativeSplash.remove();

  runApp(const GamesApp());
}

/// Aplicación principal con inyección de Providers y rutas.
///
/// Observa el ciclo de vida de la app para reconectar a MongoDB y
/// recargar la colección cuando vuelve de background (pantalla apagada,
/// minimizada, o suspendida por el sistema operativo).
class GamesApp extends StatefulWidget {
  const GamesApp({super.key});

  @override
  State<GamesApp> createState() => _GamesAppState();
}

class _GamesAppState extends State<GamesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // La app volvió a primer plano: el socket de MongoDB puede haberse
    // cerrado mientras estaba en background, así que reconectamos y
    // recargamos la colección local antes de que el usuario note nada.
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    try {
      await MongoDatabase().connect();
    } catch (e) {
      log('[App] Error al reconectar tras resume: $e');
    }

    if (!mounted) return;
    // ignore: use_build_context_synchronously
    context.read<CollectionProvider>().fetchLocalGames();
  }

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
