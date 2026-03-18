# Importacion de dependencias del sistema y manejo de datos
import os
import time
import json
import traceback

# Librerias externas para IA, base de datos y manejo de PDFs
import google.generativeai as genai
from supabase import create_client, Client
from pypdf import PdfReader
from io import BytesIO
import requests

# Utilidad para cargar variables de entorno locales
from dotenv import load_dotenv

# Carga las variables del archivo .env al entorno de ejecucion
load_dotenv()

# Asignacion de credenciales a variables globales
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Validacion de seguridad para detener la ejecucion si faltan credenciales
if not all([SUPABASE_URL, SUPABASE_KEY, GEMINI_API_KEY]):
    raise Exception("❌ Faltan variables de entorno en backend/.env")

# Inicializacion de los clientes de Supabase y Gemini
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
genai.configure(api_key=GEMINI_API_KEY)

# Definicion del modelo a utilizar. Flash es optimo para parseo rapido de JSON.
model = genai.GenerativeModel('gemini-2.5-flash')

def extract_all_text_from_pdf(url):
    # Descarga el archivo PDF desde la URL proporcionada (Supabase Storage)
    print(f"   ⬇️ Descargando PDF completo: {url}...")
    response = requests.get(url)
    
    # Validacion basica de la respuesta HTTP
    if response.status_code != 200:
        raise Exception("Error al descargar PDF desde Supabase Storage")
    
    print("   📖 Leyendo PDF...")
    
    # Convierte el contenido binario descargado en un objeto leible para PdfReader
    f = BytesIO(response.content)
    reader = PdfReader(f)
    
    full_text = ""
    # Itera sobre todas las paginas del documento para extraer el texto plano
    for page in reader.pages:
        text = page.extract_text()
        if text:
            full_text += text + "\n"
            
    return full_text

def generate_content_for_chunk(chunk_text, chunk_index):
    # Esta funcion envia un fragmento de texto a la IA para generar el material interactivo
    print(f"   🧠 IA Analizando bloque {chunk_index}...")
    
    # Prompt estructurado con las reglas de negocio para la creacion de flashcards y quizzes
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
        # Peticion a la API de Gemini
        response = model.generate_content(prompt)
        
        # Limpieza de la respuesta para evitar errores de parseo si la IA incluye formato markdown
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        
        # Asegura extraer solo el contenido entre las llaves principales del JSON
        start_idx = clean_text.find('{')
        end_idx = clean_text.rfind('}') + 1
        clean_text = clean_text[start_idx:end_idx]
        
        # Convierte el string limpio a un diccionario de Python
        return json.loads(clean_text)
    except Exception as e:
        # Manejo de errores silencioso para no detener el proceso de otros bloques
        print(f"     ⚠️ Advertencia: IA falló en parsear el bloque {chunk_index}: {e}")
        return {"topics": []}

