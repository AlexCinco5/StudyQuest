import '../../domain/entities/document_entity.dart';

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    required super.id,
    required super.title,
    required super.fileUrl,
    super.summary,
    required super.status,
    required super.uploadDate,
  });

  // De JSON (Supabase) a Dart
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      title: json['title'],
      fileUrl: json['file_url'],
      summary: json['summary_text'], // Nota: en DB se llama summary_text
      status: json['status'] ?? 'processing',
      uploadDate: DateTime.parse(json['created_at']),
    );
  }

  // De Dart a JSON (para subir a Supabase)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'file_url': fileUrl,
      'status': status,
      // No enviamos ID ni fechas porque Supabase los genera
    };
  }
}