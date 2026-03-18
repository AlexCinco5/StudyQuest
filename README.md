<div align="center">
  
  # 🚀 StudyQuest
  **Convierte tus PDFs aburridos en un videojuego**

  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
  ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
  ![Render](https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white)

</div>

---

Seamos honestos: leer un PDF de 50 páginas un día antes del examen es horrible. La retención es bajísima y es súper aburrido. Por eso nació **StudyQuest**. 

Esta aplicación toma cualquier documento de estudio, lo procesa usando Inteligencia Artificial y lo transforma literalmente en un mapa de niveles interactivo (estilo Duolingo o Candy Crush). En lugar de leer bloques de texto interminables, estudias jugando, ganando puntos de experiencia y compitiendo contra ti mismo para mantener tu racha diaria.

## ✨ ¿Qué hace a StudyQuest tan increíble?

* 🤖 **Creación de Mundos con IA:** Tú solo subes tu PDF. La app se encarga de leerlo, analizarlo y dividirlo lógicamente en "Temas" o "Niveles". Cada documento es un nuevo mundo por explorar.
* 🗺️ **Mapas de Aprendizaje Progresivo:** No puedes saltarte al final. Los temas están bloqueados; tienes que demostrar que dominas el concepto anterior para poder avanzar.
* 🃏 **Flashcards Inteligentes (Estilo Anki):** Tarjetas de memoria con repetición espaciada. Si te sabes la respuesta, la tarjeta sale del mazo. Si te equivocas, se va al final de la fila para obligarte a repasar. Además, ¡el sistema lee las tarjetas en voz alta para que repases mientras haces otras cosas!
* 🎮 **Quizzes con Vidas (Modo Supervivencia):** Exámenes rápidos de opción múltiple. Tienes 3 corazones; si los pierdes todos, es *Game Over* y tienes que volver a intentar. Si pasas, te llevas tu recompensa con lluvia de confeti y efectos de sonido.
* 💎 **Gamificación Pura:** Gana puntos XP por cada nivel superado y mantén viva tu racha ("fuego") estudiando todos los días. 
* 📖 **Guías de Estudio Generadas:** Si de plano necesitas leer, la app te genera un resumen estructurado y limpio de todo el documento.

---

## 🔗 Enlaces Importantes

* 📥 **[Descargar la App (APK para Android)](https://drive.google.com/drive/folders/1xeK7F2ebfgWrevPQ9UjAacEdkKCr3O-6?usp=sharing)**
* 📚 **[Documentación Técnica y Arquitectura](https://deepwiki.com/AlexCinco5/StudyQuest/1-overview)**

---

## 📱 ¿Cómo instalo la app en mi celular Android?

Como la app es completamente nueva y la estás descargando directamente, Android te va a pedir un permiso especial. Es súper rápido, solo sigue estos pasos:

1. Entra al enlace de descarga desde tu celular y descarga el archivo `.apk`.
2. Ve a tu carpeta de **Descargas** (o tira de la barra de notificaciones hacia abajo) y toca el archivo que acabas de bajar.
3. Te saldrá un aviso diciendo que *el teléfono bloqueó la instalación por seguridad* (esto pasa con cualquier app que no venga de la Play Store). Toca en **Configuración** o **Ajustes** en ese mismo cuadro.
4. Activa la opción que dice **Permitir desde esta fuente** (o "Instalar aplicaciones desconocidas"). Dale atrás, toca **Instalar** ¡y listo! 

---

## 🛠️ Tecnología y Ecosistema detrás de la magia

Este proyecto no es solo una cara bonita, está construido con estándares de la industria para asegurar que escale y no se trabe. Nuestro ecosistema no se queda solo en el celular, está respaldado por una sólida arquitectura en la nube:

- **Frontend Móvil:** `Flutter` & `Dart` para una interfaz fluida, nativa y animaciones 3D.
- **Arquitectura Limpia:** Uso de `Clean Architecture` & `BLoC`. Código completamente modular, separando la interfaz de la lógica de negocio para un rendimiento impecable y libre de *spaghetti code*.
- **Backend y Base de Datos:** `Supabase` (PostgreSQL). Autenticación segura y almacenamiento de PDFs en la nube. Tu progreso se guarda en tiempo real.
- **Motor de Inteligencia Artificial:** Un *worker* independiente desarrollado en `Python` y alojado en **Render**, encargado de procesar los PDFs en segundo plano y comunicarse con la API de Google Gemini.
- **Automatización (Bot Centinela):** Implementamos un bot automatizado (UptimeRobot) que monitorea la salud de nuestro servidor de IA haciéndole "ping" constantemente. Esto asegura que el "cerebro" de la app esté despierto 24/7, listo para procesar tus apuntes a cualquier hora sin interrupciones ni tiempos de espera.

---