def generate_global_context(full_text):
    # Genera los metadatos globales del documento: un titulo corto y una guia en markdown
    print("   📝 Generando título corto y Guía de Estudio Maestra...")
    
    prompt = f"""
    Lee este documento de estudio.
    1. Crea un título corto, épico y atractivo (máximo 4 palabras) para este "mundo" de estudio (ej. "Redes Cisco", "Ciberseguridad", "Lógica Digital").
    2. Escribe una **Guía de Estudio** detallada, pedagógica y motivadora en formato Markdown. 
       - Usa encabezados (##), listas con viñetas (-) y **negritas** para resaltar conceptos clave.
       - Debe ser un resumen estructurado que cubra los puntos más importantes de todo el texto.
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
        # Limpieza de markdown del output
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        start_idx = clean_text.find('{')
        end_idx = clean_text.rfind('}') + 1
        return json.loads(clean_text[start_idx:end_idx])
    except Exception as e:
        # Valores por defecto en caso de que falle la generacion del contexto global
        print(f"Error generando contexto global: {e}")
        return {"short_title": "Mundo Inexplorado", "summary": "# Guía de Estudio\n\nEl resumen no pudo ser generado."}

def process_document(doc):
    # Flujo principal de procesamiento para un documento especifico
    doc_id = doc['id']
    print(f"\n🚀 Procesando documento: {doc['title']} ({doc_id})")
    
    try:
        # Obtiene el texto completo del PDF
        full_text = extract_all_text_from_pdf(doc['file_url'])
        
        # Valida que el documento no sea solo imagenes o este vacio
        if not full_text.strip():
            raise Exception("El PDF parece estar vacío o ser un PDF escaneado sin OCR.")
        
        # Genera metadatos globales (titulo y guia de estudio)
        global_context = generate_global_context(full_text)
        short_title = global_context.get("short_title", "Nuevo Mundo")
        global_summary = global_context.get("summary", "Resumen no disponible.")
        
        # Algoritmo de chunking: divide el texto en bloques para evitar exceder el limite de contexto de la IA
        chunk_size = 25000 
        chunks = [full_text[i:i+chunk_size] for i in range(0, len(full_text), chunk_size)]
        
        print(f"   ✂️ Documento dividido en {len(chunks)} bloques lógicos.")
        
        all_topics = []
        global_topic_index = 0
        
        # Itera sobre cada fragmento de texto
        for i, chunk in enumerate(chunks):
            # Control de rate limit para la API
            if i > 0: time.sleep(2) 
            
            ai_data = generate_content_for_chunk(chunk, i + 1)
            
            # Filtra e ignora los temas que no contengan material interactivo util
            if 'topics' in ai_data:
                for topic in ai_data['topics']:
                    if len(topic.get('flashcards', [])) > 0 or len(topic.get('quizzes', [])) > 0:
                        all_topics.append(topic)
                        
        print(f"   📑 IA encontró un total de {len(all_topics)} temas en todo el PDF. Guardando en DB...")
        
        # Persistencia de datos en cascada hacia Supabase
        for index, topic_data in enumerate(all_topics):
            # Inserta el tema y recupera su ID generado por la base de datos
            topic_response = supabase.table('topics').insert({
                'document_id': doc_id,
                'title': topic_data['title'],
                'description': topic_data.get('description', ''),
                'order_index': index
            }).execute()
            
            topic_id = topic_response.data[0]['id']
            
            # Preparacion e insercion en lote (bulk insert) para flashcards
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
            
            # Preparacion e insercion en lote (bulk insert) para quizzes
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

        # Actualiza el registro del documento original marcandolo como listo
        print(f"   ✅ Renombrando a '{short_title}' y finalizando...")
        supabase.table('documents').update({
            'title': short_title,
            'status': 'ready',
            'summary_text': global_summary
        }).eq('id', doc_id).execute()
        
        print("🎉 ¡Proceso completado con éxito! El mundo está listo para jugarse.")

    except Exception as e:
        # Captura errores fatales, imprime el stacktrace y marca el documento como erroneo
        print(f"❌ Error crítico procesando documento {doc_id}: {e}")
        traceback.print_exc() 
        try:
            supabase.table('documents').update({'status': 'error'}).eq('id', doc_id).execute()
        except:
            pass

def main():
    # Punto de entrada del worker. Loop infinito que revisa trabajos pendientes en la cola.
    print("🤖 StudyQuest AI Worker (V4 - Auto-Nombramiento) iniciado...")
    print("Esperando documentos en la cola...")
    while True:
        try:
            # Consulta a Supabase por documentos que tengan el estatus 'processing'
            response = supabase.table('documents').select("*").eq('status', 'processing').execute()
            documents = response.data if hasattr(response, 'data') else response
            
            # Si hay documentos en la cola, los procesa secuencialmente
            if documents and len(documents) > 0:
                for doc in documents:
                    process_document(doc)
            else:
                # Si la cola esta vacia, el thread duerme para no saturar la API
                time.sleep(5)
        except Exception as e:
            # Manejo de desconexiones de red u otros errores externos durante el polling
            print(f"Error de conexión en el loop principal: {e}")
            time.sleep(10)

# Verificacion estandar de Python para ejecutar el bloque main solo si el script se corre directamente
if __name__ == "__main__":
    main()