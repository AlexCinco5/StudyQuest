import os
import time
import json
import google.generativeai as genai
from supabase import create_client, Client
from pypdf import PdfReader
from io import BytesIO
import requests
import os
from dotenv import load_dotenv # Importar esto

# Cargar variables del archivo .env
load_dotenv()

# --- CONFIGURACIÓN SEGURA ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not all([SUPABASE_URL, SUPABASE_KEY, GEMINI_API_KEY]):
    raise Exception("❌ Faltan variables de entorno en backend/.env")

# Inicializar clientes
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_API_KEY)

def extract_text_from_pdf(url):
    print(f"   ⬇️ Descargando PDF: {url}...")
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception("Error al descargar PDF")
    
    print("   📖 Leyendo PDF...")
    f = BytesIO(response.content)
    reader = PdfReader(f)
    text = ""
    # Leemos solo las primeras 10 páginas para no saturar tokens por ahora
    for page in reader.pages[:10]: 
        text += page.extract_text() + "\n"
    return text

def generate_content_with_ai(text):
    print("   🧠 Consultando a Gemini...")
    model = genai.GenerativeModel('gemini-2.5-flash-lite') # Modelo rápido y bueno
    
    prompt = f"""
    Actúa como un profesor experto. Analiza el siguiente texto extraído de un PDF educativo:
    
    --- COMIENZO TEXTO ---
    {text[:20000]} 
    --- FIN TEXTO ---

    (El texto está truncado).
    
    Tu tarea es generar contenido educativo en formato JSON estricto.
    Genera 2 cosas:
    1. "flashcards": Una lista de 5 conceptos clave (front: pregunta/concepto, back: definición/respuesta).
    2. "quizzes": Una lista de 3 preguntas de opción múltiple.
    
    El formato JSON debe ser exactamente así:
    {{
        "summary": "Un resumen breve del documento en 2 líneas.",
        "flashcards": [
            {{"front": "Pregunta 1", "back": "Respuesta 1"}},
            ...
        ],
        "quizzes": [
            {{
                "question": "¿Pregunta?",
                "options": ["Opción A", "Opción B", "Opción C", "Opción D"],
                "correct_index": 0,
                "explanation": "Por qué es correcta."
            }},
            ...
        ]
    }}
    Responde SOLO con el JSON.
    """
    
    response = model.generate_content(prompt)
    try:
        # Limpiamos por si el modelo pone ```json ... ```
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        return json.loads(clean_text)
    except Exception as e:
        print(f"Error parseando JSON: {e}")
        return None

def process_document(doc):
    doc_id = doc['id']
    print(f"🚀 Procesando documento: {doc['title']} ({doc_id})")
    
    try:
        # 1. Extraer texto
        pdf_text = extract_text_from_pdf(doc['file_url'])
        
        # 2. Generar IA
        ai_data = generate_content_with_ai(pdf_text)
        if not ai_data:
            raise Exception("IA no devolvió datos válidos")
        
        # 3. Guardar Flashcards
        print("   💾 Guardando Flashcards...")
        for fc in ai_data['flashcards']:
            supabase.table('flashcards').insert({
                'document_id': doc_id,
                'front_text': fc['front'],
                'back_text': fc['back'],
                'mastery_level': 1
            }).execute()

        # 4. Guardar Quizzes
        print("   💾 Guardando Quizzes...")
        for q in ai_data['quizzes']:
            supabase.table('quizzes').insert({
                'document_id': doc_id,
                'question_text': q['question'],
                'options': q['options'], # Supabase guarda arrays/json automáticamente
                'correct_answer_index': q['correct_index'],
                'explanation': q['explanation']
            }).execute()

        # 5. Actualizar Documento (Status y Resumen)
        print("   ✅ Finalizando...")
        supabase.table('documents').update({
            'status': 'ready',
            'summary_text': ai_data['summary']
        }).eq('id', doc_id).execute()
        
        print("🎉 ¡Proceso completado con éxito!")

    except Exception as e:
        print(f"❌ Error procesando: {e}")
        supabase.table('documents').update({'status': 'error'}).eq('id', doc_id).execute()

def main():
    print("🤖 StudyQuest AI Worker iniciado. Esperando documentos...")
    while True:
        # Buscar documentos en estado 'processing'
        response = supabase.table('documents').select("*").eq('status', 'processing').execute()
        documents = response.data
        
        if documents:
            for doc in documents:
                process_document(doc)
        else:
            # Si no hay nada, esperamos 5 segundos
            print(".", end="", flush=True)
            time.sleep(5)

if __name__ == "__main__":
    main()