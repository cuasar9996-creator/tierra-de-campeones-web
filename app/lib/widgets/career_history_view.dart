import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../core/role_helper.dart';

// WIDGET AISLADO: SOLO LECTURA
// No tiene capacidad de escribir en el perfil activo.
class CareerHistoryView extends StatelessWidget {
  final Map<String, dynamic> historyData;
  final String currentRoleKey;
  final String? userGender;

  const CareerHistoryView({
    super.key,
    required this.historyData,
    required this.currentRoleKey,
    this.userGender,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay historia previa, mostramos mensaje motivacional
    if (historyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Icon(
              FontAwesomeIcons.feather,
              color: Colors.white30,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'TU LEYENDA SE ESCRIBE HOY',
              style: GoogleFonts.lexend(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Aún no has cargado etapas anteriores de tu carrera.',
              style: TextStyle(color: Colors.white30, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Ordenamos los nodos cronológicamente (definido por nosotros)
    final nodes = _getOrderedNodes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 15, left: 5),
          child: Text(
            'TRAYECTORIA',
            style: GoogleFonts.lexend(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),

        // Renderizamos la línea de tiempo
        ...nodes.map((node) => _buildTimelineNode(context, node)).toList(),

        // Nodo Final (El Presente)
        _buildCurrentNode(context),
      ],
    );
  }

  // Define el orden lógico de la carrera
  List<MapEntry<String, dynamic>> _getOrderedNodes() {
    final order = [
      'cadet',
      'amateur',
      'pro-boxer',
      'retired-boxer',
      'legend-boxer',
    ];

    // Filtramos y ordenamos según la lista 'order'
    final entries = historyData.entries.toList();
    entries.sort((a, b) {
      // Extraemos la key limpia (ej: 'legacy_cadet' -> 'cadet')
      String keyA = a.key.replaceAll('legacy_', '');
      String keyB = b.key.replaceAll('legacy_', '');

      int indexA = order.indexOf(keyA);
      int indexB = order.indexOf(keyB);

      // Si no está en la lista (ej: coach), va al final
      int result = (indexA == -1 ? 99 : indexA).compareTo(
        indexB == -1 ? 99 : indexB,
      );
      return result;
    });

    return entries;
  }

  Widget _buildTimelineNode(
    BuildContext context,
    MapEntry<String, dynamic> entry,
  ) {
    final data = entry.value as Map<String, dynamic>;
    final roleKey = entry.key.replaceAll('legacy_', ''); // ej: 'cadet'

    // Usamos el Helper seguro de género
    final roleName = RoleGenderHelper.getRoleName(roleKey, userGender);

    final years = data['years'] ?? 'Periodo Desconocido';
    final record = data['record'] ?? 'Sin Récord';
    final titles = data['titles'];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna Izquierda: Línea y Punto
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
              ),
              Expanded(child: Container(width: 2, color: Colors.white10)),
            ],
          ),
          const SizedBox(width: 15),

          // Columna Derecha: Tarjeta de Datos (Solo Lectura)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          roleName.toUpperCase(),
                          style: GoogleFonts.lexend(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          years.toString(),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMiniRow(Icons.history, 'Récord: $record'),
                    if (titles != null && titles is List && titles.isNotEmpty)
                      _buildMiniRow(FontAwesomeIcons.trophy, titles.join(', ')),

                    // LOGROS CON ICONOS (SISTEMA TITANIO) 🛡️
                    _buildAchievementBadge(data),

                    const SizedBox(height: 8),
                    // Botón para ver detalles (Pop-up seguro)
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ver Detalle Histórico (Próximamente)',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'VER DETALLE COMPLETO >',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentNode(BuildContext context) {
    // El nodo actual siempre es el último y brillante
    final currentRoleName = RoleGenderHelper.getRoleName(
      currentRoleKey,
      userGender,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16, // Aumentado ligeramente para destacar
              margin: const EdgeInsets.only(
                left: 2,
              ), // Alinear con la línea de arriba
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTUALIDAD',
                style: GoogleFonts.lexend(
                  color: AppColors.primary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                currentRoleName.toUpperCase(),
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Escribiendo la historia...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              // LOGROS ACTUALES 🛡️
              _buildAchievementBadge({
                'roleKey': currentRoleKey,
                'achievements': historyData[currentRoleKey]?['achievements'],
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: Colors.white30),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(Map<String, dynamic> data) {
    final String stageKey = (data['roleKey'] ?? '').toString();

    // 1. Intentar obtener la lista nueva (Titanio)
    // Nota: El componente CareerHistoryView recibe el Map de la etapa específica,
    // pero los logros múltiples ahora se guardan en el extraData raíz como achievements_stageKey
    // Sin embargo, para mantener el desacoplamiento, buscamos primero dentro de 'data'
    // y si no está, intentaremos ver si se pasó en el Map maestro (aunque aquí no lo tenemos fácil)
    // Por suerte, en el guardado nos aseguramos de que cada etapa tenga su lista.

    List achievementsList = [];
    if (data['achievements_$stageKey'] is List) {
      achievementsList = data['achievements_$stageKey'] as List;
    } else if (data['achievements'] is List) {
      achievementsList = data['achievements'] as List;
    }

    // 2. Fallback al formato viejo (achievement_text) si la lista está vacía
    if (achievementsList.isEmpty) {
      final String fullText = data['achievement_text']?.toString() ?? '';
      final iconId = data['achievement_icon_id']?.toString();
      if (fullText.trim().isNotEmpty) {
        achievementsList = fullText
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => {'text': s.trim(), 'icon_id': iconId ?? '0'})
            .toList();
      }
    }

    if (achievementsList.isEmpty) return const SizedBox.shrink();

    // Mapeo seguro de iconos
    final Map<String, List<String>> iconSets = {
      'cadet': ['🏆', '🥇', '🥈', '🥉', '🏅'],
      'amateur': ['🏆', '🥇', '🥈', '🥉', '🏅'],
      'pro': ['👑', '🥊', '🎖️', '💎', '🌟'],
      'retired': ['👑', '🥊', '🎖️', '💎', '🌟'],
      'legend': ['👑', '🥊', '🎖️', '💎', '🌟'],
    };

    final set = iconSets[stageKey] ?? iconSets['pro']!;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: achievementsList.map((item) {
          final text = (item['text'] ?? '').toString();
          final iconId = item['icon_id']?.toString();

          String icon = '🏅';
          if (iconId != null) {
            int? idx = int.tryParse(iconId);
            if (idx != null && idx >= 0 && idx < set.length) {
              icon = set[idx];
            }
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text.toUpperCase(),
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
