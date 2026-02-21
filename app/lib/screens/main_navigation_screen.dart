import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../widgets/main_feed_view.dart';
import '../widgets/athlete_profile_view.dart';
import '../widgets/scouting_view.dart';
import '../widgets/job_market_view.dart';
import '../widgets/marketplace_view.dart';
import '../widgets/events_view.dart';
import '../widgets/streaming_arena_view.dart';
import '../widgets/chat_view.dart';
import '../widgets/settings_view.dart';
import '../widgets/profile_showcase_view.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import 'auth_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../core/role_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final bool autoOpenEdit;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.autoOpenEdit = false,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Iniciar con el índice del store si existe, o el inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != 0) {
        context.read<AppStore>().setNavIndex(widget.initialIndex);
      }
    });

    if (widget.autoOpenEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, _, _) =>
                const AuthScreen(initialView: AuthView.registerForm),
          ),
        );
      });
    }
  }

  Future<void> _pickAndUploadSidebarAvatar() async {
    final store = context.read<AppStore>();
    if (store.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para cambiar tu foto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Importante para obtener los bytes en web/desktop
      );

      if (result != null) {
        Uint8List? fileBytes = result.files.first.bytes;

        if (fileBytes != null) {
          // Convertimos bytes a Base64 para mostrarlo localmente sin backend
          String base64Image =
              'data:image/png;base64,${base64Encode(fileBytes)}';

          // Guardamos en el store
          await store.updateUserProfile({'avatar': base64Image});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Foto de perfil actualizada con éxito!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.bg,
          appBar: _buildNavbar(isDesktop),
          drawer: isDesktop ? null : _buildSidebar(isMobile: true),
          body: Container(
            decoration: _buildBackgroundTexture(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop)
                  SizedBox(
                    width: 280,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 40,
                        top: 40,
                        right: 10,
                      ),
                      child: _buildSidebar(isMobile: false),
                    ),
                  ),
                Expanded(
                  child: context.watch<AppStore>().currentNavIndex == 0
                      // FEED: barra fija abajo + posts scrolleables arriba
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 20 : 0,
                          ),
                          child: _buildMainContent(isDesktop),
                        )
                      // OTROS TABS: scroll normal
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 20 : 0,
                            vertical: 40,
                          ),
                          child: _buildMainContent(isDesktop),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildBackgroundTexture() {
    return const BoxDecoration(color: AppColors.bg);
  }

  // --- NAVBAR ---
  PreferredSizeWidget _buildNavbar(bool isDesktop) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withOpacity(0.98),
          border: const Border(
            bottom: BorderSide(color: Color(0x4DC41E3A), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
          child: Row(
            children: [
              if (!isDesktop)
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),

              // Logo
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFD4D4D4)],
                ).createShader(bounds),
                child: Text(
                  'Tierra de Campeones',
                  style: AppTheme.headingStyle.copyWith(fontSize: 20),
                ),
              ),
              const Text(
                '.',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              if (isDesktop)
                Container(
                  width: 400,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onSubmitted: (val) {
                      if (val.isNotEmpty) {
                        context.read<AppStore>().setSearchQuery(val);
                        context.read<AppStore>().setNavIndex(
                          1,
                        ); // Switch to Scouting
                      }
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar boxeadores, gimnasios...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A).withValues(alpha: 0.8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

              const Spacer(),

              // Nav Menu
              _buildNavItem(
                FontAwesomeIcons.house,
                0,
                isDesktop,
                badgeCount: context.watch<AppStore>().unreadNotificationsCount,
              ), // Inicio
              _buildNavItem(FontAwesomeIcons.compass, 1, isDesktop), // Explorar
              _buildNavItem(
                FontAwesomeIcons.briefcase,
                2,
                isDesktop,
                badgeCount: context.watch<AppStore>().newJobsCount,
              ), // Bolsa de Trabajo
              _buildNavItem(
                FontAwesomeIcons.comment,
                3,
                isDesktop,
                badgeCount: context.watch<AppStore>().unreadMessagesCount,
              ), // Chat

              _buildNavItem(FontAwesomeIcons.user, 4, isDesktop), // Perfil
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    int index,
    bool isDesktop, {
    int badgeCount = 0,
  }) {
    bool isActive = context.watch<AppStore>().currentNavIndex == index;
    return Stack(
      children: [
        IconButton(
          icon: FaIcon(
            icon,
            color: isActive ? AppColors.primary : AppColors.textMuted,
            size: 22,
          ),
          onPressed: () {
            final store = context.read<AppStore>();
            store.setNavIndex(index);
            // Marcar como visto segun el indice
            if (index == 0) store.markNotificationsAsRead();
            if (index == 2) store.markSectionVisited('jobs');
            if (index == 3) store.markSectionVisited('chat');
          },
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (isActive && isDesktop)
          Positioned(
            bottom: 4,
            left: 20,
            right: 20,
            child: Container(
              height: 4,
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  // Helper para manejar imágenes base64 o network
  ImageProvider _getAvatarImage(String avatarData) {
    if (avatarData.startsWith('data:image')) {
      try {
        final base64String = avatarData.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return const NetworkImage('https://via.placeholder.com/150');
      }
    } else {
      return NetworkImage(avatarData);
    }
  }

  // --- SIDEBAR ---
  Widget _buildSidebar({required bool isMobile}) {
    final user = context.watch<AppStore>().currentUser;

    // Detectar si es Leyenda para tema dorado
    final bool isLegend = user?.roleKey == 'legend-boxer';
    final Color legendGold = const Color(0xFFD4AF37);
    final Color legendGoldDark = const Color(0xFFB8860B);

    return Container(
      color: isMobile ? AppColors.bg : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card - SOLO SI HAY USUARIO
          if (user != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLegend
                      ? legendGold.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.06),
                  width: isLegend ? 2 : 1,
                ),
                boxShadow: isLegend
                    ? [
                        BoxShadow(
                          color: legendGold.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // Header BG (Dorado para Leyenda)
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      gradient: LinearGradient(
                        colors: isLegend
                            ? [
                                legendGold,
                                legendGoldDark,
                                const Color(0xFF1A1A1A),
                              ]
                            : [
                                AppColors.primary,
                                const Color(0xFF8A1828),
                                const Color(0xFF333333),
                              ],
                      ),
                    ),
                  ),
                  // Avatar
                  Transform.translate(
                    offset: const Offset(0, -35),
                    child: GestureDetector(
                      onTap: _pickAndUploadSidebarAvatar,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLegend ? legendGold : AppColors.bg,
                            width: isLegend ? 3 : 4,
                          ),
                          image: (user.avatar ?? '').isNotEmpty
                              ? DecorationImage(
                                  image: _getAvatarImage(user.avatar ?? ''),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: isLegend
                                  ? legendGold.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.6),
                              blurRadius: isLegend ? 20 : 16,
                              offset: const Offset(0, 4),
                              spreadRadius: isLegend ? 3 : 0,
                            ),
                          ],
                        ),
                        child: (user.avatar ?? '').isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Column(
                      children: [
                        Text(
                          user.name,
                          style: AppTheme.headingStyle.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        if ((user.extraData['nickname'] ?? '').isNotEmpty)
                          Text(
                            '"${user.extraData['nickname']}"',
                            style: GoogleFonts.roboto(
                              color: isLegend ? legendGold : AppColors.primary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLegend
                                ? legendGold.withValues(alpha: 0.2)
                                : AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isLegend
                                  ? legendGold.withValues(alpha: 0.6)
                                  : AppColors.accent.withValues(alpha: 0.3),
                            ),
                            boxShadow: isLegend
                                ? [
                                    BoxShadow(
                                      color: legendGold.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLegend) ...[
                                Icon(Icons.star, color: legendGold, size: 12),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                RoleGenderHelper.getRoleName(
                                  user.extraData['careerStage'] ?? user.roleKey,
                                  user.gender,
                                ).toUpperCase(),
                                style: GoogleFonts.roboto(
                                  color: isLegend
                                      ? legendGold
                                      : AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // BOTÓN DE EDICIÓN PROMINENTE
                        SizedBox(
                          height: 30,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            icon: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'EDITAR MI PERFIL',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // DATOS EXTRA (País, Gimnasio, Rango)
                        if (user.extraData['represents'] != null &&
                            user.extraData['represents'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_outlined, // Icono simple
                                  size: 11,
                                  color: Colors.white30,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.extraData['represents'].toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (user.extraData['gym'] != null &&
                            user.extraData['gym'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  FontAwesomeIcons.dumbbell,
                                  size: 10,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user.extraData['gym'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Si es Técnico, mostrar Rango (Lectura Robusta Titanium)
                        if ((user.roleKey == 'coach' ||
                                user.roleKey.contains('entrenador')) &&
                            ((user.extraData['coachRanks'] ??
                                    user.toJson()['coachRanks'])
                                is List))
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Wrap(
                              spacing: 4,
                              alignment: WrapAlignment.center,
                              children:
                                  ((user.extraData['coachRanks'] ??
                                              user.toJson()['coachRanks'])
                                          as List)
                                      .take(2)
                                      .map<Widget>((r) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            r.toString().toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                            ),
                          ),

                        // Si es Manager, mostrar Empresa y Licencia (Lectura Robusta Titanium)
                        if (user.roleKey == 'manager' ||
                            user.roleKey.contains('representante')) ...[
                          // Empresa/Agencia
                          if ((user.extraData['company'] ??
                                  user.toJson()['company']) !=
                              null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.business,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      (user.extraData['company'] ??
                                              user.toJson()['company'])
                                          .toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Licencia
                          if ((user.extraData['license'] ??
                                  user.toJson()['license']) !=
                              null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 11,
                                    color: Colors.white30,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Lic: ${(user.extraData['license'] ?? user.toJson()['license']).toString()}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        const SizedBox(height: 12),
                        // Stats
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.03),
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const _StatItem(label: 'POSTS', value: '0'),
                              _StatItem(
                                label: 'SIGUE',
                                value:
                                    '${user.extraData['following']?.length ?? 0}',
                              ),
                              _StatItem(
                                label: 'FANS',
                                value:
                                    '${user.extraData['followers']?.length ?? 0}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mini Redes Sociales
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSidebarSocialIcon(
                              FontAwesomeIcons.instagram,
                              Colors.pinkAccent,
                              user.extraData['instagram']?.toString(),
                            ),
                            _buildSidebarSocialIcon(
                              FontAwesomeIcons.facebook,
                              Colors.blueAccent,
                              user.extraData['facebook']?.toString(),
                            ),
                            _buildSidebarSocialIcon(
                              FontAwesomeIcons.twitter,
                              Colors.lightBlue,
                              user.extraData['twitter']?.toString(),
                            ),
                            _buildSidebarSocialIcon(
                              FontAwesomeIcons.youtube,
                              Colors.red,
                              user.extraData['youtube']?.toString(),
                            ),
                            _buildSidebarSocialIcon(
                              FontAwesomeIcons.tiktok,
                              Colors.white,
                              user.extraData['tiktok']?.toString(),
                            ),
                            _buildSidebarSocialIcon(
                              FontAwesomeIcons.twitch,
                              const Color(0xFF9146FF),
                              user.extraData['twitch']?.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // --- MENÚ LATERAL DE NAVEGACIÓN (BETA ACCESS) ---
                        const Divider(color: Colors.white10),
                        _buildSidebarMenuLink(
                          context,
                          'Marketplace',
                          FontAwesomeIcons.store,
                          5,
                        ),
                        _buildSidebarMenuLink(
                          context,
                          'Eventos',
                          FontAwesomeIcons.calendar,
                          6,
                        ),
                        _buildSidebarMenuLink(
                          context,
                          'Streaming Arena',
                          FontAwesomeIcons.video,
                          7,
                        ),
                        _buildSidebarMenuLink(
                          context,
                          'Configuración',
                          FontAwesomeIcons.gear,
                          8,
                        ),
                        const SizedBox(height: 16),

                        // FICHA RÁPIDA - Solo para Boxeadores
                        if (user.roleName.toLowerCase().contains('boxea') ||
                            user.roleKey.toLowerCase().contains('cadet')) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FICHA TÉCNICA',
                                  style: GoogleFonts.roboto(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildQuickStat(
                                  context,
                                  'EDAD',
                                  '${user.extraData['age'] ?? '--'} años',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'RÉCORD (G-P-E-NC-KO)',
                                  '${user.extraData['wins'] ?? '0'}-${user.extraData['losses'] ?? '0'}-${user.extraData['draws'] ?? '0'}-${user.extraData['nc'] ?? '0'} (${user.extraData['kos'] ?? '0'} KO)',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'CATEGORÍA',
                                  user.extraData['weightClass'] ?? 'S/D',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'ALTURA',
                                  '${user.extraData['height'] ?? '---'} cm',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'ALCANCE',
                                  '${user.extraData['reach'] ?? '---'} cm',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'GUARDIA',
                                  user.extraData['stance'] ?? 'S/D',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'REPRESENTA',
                                  user.extraData['represents'] ??
                                      user.extraData['representation'] ??
                                      '🌐',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'ORIGEN',
                                  user.extraData['nationality'] ?? 'S/D',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'GIMNASIO',
                                  user.extraData['gym'] ?? 'S/D',
                                ),
                                const SizedBox(height: 8),
                                _buildQuickStat(
                                  context,
                                  'TÉCNICO',
                                  user.extraData['trainer'] ?? 'S/D',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            // SI NO HAY USUARIO, BOTÓN DE LOGIN LIMPIO
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, _, _) =>
                          const AuthScreen(initialView: AuthView.login),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('ACCEDER AL PERFIL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Side Menu
          _buildSideMenuItem(FontAwesomeIcons.house, 'Inicio', 0),
          _buildSideMenuItem(
            FontAwesomeIcons.compass,
            'Explorar / Scouting',
            1,
          ),
          _buildSideMenuItem(FontAwesomeIcons.briefcase, 'Bolsa de Trabajo', 2),
          _buildSideMenuItem(
            FontAwesomeIcons.cartShopping,
            'Marketplace',
            5,
            badgeCount: context.watch<AppStore>().newMarketplaceCount,
          ),
          _buildSideMenuItem(
            FontAwesomeIcons.calendarDay,
            'Eventos',
            6,
            badgeCount: context.watch<AppStore>().newEventsCount,
          ),
          _buildSideMenuItem(
            FontAwesomeIcons.video,
            'Streaming Arena',
            7,
            badgeCount: context.watch<AppStore>().newStreamingCount,
          ),
          _buildSideMenuItem(FontAwesomeIcons.gear, 'Ajustes', 8),

          if (!isMobile) ...[
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'A QUIÉN SEGUIR',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildWhoToFollow(context),
          ],

          const Divider(color: Colors.white10, height: 40),
          _buildSideMenuItem(
            FontAwesomeIcons.rightFromBracket,
            'Cerrar Sesión',
            -1,
            isLogout: true,
          ),
          _buildLegalFooter(),
        ],
      ),
    );
  }

  Widget _buildLegalFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildFooterLink('Términos', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Términos de Uso próximamente')),
                );
              }),
              const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
              _buildFooterLink('Privacidad', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Política de Privacidad próximamente'),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'tierradecampeonesapp@gmail.com',
                queryParameters: {'subject': 'Consulta desde la App'},
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir el correo')),
                  );
                }
              }
            },
            child: Text(
              'tierradecampeonesapp@gmail.com',
              style: GoogleFonts.roboto(
                color: AppColors.textMuted,
                fontSize: 11,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            '© 2026 Tierra de Campeones',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWhoToFollow(BuildContext context) {
    final store = context.watch<AppStore>();
    final suggestions = store.mockUsers
        .where((u) => !store.isFollowing(u['id']))
        .take(3)
        .toList();

    return Column(
      children: suggestions
          .map(
            (u) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(u['avatar']),
              ),
              title: Text(
                u['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                u['role'],
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              trailing: GestureDetector(
                onTap: () => store.followUser(u['id']),
                child: const Text(
                  'Seguir +',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSideMenuItem(
    IconData icon,
    String label,
    int index, {
    bool isLogout = false,
    int badgeCount = 0,
  }) {
    bool isActive = context.watch<AppStore>().currentNavIndex == index;
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          FaIcon(
            icon,
            color: isLogout
                ? Colors.redAccent
                : (isActive ? AppColors.primary : AppColors.textSecondary),
            size: 18,
          ),
          if (badgeCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isLogout
              ? Colors.redAccent
              : (isActive ? Colors.white : AppColors.textSecondary),
          fontSize: 14,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        if (isLogout) {
          context.read<AppStore>().logout();
          Navigator.pushReplacementNamed(context, '/');
        } else {
          final store = context.read<AppStore>();
          store.setNavIndex(index);

          // Limpiar insignias al entrar
          if (index == 5) store.markSectionVisited('marketplace');
          if (index == 6) store.markSectionVisited('events');
          if (index == 7) store.markSectionVisited('streaming');
          if (index == 2) store.markSectionVisited('jobs');
          if (index == 0) store.markNotificationsAsRead();

          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            Navigator.pop(context); // Close drawer on mobile
          }
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: AppColors.primary.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
    );
  }

  // --- MAIN CONTENT ---
  Widget _buildMainContent(bool isDesktop) {
    final selectedIndex = context.watch<AppStore>().currentNavIndex;
    switch (selectedIndex) {
      case 0:
        return const MainFeedView();
      case 1:
        return const ScoutingView();
      case 2:
        return const JobMarketView();
      case 3:
        return const ChatView();
      case 4:
        final user = context.watch<AppStore>().currentUser;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.userLock,
                  size: 60,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 20),
                const Text(
                  'IDENTIFÍCATE, CAMPEÓN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Inicia sesión para gestionar tu perfil y carrera.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, _, _) =>
                            const AuthScreen(initialView: AuthView.login),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('INICIAR SESIÓN / REGISTRARSE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        // Si SÍ hay usuario, mostramos su perfil con permisos de edición
        // PASAMOS MAPA VACÍO PARA FORZAR USO DE APPSTORE (Precisión Quirúrgica)
        return const AthleteProfileView(userData: {});
      case 5:
        return const MarketplaceView();
      case 6:
        return const EventsView();
      case 7:
        return const StreamingArenaView();
      case 8:
        return const SettingsView();
      case 9:
        return const ProfileShowcaseView();
      default:
        return _buildPlaceholderView();
    }
  }

  // Helper para mostrar datos técnicos en el sidebar
  Widget _buildQuickStat(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarSocialIcon(IconData icon, Color color, String? url) {
    if (url == null || url.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: () {
          // Lógica de apertura de URL
        },
        child: FaIcon(icon, color: color.withValues(alpha: 0.8), size: 14),
      ),
    );
  }

  Widget _buildPlaceholderView() {
    String title = "Próximamente";
    IconData icon = FontAwesomeIcons.hammer;

    final selectedIndex = context.watch<AppStore>().currentNavIndex;
    switch (selectedIndex) {
      case 1:
        title = "Explorar / Scouting";
        icon = FontAwesomeIcons.compass;
        break;
      case 2:
        title = "Bolsa de Trabajo";
        icon = FontAwesomeIcons.briefcase;
        break;
      case 3:
        title = "Mensajes / Chat";
        icon = FontAwesomeIcons.comment;
        break;
      case 5:
        title = "Marketplace";
        icon = FontAwesomeIcons.cartShopping;
        break;
      case 6:
        title = "Eventos";
        icon = FontAwesomeIcons.calendarDay;
        break;
      case 7:
        title = "Streaming Arena";
        icon = FontAwesomeIcons.video;
        break;
      case 8:
        title = "Configuración";
        icon = FontAwesomeIcons.gear;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          FaIcon(
            icon,
            size: 60,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTheme.headingStyle.copyWith(fontSize: 24)),
          const SizedBox(height: 10),
          const Text(
            'Estamos trabajando para traerte esta sección.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenuLink(
    BuildContext context,
    String label,
    IconData icon,
    int index,
  ) {
    final bool isActive = context.watch<AppStore>().currentNavIndex == index;
    return ListTile(
      leading: FaIcon(
        icon,
        color: isActive ? AppColors.primary : AppColors.textMuted,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      visualDensity: VisualDensity.compact,
      onTap: () {
        context.read<AppStore>().setNavIndex(index);
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        }
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.headingStyle.copyWith(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
      ],
    );
  }
}
