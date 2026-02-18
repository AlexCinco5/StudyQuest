import google.generativeai as genai

# PON TU API KEY AQUÍ
API_KEY = "AIzaSyDkekl-GoI5TB1nvTVpOgr3BBruOxySfDY" 

genai.configure(api_key=API_KEY)

print("🔍 Buscando modelos disponibles para tu API Key...")
try:
    available_models = []
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"  ✅ Disponible: {m.name}")
            available_models.append(m.name)
            
    if not available_models:
        print("❌ No se encontraron modelos. Verifica tu API Key o la consola de Google Cloud.")
except Exception as e:
    print(f"❌ Error conectando: {e}")