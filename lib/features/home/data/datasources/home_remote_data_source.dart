import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../models/document_model.dart';

// Interfaz que define las operaciones remotas necesarias para la pantalla principal (Home).
// Establece un contrato estricto para recuperar el listado de documentos y subir nuevos archivos.
abstract class HomeRemoteDataSource {
  Future<List<DocumentModel>> getMyDocuments();
  Future<DocumentModel> uploadDocument(File file, String fileName);
}

// Implementacion concreta del data source utilizando el cliente de Supabase.
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  // Cliente inyectado para realizar operaciones de Storage y Base de Datos.
  final SupabaseClient supabaseClient;

  HomeRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<DocumentModel> uploadDocument(File file, String fileName) async {
    try {
      // Verificacion de sesion. Es mandatorio que exista un usuario activo para asociar el archivo.
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw const ServerFailure("Usuario no autenticado");

      // 1. Fase de preparacion para el Storage (Bucket 'pdfs').
      // Se extrae la extension original del archivo.
      final fileExt = fileName.split('.').last;
      
      // Se genera un nombre unico utilizando el timestamp actual (milisegundos) para evitar colisiones
      // de archivos con el mismo nombre.
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // La ruta logica dentro del bucket se estructura por ID de usuario para mantener el aislamiento de datos.
      final storagePath = '${user.id}/$uniqueName';

      // Ejecucion de la subida fisica del archivo al bucket 'pdfs'.
      await supabaseClient.storage.from('pdfs').upload(
            storagePath,
            file,
            // Opciones de cache configuradas para 1 hora (3600 segs) y upsert falso para no sobreescribir inadvertidamente.
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 2. Resolucion de la URL publica.
      // Una vez alojado el archivo, se solicita la URL estatica y publica para que el backend (el worker) pueda descargarlo.
      final publicUrl = supabaseClient.storage.from('pdfs').getPublicUrl(storagePath);

      // 3. Fase de persistencia en la Base de Datos.
      // Se inserta un nuevo registro en la tabla 'documents' vinculando el archivo al usuario.
      final response = await supabaseClient.from('documents').insert({
        'user_id': user.id,
        'title': fileName, // El titulo inicial es el nombre crudo del archivo hasta que la IA lo renombre.
        'file_url': publicUrl,
        'status': 'processing', // Bandera vital para que el worker sepa que debe procesar este registro.
      }).select().single(); // Retorna inmediatamente el registro creado en formato diccionario (Map).

      // Conversion del diccionario de Supabase al modelo de dominio de Dart.
      return DocumentModel.fromJson(response);

    } catch (e) {
      // Cualquier fallo en la subida, resolucion de URL o insercion en BD se consolida en un ServerFailure.
      throw ServerFailure('Error al subir documento: $e');
    }
  }

  @override
  Future<List<DocumentModel>> getMyDocuments() async {
    try {
      // Verificacion de seguridad inicial.
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw const ServerFailure("Usuario no autenticado");

      // Consulta a la tabla 'documents' aplicando filtros a nivel de base de datos.
      final response = await supabaseClient
          .from('documents')
          .select()
          .eq('user_id', user.id) // Cláusula WHERE: Restringe los resultados unicamente a los archivos dueños del usuario.
          .order('created_at', ascending: false); // Ordena cronológicamente inverso para mostrar el mas reciente primero.

      // Mapeo funcional de la lista cruda (List<dynamic>) a una lista tipada de DocumentModel.
      return (response as List)
          .map((doc) => DocumentModel.fromJson(doc))
          .toList();
    } catch (e) {
      // Captura de excepciones en la consulta de listado.
      throw ServerFailure('Error al obtener documentos: $e');
    }
  }
}