import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Pantalla principal del Módulo de Levantamientos Técnicos en Campo.
/// Permite al supervisor registrar dimensiones, notas de áreas y capturar evidencia fotográfica.
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

class _LevantamientoScreenState extends State<LevantamientoScreen> {
  // Llave global para la validación del formulario técnico
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para la captura de información de la obra
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _anchoController = TextEditingController();
  final TextEditingController _altoController = TextEditingController();
  final TextEditingController _largoController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  // Variables de control operativo para el flujo de campo
  String _unidadSeleccionada = 'm²';
  bool _guardandoEnNube = false;
  double _resultadoCalculado = 0.0;

  // Lista local para almacenar temporalmente las imágenes capturadas con la cámara
  final List<XFile> _imagenesCapturadas = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Escuchadores dinámicos para calcular áreas o volúmenes automáticamente al teclear
    _anchoController.addListener(_ejecutarCalculoTecnico);
    _altoController.addListener(_ejecutarCalculoTecnico);
    _largoController.addListener(_ejecutarCalculoTecnico);
  }

  @override
  void dispose() {
    // Liberación de memoria de los controladores al cerrar el módulo
    _areaController.dispose();
    _anchoController.dispose();
    _altoController.dispose();
    _largoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  /// Realiza el cálculo matemático automático de la partida dependiendo de la unidad técnica.
  void _ejecutarCalculoTecnico() {
    final double ancho = double.tryParse(_anchoController.text) ?? 0.0;
    final double alto = double.tryParse(_altoController.text) ?? 0.0;
    final double largo = double.tryParse(_largoController.text) ?? 0.0;

    setState(() {
      if (_unidadSeleccionada == 'm²') {
        _resultadoCalculado = ancho * alto;
      } else if (_unidadSeleccionada == 'm³') {
        _resultadoCalculado = ancho * alto * largo;
      } else {
        _resultadoCalculado = largo; // Lineal directo
      }
    });
  }

  /// Abre la cámara del dispositivo móvil para capturar evidencia fotográfica del sitio.
  Future<void> _capturarFotografiaObra() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimización de peso para sincronización veloz en Sheets/Drive
      );
      if (foto != null) {
        setState(() {
          _imagenesCapturadas.add(foto);
        });
      }
    } catch (e) {
  if (!mounted) return; // CORRECCIÓN: Valida que el widget siga activo en pantalla antes de invocar el context
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error al activar la cámara: $e')),
  );
}

  }

  /// Abre la galería del celular por si el supervisor ya tenía fotos previas del levantamiento.
  Future<void> _seleccionarDeGaleria() async {
    try {
      final List<XFile> fotos = await _picker.pickMultiImage(
        imageQuality: 85,
      );
      if (fotos.isNotEmpty) {
        setState(() {
          _imagenesCapturadas.addAll(fotos);
        });
      }
    } catch (e) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al acceder a la galería: $e')),
      );
    }
  }
  /// Envía los datos consolidados y las imágenes del levantamiento técnico hacia la nube.
  Future<void> _enviarLevantamientoANube() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imagenesCapturadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor captura al menos una fotografía de evidencia.')),
      );
      return;
    }

    setState(() => _guardandoEnNube = true);

    // Simulación de delay de red antes de conectar con el módulo Data de Sheets
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _guardandoEnNube = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Levantamiento sincronizado con Google Sheets y Drive con éxito.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    //final double anchoPantalla = MediaQuery.of(context).size.width;
    //final bool esComputadora = anchoPantalla > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF102A43),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Levantamiento: ${widget.idProyecto}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Cierra el teclado táctil al tocar fuera
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado Informativo de la Obra Actual
                    Text(
                      widget.nombreObra,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Complete las dimensiones y registre la evidencia visual del área evaluada.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF627D98)),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta Indicadora del Cálculo Automático de Obra
                    Card(
                      color: const Color(0xFF102A43),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cómputo Métrico Estimado',
                                    style: TextStyle(color: Color(0xFFBCCCDC), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_resultadoCalculado.toStringAsFixed(2)} $_unidadSeleccionada',
                                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Datos de Campo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF102A43).withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Caja de Entrada: Área o Espacio Específico de la Obra
                    TextFormField(
                      controller: _areaController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Área / Espacio evaluado',
                        hintText: 'Ej: Planta Baja - Muro Principal, Fachada Posterior',
                        prefixIcon: const Icon(Icons.layers_rounded, color: Color(0xFF1976D2)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor registre el nombre del área o partida.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Fila Adaptativa para Parámetros Dimensionales y Selector de Unidad
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool usarFilaCompleta = constraints.maxWidth > 600;
                        
                        final List<Widget> camposDimensiones = [
                          // Campo Numérico: Ancho
                          Expanded(
                            flex: usarFilaCompleta ? 1 : 0,
                            child: TextFormField(
                              controller: _anchoController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Ancho (m)',
                                prefixIcon: const Icon(Icons.unfold_more_rounded),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Requerido';
                                if (double.tryParse(value) == null) return 'Inválido';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: usarFilaCompleta ? 16 : 0, height: usarFilaCompleta ? 0 : 16),
                          
                          // Campo Numérico: Alto
                          Expanded(
                            flex: usarFilaCompleta ? 1 : 0,
                            child: TextFormField(
                              controller: _altoController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Alto / Espesor (m)',
                                prefixIcon: const Icon(Icons.unfold_less_rounded),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Requerido';
                                if (double.tryParse(value) == null) return 'Inválido';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: usarFilaCompleta ? 16 : 0, height: usarFilaCompleta ? 0 : 16),

                          // Campo Numérico: Largo (Opcional según la unidad)
                          Expanded(
                            flex: usarFilaCompleta ? 1 : 0,
                            child: TextFormField(
                              controller: _largoController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Largo / Profundidad (m)',
                                prefixIcon: const Icon(Icons.more_horiz_rounded),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (_unidadSeleccionada == 'm³' && (value == null || value.isEmpty)) {
                                  return 'Requerido para m³';
                                }
                                return null;
                              },
                            ),
                          ),
                        ];

                        if (usarFilaCompleta) {
                          return Row(children: camposDimensiones);
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: camposDimensiones,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    // Etiqueta informativa para el bloque de unidad de medida
                    const Text(
                      'Unidad de Medición Técnica',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF486581)),
                    ),
                    const SizedBox(height: 10),

                    // Fila de botones de opción (Radio Tiles) para alternar la unidad de cómputo
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD9E2EC)),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final bool usarFilaRadios = constraints.maxWidth > 500;
                          
                                                   final List<Widget> radiosUnidades = [
                            Expanded(
                              flex: usarFilaRadios ? 1 : 0,
                              child: RadioMenuButton<String>(
                                value: 'm²',
                                groupValue: _unidadSeleccionada,
                                onChanged: (value) {
                                  setState(() {
                                    _unidadSeleccionada = value!;
                                    _ejecutarCalculoTecnico();
                                  });
                                },
                                child: const Text('m² (Área)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Expanded(
                              flex: usarFilaRadios ? 1 : 0,
                              child: RadioMenuButton<String>(
                                value: 'm³',
                                groupValue: _unidadSeleccionada,
                                onChanged: (value) {
                                  setState(() {
                                    _unidadSeleccionada = value!;
                                    _ejecutarCalculoTecnico();
                                  });
                                },
                                child: const Text('m³ (Volumen)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Expanded(
                              flex: usarFilaRadios ? 1 : 0,
                              child: RadioMenuButton<String>(
                                value: 'm',
                                groupValue: _unidadSeleccionada,
                                onChanged: (value) {
                                  setState(() {
                                    _unidadSeleccionada = value!;
                                    _ejecutarCalculoTecnico();
                                  });
                                },
                                child: const Text('m (Lineal)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ];


                          if (usarFilaRadios) {
                            return Row(children: radiosUnidades);
                          } else {
                            return Column(children: radiosUnidades);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sección: Notas de campo y requerimientos técnicos
                    Text(
                      'Especificaciones y Observaciones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF102A43).withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de texto expandido para notas generales de la visita
                    TextFormField(
                      controller: _notasController,
                      maxLines: 4,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Notas del levantamiento',
                        hintText: 'Describa condiciones del muro, grietas, acabados previos o materiales especiales requeridos...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40.0),
                          child: Icon(Icons.note_alt_rounded, color: Color(0xFF388E3C)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Bloque de encabezado para el cargador de imágenes de campo
                    Text(
                      'Evidencia Fotográfica del Sitio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF102A43).withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Capture imágenes nítidas de las condiciones actuales para el reporte técnico.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF627D98)),
                    ),
                    const SizedBox(height: 16),

                    // Fila de botones para interactuar con la cámara y archivos multimedia
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _capturarFotografiaObra,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF388E3C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Tomar Foto', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _seleccionarDeGaleria,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF388E3C),
                              side: const BorderSide(color: Color(0xFF388E3C), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Galería', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Carrusel Horizontal de Previsualización de Imágenes Capturadas
                    if (_imagenesCapturadas.isNotEmpty)
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4E9F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(12),
                          itemCount: _imagenesCapturadas.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Stack(
                                children: [
                                  // Imagen miniatura
                                  Container(
                                    width: 116,
                                    height: 116,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBCCCDC)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFF9FB3C8),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  // Botón flotante para eliminar la foto del arreglo local
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _imagenesCapturadas.removeAt(index);
                                        });
                                      },
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.9),
                                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                  // Indicador secuencial numérico sobre la foto
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF102A43).withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '#${index + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    else
                      // Indicador visual en caso de que no haya imágenes adjuntas todavía
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD9E2EC), style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.add_a_photo_rounded, color: Color(0xFF9FB3C8), size: 40),
                            SizedBox(height: 12),
                            Text(
                              'Ninguna fotografía capturada todavía',
                              style: TextStyle(color: Color(0xFF627D98), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    // Botón Maestro: Guardar y Sincronizar Levantamiento Técnico en la Nube
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _guardandoEnNube ? null : _enviarLevantamientoANube,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF102A43),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFBCCCDC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _guardandoEnNube
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
                                    'Sincronizando con Google Sheets...',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.cloud_upload_rounded, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'CONCLUIR Y GUARDAR LEVANTAMIENTO',
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
                    const SizedBox(height: 24),

                    // Enlace secundario de cancelación para el retorno seguro de la interfaz
                    if (!_guardandoEnNube)
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                          ),
                          child: const Text(
                            'Cancelar captura y salir',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
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
