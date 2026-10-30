/*
 * ============================================================================
 *         🦺 CONTROL DE OBRA — DATA LAYER: LEVANTAMIENTO REPOSITORY
 * ============================================================================
 * Desarrollado para: Ing. Félix Vargas
 * Ruta Física: lib/modules/levantamientos/data/levantamiento_repository.dart
 * Lenguaje: Dart (Flutter)
 * Arquitectura: Clean Architecture - Data Layer (Preparación para Supabase)
 * ============================================================================
 */

import 'dart:typed_data';

/// Modelo de datos técnico para estructurar el paquete de datos en memoria del cliente.
/// Se eliminó por completo el método de mapeo JSON obsoleto orientado al Backend de Google.
class LevantamientoDataModel {
  final String idProyecto;
  final String tituloLevantamiento;
  final List<String> listaEquipos;
  final List<String> listaSeguridad;
  final List<Map<String, dynamic>> evidenciasFotograficas;

  const LevantamientoDataModel({
    required this.idProyecto,
    required this.tituloLevantamiento,
    required this.listaEquipos,
    required this.listaSeguridad,
    required this.evidenciasFotograficas,
  });
}

/// Repositorio central desacoplado de Google Apps Script.
/// Las llamadas estáticas tradicionales HTTP POST han sido removidas.
class LevantamientoRepository {
  
  /*
   * Utilería de bajo nivel encargada de procesar los bytes binarios de la imagen.
   * NOTA DE MIGRACIÓN: Ya no se requiere la conversión obligatoria a Base64
   * debido a que Supabase Storage acepta la carga directa de datos binarios (Uint8List).
   */
  bool validarBytesMultimedia(Uint8List bytes) {
    return bytes.isNotEmpty;
  }
  /*
   * Pipeline de abstracción técnica desacoplado de Google Sheets.
   * Recibe los controladores dinámicos directamente de la UI, filtra los elementos
   * seleccionados y empaqueta las referencias de manera asíncrona.
   * 
   * NOTA: Este método queda listo para inyectar el cliente de Supabase en el próximo paso.
   */
  Future<bool> procesarYEnviar({
    required String idProyecto,
    required String tituloLevantamiento,
    required List<dynamic> checklistEquiposRaw,
    required List<dynamic> checklistSeguridadRaw,
    required List<dynamic> listaEvidenciasRaw,
  }) async {
    try {
      // 1. Filtrado de los checklists para extraer únicamente las cadenas seleccionadas
      final List<String> equiposSeleccionados = checklistEquiposRaw
          .where((item) => item.seleccionado == true)
          .map((item) => item.nombre as String)
          .toList();

      final List<String> seguridadValidada = checklistSeguridadRaw
          .where((item) => item.seleccionado == true)
          .map((item) => item.nombre as String)
          .toList();

      // 2. Tubería multimedia optimizada para Supabase Storage (se conservan bytes puros)
      final List<Map<String, dynamic>> bloqueEvidenciasAProcesar = [];

      for (var evidencia in listaEvidenciasRaw) {
        if (validarBytesMultimedia(evidencia.bytesWeb)) {
          bloqueEvidenciasAProcesar.add({
            'bytes': evidencia.bytesWeb, // Listos para subida binaria a Bucket
            'nota_tecnica': evidencia.descripcionController.text,
          });
        }
      }

      // 3. Instanciación temporal del modelo de datos unificado
      
      final LevantamientoDataModel modeloListo = LevantamientoDataModel(
        idProyecto: idProyecto,
        tituloLevantamiento: tituloLevantamiento,
        listaEquipos: equiposSeleccionados,
        listaSeguridad: seguridadValidada,
        evidenciasFotograficas: bloqueEvidenciasAProcesar,
      );

      // Simulación de éxito temporal para no romper el flujo de la UI en la migración
      if (modeloListo.idProyecto.isEmpty) return false;
      return true;

    } catch (errorProcesamiento) {
      rethrow;
    }
  }
}
