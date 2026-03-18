# Importaciones básicas de Python para manejar archivos, pausas y formatos de texto
import os
import time
import json
import traceback

# Librerías pesadas para conectarnos a la IA, a la base de datos y para leer PDFs
import google.generativeai as genai
from supabase import create_client, Client
from pypdf import PdfReader
from io import BytesIO
import requests

# Truco de seguridad: Intenta cargar el archivo .env si estás en tu computadora.
# Si estás en Render (donde no hay archivo .env), ignora el error y sigue adelante.
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# Jalamos las contraseñas secretas de forma segura
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

# Seguro de vida: Si el script no encuentra las claves, se apaga para no romper nada
if not all([SUPABASE_URL, SUPABASE_KEY, GEMINI_API_KEY]):
    raise Exception("❌ Faltan contraseñas. Revisa tu archivo .env o el panel de Render.")

# Encendemos los motores de la base de datos y de la inteligencia artificial
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_API_KEY)

# Usamos el modelo 'flash' porque es el más rápido y obedece muy bien el formato JSON
model = genai.GenerativeModel('gemini-2.5-flash')

# Función que toma la URL del PDF que se guardó en Supabase y le saca todo el texto
def extract_all_text_from_pdf(url):
    print(f"   ⬇️ Descargando PDF completo: {url}...")
    response = requests.get(url)
    
    # Si la descarga falla (ej. internet caído), lanzamos un error
    if response.status_code != 200:
        raise Exception("Error al descargar PDF desde la nube")
    
    print("   📖 Leyendo PDF...")
    
    # BytesIO simula que el archivo descargado es un archivo físico real en la compu
    f = BytesIO(response.content)
    reader = PdfReader(f)
    
    full_text = ""
    # Hojeamos el PDF página por página sacando las letras
    for page in reader.pages:
        text = page.extract_text()
        if text:
            full_text += text + "\n"
            
    return full_text

# Función que le manda un pedazo de texto a la IA para que invente las preguntas
def generate_content_for_chunk(chunk_text, chunk_index):
    print(f"   🧠 IA Analizando bloque {chunk_index}...")
    
    # Las instrucciones estrictas para que la IA no nos conteste como chat, sino con datos
    prompt = f"""
    Actúa como un profesor universitario riguroso. Analiza esta sección extraída de un material de estudio.
    
    --- COMIENZO SECCIÓN ---
    {chunk_text} 
    --- FIN SECCIÓN ---
    
    Tu tarea es extraer los conceptos clave de esta sección específica y crear material de estudio. 
    Dependiendo de la cantidad de información en esta sección, crea entre 1 y 3 Temas ("topics").
    
    Reglas estrictas para el JSON:
    1. Si no hay información relevante en este texto (ej. es un índice o bibliografía), devuelve "topics": []
    2. Cada tema debe tener entre 3 y 5 flashcards con conceptos CRUCIALES.
    3. Cada tema debe tener entre 4 y 6 quizzes (opción múltiple, 4 opciones).
    4. Las opciones de los quizzes no deben ser obvias, incluye distractores creíbles.
    5. Solo responde con el JSON puro, sin comillas Markdown de código (```json).
    
    Formato esperado:
    {{
        "topics": [
            {{
                "title": "Nombre del Tema (Específico, no general)",
                "description": "Breve descripción de lo que trata este tema.",
                "flashcards": [
                    {{"front": "Concepto o Pregunta directa", "back": "Definición clara y concisa"}}
                ],
                "quizzes": [
                    {{
                        "question": "Pregunta analítica sobre el tema",
                        "options": ["A", "B", "C", "D"],
                        "correct_index": 0,
                        "explanation": "Por qué es correcta."
                    }}
                ]
            }}
        ]
    }}
    """
    
    try:
        # Mandamos el texto a Google
        response = model.generate_content(prompt)
        
        # Limpiamos la respuesta por si la IA le pone comillas raras o formato de código
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        
        # Recortamos exactamente desde la primera llave { hasta la última }
        start_idx = clean_text.find('{')
        end_idx = clean_text.rfind('}') + 1
        clean_text = clean_text[start_idx:end_idx]
        
        # Convertimos ese texto en un diccionario real de Python
        return json.loads(clean_text)
    except Exception as e:
        # Si la IA alucina o se equivoca de formato, no rompemos todo, solo ignoramos este bloque
        print(f"     ⚠️ Advertencia: IA falló en parsear el bloque {chunk_index}: {e}")
        return {"topics": []}

# Función para inventar un título pegajoso y un resumen general de todo el PDF
def generate_global_context(full_text):
    print("   📝 Generando título corto y Guía de Estudio Maestra...")
    
    prompt = f"""
    Lee este documento de estudio.
    1. Crea un título corto, épico y atractivo (máximo 4 palabras) para este "mundo" de estudio.
    2. Escribe una **Guía de Estudio** detallada, pedagógica y motivadora en formato Markdown. 
       - Usa encabezados (##), listas con viñetas (-) y **negritas**.
       - Usa saltos de línea reales usando '\\n' para que el JSON no se rompa.

    Devuelve SOLO un JSON con este formato exacto:
    {{
        "short_title": "Nombre Corto del Mundo",
        "summary": "# Guía de Estudio\\n\\nAquí va el resumen completo en Markdown con sus \\n\\n saltos de línea..."
    }}
    
    Inicio del documento:
    {full_text[:6000]}
    
    ...
    
    Final del documento:
    {full_text[-6000:]}
    """
    
    try:
        response = model.generate_content(prompt)
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        start_idx = clean_text.find('{')
        end_idx = clean_text.rfind('}') + 1
        return json.loads(clean_text[start_idx:end_idx])
    except Exception as e:
        # Si falla, le ponemos datos por defecto para que la app no se quede en blanco
        print(f"Error generando contexto global: {e}")
        return {"short_title": "Mundo Inexplorado", "summary": "# Guía de Estudio\n\nEl resumen no pudo ser generado."}

