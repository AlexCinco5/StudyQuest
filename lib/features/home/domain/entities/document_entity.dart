import 'package:equatable/equatable.dart';

class DocumentEntity extends Equatable {
  final String id;
  final String title;
  final String fileUrl;
  final String? summary; // Puede ser nulo si la IA aun no termina
  final String status;   // 'processing', 'ready', 'error'
  final DateTime uploadDate;

  const DocumentEntity({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.summary,
    required this.status,
    required this.uploadDate,
  });

  @override
  List<Object?> get props => [id, title, fileUrl, status];
}