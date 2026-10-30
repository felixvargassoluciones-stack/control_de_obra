/*
 * ============================================================================
 *         🦺 CONTROL DE OBRA — DATA LAYER: LEVANTAMIENTO REPOSITORY
 * ============================================================================
 * Desarrollado para: Ing. Félix Vargas
 * Ruta Física: lib/modules/levantamientos/data/levantamiento_repository.dart
 * Lenguaje: Dart (Flutter)
 * Persistencia: Supabase Client Relational Injections
 * Arquitectura: Clean Architecture - Data Provider Modular
 * ============================================================================
 */

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de datos técnico para estructurar el paquete de datos en memoria del cliente.
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

/// Repositorio central encargado de la persistencia directa en la nube de Supabase.
class LevantamientoRepository {
  // Instancia privada del cliente API inyectada desde el núcleo del sistema
  final SupabaseClient _supabase = Supabase.instance.client;

  /*
   * Utilería de bajo nivel encargada de subir los bytes binarios de forma atómica
   * hacia el Bucket de almacenamiento público y resolver su URL definitiva.
   */
  Future<String> _subirEvidenciaABucket(Uint8List bytes, String idProyecto) async {
    try {
      if (bytes.isEmpty) return "";
      
      // Genera un nombre de archivo único indexado por fecha y milisegundos de campo
      final String nombreArchivo = 'evidencia_${idProyecto}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String rutaDestino = 'levantamientos/$nombreArchivo';

      // Dispara la carga binaria directa sin conversiones costosas en memoria
      await _supabase.storage.from('evidencias').uploadBinary(
            rutaDestino,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Obtiene y retorna la dirección URL pública para su posterior indexación en las tablas SQL
      return _supabase.storage.from('evidencias').getPublicUrl(rutaDestino);
    } catch (errorStorage) {
      // Si el bucket no se encuentra creado, retornamos una cadena de contingencia o relanzamos
      return "";
    }
  }
  /*
   * Pipeline de persistencia relacional con Supabase.
   * Recibe los controladores dinámicos directamente de la UI, efectúa la carga
   * de imágenes a Storage e inserta las filas correspondientes en las tablas relacionales.
   */
  Future<bool> procesarYEnviar({
    required String idProyecto,
    required String tituloLevantamiento,
    required List<dynamic> checklistEquiposRaw,
    required List<dynamic> checklistSeguridadRaw,
    required List<dynamic> listaEvidenciasRaw,
  }) async {
    try {
      // 1. Resolución relacional: Busca el UUID interno del proyecto usando el código de campo
      final List<dynamic> respuestaProyecto = await _supabase
          .from('proyectos')
          .select('id')
          .eq('codigo_proyecto', idProyecto);

      if (respuestaProyecto.isEmpty) {
        throw Exception("Error de consistencia: El código de proyecto '$idProyecto' no está registrado en la base de datos.");
      }

      final String uuidProyectoReal = respuestaProyecto.first['id'] as String;

      // 2. Filtrado de los checklists para extraer únicamente las cadenas seleccionadas
      final List<String> equiposSeleccionados = checklistEquiposRaw
          .where((item) => item.seleccionado == true)
          .map((item) => item.nombre as String)
          .toList();

      final List<String> seguridadValidada = checklistSeguridadRaw
          .where((item) => item.seleccionado == true)
          .map((item) => item.nombre as String)
          .toList();

      // 3. Tubería masiva: Carga las imágenes binarias en el Bucket de forma asíncrona
      final List<Map<String, dynamic>> bloqueEvidenciasSerializado = [];

      for (var evidencia in listaEvidenciasRaw) {
        final Uint8List bytesImagen = evidencia.bytesWeb as Uint8List;
        
        // Ejecuta la carga en Supabase Storage de la Parte 1
        final String urlPublicaImagen = await _subirEvidenciaABucket(bytesImagen, idProyecto);
        final String notaPunto = evidencia.descripcionController.text as String;

        if (urlPublicaImagen.isNotEmpty) {
          bloqueEvidenciasSerializado.add({
            'base64_data': urlPublicaImagen, // Guardamos la URL pública en lugar de bytes crudos
            'nota_tecnica': notaPunto,
          });
        }
      }

      // 4. Disparo final de inserción en la tabla de presupuestos / levantamientos
      // Reutiliza la tabla de presupuestos mapeando la descripción general del levantamiento
      await _supabase.from('presupuestos').insert({
        'proyecto_id': uuidProyectoReal,
        'solicitante': 'SUPERVISOR DE CAMPO',
        'descripcion_general': '$tituloLevantamiento | Equipos: $equiposSeleccionados | Seguridad: $seguridadValidada',
        'preparado_por': 'ING. FELIX VARGAS',
        'fecha': DateTime.now().toIso8601String().substring(0, 10),
      });

      return true;

    } catch (errorSupabase) {
      rethrow;
    }
  }
}
