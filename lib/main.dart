import 'package:flutter/material.dart';
import 'modules/levantamientos/presentation/levantamiento_screen.dart';




void main() {
  runApp(const ControlDeObraApp());
}

/// Punto de entrada principal de la aplicación corporativa "Control De Obra".
/// Configura los parámetros globales de diseño, temas visuales y enrutamiento.
/// Adaptado por completo a los estándares modernos de Material 3.
class ControlDeObraApp extends StatelessWidget {
  const ControlDeObraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Obra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        
        // Paleta de colores de alto nivel (Azules y Grises Corporativos unificados)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF102A43),
          primary: const Color(0xFF102A43),
          secondary: const Color(0xFF1976D2),
          tertiary: const Color(0xFF388E3C),
          surface: const Color(0xFFF0F4F8),
          error: const Color(0xFFD32F2F),
        ),
        
        // Configuración de tipografías legibles tanto para campo como para oficina
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF486581),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF627D98),
          ),
        ),
        
        // CORRECCIÓN: Estilización global utilizando CardThemeData para compatibilidad
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

/// Pantalla base del Dashboard que implementa un diseño dual (PC y Celular).
/// Controla la distribución espacial dependiendo del tamaño del viewport.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _moduloSeleccionado = 0;

  // Lista unificada de módulos del sistema supervisor con metadatos descriptivos
  final List<Map<String, dynamic>> _itemsModulos = [
    {
      'titulo': 'CRM Comercial',
      'subtitulo': 'Búsqueda de prospectos y atención de clientes actuales.',
      'icono': Icons.people_alt_rounded,
      'color': const Color(0xFF1976D2),
      'id': 'crm',
    },
    {
      'titulo': 'Levantamientos',
      'subtitulo': 'Captura técnica en campo, toma de medidas y reportes fotográficos.',
      'icono': Icons.architecture_rounded,
      'color': const Color(0xFF388E3C),
      'id': 'levantamientos',
    },
    {
      'titulo': 'Cotizador',
      'subtitulo': 'Presupuestos detallados, análisis de costos e indirectos.',
      'icono': Icons.monetization_on_rounded,
      'color': const Color(0xFFF57C00),
      'id': 'cotizador',
    },
    {
      'titulo': 'Plan de Ejecución',
      'subtitulo': 'Cronograma de actividades, bitácora diaria y control de obra.',
      'icono': Icons.assignment_rounded,
      'color': const Color(0xFF7B1FA2),
      'id': 'plan_ejecucion',
    },
  ];

  /// Actualiza de forma reactiva el estado del bloque modular activo
  void _cambiarModulo(int index) {
    setState(() {
      _moduloSeleccionado = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    // Evaluación del ancho de pantalla en tiempo real para diseño responsivo
    final double anchoPantalla = MediaQuery.of(context).size.width;
    final bool esComputadora = anchoPantalla > 900;
    final bool esTablet = anchoPantalla <= 900 && anchoPantalla > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // Barra superior adaptativa corporativa
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        title: Row(
          children: [
            const Icon(
              Icons.construction_rounded,
              color: Colors.white,
              size: 26,
            ),
            const SizedBox(width: 12),
            Text(
              'CONTROL DE OBRA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.surface, // CORRECCIÓN: Evita el uso de background
                fontSize: 20,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          // Indicador visual del estado de la conexión a internet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // CORRECCIÓN: Reemplazado py por vertical
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: Colors.greenAccent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Nube Sincronizada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // El menú lateral izquierdo desplegable solo se activa en dispositivos móviles o tablets
      drawer: esComputadora ? null : AppDrawer(
        modulos: _itemsModulos,
        seleccionado: _moduloSeleccionado,
        onTap: (index) {
          _cambiarModulo(index);
          Navigator.pop(context);
        },
      ),
      body: Row(
        children: [
          // Si es PC, inyectamos el panel de navegación lateral de forma fija
          if (esComputadora)
            NavigationSidebar(
              modulos: _itemsModulos,
              seleccionado: _moduloSeleccionado,
              onTap: _cambiarModulo,
            ),
          // Contenedor principal de la aplicación
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              color: Theme.of(context).colorScheme.surface,
              child: CustomScrollView(
                slivers: [
                  // Cabecera dinámica de bienvenida dentro del área de trabajo
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16), // CORRECCIÓN: Reemplazado fromSTEB por fromLTRB
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel de Supervisión',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gestión técnica, presupuestos y control operativo en tiempo real.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: Color(0xFFBCCCDC)),
                        ],
                      ),
                    ),
                  ),
                  // CORRECCIÓN: Estructuración correcta del SliverGrid utilizando delegate
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: esComputadora ? 4 : (esTablet ? 2 : 1),
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: esComputadora ? 1.05 : 1.35,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _itemsModulos[index];
                          final bool esActivo = _moduloSeleccionado == index;
                          return ModuloCard(
                            titulo: item['titulo'] as String,
                            subtitulo: item['subtitulo'] as String,
                            icono: item['icono'] as IconData,
                            color: item['color'] as Color,
                            esActivo: esActivo,
                            onTap: () {
  _cambiarModulo(index);
  if (index == 1) { // 100% verificado: el índice 1 es Levantamientos
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LevantamientoScreen(
          idProyecto: 'PRY-2026-001',
          nombreObra: 'Remodelación de Fachada Corporativa Centro',
        ),
      ),
    );
  }
},

                          );
                        },
                        childCount: _itemsModulos.length,
                      ),
                    ),
                  ),
                  // Sección inferior: Panel de Métricas Rápidas y Estatus de Obra
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32), // CORRECCIÓN: Reemplazado fromSTEB por fromLTRB
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Resumen Operativo Global',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Datos consolidados directamente desde tu Google Sheets central.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          // Distribución adaptativa de bloques informativos
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool usarFila = constraints.maxWidth > 750;
                              if (usarFila) {
                                return Row(
                                  children: const [
                                    Expanded(child: MetricTile(titulo: 'Proyectos Activos', valor: '12 frentes', icono: Icons.business, color: Color(0xFF1976D2))),
                                    SizedBox(width: 24),
                                    Expanded(child: MetricTile(titulo: 'Levantamientos Pendientes', valor: '4 sitios', icono: Icons.explore, color: Color(0xFF388E3C))),
                                    SizedBox(width: 24),
                                    Expanded(child: MetricTile(titulo: 'Por Ejecutar', valor: '38.4 %', icono: Icons.trending_up, color: Color(0xFF7B1FA2))),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: const [
                                    MetricTile(titulo: 'Proyectos Activos', valor: '12 frentes', icono: Icons.business, color: Color(0xFF1976D2)),
                                    SizedBox(height: 16),
                                    MetricTile(titulo: 'Levantamientos Pendientes', valor: '4 sitios', icono: Icons.explore, color: Color(0xFF388E3C)),
                                    SizedBox(height: 16),
                                    MetricTile(titulo: 'Por Ejecutar', valor: '38.4 %', icono: Icons.trending_up, color: Color(0xFF7B1FA2)),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          // Bloque de advertencia o alertas de obra en curso
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFEEBA), width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start, // Se corrigió la sintaxis agregando AxisAlignment
  children: const [
    Text(

                                        'Bitácora Diaria — Recordatorio de Supervisión',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF856404), fontSize: 15),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Recuerda tomar las evidencias fotográficas del levantamiento antes de retirarte del sitio de la obra.',
                                        style: TextStyle(color: Color(0xFF856404), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
/// Componente visual reutilizable para mostrar indicadores contables u operativos masivos.
class MetricTile extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const MetricTile({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F0), width: 1),
        boxShadow: [
          BoxShadow(
           color: Colors.black.withValues(alpha: 0.02),

            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF627D98), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(fontSize: 20, color: Color(0xFF102A43), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de tarjeta interactiva y estilizada que representa cada módulo operativo.
/// Detecta estados de selección táctil y de ratón (hover) para ofrecer retroalimentación dinámica.
class ModuloCard extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final bool esActivo;
  final VoidCallback onTap;

  const ModuloCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.esActivo,
    required this.onTap,
  });

  @override
  State<ModuloCard> createState() => _ModuloCardState();
}

class _ModuloCardState extends State<ModuloCard> {
  bool _enFoco = false;

  @override
  Widget build(BuildContext context) {
    final bool resaltar = widget.esActivo || _enFoco;

    return MouseRegion(
      onEnter: (_) => setState(() => _enFoco = true),
      onExit: (_) => setState(() => _enFoco = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        transform: resaltar 
            ? Matrix4.translationValues(0.0, -6.0, 0.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: resaltar ? widget.color : const Color(0xFFE4E9F0),
            width: resaltar ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: resaltar 
                  ? widget.color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: resaltar ? 16 : 8,
              offset: resaltar ? const Offset(0, 8) : const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: widget.color.withValues(alpha: 0.01),
            highlightColor: widget.color.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenedor geométrico para el icono decorativo del módulo
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: resaltar 
                          ? widget.color 
                          : widget.color.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.icono,
                      size: 32,
                      color: resaltar ? Colors.white : widget.color,
                    ),
                  ),
                  const Spacer(),
                  // Bloque textual: Título principal del frente operativo
                  Text(
                    widget.titulo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: resaltar ? widget.color : const Color(0xFF102A43),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Bloque textual: Subtítulo o descripción resumida del alcance
                  Text(
                    widget.subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF627D98),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Indicador visual de módulo actualmente seleccionado
                  if (widget.esActivo)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: widget.color, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Modulo Seleccionado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel de navegación lateral izquierdo fijo diseñado para pantallas de PC y Escritorio.
/// Muestra un perfil rápido del supervisor y permite cambiar de módulo de forma directa.
class NavigationSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> modulos;
  final int seleccionado;
  final ValueChanged<int> onTap;

  const NavigationSidebar({
    super.key,
    required this.modulos,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
height: double.infinity,
decoration: const BoxDecoration(
  color: Color(0xFFF0F4F8),
  border: Border(
    right: BorderSide(color: Color(0xFFD9E2EC), width: 1.5),
  ),
),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección Superior: Identificación del Supervisor Activo
          Container(
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF102A43),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF1976D2),
                  child: Icon(
                    Icons.person_pin_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Ing. Félix Vargas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Supervisor de Obra',
                  style: TextStyle(
                    color: Color(0xFFBCCCDC),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Título de la sección de navegación
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'MÓDULOS DE TRABAJO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF627D98),
                letterSpacing: 1.5,
              ),
            ),
          ),
          // Menú Dinámico: Lista de frentes de obra mapeados
          Expanded(
            child: ListView.builder(
              itemCount: modulos.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final item = modulos[index];
                final bool esActivo = seleccionado == index;
                final Color colorModulo = item['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      item['icono'] as IconData,
                      color: esActivo ? colorModulo : const Color(0xFF486581),
                      size: 22,
                    ),
                    title: Text(
                      item['titulo'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: esActivo ? FontWeight.bold : FontWeight.w500,
                        color: esActivo ? const Color(0xFF102A43) : const Color(0xFF486581),
                      ),
                    ),
                    selected: esActivo,
                    selectedTileColor: colorModulo.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () => onTap(index),
                  ),
                );
              },
            ),
          ),
          // Pie de barra lateral: Versión del sistema supervisor
          const Divider(height: 1, color: Color(0xFFD9E2EC)),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: const [
                Icon(Icons.terminal_rounded, size: 16, color: Color(0xFF9FB3C8)),
                SizedBox(width: 8),
                Text(
                  'v1.0.0 — Octubre 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9FB3C8),
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Menú lateral desplegable (Drawer) diseñado y optimizado para dispositivos móviles.
/// Permite al supervisor cambiar de módulo cómodamente desde pantallas táctiles en campo.
class AppDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> modulos;
  final int seleccionado;
  final ValueChanged<int> onTap;

  const AppDrawer({
    super.key,
    required this.modulos,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del menú móvil: Perfil del Ingeniero Supervisor
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF102A43),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(22),
              ),
            ),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFF1976D2),
                  child: Icon(
                    Icons.engineering_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Ing. Félix Vargas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supervisor Activo',
                        style: TextStyle(
                          color: Color(0xFFBCCCDC),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Etiqueta indicadora de navegación móvil
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'FRENTES OPERATIVOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9FB3C8),
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Lista de opciones seleccionables del Drawer
          Expanded(
            child: ListView.builder(
              itemCount: modulos.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = modulos[index];
                final bool esActivo = seleccionado == index;
                final Color colorModulo = item['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      item['icono'] as IconData,
                      color: esActivo ? colorModulo : const Color(0xFF486581),
                      size: 24,
                    ),
                    title: Text(
                      item['titulo'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: esActivo ? FontWeight.bold : FontWeight.w500,
                        color: esActivo ? const Color(0xFF102A43) : const Color(0xFF486581),
                      ),
                    ),
                    trailing: esActivo
                        ? Icon(Icons.arrow_right_rounded, color: colorModulo, size: 28)
                        : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFBCCCDC)),
                    selected: esActivo,
                    selectedTileColor: colorModulo.withValues(alpha: 0.01),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => onTap(index),
                  ),
                );
              },
            ),
          ),
          // Cierre inferior del menú: Identificativo de la empresa
          const Divider(height: 1, color: Color(0xFFE4E9F0)),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Control de Obra Mobile Hub',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9FB3C8).withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
