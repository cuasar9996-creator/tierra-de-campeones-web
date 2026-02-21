import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../core/app_colors.dart';
import '../services/app_store.dart';
import '../core/role_helper.dart';
import '../screens/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/career_history_view.dart';
import 'retired_boxer_profile.dart'; // Nuevo Perfil Retirado
import 'legend_boxer_profile.dart'; // Nuevo Perfil Leyenda
import 'social_stats_widget.dart'; // Funciones Sociales

class AthleteProfileView extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AthleteProfileView({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final currentUser = store.currentUser;

    // Si userData está vacío o coincide con el ID del usuario actual, es "mi perfil"
    final bool isMe =
        currentUser != null &&
        (userData.isEmpty ||
            userData['userId'] == currentUser.userId ||
            userData['id'] == currentUser.userId);

    final Map<String, dynamic> effectiveData = isMe
        ? currentUser.toJson()
        : userData;

    final String role = effectiveData['role']?.toString() ?? '';
    final bool isBoxer =
        role.toLowerCase().contains('boxea') ||
        role.toLowerCase().contains('cadet') ||
        role.toLowerCase().contains('semillero');
    final String roleKey = effectiveData['roleKey']?.toString() ?? '';
    final bool isCutman =
        roleKey == 'cutman' || role.toLowerCase().contains('cutman');
    final bool isPhysicalTrainer =
        roleKey == 'physical-trainer' ||
        role.toLowerCase().contains('preparador físico') ||
        role.toLowerCase().contains('prep. físico');
    final bool isCoach =
        roleKey == 'coach' ||
        role.toLowerCase().contains('entrenador') ||
        role.toLowerCase().contains('técnico');
    final bool isPsychologist =
        roleKey == 'psychologist' || role.toLowerCase().contains('psicólogo');
    final bool isMedic =
        roleKey == 'medic' || role.toLowerCase().contains('médico');
    final bool isNutritionist =
        roleKey == 'nutritionist' ||
        role.toLowerCase().contains('nutricionista');
    final bool isManager =
        roleKey == 'manager' ||
        role.toLowerCase().contains('manager') ||
        role.toLowerCase().contains('representante');
    final bool isPromoter =
        roleKey == 'promoter' || role.toLowerCase().contains('promotor');
    final bool isGymOwner =
        roleKey == 'gym-owner' ||
        role.toLowerCase().contains('dueño de gimnasio') ||
        role.toLowerCase().contains('propietario');
    final bool isRecreational =
        roleKey == 'recreational' ||
        role.toLowerCase().contains('recreativo') ||
        role.toLowerCase().contains('fitness');
    final bool isFan =
        roleKey == 'fan' ||
        role.toLowerCase().contains('aficionado') ||
        role.toLowerCase().contains('fan');
    final bool isJournalist =
        roleKey == 'journalist' ||
        role.toLowerCase().contains('periodista') ||
        role.toLowerCase().contains('prensa');
    final bool isCombatOfficial =
        roleKey == 'judge' ||
        role.toLowerCase().contains('árbitro') ||
        role.toLowerCase().contains('juez') ||
        role.toLowerCase().contains('oficial');

    // DERIVACIÓN DE TRÁFICO (ISLETAS TITANIO) 🛡️
    // Si es Retirado o Leyenda, mostramos sus vistas exclusivas
    // y NO tocamos el código de abajo (que es para Pro/Amateur).

    // 🛡️ EXCEPCIÓN: LEGEND BOXER MANTIENE SU VISTA PROPIA
    if (roleKey == 'legend-boxer') {
      return LegendBoxerProfile(userData: effectiveData, isMe: isMe);
    }

    if (roleKey == 'legend-boxer') {
      return LegendBoxerProfile(userData: effectiveData, isMe: isMe);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section -> DNA REAL
          _buildHeader(context, isMe, effectiveData),
          _buildSocialLinks(effectiveData),
          _buildActionButtons(context, isMe, effectiveData, isCoach: isCoach),

          // SECCIONES TÉCNICAS
          if (isBoxer) ...[
            const SizedBox(height: 20),
            _buildSpecsGrid(effectiveData),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            _buildRecordBox(effectiveData),
            const SizedBox(height: 10),
            SocialStatsWidget(userData: effectiveData, isMe: isMe),
          ],

          // 🛡️ PERFIL RETIRADO INTEGRADO (Titanio)
          if (roleKey == 'retired-boxer') ...[
            const SizedBox(height: 10),
            RetiredBoxerProfile(userData: effectiveData, isMe: isMe),
          ],

          if (isCoach) ...[
            const SizedBox(height: 10),
            _buildCoachSpecs(context, effectiveData, isMe),
          ],

          if (isCutman) ...[
            const SizedBox(height: 10),
            _buildCutmanSpecs(context, effectiveData, isMe),
          ],

          if (isPhysicalTrainer) ...[
            const SizedBox(height: 10),
            _buildPhysicalTrainerSpecs(context, effectiveData, isMe),
          ],

          if (isPsychologist) ...[
            const SizedBox(height: 10),
            _buildPsychologistSpecs(context, effectiveData, isMe),
          ],

          if (isMedic) ...[
            const SizedBox(height: 10),
            _buildMedicSpecs(context, effectiveData, isMe),
          ],

          if (isNutritionist) ...[
            const SizedBox(height: 10),
            _buildNutritionistSpecs(context, effectiveData, isMe),
          ],

          if (isManager) ...[
            const SizedBox(height: 10),
            _buildManagerSpecs(context, effectiveData, isMe),
          ],

          if (isPromoter) ...[
            const SizedBox(height: 10),
            _buildPromoterSpecs(context, effectiveData, isMe),
          ],

          if (isGymOwner) ...[
            const SizedBox(height: 10),
            _buildGymOwnerSpecs(context, effectiveData, isMe),
          ],

          if (isRecreational) ...[
            const SizedBox(height: 10),
            _buildRecreationalSpecs(context, effectiveData, isMe),
          ],

          if (isFan) ...[
            const SizedBox(height: 10),
            _buildFanSpecs(context, effectiveData, isMe),
          ],

          if (isJournalist) ...[
            const SizedBox(height: 10),
            _buildJournalistSpecs(context, effectiveData, isMe),
          ],

          if (isCombatOfficial) ...[
            const SizedBox(height: 10),
            _buildCombatOfficialSpecs(context, effectiveData, isMe),
          ],

          const SizedBox(height: 30),
          // EQUIPO Y PATROCINIOS (SISTEMA DE NODOS) 🛡️
          if (isMe ||
              (effectiveData['team_members'] as List?)?.isNotEmpty == true)
            _buildHorizontalList('MI EQUIPO / RINCÓN', [
              ...((effectiveData['team_members'] as List?) ?? []).map((m) {
                return _TeamMember(userId: m['userId'], role: m['role']);
              }),
              if (isMe)
                _TeamMember(
                  onTap: () => _showAddTeamMemberDialog(context),
                  name: 'SUMAR',
                  role: 'A TU EQUIPO',
                  icon: '➕',
                ),
            ]),

          const SizedBox(height: 30),
          if (isMe || (effectiveData['sponsors'] as List?)?.isNotEmpty == true)
            _buildHorizontalList('SPONSORS / MARCAS', [
              ...((effectiveData['sponsors'] as List?) ?? []).map((s) {
                return _Sponsor(
                  brand: s['name'] ?? s['brand'] ?? '',
                  logo: s['logo'] ?? '🔗',
                  url: s['url'],
                  userId: s['userId'],
                );
              }),
              if (isMe)
                _Sponsor(
                  onTap: () => _showAddSponsorDialog(context),
                  brand: 'AGREGAR',
                  logo: '➕',
                ),
            ]),
          const SizedBox(height: 30),

          // INICIO TRAYECTORIA TITANIO 🛡️
          // Solo se muestra si hay historial y no rompe el flujo actual
          _buildLegacyTimeline(context, effectiveData),
          const SizedBox(height: 30),

          // FIN TRAYECTORIA TITANIO 🛡️
          if (!isMe) ...[_buildProfileTabs(), _buildPostGrid()],
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // WIDGET WRAPPER TITANIO 🛡️
  // Envuelve la vista de historial en un bloque seguro.
  // Si falla o no hay datos, devuelve un SizedBox vacío (invisible).
  Widget _buildLegacyTimeline(BuildContext context, Map<String, dynamic> data) {
    try {
      // 1. Verificación de Existencia de Datos (Búsqueda Profunda)
      // Buscamos en la raíz O dentro de extraData explícitamente por si acaso
      var history = data['career_history'];

      if (history == null && data['extraData'] is Map) {
        history = data['extraData']['career_history'];
      }

      if (history == null ||
          history is! Map<String, dynamic> ||
          history.isEmpty) {
        // Debug silencioso para saber por qué no se muestra
        // debugPrint('Trayectoria: No data found (history is null or empty)');
        return const SizedBox.shrink(); // Silencioso si no hay datos
      }

      // 2. Extracción segura de rol y género
      final currentRole = data['roleKey']?.toString() ?? 'unknown';
      final gender = data['gender']?.toString();

      // 3. Renderizado Átomico
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: CareerHistoryView(
          historyData: history,
          currentRoleKey: currentRole,
          userGender: gender,
        ),
      );
    } catch (e) {
      // 4. Captura de Errores Silenciosa (Regla Titanio)
      debugPrint('Error en Trayectoria Titanio: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildSocialLinks(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 15,
        runSpacing: 10,
        children: [
          _SocialIcon(
            icon: FontAwesomeIcons.instagram,
            color: Colors.pinkAccent,
            url: data['instagram'],
          ),
          _SocialIcon(
            icon: FontAwesomeIcons.facebook,
            color: Colors.blueAccent,
            url: data['facebook'],
          ),
          _SocialIcon(
            icon: FontAwesomeIcons.twitter,
            color: Colors.lightBlue,
            url: data['twitter'],
          ),
          _SocialIcon(
            icon: FontAwesomeIcons.youtube,
            color: Colors.red,
            url: data['youtube'],
          ),
          _SocialIcon(
            icon: FontAwesomeIcons.tiktok,
            color: Colors.white,
            url: data['tiktok'],
          ),
          _SocialIcon(
            icon: FontAwesomeIcons.twitch,
            color: const Color(0xFF9146FF),
            url: data['twitch'],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isMe,
    Map<String, dynamic> effectiveData, {
    bool isCoach = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Column(
        children: [
          if (!isMe)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('SEGUIR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AppStore>().startChatWithUser(
                        effectiveData['name'] ?? 'Usuario',
                        effectiveData['avatar'] ?? '',
                      );
                      // Regresar a la navegación principal para ver el chat
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF444444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'MENSAJE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                // Botón PATROCINAR para Marcas/Representantes 🛡️
                if (Provider.of<AppStore>(
                          context,
                          listen: false,
                        ).currentUser?.roleKey !=
                        null &&
                    (Provider.of<AppStore>(
                          context,
                          listen: false,
                        ).currentUser!.roleKey.contains('promoter') ||
                        Provider.of<AppStore>(
                          context,
                          listen: false,
                        ).currentUser!.roleKey.contains('manager') ||
                        Provider.of<AppStore>(
                          context,
                          listen: false,
                        ).currentUser!.roleKey.contains('gym'))) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AppStore>().sendSponsorRequest(
                          toUserId:
                              effectiveData['userId'] ?? effectiveData['id'],
                          toUserName: effectiveData['name'] ?? '',
                          toAvatar: effectiveData['avatar'] ?? '',
                        );
                        // Regresar a la navegación principal para ver el chat
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'PATROCINAR',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (_, _, _) => const AuthScreen(
                            initialView: AuthView.registerForm,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('EDITAR PERFIL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enlace copiado al portapapeles'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.share,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'COMPARTIR',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF444444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Botón de Debug eliminado para limpiar la UI final
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final Uint8List fileBytes = result.files.first.bytes!;
        final String fileName = result.files.first.name;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⬆️ Subiendo foto a la nube...')),
        );

        final store = context.read<AppStore>();
        final userId = store.currentUser?.userId ?? '';

        // Supabase Storage: subir la imagen al bucket 'avatars'
        String avatarUrl;
        if (!userId.startsWith('dev_')) {
          try {
            final String storagePath = 'avatars/$userId/$fileName';
            await Supabase.instance.client.storage
                .from('avatars')
                .uploadBinary(
                  storagePath,
                  fileBytes,
                  fileOptions: const FileOptions(upsert: true),
                );
            avatarUrl = Supabase.instance.client.storage
                .from('avatars')
                .getPublicUrl(storagePath);
          } catch (storageError) {
            // Fallback a base64 si Supabase Storage no está configurado
            debugPrint('Supabase Storage no disponible: $storageError');
            avatarUrl = 'data:image/png;base64,${base64Encode(fileBytes)}';
          }
        } else {
          // Dev mode: usar base64 local
          avatarUrl = 'data:image/png;base64,${base64Encode(fileBytes)}';
        }

        await store.updateUserProfile({'avatar': avatarUrl});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Foto de perfil actualizada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
    }
  }

  ImageProvider _getAvatarImage(String avatarData) {
    if (avatarData.startsWith('data:image')) {
      try {
        final base64String = avatarData.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return const NetworkImage('https://via.placeholder.com/150');
      }
    } else {
      return NetworkImage(
        avatarData.isEmpty ? 'https://via.placeholder.com/150' : avatarData,
      );
    }
  }

  Widget _buildHeader(
    BuildContext context,
    bool isMe,
    Map<String, dynamic> sourceData,
  ) {
    final String name = (sourceData['name'] ?? 'Usuario').toString();
    final role = (sourceData['role'] ?? 'Rol').toString();
    final String stage = (sourceData['careerStage'] ?? '').toString();
    final String gender = (sourceData['gender'] ?? '').toString();
    final String roleTitle = _getDisplayRole(role, stage, gender);
    final avatar = (sourceData['avatar'] ?? '').toString();
    final String bio =
        (sourceData['bio'] ??
                sourceData['extraData']?['bio'] ??
                'Sin biografía disponible.')
            .toString();

    return Column(
      children: [
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    image: avatar.isNotEmpty
                        ? DecorationImage(
                            image: _getAvatarImage(avatar),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: avatar.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(25),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        )
                      : null,
                ),
                if (isMe)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadImage(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 25),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      if (sourceData['is_verified'] == true)
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      if (sourceData['nickname'] != null &&
                          sourceData['nickname'].toString().isNotEmpty)
                        Text(
                          '"${sourceData['nickname']}"'.toUpperCase(),
                          style: GoogleFonts.lexend(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        roleTitle.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stage.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHeaderInfoRow(
                    context,
                    nationality:
                        sourceData['nationality'] ??
                        sourceData['extraData']?['nationality'],
                    represents:
                        sourceData['represents'] ??
                        sourceData['extraData']?['represents'] ??
                        sourceData['extraData']?['representation'],
                    gym:
                        sourceData['gym'] ??
                        sourceData['extraData']?['gym'] ??
                        sourceData['extraData']?['coachBaseGym'],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecsGrid(Map<String, dynamic> sourceData) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 20,
        runSpacing: 20,
        children: [
          _SpecItem(
            label: 'ESTADO',
            value: (sourceData['careerStage'] ?? 'S/D')
                .toString()
                .toUpperCase(),
          ),
          _SpecItem(
            label: 'ALTURA',
            value:
                (sourceData['height'] ??
                        sourceData['extraData']?['height'] ??
                        '---')
                    .toString(),
          ),
          _SpecItem(
            label: 'ALCANCE',
            value:
                (sourceData['reach'] ??
                        sourceData['extraData']?['reach'] ??
                        '---')
                    .toString(),
          ),
          _SpecItem(
            label: 'GUARDIA',
            value:
                (sourceData['stance'] ??
                        sourceData['extraData']?['stance'] ??
                        'S/D')
                    .toString(),
          ),
          _SpecItem(
            label: 'EDAD',
            value:
                (sourceData['age'] ?? sourceData['extraData']?['age'] ?? '--')
                    .toString(),
          ),
          _SpecItem(
            label: 'GYM',
            value:
                (sourceData['gym'] ?? sourceData['extraData']?['gym'] ?? 'S/D')
                    .toString()
                    .toUpperCase(),
          ),
          _SpecItem(
            label: 'TÉCNICO',
            value:
                (sourceData['trainer'] ??
                        sourceData['extraData']?['trainer'] ??
                        'S/D')
                    .toString()
                    .toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordBox(Map<String, dynamic> sourceData) {
    // RECUPERACIÓN DE RÉCORD G-P-E-NC-KO (REGLA TITANIO) 🛡️
    final extra = sourceData['extraData'] ?? {};
    final w = (sourceData['wins'] ?? extra['wins'] ?? '0').toString();
    final l = (sourceData['losses'] ?? extra['losses'] ?? '0').toString();
    final d = (sourceData['draws'] ?? extra['draws'] ?? '0').toString();
    final nc = (sourceData['nc'] ?? extra['nc'] ?? '0').toString();
    final ko = (sourceData['kos'] ?? extra['kos'] ?? '0').toString();

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            _RecordStat(label: 'G', value: w, color: Colors.green),
            _RecordStat(label: 'P', value: l, color: Colors.red),
            _RecordStat(label: 'E', value: d, color: Colors.yellow),
            _RecordStat(label: 'NC', value: nc, color: Colors.grey),
            _RecordStat(label: 'KO', value: ko, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 10),
        if (extra['boxrecUrl'] != null &&
            extra['boxrecUrl'].toString().isNotEmpty)
          ElevatedButton.icon(
            onPressed: () {
              // Lógica para abrir URL (se podría usar url_launcher)
            },
            icon: const Icon(Icons.link, color: Colors.black, size: 16),
            label: const Text(
              'BOXREC OFICIAL',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }

  static const Map<String, List<String>> _coachModulesData = {
    '🧠 FORMACIÓN TÉCNICA': [
      'Enseñanza de técnica básica (guardia, postura, desplazamientos)',
      'Corrección de golpes: jab, cross, hook, uppercut',
      'Desarrollo de combinaciones ofensivas',
      'Coordinación mano-ojo',
      'Precisión de golpeo',
      'Uso de la distancia y timing',
    ],
    '🛡️ DEFENSA': [
      'Esquives (slip, duck, bob & weave)',
      'Bloqueos y paradas',
      'Defensa activa y pasiva',
      'Salidas laterales',
      'Pivoteos y cambios de ángulo',
    ],
    '🎯 PLANIFICACIÓN TÉCNICA': [
      'Diseño de rutinas técnicas',
      'Planificación por nivel (recreativo / amateur / profesional)',
      'Corrección de vicios técnicos',
      'Desarrollo progresivo del boxeador',
      'Ajustes técnicos según estilo',
    ],
    '🥊 TRABAJO EN RING / SPARRING': [
      'Supervisión de sparring',
      'Correcciones en tiempo real',
      'Control de intensidad',
      'Selección de sparrings',
      'Evaluación de desempeño en combate de práctica',
    ],
    '🧾 ESTRATEGIA Y TÁCTICA': [
      'Análisis técnico de rivales',
      'Diseño de plan de pelea',
      'Adaptación estratégica por rounds',
      'Estilo: Estilista',
      'Estilo: Fajador',
      'Estilo: Contragolpeador',
      'Estilo: Presionador',
    ],
    '🏆 COMPETENCIA': [
      'Acompañamiento a eventos',
      'Trabajo en esquina',
      'Indicaciones entre rounds',
      'Lectura de combate en vivo',
      'Ajustes tácticos durante la pelea',
    ],
  };

  static const Map<String, List<String>> _cutmanModulesData = {
    '🩹 VENDAJES PROFESIONALES': [
      'Vendaje de competición (Gasa y Cinta)',
      'Vendaje de entrenamiento / sparring',
      'Protección de metacarpianos (puente)',
      'Ajuste de tensión según preferencia del boxeador',
      'Cumplimiento de reglamentación (WBC, WBA, IBF, WBO)',
    ],
    '🩸 CONTROL DE CORTES': [
      'Uso de Adrenalina 1:1000 (donde esté permitido)',
      'Aplicación de Avitene / Thrombin',
      'Técnica de presión directa selectiva',
      'Limpieza y esterilización del área',
      'Cierre temporal para continuidad del combate',
    ],
    '🧊 INFLAMACIÓN FACIAL': [
      'Uso de Enswell (Hierro frío) para hematomas',
      'Presión fría controlada',
      'Técnica de drenaje hacia zonas externas',
      'Manejo de inflamación periorbital',
      'Manejo de hematomas malares',
    ],
    '💉 HEMOSTASIA': [
      'Control de Epistaxis (sangrado nasal)',
      'Uso de taponamientos químicos/mecánicos',
      'Manejo de sangrado intraoral',
      'Hemostasia capilar rápida',
    ],
    '🥊 ASISTENCIA EN ESQUINA': [
      'Aplicación de vaselina (Grease) protectora',
      'Gestión de tiempos en los 60 segundos',
      'Coordinación con el entrenador principal (Chief Second)',
      'Monitoreo del estado físico del boxeador',
    ],
  };

  Widget _buildExpandableModule(
    BuildContext context, {
    required String title,
    required List<String> allOptions,
    required List<String> selectedOptions,
    required String dataKey,
    required bool isMe,
  }) {
    return _buildExpandingSection(
      context,
      title: title,
      isMe: isMe,
      children: allOptions.map((item) {
        final bool isSelected = selectedOptions.contains(item);
        if (!isMe && !isSelected) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: isMe
                ? () {
                    final List<String> current = List<String>.from(
                      selectedOptions,
                    );
                    if (isSelected) {
                      current.remove(item);
                    } else {
                      current.add(item);
                    }
                    final store = context.read<AppStore>();
                    final nextExtra = Map<String, dynamic>.from(
                      store.currentUser?.extraData ?? {},
                    );
                    nextExtra[dataKey] = current;
                    store.updateUserProfile({'extraData': nextExtra});
                  }
                : null,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : Colors.white30,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCutmanSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        ..._cutmanModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey = 'cutman_module_${title.replaceAll(' ', '_')}';

          // Usar watch para que se actualice automáticamente
          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title,
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  static const Map<String, List<String>> _physicalTrainerModulesData = {
    '💪 FUERZA': [
      'Fuerza Máxima (Cargas altas)',
      'Fuerza Hipertrofia (Desarrollo muscular)',
      'Fuerza Isométrica (Estabilidad)',
      'Fuerza Reactiva (Pliometría)',
      'Levantamiento Olímpico (Cargas dinámicas)',
    ],
    '🏃 RESISTENCIA': [
      'Resistencia Aeróbica (Fondo)',
      'Resistencia Anaeróbica Láctica (Tolerancia)',
      'Resistencia Aláctica (Sprints cortos)',
      'VO2 Max (Capacidad de oxígeno)',
      'Recuperación entre rounds',
    ],
    '⚡ POTENCIA': [
      'Explosividad de pegada',
      'Transferencia de fuerza a velocidad',
      'Entrenamiento con bandas elásticas',
      'Lanzamiento de balones medicinales',
      'Potencia de empuje y rotación',
    ],
    '🏎️ VELOCIDAD': [
      'Velocidad de desplazamiento',
      'Velocidad de reacción (Estímulos)',
      'Frecuencia gestual de golpeo',
      'Agilidad y cambio de dirección',
      'Coordinación óculo-manual',
    ],
    '📊 PLANIFICACIÓN FÍSICA': [
      'Periodización por bloques',
      'Macrociclos de competición',
      'Control de carga y fatiga',
      'Prevención de lesiones / Core',
      'Tapering (Puesta a punto)',
    ],
  };

  Widget _buildPhysicalTrainerSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        ..._physicalTrainerModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey = 'pt_module_${title.replaceAll(' ', '_')}';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title,
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  static const Map<String, List<String>> _psychologistModulesData = {
    '🧩 Preparación mental competitiva': [
      'Desarrollo de mentalidad competitiva',
      'Entrenamiento de enfoque y concentración',
      'Fortalecimiento de la confianza deportiva',
      'Gestión de presión competitiva',
      'Preparación mental para debut o peleas importantes',
    ],
    '😰 Gestión emocional': [
      'Control de ansiedad pre-pelea',
      'Manejo del miedo al golpe',
      'Regulación del estrés competitivo',
      'Control de frustración post-derrota',
      'Gestión emocional durante campamentos',
    ],
    '🎯 Motivación y objetivos': [
      'Definición de metas deportivas',
      'Sostenimiento de motivación a largo plazo',
      'Reencuadre tras lesiones o pausas',
      'Prevención de abandono deportivo',
      'Seguimiento motivacional',
    ],
    '🧠 Entrenamiento cognitivo': [
      'Visualización de combate',
      'Ensayo mental de estrategias',
      'Toma de decisiones bajo presión',
      'Tiempo de reacción mental',
      'Lectura anticipada de situaciones de pelea',
    ],
    '🥊 Psicología aplicada al combate': [
      'Preparación mental por rival',
      'Manejo de provocaciones',
      'Control emocional en el ring',
      'Recuperación mental entre rounds',
      'Resiliencia en combate adverso',
    ],
    '🧑‍🏫 Acompañamiento integral': [
      'Adaptación a vida de competencia',
      'Balance vida personal/deportiva',
      'Manejo de exposición pública',
      'Apoyo en cambios de categoría o etapa',
    ],
    '🩺 Intervención clínica': [
      'Tratamiento de ansiedad deportiva',
      'Depresión post-competencia',
      'Trastornos del sueño',
      'Burnout deportivo',
      'Terapia individual',
    ],
  };

  static const List<String> _psychologistServicesItems = [
    'Sesiones individuales',
    'Sesiones grupales (equipo)',
    'Preparación mental pre-competencia',
    'Seguimiento durante campamento',
    'Intervención post-pelea',
    'Evaluación psicológica deportiva',
    'Talleres motivacionales',
    'Manejo de ansiedad escénica',
  ];

  Widget _buildPsychologistSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};
    final bool isTherapeutic = extraData['psy_is_therapeutic'] == true;

    return Column(
      children: [
        // ENFOQUE DE TRABAJO (Toggle)
        if (isMe)
          _buildExpandingSection(
            context,
            title: '⚙️ ENFOQUE DE TRABAJO',
            isMe: isMe,
            children: [
              SwitchListTile(
                title: Text(
                  isTherapeutic
                      ? 'Psicología clínica deportiva (Terapéutica)'
                      : 'Psicología deportiva (Coaching mental)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                value: isTherapeutic,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  final store = context.read<AppStore>();
                  final nextExtra = Map<String, dynamic>.from(
                    store.currentUser?.extraData ?? {},
                  );
                  nextExtra['psy_is_therapeutic'] = val;
                  store.updateUserProfile({'extraData': nextExtra});
                },
              ),
            ],
          )
        else if (extraData.containsKey('psy_is_therapeutic'))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isTherapeutic
                        ? 'ENFOQUE TERAPÉUTICO'
                        : 'ENFOQUE COACHING MENTAL',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // MÓDULOS TÉCNICOS
        ..._psychologistModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey = 'psy_module_${title.replaceAll(' ', '_')}';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),

        // SERVICIOS DISPONIBLES
        _buildExpandingSection(
          context,
          title: '🧾 SERVICIOS DISPONIBLES',
          isMe: isMe,
          children: _psychologistServicesItems.map((service) {
            final store = context.watch<AppStore>();
            final List<dynamic> selectedServices =
                (isMe
                    ? store.currentUser?.extraData['psy_services']
                    : extraData['psy_services']) ??
                [];
            final bool isSelected = selectedServices.contains(service);
            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selectedServices,
                        );
                        if (isSelected) {
                          current.remove(service);
                        } else {
                          current.add(service);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['psy_services'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      service,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const Map<String, List<String>> _medicModulesData = {
    '🧾 EVALUACIÓN MÉDICA ': [
      'Historia clínica deportiva',
      'Evaluación médica integral',
      'Aptos físicos (Amateur / Pro)',
      'Exámenes pre-competencia',
      'Certificados médicos oficiales',
    ],
    '❤️ EVALUACIÓN CARDIOVASCULAR': [
      'Electrocardiograma (ECG)',
      'Pruebas de esfuerzo',
      'Control de frecuencia cardíaca',
      'Detección de riesgos cardíacos',
      'Seguimiento de salud cardiovascular',
    ],
    '🦴 DIAGNÓSTICO DE LESIONES': [
      'Evaluación de lesiones musculares',
      'Lesiones articulares',
      'Traumatismos por impacto',
      'Sospecha de fracturas',
      'Lesiones por sobreentrenamiento',
    ],
    '🩹 TRATAMIENTO MÉDICO': [
      'Indicaciones de reposo deportivo',
      'Protocolos de recuperación',
      'Antiinflamatorios / Analgésicos',
      'Infiltraciones controladas',
      'Seguimiento evolutivo de lesiones',
    ],
    '⚖️ CONTROL DE PESO Y CORTE': [
      'Supervisión médica del corte de peso',
      'Evaluación de hidratación',
      'Riesgos de deshidratación',
      'Recuperación post-pesaje',
      'Prevención de colapsos físicos',
    ],
    '🧪 ESTUDIOS Y CONTROLES CLÍNICOS': [
      'Análisis de sangre',
      'Perfil hormonal',
      'Niveles de hierro / Ferritina',
      'Fatiga crónica',
      'Déficits nutricionales',
    ],
    '💊 FARMACOLOGÍA DEPORTIVA': [
      'Prescripción de medicación',
      'Suplementación médica indicada',
      'Control de sustancias permitidas',
      'Prevención de dopaje accidental',
      'Certificados TUE (Uso terapéutico)',
    ],
    '🧠 SALUD NEUROLÓGICA BÁSICA': [
      'Evaluación post-conmoción',
      'Protocolos de KO / TKO',
      'Reposo neurológico',
      'Seguimiento tras golpes reiterados',
      'Derivación a neurología',
    ],
    '📋 SEGUIMIENTO DEL DEPORTISTA': [
      'Controles periódicos',
      'Evolución física general',
      'Aptitud para volver a competir',
      'Prevención de riesgos médicos',
    ],
  };

  static const List<String> _medicSpecialtiesItems = [
    'Deportología',
    'Traumatología',
    'Cardiología Deportiva',
    'Emergentología',
    'Medicina General',
    'Neurología Deportiva',
    'Rehabilitación',
  ];

  static const List<String> _medicServicesItems = [
    'Aptos físicos deportivos',
    'Evaluación pre-competencia',
    'Control de corte de peso',
    'Tratamiento de lesiones',
    'Estudios clínicos',
    'Certificados médicos',
    'Seguimiento de campamento',
    'Control cardiovascular',
    'Evaluación post-KO',
  ];

  Widget _buildMedicSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // ESPECIALIDADES MÉDICAS
        _buildExpandingSection(
          context,
          title: '⭐️ ESPECIALIDADES MÉDICAS',
          isMe: isMe,
          children: _medicSpecialtiesItems.map((spec) {
            final store = context.watch<AppStore>();
            final List<dynamic> selected =
                (isMe
                    ? store.currentUser?.extraData['med_specs']
                    : extraData['med_specs']) ??
                [];
            final bool isSelected = selected.contains(spec);

            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selected,
                        );
                        if (isSelected) {
                          current.remove(spec);
                        } else {
                          current.add(spec);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['med_specs'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        spec,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // MÓDULOS TÉCNICOS MÉDICOS
        ..._medicModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          // Limpiar el título de emojis para generar la key correcta
          final String cleanTitle = title.split(' ').skip(1).join('_');
          final String fieldKey = 'med_module_$cleanTitle';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),

        // SERVICIOS MÉDICOS DISPONIBLES
        _buildExpandingSection(
          context,
          title: '🧾 SERVICIOS DISPONIBLES',
          isMe: isMe,
          children: _medicServicesItems.map((service) {
            final store = context.watch<AppStore>();
            final List<dynamic> selectedServices =
                (isMe
                    ? store.currentUser?.extraData['med_services']
                    : extraData['med_services']) ??
                [];
            final bool isSelected = selectedServices.contains(service);
            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selectedServices,
                        );
                        if (isSelected) {
                          current.remove(service);
                        } else {
                          current.add(service);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['med_services'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const Map<String, List<String>> _nutritionistModulesData = {
    '⚖️ PLANIFICACIÓN NUTRICIONAL': [
      'Doc: Plan alimenticio personalizado',
      'Alimentación según categoría de peso',
      'Ajustes por etapa de entrenamiento',
      'Nutrición para campamentos de pelea',
      'Planes para Amateur / Profesional',
    ],
    '🥊 CORTE DE PESO NUTRICIONAL': [
      'Estrategias de descenso de peso',
      'Planificación progresiva de corte',
      'Reducción de grasa sin perder rendimiento',
      'Manejo de sodio y líquidos',
      'Prevención de cortes extremos peligrosos',
    ],
    '💧 HIDRATACIÓN DEPORTIVA': [
      'Protocolos de hidratación diaria',
      'Hidratación en campamento',
      'Estrategias pre-pesaje',
      'Rehidratación post-pesaje',
      'Balance electrolítico',
    ],
    '🍽️ ALIMENTACIÓN PRE/POST COMBATE': [
      'Pre: Cargas de glucógeno',
      'Pre: Timing de comidas y digestibilidad',
      'Post: Recuperación muscular y reposición',
      'Post: Ventana anabólica y reparación',
    ],
    '🧪 SUPLEMENTACIÓN DEPORTIVA': [
      'Proteínas y Creatina',
      'BCAA / Aminoácidos',
      'Electrolitos y Vitaminas',
      'Control de sustancias permitidas (Antidopaje)',
    ],
    '📊 EVALUACIÓN ANTROPOMÉTRICA': [
      'Estudio de % de grasa y masa muscular',
      'Medición de pliegues cutáneos',
      'Evolución física nutricional',
      'Control de peso corporal periódico',
    ],
    '🥗 EDUCACIÓN ALIMENTARIA': [
      'Hábitos saludables y organización',
      'Lectura de etiquetas nutricionales',
      'Alimentación fuera de campamento',
      'Conducta nutricional del deportista',
    ],
  };

  static const List<String> _nutritionistServicesItems = [
    'Plan nutricional personalizado',
    'Corte de peso',
    'Hidratación deportiva',
    'Plan pre-competencia',
    'Plan post-competencia',
    'Suplementación deportiva',
    'Evaluación antropométrica',
    'Seguimiento de campamento',
    'Educación alimentaria',
  ];

  static const List<String> _nutritionistSpecialtiesItems = [
    'Deportes de combate',
    'Corte de peso',
    'Alto rendimiento',
    'Amateur',
    'Profesional',
    'Reeducación alimentaria',
    'Suplementación deportiva',
  ];

  Widget _buildNutritionistSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // ESPECIALIDADES
        _buildExpandingSection(
          context,
          title: '⭐️ ESPECIALIDADES',
          isMe: isMe,
          children: _nutritionistSpecialtiesItems.map((spec) {
            final store = context.watch<AppStore>();
            final List<dynamic> selected =
                (isMe
                    ? store.currentUser?.extraData['nut_specs']
                    : extraData['nut_specs']) ??
                [];
            final bool isSelected = selected.contains(spec);

            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selected,
                        );
                        if (isSelected) {
                          current.remove(spec);
                        } else {
                          current.add(spec);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['nut_specs'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        spec,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // MÓDULOS TÉCNICOS
        ..._nutritionistModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          // Limpiar el título de emojis para generar la key correcta
          final String cleanTitle = title.split(' ').skip(1).join('_');
          final String fieldKey = 'nut_module_$cleanTitle';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),

        // SERVICIOS
        _buildExpandingSection(
          context,
          title: '🧾 SERVICIOS DISPONIBLES',
          isMe: isMe,
          children: _nutritionistServicesItems.map((service) {
            final store = context.watch<AppStore>();
            final List<dynamic> selectedServices =
                (isMe
                    ? store.currentUser?.extraData['nut_services']
                    : extraData['nut_services']) ??
                [];
            final bool isSelected = selectedServices.contains(service);
            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selectedServices,
                        );
                        if (isSelected) {
                          current.remove(service);
                        } else {
                          current.add(service);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['nut_services'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const Map<String, List<String>> _managerModulesData = {
    '📅 GESTIÓN DE CARRERA': [
      'Planificación estratégica de carrera',
      'Selección de rivales y proyección de ranking',
      'Desarrollo de récord y tiempos de pelea',
      'Asesoría en decisiones deportivas clave',
    ],
    '🤝 NEGOCIACIÓN DE PELEAS': [
      'Negociación de bolsas y premios',
      'Condiciones contractuales y categorías',
      'Cláusulas de revancha y duración',
      'Acuerdos de exclusividad y derechos',
    ],
    '📄 CONTRATOS Y ACUERDOS': [
      'Firma de contratos de pelea',
      'Revisión legal de cláusulas',
      'Acuerdos con promotoras internacionales',
      'Gestión de derechos de imagen',
    ],
    '🏟️ RELACIÓN CON PROMOTORES': [
      'Contacto directo con promotores',
      'Gestión de oportunidades en carteleras',
      'Inclusión en eventos televisados',
      'Representación frente a promotoras',
    ],
    '💰 GESTIÓN ECONÓMICA': [
      'Administración de bolsas y porcentajes',
      'Gestión de pagos a staff y equipo',
      'Control de viáticos y logística financiera',
      'Seguimiento de ingresos por pelea',
    ],
    '✈️ LOGÍSTICA DE COMPETENCIA': [
      'Gestión de viajes y traslados',
      'Coordinación de hospedaje',
      'Acreditaciones y pesaje',
      'Documentación para peleas internacionales',
    ],
    '📈 MARKETING Y BRANDING': [
      'Marketing personal del boxeador',
      'Gestión de imagen y redes sociales',
      'Búsqueda y gestión de sponsors',
      'Acuerdos de patrocinio y marcas',
    ],
    '📈 BÚSQUEDA DE OPORTUNIDADES': [
      'Gestión de títulos regionales / mundiales',
      'Eliminatorias y rankings federativos',
      'Relación con organismos (WBC, WBA, etc.)',
    ],
  };

  static const List<String> _managerServicesItems = [
    'Gestión de carrera',
    'Negociación de peleas',
    'Firma de contratos',
    'Búsqueda de rivales',
    'Inclusión en eventos',
    'Gestión económica',
    'Logística de viajes',
    'Gestión de sponsors',
    'Marketing deportivo',
  ];

  Widget _buildManagerSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // MÓDULOS TÉCNICOS MANAGER
        ..._managerModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          // Limpiar el título de emojis para generar una key limpia y robusta
          // Ej: "📅 GESTIÓN DE CARRERA" -> "GESTIÓN_DE_CARRERA"
          final String cleanTitle = title
              .split(' ')
              .skip(1)
              .join('_'); // Saltar el emoji
          final String fieldKey = 'man_module_$cleanTitle';

          // Lectura robusta: Buscar en extraData y en sourceData
          final List<dynamic> selected =
              (extraData[fieldKey] ?? sourceData[fieldKey]) ?? [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final store = context.read<AppStore>();
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      // Icono condicional: Check para seleccionado, punto o nada para lista
                      if (isMe)
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white10,
                          size: 16,
                        )
                      else
                        const Icon(
                          Icons.check, // Icono fijo para visualización
                          color: AppColors.primary,
                          size: 14,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isMe
                                ? (isSelected ? Colors.white : Colors.white30)
                                : Colors.white, // Visitante ve blanco brillante
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),

        // SERVICIOS MANAGER DISPONIBLES
        _buildExpandingSection(
          context,
          title: '🧾 SERVICIOS DISPONIBLES',
          isMe: isMe,
          children: _managerServicesItems.map((service) {
            // Lectura robusta: igual que en los módulos
            final List<dynamic> selectedServices =
                (extraData['man_services'] ?? sourceData['man_services']) ?? [];
            final bool isSelected = selectedServices.contains(service);
            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final store = context.read<AppStore>();
                        final List<String> current = List<String>.from(
                          selectedServices,
                        );
                        if (isSelected) {
                          current.remove(service);
                        } else {
                          current.add(service);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['man_services'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    // Icono condicional: igual que en los módulos
                    if (isMe)
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppColors.primary : Colors.white10,
                        size: 16,
                      )
                    else
                      const Icon(
                        Icons.check,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service,
                        style: TextStyle(
                          color: isMe
                              ? (isSelected ? Colors.white : Colors.white30)
                              : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const Map<String, List<String>> _promoterModulesData = {
    '🏟️ ORGANIZACIÓN DE EVENTOS': [
      'Producción integral de veladas de boxeo',
      'Selección estratégica de sedes y estadios',
      'Coordinación de infraestructura y ring',
      'Gestión de logística de eventos masivos',
    ],
    '🥊 ARMADO DE CARTELERAS': [
      'Matchmaking profesional de peleas',
      'Diseño de pelea estelar (Main Event)',
      'Organización de peleas co-estelares',
      'Programación y orden de combates',
    ],
    '🤝 CONTRATACIÓN Y ACUERDOS': [
      'Negociación con managers y agencias',
      'Firma de contratos de pelea y bolsas',
      'Gestión de condiciones de combate',
      'Acuerdos de exclusividad por evento',
    ],
    '💰 FINANCIAMIENTO Y SPONSORS': [
      'Gestión de inversión inicial y retorno',
      'Búsqueda y venta de publicidad/sponsors',
      'Venta de derechos televisivos / Streaming',
      'Implementación de sistema PPV',
    ],
    '📣 MARKETING Y PROMOCIÓN': [
      'Difusión masiva de eventos y prensa',
      'Organización de conferencias de prensa',
      'Gestión de "Cara a Cara" (Face Off)',
      'Campañas de marketing digital y branding',
    ],
    '🎫 GESTIÓN DE ENTRADAS': [
      'Implementación de ticketera y preventa',
      'Gestión de Ringside y áreas VIP',
      'Control de accesos y seguridad',
      'Venta directa y puntos de comercialización',
    ],
    '📺 PRODUCCIÓN AUDIOVISUAL': [
      'Producción de señal de TV / Streaming',
      'Coordinación de relatores y comentaristas',
      'Gestión de derechos de emisión internacional',
      'Post-producción y destacados del evento',
    ],
    '📋 REGULACIÓN Y PERMISOS': [
      'Gestión de permisos municipales y habilitaciones',
      'Seguro de responsabilidad civil del evento',
      'Coordinación con federaciones y comisiones',
      'Cumplimiento de normativas de salud y seguridad',
    ],
  };

  static const List<String> _promoterServicesItems = [
    'Organización de veladas',
    'Producción de eventos',
    'Armado de carteleras',
    'Contratación de boxeadores',
    'Promoción de peleas',
    'Venta de entradas',
    'Streaming / TV',
    'Sponsoreo de eventos',
    'Marketing deportivo',
  ];

  Widget _buildPromoterSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // MÓDULOS TÉCNICOS PROMOTOR
        ..._promoterModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey = 'pro_module_${title.replaceAll(' ', '_')}';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),

        // SERVICIOS PROMOTOR DISPONIBLES
        _buildExpandingSection(
          context,
          title: '🧾 SERVICIOS DISPONIBLES',
          isMe: isMe,
          children: _promoterServicesItems.map((service) {
            final store = context.watch<AppStore>();
            final List<dynamic> selectedServices =
                (isMe
                    ? store.currentUser?.extraData['pro_services']
                    : extraData['pro_services']) ??
                [];
            final bool isSelected = selectedServices.contains(service);
            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selectedServices,
                        );
                        if (isSelected) {
                          current.remove(service);
                        } else {
                          current.add(service);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['pro_services'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      service,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const Map<String, List<String>> _gymOwnerModulesData = {
    '🏢 ADMINISTRACIÓN GENERAL': [
      'Gestión integral del establecimiento',
      'Organización de horarios y grilla',
      'Control de funcionamiento diario',
      'Gestión de personal y normativas',
    ],
    '👥 GESTIÓN DE STAFF': [
      'Contratación de técnicos y entrenadores',
      'Coordinación de preparadores físicos',
      'Supervisión de equipo multidisciplinario',
      'Búsqueda de profesionales de salud',
    ],
    '🥊 INFRAESTRUCTURA DEPORTIVA': [
      'Ring de boxeo profesional',
      'Zona de bolsas pesadas y puching balls',
      'Área de sparring con protecciones',
      'Sector de entrenamiento funcional/pesas',
    ],
    '🛠️ EQUIPAMIENTO DISPONIBLE': [
      'Lonas, cuerdas y mantenimiento de ring',
      'Bolsas pera / Cielo-Tierra / Velocidad',
      'Guantes y cabezales de préstamo',
      'Pisos de goma y colchonetas técnicas',
    ],
    '📅 ACTIVIDADES Y CLASES': [
      'Boxeo Recreativo / Fitness',
      'Clases para Amateur y Semillero',
      'Entrenamientos para Profesionales',
      'Escuelita formativa (Boxeo Infantil)',
    ],
    '🧾 GESTIÓN DE SOCIOS': [
      'Control de inscripciones y cuotas',
      'Seguimiento de asistencia por niveles',
      'Archivo de fichas médicas obligatorias',
      'Evaluaciones de nivel técnico',
    ],
    '🏆 DESARROLLO DEPORTIVO': [
      'Formación competitiva amateur',
      'Preparación para torneos y festivales',
      'Vinculación con managers y agencias',
      'Derivación al profesionalismo',
    ],
    '🤝 ALIANZAS Y CONVENIOS': [
      'Convenios con federaciones oficiales',
      'Relación con promotores de eventos',
      'Búsqueda de sponsors para el gimnasio',
      'Vínculos con clubes y asociaciones',
    ],
    '🎟️ EVENTOS INTERNOS': [
      'Exhibiciones y sparrings abiertos',
      'Festivales amateur internos',
      'Veladas de promoción local',
      'Masterclasses y seminarios',
    ],
  };

  static const List<String> _gymOwnerServicesItems = [
    'Clases de boxeo',
    'Entrenamiento personalizado',
    'Sparring supervisado',
    'Preparación competitiva',
    'Uso libre de instalaciones',
    'Escuela de boxeo infantil',
    'Venta de equipamiento',
    'Alquiler de ring',
  ];

  Widget _buildGymOwnerSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // MÓDULOS TÉCNICOS GIMNASIO
        ..._gymOwnerModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey = 'gym_module_${title.replaceAll(' ', '_')}';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),

        // SERVICIOS GIMNASIO DISPONIBLES
        _buildExpandingSection(
          context,
          title: '🧾 SERVICIOS DISPONIBLES',
          isMe: isMe,
          children: _gymOwnerServicesItems.map((service) {
            final store = context.watch<AppStore>();
            final List<dynamic> selectedServices =
                (isMe
                    ? store.currentUser?.extraData['gym_services']
                    : extraData['gym_services']) ??
                [];
            final bool isSelected = selectedServices.contains(service);
            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selectedServices,
                        );
                        if (isSelected) {
                          current.remove(service);
                        } else {
                          current.add(service);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['gym_services'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      service,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const Map<String, List<String>> _recreationalModulesData = {
    '🎯 ¿QUÉ HACE EN EL GYM?': [
      'Entrenar boxeo recreativo',
      'Aprender técnica básica',
      'Hacer bolsa',
      'Hacer sombra',
      'Entrenar físicamente',
      'Participar en clases grupales',
      'Hacer sparring recreativo',
      'Entrenar de forma individual',
    ],
    '🧭 ¿PARA QUÉ ENTRENA?': [
      'Mejorar estado físico',
      'Bajar de peso',
      'Tonificar cuerpo',
      'Ganar resistencia',
      'Mejorar coordinación',
      'Complementar otro deporte',
      'Actividad recreativa',
    ],
    '🧠 ¿POR QUÉ ELIGIÓ BOXEO?': [
      'Descargar estrés',
      'Salud mental',
      'Disciplina personal',
      'Superación',
      'Hobby / pasión por el boxeo',
      'Inspiración en boxeadores',
      'Defensa personal',
      'Cambio de hábitos',
    ],
    '🔥 OBJETIVO FÍSICO PRINCIPAL': [
      'Quemar grasa',
      'Definición muscular',
      'Mejorar cardio',
      'Resistencia aeróbica',
      'Fuerza funcional',
      'Mejorar movilidad',
    ],
  };

  static const List<String> _recreationalImplicationLevels = [
    'Casual (1–2 veces por semana)',
    'Regular (3–4 veces por semana)',
    'Intensivo recreativo (5+ veces)',
    'Fitness competitivo (Pre-competencia)',
  ];

  static const List<String> _recreationalInterestsItems = [
    'Bolsa libre',
    'Clases técnicas',
    'Sparring suave',
    'Rutinas fitness',
    'Entrenamiento personalizado',
  ];

  Widget _buildRecreationalSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // NIVEL DE IMPLICACIÓN (Selector)
        _buildExpandingSection(
          context,
          title: '🥊 NIVEL DE IMPLICACIÓN',
          isMe: isMe,
          children: _recreationalImplicationLevels.map((level) {
            final store = context.watch<AppStore>();
            final String currentLevel =
                (isMe
                    ? store.currentUser?.extraData['rec_level']
                    : extraData['rec_level']) ??
                '';
            final bool isSelected = currentLevel == level;

            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['rec_level'] = level;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      level,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // MÓDULOS TÉCNICOS RECREATIVOS
        ..._recreationalModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey = 'rec_module_${title.replaceAll(' ', '_')}';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),

        // INTERESES DENTRO DEL GYM
        _buildExpandingSection(
          context,
          title: '🧩 INTERESES DENTRO DEL GYM',
          isMe: isMe,
          children: _recreationalInterestsItems.map((interest) {
            final store = context.watch<AppStore>();
            final List<dynamic> selectedInterests =
                (isMe
                    ? store.currentUser?.extraData['rec_interests']
                    : extraData['rec_interests']) ??
                [];
            final bool isSelected = selectedInterests.contains(interest);
            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selectedInterests,
                        );
                        if (isSelected) {
                          current.remove(interest);
                        } else {
                          current.add(interest);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['rec_interests'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      interest,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const Map<String, List<String>> _fanModulesData = {
    '📺 CONSUMO DE CONTENIDO': [
      'Ver peleas en vivo / streaming',
      'Ver repeticiones de combates',
      'Seguir eventos y carteleras',
      'Mirar entrenamientos abiertos',
      'Consumir entrevistas y conferencias',
    ],
    '🏟️ PARTICIPACIÓN EN EVENTOS': [
      'Asistir a veladas de boxeo',
      'Comprar entradas y ringside',
      'Viajar para ver peleas',
      'Participar en pesajes públicos',
      'Meet & Greet con boxeadores',
    ],
    '💬 INTERACCIÓN SOCIAL': [
      'Comentar peleas y noticias',
      'Participar en foros y debates',
      'Votar resultados de peleas',
      'Hacer predicciones (Pronósticos)',
      'Reaccionar a contenido de atletas',
    ],
    '🧠 ANÁLISIS AMATEUR': [
      'Opinar sobre fallos arbitrales',
      'Analizar rendimiento de boxeadores',
      'Debatir sobre rankings mundiales',
      'Evaluar estilos de pelea',
      'Hacer Fantasy Matchups',
    ],
    '🛍️ CONSUMO COMERCIAL': [
      'Comprar merchandising oficial',
      'Coleccionar guantes / réplicas',
      'Comprar eventos PPV',
      'Suscripciones a medios de boxeo',
    ],
  };

  static const List<String> _fanMotivationsItems = [
    'Pasión por el boxeo',
    'Admiración por boxeadores',
    'Entretenimiento deportivo',
    'Análisis técnico',
    'Cultura del boxeo',
    'Inspiración personal',
    'Historia del deporte',
  ];

  Widget _buildFanSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // MOTIVACIONES (Filtro por Badges)
        _buildExpandingSection(
          context,
          title: '🎯 MIS MOTIVACIONES',
          isMe: isMe,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fanMotivationsItems.map((mot) {
                final store = context.watch<AppStore>();
                final List<dynamic> selected =
                    (isMe
                        ? store.currentUser?.extraData['fan_mots']
                        : extraData['fan_mots']) ??
                    [];
                final bool isSelected = selected.contains(mot);

                if (!isMe && !isSelected) return const SizedBox.shrink();

                return InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(mot);
                          } else {
                            current.add(mot);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra['fan_mots'] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      mot,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // MÓDULOS TÉCNICOS FANS
        ..._fanModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey = 'fan_module_${title.replaceAll(' ', '_')}';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  static const Map<String, List<String>> _journalistModulesData = {
    '🎤 COBERTURA PERIODÍSTICA': [
      'Cubrir veladas en vivo',
      'Cobertura de pesajes públicos',
      'Conferencias de prensa oficiales',
      'Eventos promocionales y firmas',
      'Entrenamientos abiertos al público',
      'Cobertura de Backstage / Detrás de escena',
    ],
    '🎙️ ROLES EN TRANSMISIÓN': [
      'Relator / Narrador de combate',
      'Comentarista técnico',
      'Analista post-pelea',
      'Panelista de programas especializados',
      'Entrevistador oficial en el Ring',
    ],
    '✍️ PRODUCCIÓN ESCRITA': [
      'Crónicas y relatos de combates',
      'Notas previas y análisis de cartelera',
      'Entrevistas exclusivas',
      'Columnas de opinión y editorial',
      'Rankings y estudios de récords',
      'Historias de vida y trayectorias',
    ],
    '🎥 PRODUCCIÓN AUDIOVISUAL': [
      'Entrevistas en video y documentales',
      'Cobertura dinámica para redes sociales',
      'Reels / Highlights de eventos',
      'Programas especializados de boxeo',
      'Podcasts y transmisiones en vivo',
    ],
    '📊 ANÁLISIS DEPORTIVO': [
      'Análisis táctico y de estilos',
      'Estudio comparativo histórico',
      'Evaluación de rendimiento físico',
      'Predicciones y pronósticos expertos',
    ],
    '🌐 DIFUSIÓN Y PRENSA DIGITAL': [
      'Gestión de portales y blogs de boxeo',
      'Canales de YouTube especializados',
      'Streaming independiente',
      'Manejo de redes sociales deportivas',
    ],
  };

  static const List<String> _journalistSpecialtiesItems = [
    'Boxeo Amateur',
    'Boxeo Profesional',
    'Boxeo Femenino',
    'Prospectos',
    'Historia del Boxeo',
    'Negocios del Boxeo',
    'Rankings y Estadísticas',
  ];

  static const List<String> _journalistServicesItems = [
    'Entrevistas a boxeadores',
    'Cobertura de eventos',
    'Difusión de peleas',
    'Publicación de gacetillas',
    'Producción promocional',
    'Moderación de conferencias',
    'Presentación de eventos',
  ];

  Widget _buildJournalistSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // ESPECIALIZACIONES (Badges)
        _buildExpandingSection(
          context,
          title: '🧱 ESPECIALIZACIÓN',
          isMe: isMe,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _journalistSpecialtiesItems.map((spec) {
                final store = context.watch<AppStore>();
                final List<dynamic> selected =
                    (isMe
                        ? store.currentUser?.extraData['jou_specs']
                        : extraData['jou_specs']) ??
                    [];
                final bool isSelected = selected.contains(spec);

                if (!isMe && !isSelected) return const SizedBox.shrink();

                return InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(spec);
                          } else {
                            current.add(spec);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra['jou_specs'] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      spec,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // MÓDULOS TÉCNICOS PERIODISTA
        ..._journalistModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey = 'jou_module_${title.replaceAll(' ', '_')}';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: items.map((item) {
              final bool isSelected = selected.contains(item);
              if (!isMe && !isSelected) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: isMe
                      ? () {
                          final List<String> current = List<String>.from(
                            selected,
                          );
                          if (isSelected) {
                            current.remove(item);
                          } else {
                            current.add(item);
                          }
                          final nextExtra = Map<String, dynamic>.from(
                            store.currentUser?.extraData ?? {},
                          );
                          nextExtra[fieldKey] = current;
                          store.updateUserProfile({'extraData': nextExtra});
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.white30,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),

        // SERVICIOS PERIODÍSTICOS
        _buildExpandingSection(
          context,
          title: '🧾 SERVICIOS DISPONIBLES',
          isMe: isMe,
          children: _journalistServicesItems.map((service) {
            final store = context.watch<AppStore>();
            final List<dynamic> selectedServices =
                (isMe
                    ? store.currentUser?.extraData['jou_services']
                    : extraData['jou_services']) ??
                [];
            final bool isSelected = selectedServices.contains(service);
            if (!isMe && !isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: isMe
                    ? () {
                        final List<String> current = List<String>.from(
                          selectedServices,
                        );
                        if (isSelected) {
                          current.remove(service);
                        } else {
                          current.add(service);
                        }
                        final nextExtra = Map<String, dynamic>.from(
                          store.currentUser?.extraData ?? {},
                        );
                        nextExtra['jou_services'] = current;
                        store.updateUserProfile({'extraData': nextExtra});
                      }
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : Colors.white30,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      service,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const List<String> _officialRolesItems = [
    'Árbitro',
    'Juez',
    'Supervisor',
  ];

  static const List<String> _officialExperienceItems = [
    'Amateur',
    'Profesional',
    'Regional',
    'Nacional',
    'Internacional',
    'Mundial',
  ];

  static const List<String> _officialOrgsItems = [
    'WBC',
    'WBA',
    'IBF',
    'WBO',
    'FAB',
    'Comisión Local',
    'AIBA',
  ];

  static const Map<String, List<String>> _officialModulesData = {
    '⚖️ ESPECIALIDADES REGLAMENTARIAS': [
      'Conteo de protección',
      'Faltas técnicas',
      'Seguridad del boxeador',
      'Reglamento Amateur',
      'Reglamento Profesional',
      'Protocolo de conmoción',
      'Evaluación de golpes (Juez)',
      'Sistema 10-Point Must',
    ],
  };

  static const List<String> _officialServicesItems = [
    'Arbitraje Amateur',
    'Arbitraje Profesional',
    'Juez de Silla',
    'Fiscalización de Eventos',
    'Capacitación / Seminarios',
    'Exhibiciones',
  ];

  Widget _buildCombatOfficialSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // ROLES ACTIVOS (Estilo Chips Titanio) 🛡️
        _buildExpandingSection(
          context,
          title: '⚖️ ROLES ACTIVOS',
          isMe: isMe,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _officialRolesItems.map((role) {
                final store = context.watch<AppStore>();
                final List<dynamic> selected =
                    (isMe
                        ? store.currentUser?.extraData['official_roles']
                        : extraData['official_roles']) ??
                    [];
                final bool isSelected = selected.contains(role);
                if (!isMe && !isSelected) return const SizedBox.shrink();

                return _buildSelectableChip(
                  label: role,
                  isSelected: isSelected,
                  isMe: isMe,
                  onTap: () {
                    final List<String> current = List<String>.from(selected);
                    if (isSelected) {
                      current.remove(role);
                    } else {
                      current.add(role);
                    }
                    final nextExtra = Map<String, dynamic>.from(
                      store.currentUser?.extraData ?? {},
                    );
                    nextExtra['official_roles'] = current;
                    store.updateUserProfile({'extraData': nextExtra});
                  },
                );
              }).toList(),
            ),
          ],
        ),

        // NIVEL DE EXPERIENCIA (Chips)
        _buildExpandingSection(
          context,
          title: '📈 NIVEL DE EXPERIENCIA',
          isMe: isMe,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _officialExperienceItems.map((lvl) {
                final store = context.watch<AppStore>();
                final List<dynamic> selected =
                    (isMe
                        ? store.currentUser?.extraData['official_exp']
                        : extraData['official_exp']) ??
                    [];
                final bool isSelected = selected.contains(lvl);

                if (!isMe && !isSelected) return const SizedBox.shrink();

                return _buildSelectableChip(
                  label: lvl,
                  isSelected: isSelected,
                  isMe: isMe,
                  onTap: () {
                    final List<String> current = List<String>.from(selected);
                    if (isSelected) {
                      current.remove(lvl);
                    } else {
                      current.add(lvl);
                    }
                    final nextExtra = Map<String, dynamic>.from(
                      store.currentUser?.extraData ?? {},
                    );
                    nextExtra['official_exp'] = current;
                    store.updateUserProfile({'extraData': nextExtra});
                  },
                );
              }).toList(),
            ),
          ],
        ),

        // DATOS ADMINISTRATIVOS (Licencia y Peleas)
        _buildExpandingSection(
          context,
          title: '📋 DATOS TÉCNICOS',
          isMe: isMe,
          children: [
            _buildShowcaseTextField(
              context,
              label: 'LICENCIA / CERTIFICACIÓN',
              hint: 'Licencia FAB / Comisión...',
              dataKey: 'license',
              currentValue:
                  (isMe
                          ? context
                                .watch<AppStore>()
                                .currentUser
                                ?.extraData['license']
                          : extraData['license'])
                      ?.toString() ??
                  '',
              isMe: isMe,
            ),
            const SizedBox(height: 15),
            _buildShowcaseTextField(
              context,
              label: 'CANTIDAD DE PELEAS OFICIALES',
              hint: 'Ej: +100',
              dataKey: 'official_fights_count',
              currentValue:
                  (isMe
                          ? context
                                .watch<AppStore>()
                                .currentUser
                                ?.extraData['official_fights_count']
                          : extraData['official_fights_count'])
                      ?.toString() ??
                  '',
              isMe: isMe,
            ),
          ],
        ),

        // ORGANISMOS / FEDERACIONES
        _buildExpandingSection(
          context,
          title: '🏛️ ORGANISMOS',
          isMe: isMe,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _officialOrgsItems.map((org) {
                final store = context.watch<AppStore>();
                final List<dynamic> selected =
                    (isMe
                        ? store.currentUser?.extraData['official_orgs']
                        : extraData['official_orgs']) ??
                    [];
                final bool isSelected = selected.contains(org);

                if (!isMe && !isSelected) return const SizedBox.shrink();

                return _buildSelectableChip(
                  label: org,
                  isSelected: isSelected,
                  isMe: isMe,
                  onTap: () {
                    final List<String> current = List<String>.from(selected);
                    if (isSelected) {
                      current.remove(org);
                    } else {
                      current.add(org);
                    }
                    final nextExtra = Map<String, dynamic>.from(
                      store.currentUser?.extraData ?? {},
                    );
                    nextExtra['official_orgs'] = current;
                    store.updateUserProfile({'extraData': nextExtra});
                  },
                );
              }).toList(),
            ),
          ],
        ),

        // MÓDULOS TÉCNICOS OFICIAL
        ..._officialModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          final String fieldKey =
              'official_module_${title.split(' ').skip(1).join('_')}';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) {
                  final bool isSelected = selected.contains(item);
                  if (!isMe && !isSelected) return const SizedBox.shrink();

                  return _buildSelectableChip(
                    label: item,
                    isSelected: isSelected,
                    isMe: isMe,
                    onTap: () {
                      final List<String> current = List<String>.from(selected);
                      if (isSelected) {
                        current.remove(item);
                      } else {
                        current.add(item);
                      }
                      final nextExtra = Map<String, dynamic>.from(
                        store.currentUser?.extraData ?? {},
                      );
                      nextExtra[fieldKey] = current;
                      store.updateUserProfile({'extraData': nextExtra});
                    },
                  );
                }).toList(),
              ),
            ],
          );
        }).toList(),

        // SERVICIOS DISPONIBLES
        _buildExpandingSection(
          context,
          title: '🧾 SERVICIOS DISPONIBLES',
          isMe: isMe,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _officialServicesItems.map((service) {
                final store = context.watch<AppStore>();
                final List<dynamic> selectedServices =
                    (isMe
                        ? store.currentUser?.extraData['official_services']
                        : extraData['official_services']) ??
                    [];
                final bool isSelected = selectedServices.contains(service);
                if (!isMe && !isSelected) return const SizedBox.shrink();

                return _buildSelectableChip(
                  label: service,
                  isSelected: isSelected,
                  isMe: isMe,
                  onTap: () {
                    final List<String> current = List<String>.from(
                      selectedServices,
                    );
                    if (isSelected) {
                      current.remove(service);
                    } else {
                      current.add(service);
                    }
                    final nextExtra = Map<String, dynamic>.from(
                      store.currentUser?.extraData ?? {},
                    );
                    nextExtra['official_services'] = current;
                    store.updateUserProfile({'extraData': nextExtra});
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  // HELPER PARA CHIPS SELECCIONABLES (TITANIO) 🛡️
  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required bool isMe,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isMe ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // HELPER PARA TEXTFIELDS EN VIDRIERA (TITANIO) 🛡️
  Widget _buildShowcaseTextField(
    BuildContext context, {
    required String label,
    required String hint,
    required String dataKey,
    required String currentValue,
    required bool isMe,
  }) {
    if (!isMe && currentValue.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (isMe)
          TextField(
            onChanged: (val) {
              final store = context.read<AppStore>();
              final nextExtra = Map<String, dynamic>.from(
                store.currentUser?.extraData ?? {},
              );
              nextExtra[dataKey] = val;
              store.updateUserProfile({'extraData': nextExtra});
            },
            controller: TextEditingController(text: currentValue)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: currentValue.length),
              ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white10),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              currentValue,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildCoachSpecs(
    BuildContext context,
    Map<String, dynamic> sourceData,
    bool isMe,
  ) {
    final extraData = sourceData['extraData'] ?? {};

    return Column(
      children: [
        // MÓDULOS TÉCNICOS (LOS 6 PILARES TITANIO)
        ..._coachModulesData.entries.map((entry) {
          final String title = entry.key;
          final List<String> items = entry.value;
          // Limpiar el título de emojis para generar la key correcta
          final String cleanTitle = title.split(' ').skip(1).join('_');
          final String fieldKey = 'coach_module_$cleanTitle';

          final store = context.watch<AppStore>();
          final List<dynamic> selected =
              (isMe
                  ? store.currentUser?.extraData[fieldKey]
                  : extraData[fieldKey]) ??
              [];

          // Si no soy yo y no hay nada seleccionado, ocultar sección
          if (!isMe && selected.isEmpty) return const SizedBox.shrink();

          return _buildExpandingSection(
            context,
            title: title.toUpperCase(),
            isMe: isMe,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) {
                  final bool isSelected = selected.contains(item);

                  // Si no soy yo y no está seleccionado, no mostrar este item
                  if (!isMe && !isSelected) return const SizedBox.shrink();

                  return _buildSelectableChip(
                    label: item,
                    isSelected: isSelected,
                    isMe: isMe,
                    onTap: () {
                      final List<String> current = List<String>.from(selected);
                      if (isSelected) {
                        current.remove(item);
                      } else {
                        current.add(item);
                      }
                      final nextExtra = Map<String, dynamic>.from(
                        store.currentUser?.extraData ?? {},
                      );
                      nextExtra[fieldKey] = current;
                      store.updateUserProfile({'extraData': nextExtra});
                    },
                  );
                }).toList(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExpandingSection(
    BuildContext context, {
    required String title,
    IconData? icon,
    required List<Widget> children,
    required bool isMe,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: icon != null
              ? Icon(icon, color: AppColors.primary, size: 20)
              : null,
          title: Text(
            title,
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: Colors.white30,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
            const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TabItem(icon: Icons.grid_on, label: 'POSTS', isActive: true),
          SizedBox(width: 40),
          _TabItem(
            icon: Icons.video_library_outlined,
            label: 'REELS',
            isActive: false,
          ),
          SizedBox(width: 40),
          _TabItem(
            icon: Icons.bookmark_border,
            label: 'GUARDADO',
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_outline, color: Colors.white24),
          ),
        );
      },
    );
  }

  String _getDisplayRole(String baseRole, String stage, String gender) {
    if (stage.isEmpty) return baseRole;
    return RoleGenderHelper.getRoleName(stage, gender);
  }

  // 🛡️ TITANIO: Helper para extraer valores de forma segura
  String _safeStringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      // Si es un Map, intentar extraer 'value' o 'label'
      return value['value']?.toString() ?? value['label']?.toString() ?? '';
    }
    // Si es otro tipo de objeto, intentar toString() pero con precaución
    final str = value.toString();
    // Si contiene "Instance of" o "DropdownMenuItem", es un objeto no procesado
    if (str.contains('Instance of') || str.contains('DropdownMenuItem')) {
      return '';
    }
    return str;
  }

  Widget _buildHeaderInfoRow(
    BuildContext context, {
    required dynamic nationality,
    required dynamic represents,
    required dynamic gym,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _HeaderInfoBadge(
            icon: Icons.cake,
            label: _safeStringValue(nationality),
          ),
          _HeaderInfoBadge(
            icon: Icons.flag,
            label: _safeStringValue(represents),
          ),
          _HeaderInfoBadge(
            icon: Icons.location_on,
            label: _safeStringValue(gym),
          ),
        ],
      ),
    );
  }

  void _showAddTeamMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddTeamMemberDialog(),
    );
  }

  void _showAddSponsorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddSponsorDialog(),
    );
  }
}

class _AddTeamMemberDialog extends StatefulWidget {
  const _AddTeamMemberDialog();

  @override
  State<_AddTeamMemberDialog> createState() => _AddTeamMemberDialogState();
}

class _AddTeamMemberDialogState extends State<_AddTeamMemberDialog> {
  String _selectedRole = 'Técnico';
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  final List<String> _teamRoles = [
    'Técnico',
    'Preparador Físico',
    'Cutman',
    'Nutricionista',
    'Psicólogo',
    'Manager',
    'Sparring Partner',
  ];

  void _search(String val) async {
    setState(() {
      _isLoading = true;
    });
    final results = await context.read<AppStore>().getScoutingUsers(query: val);
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INVITAR AL EQUIPO',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              '¿Qué rol ocupará en tu rincón?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  items: _teamRoles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: _search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar nombre o rol...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 250,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay resultados',
                        style: TextStyle(color: Colors.white24),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['avatar'] != null
                                ? NetworkImage(user['avatar'])
                                : null,
                            child: user['avatar'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            user['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            user['role'],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              context.read<AppStore>().sendTeamRequest(
                                toUserId: user['id'],
                                toUserName: user['name'],
                                toAvatar: user['avatar'] ?? '',
                                role: _selectedRole,
                              );
                              // Regresar a la raíz para ver el cambio de pestaña al chat
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Solicitud enviada a ${user['name']}',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            child: const Text(
                              'INVITAR',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSponsorDialog extends StatefulWidget {
  const _AddSponsorDialog();

  @override
  State<_AddSponsorDialog> createState() => _AddSponsorDialogState();
}

class _AddSponsorDialogState extends State<_AddSponsorDialog> {
  int _tabIndex = 0; // 0: Buscar en App, 1: Link Externo
  String _extName = '';
  String _extUrl = '';
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  void _search(String val) async {
    setState(() => _isLoading = true);
    final results = await context.read<AppStore>().getScoutingUsers(query: val);
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AGREGAR SPONSOR',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTab(0, 'BUSCAR EN APP'),
                const SizedBox(width: 10),
                _buildTab(1, 'LINK EXTERNO'),
              ],
            ),
            const SizedBox(height: 20),
            if (_tabIndex == 0)
              _buildAppSearchTab()
            else
              _buildExternalLinkTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final bool active = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppSearchTab() {
    return Column(
      children: [
        TextField(
          onChanged: _search,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar marca o empresa...',
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar'] != null
                            ? NetworkImage(user['avatar'])
                            : null,
                        child: user['avatar'] == null
                            ? const Icon(Icons.business)
                            : null,
                      ),
                      title: Text(
                        user['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          context.read<AppStore>().sendSponsorRequest(
                            toUserId: user['id'],
                            toUserName: user['name'],
                            toAvatar: user['avatar'] ?? '',
                          );
                          // Regresar a la raíz para ver el cambio de pestaña al chat
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Solicitud de patrocinio enviada'),
                              backgroundColor: Colors.blueAccent,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text(
                          'SOLICITAR',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExternalLinkTab() {
    return Column(
      children: [
        TextField(
          onChanged: (v) => _extName = v,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nombre de la marca...',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => _extUrl = v,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'URL (FB, IG, Web)...',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            if (_extName.isNotEmpty && _extUrl.isNotEmpty) {
              context.read<AppStore>().addExternalSponsor(_extName, _extUrl);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('AGREGAR SPONSOR EXTERNO'),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? url;

  const _SocialIcon({required this.icon, required this.color, this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: IconButton(
        icon: FaIcon(
          icon,
          color: url != null ? color : Colors.white24,
          size: 22,
        ),
        onPressed: () {
          if (url != null) {
            // Lógica para abrir URL
          }
        },
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String label;
  final String value;
  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _RecordStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RecordStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String? userId;
  final String name;
  final String role;
  final String icon;
  final VoidCallback? onTap;

  const _TeamMember({
    this.userId,
    this.name = '',
    this.role = '',
    this.icon = '👤',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (userId != null && userId!.isNotEmpty) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: context.read<AppStore>().getUserProfileById(userId!),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final String dName = data?['name'] ?? name;
          final String dRole = role;
          final String dAvatar = data?['avatar'] ?? '';

          return _buildStaticCard(context, dName, dRole, dAvatar);
        },
      );
    }
    return _buildStaticCard(context, name, role, '', icon: icon);
  }

  Widget _buildStaticCard(
    BuildContext context,
    String name,
    String role,
    String avatar, {
    String icon = '👤',
  }) {
    final currentUser = context.read<AppStore>().currentUser;
    // canRemove if: I am viewing my own profile OR the member is ME
    final bool canRemove =
        (currentUser?.userId ==
            (context
                    .findAncestorWidgetOfExactType<AthleteProfileView>()
                    ?.userData['userId'] ??
                '')) ||
        (userId == currentUser?.userId);

    return InkWell(
      onLongPress: canRemove
          ? () {
              if (userId != null && userId!.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text(
                      '¿Desvincular del equipo?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      '¿Deseas que $name deje de formar parte del equipo?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('CANCELAR'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<AppStore>().leaveTeam(userId!);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'DESVINCULAR',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
          : null,
      onTap: () async {
        if (onTap != null) {
          onTap!();
          return;
        }
        if (userId != null && userId!.isNotEmpty) {
          final targetData = await context.read<AppStore>().getUserProfileById(
            userId!,
          );
          if (targetData != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AthleteProfileView(userData: targetData),
              ),
            );
          }
        }
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF333333),
                  backgroundImage: avatar.isNotEmpty
                      ? (avatar.startsWith('http')
                            ? NetworkImage(avatar) as ImageProvider
                            : MemoryImage(base64Decode(avatar.split(',').last)))
                      : null,
                  child: avatar.isEmpty
                      ? Text(icon, style: const TextStyle(fontSize: 20))
                      : null,
                ),
                if (userId != null &&
                    userId!.isNotEmpty &&
                    userId != currentUser?.userId)
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: GestureDetector(
                      onTap: () {
                        context.read<AppStore>().startChatWithUser(
                          name,
                          avatar,
                          initialMessage:
                              '¡Hola! Te contacto por tu perfil en Tierra de Campeones.',
                        );
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              role,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Sponsor extends StatelessWidget {
  final String brand;
  final String logo;
  final String? url;
  final String? userId;
  final VoidCallback? onTap;

  const _Sponsor({
    required this.brand,
    required this.logo,
    this.url,
    this.userId,
    this.onTap,
  });

  Widget _buildLogo() {
    if (url != null && url!.isNotEmpty) {
      if (url!.contains('facebook.com')) {
        return const Icon(
          FontAwesomeIcons.facebook,
          color: Colors.blueAccent,
          size: 30,
        );
      }
      if (url!.contains('instagram.com')) {
        return const Icon(
          FontAwesomeIcons.instagram,
          color: Colors.pinkAccent,
          size: 30,
        );
      }
      if (url!.contains('twitter.com') || url!.contains('x.com')) {
        return const Icon(
          FontAwesomeIcons.xTwitter,
          color: Colors.black,
          size: 30,
        );
      }
      if (url!.contains('youtube.com')) {
        return const Icon(
          FontAwesomeIcons.youtube,
          color: Colors.red,
          size: 30,
        );
      }
      if (url!.contains('tiktok.com')) {
        return const Icon(
          FontAwesomeIcons.tiktok,
          color: Colors.black,
          size: 30,
        );
      }
    }
    return Text(
      logo,
      style: const TextStyle(fontSize: 30, color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final currentUser = store.currentUser;
    // canRemove if: viewing my own profile OR member of the team/sponsor link
    final String? profileOwnerId =
        context
            .findAncestorWidgetOfExactType<AthleteProfileView>()
            ?.userData['userId'] ??
        context
            .findAncestorWidgetOfExactType<AthleteProfileView>()
            ?.userData['id'];

    final bool canRemove = (currentUser?.userId == profileOwnerId);
    // Para sponsors internos buscamos si hay un userId en la data de sponsors
    // Pero aquí solo recibimos brand/logo/url.
    // Tendríamos que haber pasado el userId del sponsor.
    // Por simplicidad en esta iteración quirúrgica, permitimos el longpress si es Mi Perfil.

    return InkWell(
      onLongPress: canRemove
          ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text(
                    'Remover Patrocinio',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    '¿Deseas remover a $brand de tu lista de patrocinadores?',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCELAR'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Si no tenemos userId (es externo), lo manejamos en el loop del extraData
                        // Por ahora le pasamos el 'brand' o 'url' para que el store lo busque
                        // Pero ajustaremos el store para que stopSponsoring use el nombre si no hay ID
                        context.read<AppStore>().stopSponsoring(
                          brand,
                        ); // Buscaremos por ID o Nombre
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'REMOVER',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            }
          : null,
      onTap: () {
        if (onTap != null) {
          onTap!();
          return;
        }
        if (url != null && url!.isNotEmpty) {
          // Lógica para abrir link externo si es necesario
        }
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  _buildLogo(),
                  if (userId != null &&
                      userId!.isNotEmpty &&
                      userId != currentUser?.userId)
                    Positioned(
                      right: -5,
                      bottom: -5,
                      child: GestureDetector(
                        onTap: () {
                          context.read<AppStore>().startChatWithUser(
                            brand,
                            '', // Logo de la marca es un emoji o icono, no un avatar base64 usualmente
                            initialMessage:
                                '¡Hola! Te contacto por tu patrocinio en Tierra de Campeones.',
                          );
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                brand,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: isActive
            ? const Border(top: BorderSide(color: Colors.white, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderInfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderInfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty ||
        label == 'null' ||
        label == 'S/D' ||
        label == '--' ||
        label == 'No especificado' ||
        label == 'Global')
      return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
