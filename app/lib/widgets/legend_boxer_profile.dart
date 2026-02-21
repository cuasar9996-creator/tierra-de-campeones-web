import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import '../core/app_colors.dart'; // Verified unused in this file

class LegendBoxerProfile extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isMe;

  // Paleta de Colores Exclusiva para Leyendas
  static const Color goldPrimary = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFAA8E00);
  static const Color legendBlack = Color(0xFF0F0F0F);

  const LegendBoxerProfile({
    super.key,
    required this.userData,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // Datos seguros
    final record = userData['extraData']?['record'] ?? 'Invicto';
    final nickname = userData['extraData']?['nickname'] ?? 'El Grande';
    final location = userData['currentLocation'] ?? 'Salón de la Fama';
    final bio = userData['bio'] ?? 'Una leyenda viviente del boxeo mundial.';

    // Logros Épicos
    final achievements =
        (userData['achievements'] ??
                userData['extraData']?['achievements'] ??
                'Campeón Mundial Unificado')
            .toString();
    final greatestFight = (userData['greatestFight'] ?? 'La Pelea del Siglo')
        .toString();

    return Container(
      color: legendBlack, // Fondo total negro premium
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabecera Heroica (Dorado)
          _buildHeroHeader(context, nickname, location),

          const SizedBox(height: 30),

          // 2. Insignia de Honor
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: goldPrimary.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(30),
                color: goldPrimary.withOpacity(0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    FontAwesomeIcons.crown,
                    color: goldPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'STATUS: LEYENDA VIVIENTE',
                    style: GoogleFonts.lexend(
                      color: goldPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 3. Vitrina de Trofeos (Logros)
          Container(
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [goldDark.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(left: BorderSide(color: goldPrimary, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEGADO INMORTAL',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                if (userData['achievements'] is List ||
                    (userData['extraData'] != null &&
                        userData['extraData']['achievements'] is List)) ...[
                  ...((userData['achievements'] ??
                              userData['extraData']['achievements'])
                          as List)
                      .map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            (item['text'] ?? '').toString().toUpperCase(),
                            style: GoogleFonts.libreBaskerville(
                              color: Colors.white,
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }),
                ] else
                  Text(
                    achievements.toUpperCase(),
                    style: GoogleFonts.libreBaskerville(
                      // Fuente clásica
                      color: Colors.white,
                      fontSize: 22,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.star, color: goldPrimary, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Pelea Histórica: $greatestFight',
                      style: const TextStyle(color: goldPrimary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 4. Estadística Final
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendStat('RÉCORD FINAL', record),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildLegendStat(
                'AÑOS ACTIVO',
                '1990-2010',
              ), // Placeholder o dato real
            ],
          ),

          const SizedBox(height: 40),

          // 5. Bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              '"$bio"',
              textAlign: TextAlign.center,
              style: GoogleFonts.libreBaskerville(
                color: Colors.white60,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 50),

          // 6. GALERÍA DE FOTOS HISTÓRICAS
          _buildPhotoGallery(context),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(BuildContext context) {
    // Obtener galería de fotos desde userData
    final List<dynamic> gallery =
        userData['gallery'] ?? userData['extraData']?['gallery'] ?? [];

    // Si no hay fotos, mostrar mensaje motivacional
    if (gallery.isEmpty && !isMe) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la galería
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [goldPrimary, goldDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GALERÍA HISTÓRICA',
                    style: GoogleFonts.cinzel(
                      color: goldPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Momentos inmortales de una carrera legendaria',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // Grid de fotos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: gallery.isEmpty
              ? _buildEmptyGallery()
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: gallery.length > 9 ? 9 : gallery.length,
                  itemBuilder: (context, index) {
                    final photo = gallery[index];
                    return _buildPhotoItem(context, photo, index);
                  },
                ),
        ),

        if (isMe && gallery.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de carga de fotos próximamente'),
                      backgroundColor: goldDark,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add_photo_alternate, color: legendBlack),
                label: Text(
                  'AGREGAR FOTOS',
                  style: GoogleFonts.lexend(
                    color: legendBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyGallery() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: goldPrimary.withOpacity(0.2), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.images,
              color: goldPrimary.withOpacity(0.3),
              size: 40,
            ),
            const SizedBox(height: 15),
            Text(
              'GALERÍA VACÍA',
              style: GoogleFonts.lexend(
                color: Colors.white30,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Agrega fotos de tu carrera legendaria',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, dynamic photo, int index) {
    final String imageUrl = photo is String ? photo : (photo['url'] ?? '');
    final String caption = photo is Map ? (photo['caption'] ?? '') : '';

    return GestureDetector(
      onTap: () {
        // Mostrar foto en pantalla completa
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    decoration: BoxDecoration(
                      border: Border.all(color: goldPrimary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: goldPrimary.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.contain)
                        : Container(
                            color: Colors.grey.shade900,
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 100,
                                color: Colors.white30,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: legendBlack.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: goldPrimary),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: goldPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                if (caption.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            legendBlack.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Text(
                        caption,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.libreBaskerville(
                          color: goldPrimary,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: goldPrimary.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: goldPrimary.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade900,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white30,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.white30,
                          size: 30,
                        ),
                      ),
                    ),
              // Overlay con gradiente
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, legendBlack.withOpacity(0.7)],
                  ),
                ),
              ),
              // Número de foto
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: goldPrimary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.lexend(
                      color: legendBlack,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    String nickname,
    String location,
  ) {
    // USAR userData en lugar de store.currentUser para evitar "Robo de Identidad"
    final String name = (userData['name'] ?? 'Leyenda').toString();
    final String avatar = (userData['avatar'] ?? '').toString();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Imagen heroica de fondo
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            image: avatar.isNotEmpty
                ? DecorationImage(
                    image: avatar.startsWith('data:image')
                        ? MemoryImage(base64Decode(avatar.split(',').last))
                        : NetworkImage(avatar) as ImageProvider,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.darken,
                    ),
                  )
                : null,
            color: Colors.black,
          ),
          child: avatar.isEmpty
              ? const Center(
                  child: Icon(Icons.person, color: Colors.white10, size: 100),
                )
              : null,
        ),
        // Gradiente inferior
        Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, legendBlack],
            ),
          ),
        ),
        // Nombre
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Text(
                name.toUpperCase(),
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              if (nickname.isNotEmpty)
                Text(
                  nickname.toUpperCase(),
                  style: GoogleFonts.charm(color: goldPrimary, fontSize: 24),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: goldPrimary,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
