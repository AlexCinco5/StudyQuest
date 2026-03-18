import 'package:flutter/material.dart';
// Librería especial para poder mostrar texto con formato (negritas, listas, títulos) tipo Markdown
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

// Pantalla donde se muestra el resumen de texto que la IA generó para el PDF.
class StudyGuidePage extends StatefulWidget {
  // Necesitamos el ID del documento para buscarlo en la base de datos
  final String documentId;
  final String worldTitle;

  const StudyGuidePage({
    super.key,
    required this.documentId,
    required this.worldTitle,
  });

  @override
  State<StudyGuidePage> createState() => _StudyGuidePageState();
}

class _StudyGuidePageState extends State<StudyGuidePage> {
  // Variable para saber si el internet sigue cargando el texto
  bool _isLoading = true;
  // Aquí guardaremos el texto largo que nos mande la IA
  String _markdownData = "";

  @override
  void initState() {
    super.initState();
    // Apenas se abre la pantalla, mandamos a traer el resumen
    _fetchSummary();
  }

  // Función para ir a Supabase por el texto del resumen
  Future<void> _fetchSummary() async {
    try {
      // Buscamos en la tabla 'documents', específicamente la columna 'summary_text'
      final response = await Supabase.instance.client
          .from('documents')
          .select('summary_text')
          .eq('id', widget.documentId)
          .single();

      setState(() {
        // Si el resumen existe lo guardamos, si no, ponemos un aviso
        _markdownData = response['summary_text'] ?? "No hay resumen disponible.";
        _isLoading = false;
      });
    } catch (e) {
      // Si el internet falla, avisamos en pantalla
      setState(() {
        _markdownData = "Hubo un error al cargar la guía: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo gris clarito
      appBar: AppBar(
        title: Text("Guía: ${widget.worldTitle}"),
        centerTitle: true,
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Si está cargando, mostramos la bolita de carga. Si no, mostramos el texto con formato.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
          : Markdown(
              // Este widget toma el texto plano y lo dibuja con estilos bonitos
              data: _markdownData,
              // Aquí personalizamos cómo se ven los títulos y los párrafos
              styleSheet: MarkdownStyleSheet(
                // Los títulos grandes van en azul oscuro
                h1: const TextStyle(color: AppTheme.darkBlue, fontSize: 24, fontWeight: FontWeight.bold),
                // Los subtítulos van en turquesa
                h2: TextStyle(color: AppTheme.teal, fontSize: 20, fontWeight: FontWeight.bold),
                // El texto normal tiene un espacio entre líneas cómodo para leer
                p: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                // Los puntitos de las listas van en turquesa
                listBullet: const TextStyle(color: AppTheme.teal, fontSize: 18),
              ),
            ),
    );
  }
}