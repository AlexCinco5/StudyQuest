import os
import time
import json
import google.generativeai as genai
from supabase import create_client, Client
from pypdf import PdfReader
from io import BytesIO
import requests
from dotenv import load_dotenv

# Cargar variables del archivo .env
load_dotenv()

# CONFIGURACIÓN SEGURA
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not all([SUPABASE_URL, SUPABASE_KEY, GEMINI_API_KEY]):
    raise Exception("❌ Faltan variables de entorno en backend/.env")

# Inicializar clientes
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_API_KEY)
# Usamos el modelo flash normal, que es más inteligente para estructurar JSONs complejos
model = genai.GenerativeModel('gemini-2.5-flash') 

def extract_text_from_pdf(url):
    print(f"   ⬇️ Descargando PDF: {url}...")
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception("Error al descargar PDF")
    
    print("   📖 Leyendo PDF...")
    f = BytesIO(response.content)
    reader = PdfReader(f)
    text = ""
    # Leemos hasta 15 páginas para tener mejor contexto
    for page in reader.pages[:15]: 
        text += page.extract_text() + "\n"
    return text

def generate_syllabus_with_ai(text):
    print("   🧠 IA Analizando estructura y temas...")
    
    prompt = f"""
    Actúa como un profesor experto. Analiza el siguiente texto extraído de un PDF educativo:
    
    --- COMIENZO TEXTO ---
    {text[:30000]} 
    --- FIN TEXTO ---
    
    Tu tarea es estructurar este texto en un curso. Extrae los temas principales (entre 2 y 4 temas dependiendo de la longitud).
    
    El formato JSON debe ser EXACTAMENTE así:
    {{
        "summary": "Un resumen general de todo el documento en 2 líneas.",
        "topics": [
            {{
                "title": "Nombre del Tema 1",
                "description": "Breve descripción de lo que trata este tema.",
                "flashcards": [
                    {{"front": "Concepto 1 del tema 1", "back": "Definición"}},
                    {{"front": "Concepto 2 del tema 1", "back": "Definición"}},
                    {{"front": "Concepto 3 del tema 1", "back": "Definición"}}
                ],
                "quizzes": [
                    {{
                        "question": "¿Pregunta sobre el tema 1?",
                        "options": ["A", "B", "C", "D"],
                        "correct_index": 0,
                        "explanation": "Por qué es correcta."
                    }},
                    {{
                        "question": "¿Otra pregunta sobre el tema 1?",
                        "options": ["A", "B", "C", "D"],
                        "correct_index": 2,
                        "explanation": "Por qué es correcta."
                    }}
                ]
            }},
            {{
                "title": "Nombre del Tema 2",
                "description": "Breve descripción...",
                "flashcards": [ ... ],
                "quizzes": [ ... ]
            }}
        ]
    }}
    
    Asegúrate de que cada tema tenga al menos 3 flashcards y 2 quizzes. Responde SOLO con el JSON válido, sin formato Markdown alrededor.
    """
    
    response = model.generate_content(prompt)
    try:
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_text)
    except Exception as e:
        print(f"Error parseando JSON estructural: {e}")
        print("Respuesta cruda de IA:", response.text)
        return None

def process_document(doc):
    doc_id = doc['id']
    print(f"\n🚀 Procesando documento: {doc['title']} ({doc_id})")
    
    try:
        # 1. Extraer texto
        pdf_text = extract_text_from_pdf(doc['file_url'])
        
        # 2. Generar IA (Estructura de Temas + Contenido)
        ai_data = generate_syllabus_with_ai(pdf_text)
        if not ai_data or 'topics' not in ai_data:
            raise Exception("IA no devolvió datos estructurados válidos")
        
        # 3. Guardar Temas y su contenido
        topics = ai_data['topics']
        print(f"   📑 IA encontró {len(topics)} temas. Guardando en cascada...")
        
        for index, topic_data in enumerate(topics):
            # A) Insertar el Tema (Nivel)
            topic_response = supabase.table('topics').insert({
                'document_id': doc_id,
                'title': topic_data['title'],
                'description': topic_data.get('description', ''),
                'order_index': index
            }).execute()
            
            # Obtener el ID del tema recién creado
            topic_id = topic_response.data[0]['id'] if hasattr(topic_response, 'data') else None
            
            # B) Insertar Flashcards vinculadas al Documento y al Tema
            if 'flashcards' in topic_data:
                for fc in topic_data['flashcards']:
                    supabase.table('flashcards').insert({
                        'document_id': doc_id,
                        'topic_id': topic_id,
                        'front_text': fc['front'],
                        'back_text': fc['back'],
                        'mastery_level': 1
                    }).execute()
            
            # C) Insertar Quizzes vinculadas al Documento y al Tema
            if 'quizzes' in topic_data:
                for q in topic_data['quizzes']:
                    supabase.table('quizzes').insert({
                        'document_id': doc_id,
                        'topic_id': topic_id,
                        'question_text': q['question'],
                        'options': q['options'],
                        'correct_answer_index': q['correct_index'],
                        'explanation': q.get('explanation', '')
                    }).execute()
                    
            print(f"      ✓ Tema '{topic_data['title']}' guardado con su contenido.")

        # 4. Actualizar Documento (Status y Resumen)
        print("   ✅ Finalizando proceso del documento...")
        supabase.table('documents').update({
            'status': 'ready',
            'summary_text': ai_data.get('summary', 'Resumen no generado.')
        }).eq('id', doc_id).execute()
        
        print("🎉 ¡Proceso completado con éxito!")

    except Exception as e:
        print(f"❌ Error procesando documento {doc_id}: {e}")
        # Solo actualizamos el status si logramos tener el doc_id
        supabase.table('documents').update({'status': 'error'}).eq('id', doc_id).execute()

def main():
    print("🤖 StudyQuest AI Worker (V2 - Syllabus Engine) iniciado...")
    print("Esperando documentos...")
    while True:
        try:
            response = supabase.table('documents').select("*").eq('status', 'processing').execute()
            # Validar si hay datos en la respuesta (depende de la versión de supabase-py)
            documents = response.data if hasattr(response, 'data') else response
            
            if documents and len(documents) > 0:
                for doc in documents:
                    process_document(doc)
            else:
                time.sleep(5)
        except Exception as e:
            print(f"Error general en el loop: {e}")
            time.sleep(10) # Esperar más si hay error de conexión

if __name__ == "__main__":
    main()