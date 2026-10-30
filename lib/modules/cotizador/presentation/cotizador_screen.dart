/*
 * ============================================================================
 *         🦺 CONTROL DE OBRA — PRESENTATION LAYER: COTIZADOR SCREEN (1/8)
 * ============================================================================
 * Desarrollado para: Ing. Félix Vargas
 * Ruta Física: lib/modules/cotizador/presentation/cotizador_screen.dart
 * Lenguaje: Dart (Flutter)
 * Diseño: Interfaz de Presupuestos Basada en Formato Estándar Corporativo
 * ============================================================================
 */

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/presupuesto_pdf_service.dart';

/// Modelo de datos local para capturar y controlar de forma reactiva
/// cada renglón de Mano de Obra (Labor Breakdown) en la interfaz de usuario.
class ConceptoManoObraInput {
  final TextEditingController puestoController = TextEditingController();
  final TextEditingController costoHoraController = TextEditingController();
  final TextEditingController horasController = TextEditingController();
  bool esProveedor = false;
}

/// Modelo de datos local para capturar y controlar de forma reactiva
/// cada renglón de Materiales (Material Breakdown) en la interfaz de usuario.
class ConceptoMaterialInput {
  final TextEditingController conceptoController = TextEditingController();
  final TextEditingController precioUnitarioController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
}
class CotizadorScreen extends StatefulWidget {
  final String idProyecto;
  final String nombreObra;

  const CotizadorScreen({
    super.key,
    required this.idProyecto,
    required this.nombreObra,
  });

  @override
  State<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends State<CotizadorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores Generales del Encabezado Corporativo
  final TextEditingController _solicitanteController = TextEditingController(text: 'ING. Enrique Mauricio Ortega');
  final TextEditingController _descripcionController = TextEditingController(
    text: 'MANTENIMIENTOS EN BAÑOS DE WELDING CON USO DE PINTURA ESMALTE COLOR BLANCO...',
  );
  final TextEditingController _preparadoPorController = TextEditingController(text: 'FELIX VARGAS');

  // Listas Dinámicas para la Inserción de Renglones Múltiples
  final List<ConceptoManoObraInput> _listaManoObra = [];
  final List<ConceptoMaterialInput> _listaMateriales = [];

  // Parámetros Porcentuales de Operación por Contrato (Valores Base Excel)
  double utilidadAcissaPct = 20.0;
  double comisionNamfePct = 3.0;
  double ivaPct = 16.0;

  @override
  void initState() {
    super.initState();
    _agregarRenglonManoObra();
    _agregarRenglonMaterial();
  }

  void _agregarRenglonManoObra() {
    setState(() {
      _listaManoObra.add(ConceptoManoObraInput());
    });
  }

