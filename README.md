# 🎮 Games Vault

Aplicación Flutter para gestionar una colección personal de videojuegos, con exploración de catálogo en tiempo real a través de la API de RAWG. Construida con arquitectura *feature-first*, paleta monocromática minimalista y persistencia en MongoDB.

---

## Tabla de contenidos

- [Características](#características)
- [Capturas](#capturas)
- [Stack técnico](#stack-técnico)
- [Arquitectura](#arquitectura)
- [Sistema de diseño](#sistema-de-diseño)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Decisiones técnicas](#decisiones-técnicas)
- [Roadmap](#roadmap)

---

## Características

**Colección local (CRUD)**
- Alta, edición y eliminación de juegos persistidos en MongoDB
- Búsqueda en tiempo real con debounce
- Filtros dinámicos por categoría y plataforma, generados automáticamente a partir de los datos existentes
- Pull-to-refresh y manejo de estados vacíos diferenciados (colección vacía vs. sin resultados de filtro)

**Explorador RAWG**
- Catálogo de videojuegos consumido desde la [RAWG API](https://rawg.io/apidocs)
- Infinite scrolling con paginación automática
- Búsqueda por nombre con debounce y filtros por género/plataforma vía query params
- Guardado directo de un resultado al catálogo local, con detección de duplicados

**Formulario inteligente**
- Selección de categoría y plataforma mediante dropdowns (sin texto libre)
- Carga de imagen desde galería, persistida en almacenamiento local del dispositivo (sin URLs externas para contenido propio)
- Validación de campos obligatorios

**Detalle de juego**
- `Hero` animation entre lista y detalle
- Imagen adaptable a fuente local (`Image.file`) o remota (`CachedNetworkImage`)
- Limpieza automática del archivo de imagen local al eliminar un juego

**Splash screen e ícono nativos**
- Generados con `flutter_native_splash` y `flutter_launcher_icons`
- Soporte para modo claro/oscuro del sistema operativo

---

## Capturas

| Home | Colección | Explorador | Detalle | Form | Acerca |
|------|-----------|------------|---------|------|--------|
|<img width="251" height="522" alt="WhatsApp Image 2026-06-17 at 11 24 30 PM" src="https://github.com/user-attachments/assets/436fff00-e84d-4685-8d33-114978bcc357" />
| _pendiente_ | _pendiente_ | _pendiente_ |

---

## Stack técnico

| Categoría | Paquete | Uso |
|---|---|---|
| Framework | `flutter` / `dart` | Base de la aplicación |
| State management | `provider` | Inyección de dependencias y manejo de estado reactivo |
| Persistencia | `mongo_dart` | Conexión y operaciones CRUD contra MongoDB |
| Red | `http` | Consumo de la RAWG API |
| Imágenes | `cached_network_image` | Cache de imágenes remotas del catálogo |
| Imágenes | `image_picker` | Selección de imágenes desde galería |
| Imágenes | `path_provider`, `path` | Persistencia de imágenes en almacenamiento local |
| Identificadores | `uuid` | Generación de IDs únicos para juegos creados localmente |
| Splash / íconos | `flutter_native_splash`, `flutter_launcher_icons` | Generación de assets nativos por plataforma |

---

## Arquitectura

El proyecto sigue una organización **feature-first**: el código se agrupa por funcionalidad de negocio en lugar de por tipo de archivo, lo que facilita la escalabilidad y localización de cambios.

```
lib/
 ┣ core/
 ┃ ┣ theme/             → AppColors, AppTheme (tema global)
 ┃ ┣ database/          → MongoDatabase (conexión y queries)
 ┃ ┣ network/           → RawgApiService (cliente HTTP de RAWG)
 ┃ ┗ services/          → ImageService (gestión de imágenes locales)
 ┣ models/              → GameItem (modelo unificado Mongo/RAWG)
 ┣ features/
 ┃ ┣ home/              → Menú principal y navegación
 ┃ ┣ collection/         → CRUD: listado, formulario, detalle
 ┃ ┣ api_explorer/       → Explorador RAWG + infinite scrolling
 ┃ ┗ about/              → Pantalla de créditos
 ┗ main.dart             → Inyección de dependencias, rutas y splash
```

Cada *feature* con estado complejo expone su propio `ChangeNotifier` (`CollectionProvider`, `ApiExplorerProvider`), evitando lógica de negocio dentro de los widgets. Las pantallas (`*Page`) son responsables únicamente de presentación y delegan toda mutación de datos al provider correspondiente.

---

## Sistema de diseño

La interfaz parte de un dark mode con acentos de color y evoluciona hacia una paleta **monocromática minimalista** (blancos, grises, negro), priorizando jerarquía tipográfica y espaciado sobre el color como herramienta de comunicación visual.

```dart
class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface    = Color(0xFFF5F5F5);
  static const Color card       = Color(0xFFFAFAFA);

  static const Color text          = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary  = Color(0xFFAAAAAA);

  static const Color accent      = Color(0xFF0A0A0A); // negro — CTA primario
  static const Color divider     = Color(0xFFE8E8E8);
  static const Color border      = Color(0xFFD4D4D4);
}
```

**Principios aplicados:**
- Sin colores semánticos (verde/amarillo/rojo) en estados de éxito o advertencia; la jerarquía se comunica con peso tipográfico y contraste de grises
- Chips de filtro con estado seleccionado invertido (fondo negro, texto blanco) en lugar de colores de acento
- Tarjetas con borde sutil (`AppColors.divider`) en vez de sombras, para una estética plana y consistente
- Componentes reutilizables (`_SectionLabel`, `_FilterChip`, `_InfoRow`) compartidos entre formulario, colección y explorador para garantizar coherencia visual

---

## Instalación

### Requisitos previos
- Flutter SDK ^3.11.4
- Una instancia de MongoDB (local o Atlas)
- API key de [RAWG](https://rawg.io/apidocs) (gratuita)

### Pasos

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd games_vault

# 2. Instalar dependencias
flutter pub get

# 3. Generar splash screen e íconos nativos
dart run flutter_native_splash:create
dart run flutter_launcher_icons

# 4. Ejecutar la aplicación
flutter run
```

---

## Configuración

### MongoDB
La cadena de conexión se configura en `lib/core/database/mongo_database.dart`. Para producción, evitar exponer credenciales directamente en el cliente; este enfoque es aceptable únicamente en un contexto académico o de prototipo.

### RAWG API
La API key se configura en `lib/core/network/rawg_api_service.dart`:

```dart
static const String _apiKey = 'TU_API_KEY_AQUI';
```

### Assets de splash e ícono
Las imágenes fuente (1024×1024 para ícono, 1152×1152 para splash, fondo transparente) se ubican en `assets/images/` y se referencian desde `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/images/splash_image.png
  color_dark: "#0A0A0A"
  image_dark: assets/images/splash_image_dark.png

flutter_launcher_icons:
  image_path: "assets/images/app_icon.png"
```

---

## Estructura del proyecto

```
lib/
 ┣ core/
 ┃ ┣ theme/
 ┃ ┃ ┣ app_colors.dart
 ┃ ┃ ┗ app_theme.dart
 ┃ ┣ database/
 ┃ ┃ ┗ mongo_database.dart
 ┃ ┣ network/
 ┃ ┃ ┗ rawg_api_service.dart
 ┃ ┗ services/
 ┃   ┗ image_service.dart
 ┣ models/
 ┃ ┗ game_item.dart
 ┣ features/
 ┃ ┣ home/
 ┃ ┃ ┗ home_page.dart
 ┃ ┣ collection/
 ┃ ┃ ┣ providers/
 ┃ ┃ ┃ ┗ collection_provider.dart
 ┃ ┃ ┣ collection_page.dart
 ┃ ┃ ┣ detail_page.dart
 ┃ ┃ ┗ form_page.dart
 ┃ ┣ api_explorer/
 ┃ ┃ ┣ providers/
 ┃ ┃ ┃ ┗ api_explorer_provider.dart
 ┃ ┃ ┗ api_explorer_page.dart
 ┃ ┗ about/
 ┃   ┗ about_page.dart
 ┗ main.dart
```

---

## Decisiones técnicas

**Filtrado en memoria para la colección local.** `CollectionProvider.localGames` es un getter derivado que filtra la lista en RAM en cada acceso, en lugar de hacer queries a MongoDB por cada cambio de filtro. Es la opción correcta cuando los datos ya residen en el cliente: evita latencia de red y simplifica el estado.

**Imágenes locales vs. remotas en un mismo modelo.** `GameItem.imagen` puede contener tanto una ruta de archivo local (juegos creados manualmente, con imagen subida desde galería) como una URL (juegos importados de RAWG). `ImageService.isLocalPath()` centraliza esa distinción y cada widget de imagen (`_TileImage`, `_GameImage`, `_ImagePicker`) decide entre `Image.file` y `CachedNetworkImage` según corresponda.

**Slugs explícitos para filtros de género.** La RAWG API no acepta nombres de género en lenguaje natural como parámetro (`RPG` falla); requiere slugs específicos (`role-playing-games-rpg`). Esto se resolvió con un mapa `genreSlugs` en `ExplorerFilters`, separando el label visible del valor que efectivamente viaja en el query string.

**Debounce en búsquedas.** Tanto el explorador (450 ms, por tratarse de llamadas de red) como la colección local (300 ms, filtrado en memoria) usan `Timer` con debounce para evitar disparar la lógica de filtrado en cada pulsación de tecla.

**Splash con `preserve`/`remove`.** El splash nativo se mantiene visible mientras se resuelve la conexión a MongoDB en `main()`, y se retira explícitamente con `FlutterNativeSplash.remove()` —incluso si la conexión falla— para no bloquear el arranque de la aplicación.

---

## Roadmap

- [ ] Tests unitarios para los providers (`CollectionProvider`, `ApiExplorerProvider`)
- [ ] Migrar la API key de RAWG a variables de entorno (`--dart-define`)
- [ ] Soporte offline-first con sincronización diferida
- [ ] Exportar la colección a CSV/JSON

---

## Licencia

Proyecto académico — Taller de Flutter.