# La máquina principal que ensambla todo el proceso para un solo PDF
def process_document(doc):
    doc_id = doc['id']
    print(f"\n🚀 Procesando documento: {doc['title']} ({doc_id})")
    
    try:
        full_text = extract_all_text_from_pdf(doc['file_url'])
        
        # Si el PDF era puro escaneo de fotos y no hay texto seleccionable, marcamos error
        if not full_text.strip():
            raise Exception("El PDF parece estar vacío o ser un PDF escaneado sin OCR.")
        
        global_context = generate_global_context(full_text)
        short_title = global_context.get("short_title", "Nuevo Mundo")
        global_summary = global_context.get("summary", "Resumen no disponible.")
        
        # Partimos el texto gigante en pedazos de 25,000 caracteres para no ahogar a la IA
        chunk_size = 25000 
        chunks = [full_text[i:i+chunk_size] for i in range(0, len(full_text), chunk_size)]
        
        print(f"   ✂️ Documento dividido en {len(chunks)} bloques lógicos.")
        
        all_topics = []
        
        for i, chunk in enumerate(chunks):
            # Le damos 2 segundos de respiro a la IA entre preguntas para que no nos bloquee
            if i > 0: time.sleep(2) 
            
            ai_data = generate_content_for_chunk(chunk, i + 1)
            
            # Solo guardamos los temas que sí traigan tarjetas o preguntas de examen
            if 'topics' in ai_data:
                for topic in ai_data['topics']:
                    if len(topic.get('flashcards', [])) > 0 or len(topic.get('quizzes', [])) > 0:
                        all_topics.append(topic)
                        
        print(f"   📑 IA encontró un total de {len(all_topics)} temas. Guardando en DB...")
        
        # Guardado en cascada: Primero guardamos el Tema, luego sus Tarjetas y luego sus Preguntas
        for index, topic_data in enumerate(all_topics):
            topic_response = supabase.table('topics').insert({
                'document_id': doc_id,
                'title': topic_data['title'],
                'description': topic_data.get('description', ''),
                'order_index': index
            }).execute()
            
            # Sacamos el ID que la base de datos le inventó a este tema recién creado
            topic_id = topic_response.data[0]['id']
            
            # Guardamos todas las flashcards de golpe (bulk insert) para ahorrar tiempo
            if 'flashcards' in topic_data:
                flashcards_to_insert = []
                for fc in topic_data['flashcards']:
                    flashcards_to_insert.append({
                        'document_id': doc_id,
                        'topic_id': topic_id,
                        'front_text': fc['front'],
                        'back_text': fc['back'],
                        'mastery_level': 1
                    })
                if flashcards_to_insert:
                    supabase.table('flashcards').insert(flashcards_to_insert).execute()
            
            # Guardamos todas las preguntas de examen de golpe
            if 'quizzes' in topic_data:
                quizzes_to_insert = []
                for q in topic_data['quizzes']:
                    quizzes_to_insert.append({
                        'document_id': doc_id,
                        'topic_id': topic_id,
                        'question_text': q['question'],
                        'options': q['options'],
                        'correct_answer_index': q['correct_index'],
                        'explanation': q.get('explanation', '')
                    })
                if quizzes_to_insert:
                    supabase.table('quizzes').insert(quizzes_to_insert).execute()
                    
            print(f"      ✓ Nivel '{topic_data['title']}' configurado.")

        # Cuando terminamos todo, le decimos a la base de datos que este mundo ya está jugable
        print(f"   ✅ Renombrando a '{short_title}' y finalizando...")
        supabase.table('documents').update({
            'title': short_title,
            'status': 'ready', # ¡Aquí ocurre la magia que desbloquea la app en el celular!
            'summary_text': global_summary
        }).eq('id', doc_id).execute()
        
        print("🎉 ¡Proceso completado con éxito! El mundo está listo para jugarse.")

    except Exception as e:
        # Si algo explota feo, pintamos el error y marcamos el PDF como fallido para que el usuario sepa
        print(f"❌ Error crítico procesando documento {doc_id}: {e}")
        traceback.print_exc() 
        try:
            supabase.table('documents').update({'status': 'error'}).eq('id', doc_id).execute()
        except:
            pass

# El vigilante infinito: se queda prendido 24/7 buscando trabajo nuevo
def main():
    print("🤖 StudyQuest AI Worker iniciado...")
    print("Esperando documentos en la cola...")
    
    # Este 'while True' es el que mantiene al servidor de Render vivo para siempre
    while True:
        try:
            # Preguntamos si hay algún PDF nuevo que el celular haya dejado en estado 'processing'
            response = supabase.table('documents').select("*").eq('status', 'processing').execute()
            documents = response.data if hasattr(response, 'data') else response
            
            # Si hay trabajo, lo hacemos uno por uno
            if documents and len(documents) > 0:
                for doc in documents:
                    process_document(doc)
            else:
                # Si no hay nada, el trabajador "duerme" 5 segundos antes de volver a preguntar
                time.sleep(5)
        except Exception as e:
            # Si se cae el internet de Render por un segundo, no apagamos el script, solo esperamos
            print(f"Error de conexión en el loop principal: {e}")
            time.sleep(10)

# Verificamos que este archivo se esté ejecutando directamente y arrancamos
if __name__ == "__main__":
    main()