/*
 * ============================================================================
 *         🦺 CONTROL DE OBRA — DATA LAYER: PRESUPUESTO PDF SERVICE
 * ============================================================================
 * Desarrollado para: Ing. Félix Vargas
 * Ruta Física: lib/modules/cotizador/data/presupuesto_pdf_service.dart
 * Lenguaje: Dart (Flutter PDF Engine)
 * Diseño: Renderizado de Plantilla Estándar TMMGT Indirect Purchasing
 * ============================================================================
 */


import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PresupuestoPdfService {
  /*
   * Orquestador de diseño gráfico. Genera la estructura del documento en memoria 
   * y gatilla el cuadro de diálogo de guardado/impresión nativo del navegador.
   */
  static Future<void> exportarPresupuestoPDF({
    required String idProyecto,
    required String nombreObra,
    required String solicitante,
    required String descripcionGeneral,
    required String preparadoPor,
    required Map<String, double> metricas,
    required List<dynamic> listaManoObraRaw,
    required List<dynamic> listaMaterialesRaw,
  }) async {
    final pw.Document pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(
          marginBottom: 30,
          marginTop: 30,
          marginLeft: 40,
          marginRight: 40,
        ),
        build: (pw.Context context) {
          return [
            // 1. ENCABEZADO INSTITUCIONAL CORPORATIVO
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TMMGT INDIRECT PURCHASING',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                    pw.Text(
                      'STANDARD VENDOR QUOTE',
                      style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ACISSA',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColor.fromInt(0xFF102A43)),
                    ),
                    pw.Text(
                      'Fecha: 29/10/2026',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 12),

            // 2. CUADRO DE METADATOS DEL FRENTE DE TRABAJO
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Supplier Name: ASOCIACION COMERCIAL DE INGENIERIA Y SERVICIOS SA DE CV', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(child: pw.Text('ERP Vendor ID: Shop F&F', style: pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Requester: $solicitante', style: pw.TextStyle(fontSize: 9))),
                      pw.Expanded(child: pw.Text('Project ID: $idProyecto', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Obra: $nombreObra', style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 6),
                  pw.Text('Especificación:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  pw.Text(descripcionGeneral, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey900)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 3. TABLA: DESGLOSE DE MANO DE OBRA (LABOR BREAKDOWN)
            pw.Text(
              '(A) LABOR BREAKDOWN',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromInt(0xFF102A43)),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F4F8)),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Worker Position', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cost per hour', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Quantity hours', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total Cost', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
                ...listaManoObraRaw.map((item) {
                  final String puesto = item.puestoController.text.isNotEmpty ? item.puestoController.text : 'Personal de Obra';
                  final double costo = double.tryParse(item.costoHoraController.text) ?? 0.0;
                  final double horas = double.tryParse(item.horasController.text) ?? 0.0;
                  final double totalRenglon = costo * horas;

                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(puesto, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('\$ ${costo.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(horas.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('\$ ${totalRenglon.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('(A) TOTAL LABOR COST: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('\$ ${metricas['mano_obra']!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 16),
            // 4. TABLA: DESGLOSE DE MATERIALES (MATERIAL BREAKDOWN)
            pw.Text(
              '(B) MATERIAL BREAKDOWN',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromInt(0xFF102A43)),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F4F8)),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Material List', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Unit Cost', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total Cost', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
                ...listaMaterialesRaw.map((item) {
                  final String concepto = item.conceptoController.text.isNotEmpty ? item.conceptoController.text : 'Insumo de Obra';
                  final double precio = double.tryParse(item.precioUnitarioController.text) ?? 0.0;
                  final double cantidad = double.tryParse(item.cantidadController.text) ?? 0.0;
                  final double totalRenglon = precio * cantidad;

                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(concepto, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('\$ ${precio.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(cantidad.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('\$ ${totalRenglon.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('(B) TOTAL MATERIAL COST: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('\$ ${metricas['materiales']!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 24),

            // 5. RESUMEN DE CONSOLIDACIÓN GENERAL Y DEDUCIBLES
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                     pw.SizedBox(height: 20),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),

                      pw.Text('Quote Prepared by: $preparadoPor', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ACISSA SELECCIÓN CON INGENIERÍA', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF0F4F8),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      children: [
                        _buildFilaPdf('Sub Total A+B+C:', '\$ ${metricas['subtotal_abc']!.toStringAsFixed(2)}', esBold: true),
                        _buildFilaPdf('Utilidad ACISSA (20%):', '\$ ${metricas['utilidad']!.toStringAsFixed(2)}'),
                        _buildFilaPdf('Comisión NAMFE (3%):', '\$ ${metricas['comision']!.toStringAsFixed(2)}'),
                        _buildFilaPdf('Monto Costo Deducible:', '\$ ${metricas['total_deducible']!.toStringAsFixed(2)}', esBold: true),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        _buildFilaPdf('IVA (16%):', '\$ ${metricas['iva']!.toStringAsFixed(2)}'),
                        _buildFilaPdf('GRAND TOTAL:', '\$ ${metricas['grand_total']!.toStringAsFixed(2)}', esBold: true, fontSize: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // 6. LANZAMIENTO DEL PROCESO DE IMPRESIÓN / GUARDADO NATIVO DEL NAVEGADOR
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Presupuesto_${idProyecto}_ACISSA.pdf',
    );
  }

  static pw.Widget _buildFilaPdf(String etiqueta, String valor, {bool esBold = false, double fontSize = 8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(etiqueta, style: pw.TextStyle(fontSize: fontSize, fontWeight: esBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(valor, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
