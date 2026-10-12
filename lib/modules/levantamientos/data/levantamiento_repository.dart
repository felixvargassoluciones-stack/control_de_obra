/*
 * ============================================================================
 *         🦺 CONTROL DE OBRA — DATA LAYER: LEVANTAMIENTO REPOSITORY
 * ============================================================================
 * Desarrollado para: Ing. Félix Vargas
 * Ruta Física: lib/modules/levantamientos/data/levantamiento_repository.dart
 * Arquitectura: Clean Architecture - Data Provider Modular
 * ============================================================================
 */

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
//import 'package:image_picker/image_picker.dart';

// Modelo de datos técnico para estructurar y mapear de forma segura el paquete
// JSON de salida hacia el endpoint de Google Apps Script.
class LevantamientoDataModel {
  final String idProyecto;
  final String tituloLevantamiento;
  final List<String> listaEquipos;
  final List<String> listaSeguridad;
  final List<Map<String, String>> evidenciasFotograficas;

  const LevantamientoDataModel({
    required this.idProyecto,
    required this.tituloLevantamiento,
    required this.listaEquipos,
    required this.listaSeguridad,
    required this.evidenciasFotograficas,
  });

  /*
   * Convierte la instancia del modelo en un mapa de llaves y valores (Map)
   * tipado estrictamente para cumplir con el contrato JSON del Backend.
   */
  Map<String, dynamic> toJson() {
    return {
      'id_proyecto': idProyecto,
      'titulo_levantamiento': tituloLevantamiento,
      'lista_equipos': listaEquipos,
      'lista_seguridad': listaSeguridad,
      'evidencias_fotograficas': evidenciasFotograficas,
    };
  }
}

// Repositorio central encargado de gestionar las llamadas de red, la codificación
// en Base64 de las evidencias en memoria y la transferencia HTTP hacia la nube.
class LevantamientoRepository {
  // Constante estricta del Endpoint de Producción de Google Apps Script.
  // REGLA: Pegue aquí la URL de la Aplicación Web generada en el paso anterior.
  static const String _endpointAppsScript = "https://script.google.com/macros/s/AKfycbyOZcIb-_VirLZmaRQcktYyKpT30zqK8xYu54-0D4C98n8SXqSo3BNRssIWKLYfgPLV/exec";

  /*
   * Utilería de bajo nivel encargada de procesar los bytes binarios de la imagen
   * y transformarlos en texto plano Base64 compatible con la web de GitHub Pages.
   * @param bytes Archivo de imagen cargado en la memoria RAM del cliente.
   * @return Cadena formateada lista para transmisión HTTP.
   */
  String convertirBytesABase64(Uint8List bytes) {
    if (bytes.isEmpty) return "";
    return base64Encode(bytes);
  }

  /*
   * Procesa la orquestación asíncrona de las evidencias de campo, serializa el contenido
   * y efectúa la petición de red HTTP POST hacia el API centralizado de Google.
   * @param modelo El contenedor estructurado con los datos del reporte.
   * @return Future<bool> Retorna verdadero si el Sheets confirmó la fila con código 200.
   */
  Future<bool> enviarReporteAAppsScript(LevantamientoDataModel modelo) async {
    try {
      // 1. Validación preventiva de existencia de la URL del endpoint de red
           // 1. Validación preventiva de existencia de la URL del endpoint de red
      if (_endpointAppsScript == "PEGA_AQUI_TU_URL_DE_EXEC_DE_GOOGLE" || _endpointAppsScript.isEmpty) {
        throw Exception("Error de Configuración Local: No se ha parametrizado el enlace URL definitivo de Google Apps Script.");
      }


      // 2. Parseo sintáctico de la URI del microservicio cloud
      final Uri urlServidor = Uri.parse(_endpointAppsScript);

      // 3. Serialización estricta del modelo de datos hacia una cadena JSON (String)
      final String cuerpoJsonSerializado = jsonEncode(modelo.toJson());

      // 4. Ejecución del canal HTTP POST inyectando cabeceras de control para evitar rebotes de CORS
      final http.Response respuestaServidor = await http.post(
        urlServidor,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: cuerpoJsonSerializado,
      ).timeout(
        const Duration(seconds: 45), // Tiempo senior de tolerancia para permitir la decodificación pesada de fotos en Drive
      );

      // 5. Análisis sintáctico del código de estatus del servidor web
      if (respuestaServidor.statusCode == 200) {
        final Map<String, dynamic> cuerpoRespuesta = jsonDecode(respuestaServidor.body) as Map<String, dynamic>;
        
        // Verificación del estatus lógico emitido por nuestra función generarRespuestaError en code.gs
        if (cuerpoRespuesta['status'] == 'SUCCESS') {
          return true;
        } else {
          throw Exception("Fallo lógico reportado por Apps Script: ${cuerpoRespuesta['message']}");
        }
      } else {
        throw Exception("Error de conexión externa. Código de error del servidor de Google: ${respuestaServidor.statusCode}");
      }

    } catch (excepcionRed) {
      // Propagación limpia del rastro del error hacia la capa de presentación para notificar al supervisor
      rethrow;
    }
  }
  /*
   * Método de abstracción técnica. Recibe los controladores dinámicos directamente de la UI,
   * extrae los bytes y descripciones, y empaqueta todo de forma asíncrona hacia el pipeline de red.
   */
  Future<bool> procesarYEnviar({
    required String idProyecto,
    required String tituloLevantamiento,
    required List<dynamic> checklistEquiposRaw,
    required List<dynamic> checklistSeguridadRaw,
    required List<dynamic> listaEvidenciasRaw,
  }) async {
    try {
      // 1. Filtrado quirúrgico de los checklists para extraer únicamente las cadenas seleccionadas
      final List<String> equiposSeleccionados = checklistEquiposRaw
          .where((item) => item.seleccionado == true)
          .map((item) => item.nombre as String)
          .toList();

      final List<String> seguridadValidada = checklistSeguridadRaw
          .where((item) => item.seleccionado == true)
          .map((item) => item.nombre as String)
          .toList();

      // 2. Tubería masiva de codificación Base64 para el arreglo multimedia de evidencias
      final List<Map<String, String>> bloqueEvidenciasSerializado = [];

      for (var evidencia in listaEvidenciasRaw) {
        // Conversión atómica de la memoria RAM del navegador a cadena de caracteres de red
        final String base64Imagen = convertirBytesABase64(evidencia.bytesWeb);
        final String notaPunto = evidencia.descripcionController.text;

        bloqueEvidenciasSerializado.add({
          'base64_data': base64Imagen,
          'nota_tecnica': notaPunto,
        });
      }

      // 3. Instanciación e inyección del modelo de datos unificado
      final LevantamientoDataModel modeloListoParaEnviar = LevantamientoDataModel(
        idProyecto: idProyecto,
        tituloLevantamiento: tituloLevantamiento,
        listaEquipos: equiposSeleccionados,
        listaSeguridad: seguridadValidada,
        evidenciasFotograficas: bloqueEvidenciasSerializado,
      );

      // 4. Disparo final hacia el bus HTTP POST de la nube de Google
      return await enviarReporteAAppsScript(modeloListoParaEnviar);

    } catch (errorProcesamiento) {
      rethrow;
    }
  }
 
}