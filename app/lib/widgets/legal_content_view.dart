import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class LegalContentView extends StatelessWidget {
  final String title;
  final String content;

  const LegalContentView({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- TEXTOS LEGALES ---

  static const String termsOfUse = """
TÉRMINOS DE USO - TIERRA DE CAMPEONES

Bienvenido a Tierra de Campeones. Al utilizar esta aplicación, aceptas los siguientes términos:

1. COMPROMISO DE LA COMUNIDAD
Nuestra misión es unir al mundo del boxeo. No se tolerará el acoso, el discurso de odio, el racismo o la violencia fuera del ámbito deportivo. Los usuarios que infrinjan estas normas podrán ser baneados permanentemente.

2. CONTENIDO Y STREAMING (ARENA)
El Arena es una vidriera para el deporte. Al compartir enlaces de streaming, confirmas que:
• El contenido cumple con las normas de la comunidad.
• Aceptas la responsabilidad de compartir dicho enlace y que el contenido es de libre acceso en su plataforma original.
• Entiendes que el contenido con 3 denuncias de la comunidad entrará en revisión automática.

3. RESPONSABILIDAD DEL USUARIO
Eres responsable de mantener la seguridad de tu cuenta y de toda la actividad que ocurra bajo tu perfil. Tierra de Campeones se reserva el derecho de moderar cualquier contenido que se considere inapropiado para el ecosistema profesional del boxeo.

4. COMERCIO (MARKETPLACE) Y EMPLEO
Tierra de Campeones actúa solo como plataforma de conexión. No somos responsables de las transacciones privadas entre usuarios en el Marketplace o en las búsquedas de empleo.

5. ACTUALIZACIONES
Podemos actualizar estos términos periódicamente para reflejar mejoras en la seguridad y funcionalidad de la app.
  """;

  static const String privacyPolicy = """
POLÍTICA DE PRIVACIDAD - TIERRA DE CAMPEONES

En Tierra de Campeones, valoramos tu privacidad. Esta política explica cómo manejamos tus datos:

1. DATOS RECOLECTADOS
Para proporcionarte una experiencia profesional, recolectamos:
• Información de perfil: Nombre, rol (boxeador, coach, etc.), historial deportivo y ubicación.
• Datos de contacto: Correo electrónico para autenticación y recuperación de cuenta.
• Interacciones: Mensajes del chat, likes y reportes realizados.

2. USO DE LA INFORMACIÓN
Utilizamos tus datos para:
• Permitir la interacción social y profesional entre miembros.
• Facilitar la búsqueda de talentos (Scouting).
• Notificarte sobre actividad relevante (likes, mensajes, nuevos eventos).

3. ALMACENAMIENTO Y SEGURIDAD
Tus datos se almacenan de forma segura utilizando la infraestructura de Supabase, que cumple con estándares internacionales de seguridad. Nunca compartimos tus datos personales con terceros con fines comerciales.

4. TUS DERECHOS
Puedes actualizar tu información personal en cualquier momento desde los ajustes. Si deseas dar de baja tu cuenta y borrar tus datos por completo, puedes contactar con nuestro soporte oficial.

5. CONTACTO
Si tienes dudas sobre tu privacidad, escríbenos a: tierradecampeonesapp@gmail.com
  """;
}