  void _agregarRenglonMaterial() {
    setState(() {
      _listaMateriales.add(ConceptoMaterialInput());
    });
  }
  // ============================================================================
  //         🎰 MOTOR MATEMÁTICO DE CONSOLIDACIÓN FINANCIERA (CONCENTRADOR)
  // ============================================================================
  Map<String, double> _calcularEstructuraFinanciera() {
    double totalManoObra = 0.0;
    double totalMateriales = 0.0;

    for (var item in _listaManoObra) {
      final double costo = double.tryParse(item.costoHoraController.text) ?? 0.0;
      final double horas = double.tryParse(item.horasController.text) ?? 0.0;
      totalManoObra += (costo * horas);
    }

    for (var item in _listaMateriales) {
      final double precio = double.tryParse(item.precioUnitarioController.text) ?? 0.0;
      final double cantidad = double.tryParse(item.cantidadController.text) ?? 0.0;
      totalMateriales += (precio * cantidad);
    }

    final double subtotalABC = totalManoObra + totalMateriales;
    final double utilidadMonto = subtotalABC * (utilidadAcissaPct / 100);
    final double comisionNamfeMonto = subtotalABC * (comisionNamfePct / 100);
    final double totalDeducible = utilidadMonto + comisionNamfeMonto;
    final double ivaMonto = subtotalABC * (ivaPct / 100);
    final double grandTotal = subtotalABC + ivaMonto;

    return {
      'mano_obra': totalManoObra,
      'materiales': totalMateriales,
      'subtotal_abc': subtotalABC,
      'utilidad': utilidadMonto,
      'comision': comisionNamfeMonto,
      'total_deducible': totalDeducible,
      'iva': ivaMonto,
      'grand_total': grandTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'GENERADOR DE PRESUPUESTOS',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18, letterSpacing: 1.1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TARJETA METADATOS DEL PROYECTO SELECCIONADO
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF1976D2),
                        child: Icon(Icons.assignment_turned_in_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código Frente: ${widget.idProyecto}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF627D98))),
                            const SizedBox(height: 4),
                            Text(widget.nombreObra, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF102A43))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. FORMULARIO DE ENCABEZADO GENERAL
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ENCABEZADO GENERAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102A43), letterSpacing: 0.5)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _solicitanteController,
                              decoration: const InputDecoration(labelText: 'Solicitante / Comprador', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _preparadoPorController,
                              decoration: const InputDecoration(labelText: 'Cotizado / Preparado por', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Especificación Detallada de los Trabajos', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 3. SECCIÓN: DESGLOSE DE MANO DE OBRA (LABOR BREAKDOWN)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.values.firstWhere((e) => e.name == 'between'),
                        children: [
                          const Text('MANO DE OBRA (LABOR BREAKDOWN)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
                          ElevatedButton.icon(
                            onPressed: _agregarRenglonManoObra,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Añadir Personal'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF388E3C), foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _listaManoObra.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _listaManoObra[index];
                          return Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: item.puestoController,
                                  decoration: const InputDecoration(labelText: 'Puesto', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: item.costoHoraController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Costo Hora', prefixText: '\$ ', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: item.horasController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Horas', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  const Text('Sub', style: TextStyle(fontSize: 12)),
                                  Checkbox(
                                    value: item.esProveedor,
                                    onChanged: (val) {
                                      setState(() {
                                        item.esProveedor = val ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
                                onPressed: () {
                                  if (_listaManoObra.length > 1) {
                                    setState(() {
                                      _listaManoObra.removeAt(index);
                                    });
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 4. SECCIÓN: DESGLOSE DE MATERIALES (MATERIAL BREAKDOWN)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.values.firstWhere((e) => e.name == 'between'),
                        children: [
                          const Text('MATERIALES (MATERIAL BREAKDOWN)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
                          ElevatedButton.icon(
                            onPressed: _agregarRenglonMaterial,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Añadir Material'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _listaMateriales.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _listaMateriales[index];
                          return Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  controller: item.conceptoController,
                                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: item.precioUnitarioController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'P. Unitario', prefixText: '\$ ', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: item.cantidadController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Cant.', border: OutlineInputBorder()),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
                                onPressed: () {
                                  if (_listaMateriales.length > 1) {
                                    setState(() {
                                      _listaMateriales.removeAt(index);
                                    });
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 5. BLOQUE DE RESUMEN FINANCIERO DINÁMICO (VISTA DE TOTALES CON ESCUCHA ACTIVA)
              AnimatedBuilder(
                animation: Listenable.merge([
                  ..._listaManoObra.map((e) => e.costoHoraController),
                  ..._listaManoObra.map((e) => e.horasController),
                  ..._listaMateriales.map((e) => e.precioUnitarioController),
                  ..._listaMateriales.map((e) => e.cantidadController),
                ]),
                builder: (context, _) {
                  final metricas = _calcularEstructuraFinanciera();
                  return Card(
                    color: const Color(0xFF102A43),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RESUMEN DE COTIZACIÓN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                          const Divider(height: 24, color: Colors.white24),
                          _buildFilaMetrica('Mano de Obra (A):', '\$ ${metricas['mano_obra']!.toStringAsFixed(2)}'),
                          _buildFilaMetrica('Materiales (B):', '\$ ${metricas['materiales']!.toStringAsFixed(2)}'),
                          _buildFilaMetrica('Equipo (C):', '\$ 0.00'),
                          const Divider(color: Colors.white24),
                          _buildFilaMetrica('Subtotal A+B+C:', '\$ ${metricas['subtotal_abc']!.toStringAsFixed(2)}', esBold: true),
                          _buildFilaMetrica('Utilidad ACISSA (${utilidadAcissaPct.toStringAsFixed(0)}%):', '\$ ${metricas['utilidad']!.toStringAsFixed(2)}'),
                          _buildFilaMetrica('Comisión NAMFE (${comisionNamfePct.toStringAsFixed(0)}%):', '\$ ${metricas['comision']!.toStringAsFixed(2)}'),
                          _buildFilaMetrica('Total Costo Deducible:', '\$ ${metricas['total_deducible']!.toStringAsFixed(2)}', colorTexto: const Color(0xFFFFD43A)),
                          const Divider(color: Colors.white38),
                          _buildFilaMetrica('IVA (${ivaPct.toStringAsFixed(0)}%):', '\$ ${metricas['iva']!.toStringAsFixed(2)}'),
                          _buildFilaMetrica('GRAND TOTAL:', '\$ ${metricas['grand_total']!.toStringAsFixed(2)}', esLarge: true, colorTexto: const Color(0xFF81C784)),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _guardarPresupuestoEnSupabase(metricas),
                                  icon: const Icon(Icons.cloud_upload_rounded),
                                  label: const Text('Guardar en Supabase'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final Map<String, double> ratiosFinancieros = _calcularEstructuraFinanciera();
                                    await PresupuestoPdfService.exportarPresupuestoPDF(
                                      idProyecto: widget.idProyecto,
                                      nombreObra: widget.nombreObra,
                                      solicitante: _solicitanteController.text,
                                      descripcionGeneral: _descripcionController.text,
                                      preparadoPor: _preparadoPorController.text,
                                      metricas: ratiosFinancieros,
                                      listaManoObraRaw: _listaManoObra,
                                      listaMaterialesRaw: _listaMateriales,
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf_rounded),
                                  label: const Text('Exportar PDF'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF388E3C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFilaMetrica(String label, String valor, {bool esBold = false, bool esLarge = false, Color colorTexto = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.values.firstWhere((e) => e.name == 'between'),
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: esLarge ? 16 : 14, fontWeight: esBold ? FontWeight.bold : FontWeight.normal)),
          Text(valor, style: TextStyle(color: colorTexto, fontSize: esLarge ? 22 : (esBold ? 16 : 14), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _guardarPresupuestoEnSupabase(Map<String, double> ratios) async {
    try {
      final SupabaseClient cliente = Supabase.instance.client;

      final List<dynamic> proyectoQuery = await cliente.from('proyectos').select('id').eq('codigo_proyecto', widget.idProyecto);
      if (proyectoQuery.isEmpty) throw Exception("Proyecto no indexado.");
      final String uuidProyecto = proyectoQuery.first['id'] as String;

      final resPresupuesto = await cliente.from('presupuestos').insert({
        'proyecto_id': uuidProyecto,
        'solicitante': _solicitanteController.text,
        'descripcion_general': _descripcionController.text,
        'porcentaje_utilidad_acissa': utilidadAcissaPct,
        'porcentaje_comision_namfe': comisionNamfePct,
        'porcentaje_iva': ivaPct,
        'preparado_por': _preparadoPorController.text,
      }).select();

      final String uuidPresupuesto = resPresupuesto.first['id'] as String;

      for (var item in _listaManoObra) {
        if (item.puestoController.text.isNotEmpty) {
          await cliente.from('presupuesto_mano_obra').insert({
            'presupuesto_id': uuidPresupuesto,
            'puesto': item.puestoController.text,
            'costo_por_hora': double.tryParse(item.costoHoraController.text) ?? 0.0,
            'horas_estandar': double.tryParse(item.horasController.text) ?? 0.0,
            'es_proveedor': item.esProveedor,
          });
        }
      }

      for (var item in _listaMateriales) {
        if (item.conceptoController.text.isNotEmpty) {
          await cliente.from('presupuesto_materiales').insert({
            'presupuesto_id': uuidPresupuesto,
            'concepto': item.conceptoController.text,
            'precio_unitario': double.tryParse(item.precioUnitarioController.text) ?? 0.0,
            'cantidad': double.tryParse(item.cantidadController.text) ?? 0.0,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Presupuesto consolidado e insertado con éxito en Supabase.')));
      }
    } catch (ex) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error de persistencia: ${ex.toString()}')));
      }
    }
  }
}
