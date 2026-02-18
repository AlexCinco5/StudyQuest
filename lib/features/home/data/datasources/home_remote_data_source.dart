import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../models/document_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<DocumentModel>> getMyDocuments();
  Future<DocumentModel> uploadDocument(File file, String fileName);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final SupabaseClient supabaseClient;

  HomeRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<DocumentModel> uploadDocument(File file, String fileName) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw const ServerFailure("Usuario no autenticado");

      // 1. Subir archivo al Storage (Bucket 'pdfs')
      // Ruta: user_id/timestamp_nombre.pdf
      final fileExt = fileName.split('.').last;
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = '${user.id}/$uniqueName';

      await supabaseClient.storage.from('pdfs').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 2. Obtener la URL pública del archivo
      final publicUrl = supabaseClient.storage.from('pdfs').getPublicUrl(storagePath);

      // 3. Guardar la referencia en la Base de Datos
      final response = await supabaseClient.from('documents').insert({
        'user_id': user.id,
        'title': fileName, // Usamos el nombre del archivo como título inicial
        'file_url': publicUrl,
        'status': 'processing', // Inicialmente procesando
      }).select().single(); // .select().single() nos devuelve el registro creado

      return DocumentModel.fromJson(response);

    } catch (e) {
      throw ServerFailure('Error al subir documento: $e');
    }
  }

  @override
  Future<List<DocumentModel>> getMyDocuments() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw const ServerFailure("Usuario no autenticado");

      final response = await supabaseClient
          .from('documents')
          .select()
          .eq('user_id', user.id) // Solo mis documentos
          .order('created_at', ascending: false); // Los más nuevos primero

      return (response as List)
          .map((doc) => DocumentModel.fromJson(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al obtener documentos: $e');
    }
  }
}