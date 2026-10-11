import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Pantalla reestructurada del Módulo de Levantamientos Técnicos en Campo.
/// Implementa un flujo operativo basado en inspección fotográfica detallada por punto,
/// control de inventario de equipos y validación de protocolos de seguridad en sitio.
class LevantamientoScreen extends StatefulWidget {
  final String idProyecto;
  final String nombreObra;

  const LevantamientoScreen({
    super.key,
    required this.idProyecto,
    required this.nombreObra,
  });

  @override
  State<LevantamientoScreen> createState() => _LevantamientoScreenState();
}

/// Clase de soporte para estructurar cada evidencia fotográfica con su respectiva descripción individual.
class EvidenciaInspeccion {
  final XFile archivo;
  final Uint8List bytesWeb; // Indispensable para renderizar la miniatura correctamente en GitHub Pages
  final TextEditingController descripcionController;

  EvidenciaInspeccion({
    required this.archivo,
    required this.bytesWeb,
    required this.descripcionController,
  });
}

/// Clase de soporte para el manejo de listas de verificación con estados booleanos (Checks)
class ItemChecklist {
  final String nombre;
  bool seleccionado;

  ItemChecklist({
    required this.nombre,
    this.seleccionado = false,
  });
}

class _LevantamientoScreenState extends State<LevantamientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _tituloLevantamientoController;

  @override
  void initState() {
    super.initState();
    _tituloLevantamientoController = TextEditingController(text: widget.nombreObra);
  }

  bool _sincronizandoNube = false;

  // Lista dinámica principal donde se acumularán las evidencias fotográficas con su descripción
  final List<EvidenciaInspeccion> _listaEvidencias = [];

  // Lista de control de Maquinaria y Equipo técnico requerido en la obra
  final List<ItemChecklist> _checklistEquipos = [
    ItemChecklist(nombre: 'Andamios de Sección Estándar'),
    ItemChecklist(nombre: 'Arnés de Seguridad Contra Caídas'),
    ItemChecklist(nombre: 'Rotomartillo / Demoledor Industrial'),
    ItemChecklist(nombre: 'Esmeriladora Angular de 4-1/2"'),
    ItemChecklist(nombre: 'Cortadora de Concreto / Disco de Diamante'),
    ItemChecklist(nombre: 'Generador Eléctrico Portátil (Planta de luz)'),
    ItemChecklist(nombre: 'Extensión Eléctrica de Uso Rudo (Calibre 12)'),
    ItemChecklist(nombre: 'Escalera de Extensión (Fibra de vidrio)'),
    ItemChecklist(nombre: 'Mezcladora de Concreto (Saco completo)'),
    ItemChecklist(nombre: 'Herramienta Menor (Palas, picos, marros, flexómetros)'),
  ];

  // Lista de control para el cumplimiento de protocolos de seguridad del personal
  final List<ItemChecklist> _checklistSeguridad = [
    ItemChecklist(nombre: 'Casco de Protección Industrial (Clase E)'),
    ItemChecklist(nombre: 'Calzado de Seguridad con Casquillo de Acero / Policarbonato'),
    ItemChecklist(nombre: 'Lentes de Protección Policarbonato (Anti-impacto)'),
    ItemChecklist(nombre: 'Guantes de Carnaza / Nitrilo para Maniobras'),
    ItemChecklist(nombre: 'Chaleco Reflejante con Alta Visibilidad'),
    ItemChecklist(nombre: 'Mascarilla Contra Polvos / Respirador N95'),
    ItemChecklist(nombre: 'Línea de Vida y Puntos de Anclaje Certificados'),
    ItemChecklist(nombre: 'Botiquín de Primeros Auxilios Operativo en Sitio'),
    ItemChecklist(nombre: 'Extintor de Polvo Químico Seco (PQS) Vigente ABC'),
    ItemChecklist(nombre: 'Delimitación de Área (Malla plástica / Cinta de precaución)'),
  ];

  @override
  void dispose() {
    // Liberación estricta de memoria para todos los controladores dinámicos creados por foto
    for (var evidencia in _listaEvidencias) {
      evidencia.descripcionController.dispose();
    }
    super.dispose();
  }

  /// Dispara la cámara del dispositivo móvil, extrae los bytes para la web y añade el nodo a la lista.
  Future<void> _capturarEvidenciaConCamara() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Optimización senior para balancear nitidez y peso de red
      );
      
      if (foto != null) {
        // Operación crítica: Extraer bytes asíncronos para garantizar visualización en GitHub Pages
        final Uint8List bytes = await foto.readAsBytes();
        
          setState(() {
          _listaEvidencias.insert(
            0,
            EvidenciaInspeccion(
              archivo: foto,
              bytesWeb: bytes,
              descripcionController: TextEditingController(),
            ),
          );
        });

      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inicializar el hardware de la cámara: $e')),
      );
    }
  }
  /// Abre la galería del dispositivo, procesa múltiples imágenes en lote y extrae sus bytes.
  Future<void> _importarEvidenciasDesdeGaleria() async {
    try {
      final List<XFile> fotosSeleccionadas = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      
      if (fotosSeleccionadas.isNotEmpty) {
        for (var foto in fotosSeleccionadas) {
          final Uint8List bytes = await foto.readAsBytes();
          setState(() {
            _listaEvidencias.insert(
              0,
              EvidenciaInspeccion(
                archivo: foto,
                bytesWeb: bytes,
                descripcionController: TextEditingController(),
              ),
            );
          });

        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al acceder a la galería multimedia: $e')),
      );
    }
  }

  /// Procesa el empaquetado final de datos técnicos, notas, listas de control y fotos para enviarlo a la nube.
  Future<void> _guardarReporteLevantamiento() async {
    if (!_formKey.currentState!.validate()) return;

    if (_listaEvidencias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requerido: Capture o cargue al menos una evidencia fotográfica de la obra.')),
      );
      return;
    }

    setState(() => _sincronizandoNube = true);

    // Simulación técnica de latencia de red para validar el estado de carga (Loading status)
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _sincronizandoNube = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Inspección de campo y reportes de seguridad sincronizados con éxito.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double anchoPantalla = MediaQuery.of(context).size.width;
    final bool esEscritorio = anchoPantalla > 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF102A43),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Levantamiento Técnico: ${widget.idProyecto}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Oculta el teclado táctil al interactuar con el fondo
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título Principal del Proyecto Asignado
                                        // Título Principal Editable del Levantamiento
                    TextFormField(
                      controller: _tituloLevantamientoController,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nombre / Título del Levantamiento',
                        labelStyle: TextStyle(fontSize: 14, color: Color(0xFF627D98)),
                        border: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF102A43), width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El título del levantamiento no puede estar vacío';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 6),
                    const Text(
                      'Registre evidencias visuales con descripciones puntuales y valide las listas de seguridad y equipos.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF627D98)),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta Informativa Resumen del Reporte en Progreso
                    Card(
                      color: const Color(0xFF102A43),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              child: const Icon(Icons.photo_camera_back_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Evidencias Registradas para Bitácora',
                                    style: TextStyle(color: Color(0xFFBCCCDC), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_listaEvidencias.length} puntos de inspección capturados',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Bloque de Acciones: Captura y Carga Multimedia
                    Text(
                      'Captura de Evidencias en Sitio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF102A43).withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fila de controles operativos para interactuar con la cámara y archivos
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _capturarEvidenciaConCamara,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF388E3C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                            ),
                            icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                            label: const Text('Tomar Foto en Obra', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _importarEvidenciasDesdeGaleria,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF388E3C),
                              side: const BorderSide(color: Color(0xFF388E3C), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.collections_rounded, size: 20),
                            label: const Text('Cargar de Galería', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Sección Dinámica de Visualización: Fotos con Descripción Individual
                    Text(
                      'Desglose Visual de Inspección',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF102A43).withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cada imagen capturada requiere una nota técnica descriptiva que se anexará al reporte.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF627D98)),
                    ),
                    const SizedBox(height: 16),

                    // Cuadrícula Responsiva de Alto Nivel con Límite de 4 Columnas Horizontales
                    if (_listaEvidencias.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // El scroll lo maneja el contenedor principal
                        itemCount: _listaEvidencias.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: esEscritorio ? 4 : (anchoPantalla > 580 ? 2 : 1),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: esEscritorio ? 0.72 : 0.85, // Proporción estirada para que quepa la foto y la caja de texto
                        ),
                        itemBuilder: (context, index) {
                          final evidencia = _listaEvidencias[index];
                          return Card(
                            elevation: 3,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(14),
  side: const BorderSide(color: Color(0xFFD9E2EC), width: 1), // Se cambió 'border' por 'side' y 'Border.all' por 'BorderSide'
),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Bloque de Previsualización Real de la Fotografía usando Bytes (Solución Web)
                                Expanded(
                                  flex: 5,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFBCCCDC),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(13),
                                            topRight: Radius.circular(13),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(13),
                                            topRight: Radius.circular(13),
                                          ),
                                          // Renderizador de memoria directa para solucionar las fotos transparentes o grises en la web
                                          child: Image.memory(
                                            evidencia.bytesWeb,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      // Botón flotante superior para remover la foto de forma individual
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              evidencia.descripcionController.dispose();
                                              _listaEvidencias.removeAt(index);
                                            });
                                          },
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.9),
                                            child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                      // Identificador correlativo del punto evaluado
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF102A43).withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'PUNTO #${index + 1}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Bloque de Entrada de Texto: Descripción Individual por Imagen
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: TextFormField(
                                      controller: evidencia.descripcionController,
                                      maxLines: 3,
                                      minLines: 2,
                                      style: const TextStyle(fontSize: 12),
                                      textCapitalization: TextCapitalization.sentences,
                                      decoration: InputDecoration(
                                        labelText: 'Descripción del punto',
                                        hintText: 'Ej: Grieta por asentamiento en contratrabe...',
                                        alignLabelWithHint: true,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.all(10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Falta descripción';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      // Indicador visual responsivo en caso de no tener evidencias cargadas aún
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9E2EC), width: 1.5),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF9FB3C8), size: 48),
                            SizedBox(height: 16),
                            Text(
                              'No se han registrado puntos de inspección fotográfica.',
                              style: TextStyle(color: Color(0xFF486581), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Use los botones superiores para activar la cámara del celular.',
                              style: TextStyle(color: Color(0xFF627D98), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 36),

                    // SECCIÓN NUEVA: EQUIPO Y MAQUINARIA REQUERIDA EN SITIO
                    Text(
                      'Logística: Equipos y Maquinaria',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF102A43).withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Seleccione los elementos y herramientas que se van a utilizar para la ejecución de los trabajos.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF627D98)),
                    ),
                    const SizedBox(height: 16),

                    // Contenedor responsivo GridView para las casillas de verificación de Maquinaria
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E2EC)),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklistEquipos.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: esEscritorio ? 2 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 4,
                          childAspectRatio: esEscritorio ? 7.5 : 6.5,
                        ),
                        itemBuilder: (context, index) {
                          final item = _checklistEquipos[index];
                          return CheckboxListTile(
                            title: Text(item.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            value: item.seleccionado,
                            activeColor: const Color(0xFF1976D2),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (bool? valor) {
                              setState(() {
                                item.seleccionado = valor ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 36),
                    // SECCIÓN NUEVA: PROTOCOLOS Y ELEMENTOS DE SEGURIDAD
                    Text(
                      'Seguridad y Salud Ocupacional',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF102A43).withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Valide el cumplimiento del equipo de protección personal (EPP) y mitigación de riesgos exigidos en obra.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF627D98)),
                    ),
                    const SizedBox(height: 16),

                    // Contenedor responsivo GridView para las casillas de verificación de Seguridad
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E2EC)),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklistSeguridad.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: esEscritorio ? 2 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 4,
                          childAspectRatio: esEscritorio ? 7.5 : 6.5,
                        ),
                        itemBuilder: (context, index) {
                          final item = _checklistSeguridad[index];
                          return CheckboxListTile(
                            title: Text(item.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            value: item.seleccionado,
                            activeColor: const Color(0xFF388E3C),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (bool? valor) {
                              setState(() {
                                item.seleccionado = valor ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Botón Maestro de Alto Nivel: Concluir y Enviar Reporte de Inspección Completo
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _sincronizandoNube ? null : _guardarReporteLevantamiento,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF102A43),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFBCCCDC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _sincronizandoNube
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Sincronizando Reporte e Imágenes con Servidor...',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.assignment_turned_in_rounded, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'CONCLUIR Y GUARDAR INSPECCIÓN',
                                    style: TextStyle(
                                      fontSize: 15, 
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Enlace secundario de cancelación para el retorno seguro de la interfaz
                    if (!_sincronizandoNube)
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                          ),
                          child: const Text(
                            'Cancelar inspección y salir',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget auxiliar de envoltura para simplificar la inicialización del módulo de campo.
/// Proporciona un punto de enganche directo para realizar pruebas aisladas de levantamientos.
class TestLevantamientoWrapper extends StatelessWidget {
  const TestLevantamientoWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const LevantamientoScreen(
      idProyecto: 'PRY-2026-001',
      nombreObra: 'Remodelación de Fachada Corporativa Centro',
    );
  }
}

// Bloque de extensiones de datos técnicos para el módulo de levantamientos en sitio
class AnalisisPartidaMuro {
  final double espesorMuro;
  final String materialSugerido;
  final bool requiereAndamio;

  const AnalisisPartidaMuro({
    required this.espesorMuro,
    required this.materialSugerido,
    this.requiereAndamio = false,
  });
}

class ResumenInsumosObra {
  final List<String> herramientas;
  final List<String> equipoProteccion;
  final int totalPuntosInspeccion;

  const ResumenInsumosObra({
    required this.herramientas,
    required this.equipoProteccion,
    required this.totalPuntosInspeccion,
  });
}

class RegistroBitacoraCampo {
  final DateTime fechaVisita;
  final String ingenieroResponsable;
  final String comentariosSupervisor;

  const RegistroBitacoraCampo({
    required this.fechaVisita,
    required this.ingenieroResponsable,
    required this.comentariosSupervisor,
  });
}
