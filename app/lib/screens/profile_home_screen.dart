import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../services/app_store.dart';
import 'auth_screen.dart';
import '../widgets/main_feed_view.dart';
import '../widgets/athlete_profile_view.dart';
import '../widgets/job_market_view.dart';
import '../widgets/marketplace_view.dart';
import '../widgets/events_view.dart';
import '../widgets/chat_view.dart';
import '../widgets/scouting_view.dart';
import '../widgets/streaming_arena_view.dart';
import '../widgets/settings_view.dart';
import '../widgets/social_stats_widget.dart';

class ProfileHomeScreen extends StatefulWidget {
  final bool autoOpenEdit;
  const ProfileHomeScreen({super.key, this.autoOpenEdit = false});

  @override
  State<ProfileHomeScreen> createState() => _ProfileHomeScreenState();
}

class _ProfileHomeScreenState extends State<ProfileHomeScreen> {
  int _selectedIndex = 0; // 0: Muro, 1: Perfil, 2: Mercado Laboral, 3: Settings

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AuthScreen(initialView: AuthView.registerForm),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStore>().currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: _buildAppBar(context, user, isDesktop),
          drawer: isDesktop ? null : _buildMobileSidebar(context, user),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COLUMNA 1: SIDEBAR (DashBoard Original Style)
              if (isDesktop)
                Container(
                  width: 280,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    border: Border(right: BorderSide(color: Colors.white10)),
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      child: _buildSidebarContent(context, user),
                    ),
                  ),
                ),

              // COLUMNA 2: MAIN CONTENT (Feed / Profile / etc)
              Expanded(
                child: Container(
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.2),
                  child: _selectedIndex == 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 40 : 10,
                          ),
                          child: _buildMainContent(),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 40 : 10,
                            vertical: 30,
                          ),
                          child: _buildMainContent(),
                        ),
                ),
              ),

              // COLUMNA 3: SOCIAL / SUGGESTIONS (Dashboard 3 Columns)
              if (isDesktop && constraints.maxWidth > 1200)
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(30),
                  child: _buildRightSidebar(context),
                ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    dynamic user,
    bool isDesktop,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              isDesktop ? 'TIERRA DE CAMPEONES' : 'T. CAMPEONES',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lexend(
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Text(
            '.',
            style: TextStyle(color: AppColors.primary, fontSize: 24),
          ),
        ],
      ),
      actions: [
        if (isDesktop)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _selectedIndex == 0
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedIndex == 0 ? AppColors.primary : Colors.white10,
                width: 1,
              ),
            ),
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedIndex = 0),
              icon: Icon(
                FontAwesomeIcons.newspaper,
                size: 14,
                color: _selectedIndex == 0 ? AppColors.primary : Colors.white,
              ),
              label: Text(
                'MURO',
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        const SizedBox(width: 15),

        // MARKETPLACE CART
        IconButton(
          onPressed: () => setState(() => _selectedIndex = 3),
          icon: Icon(
            FontAwesomeIcons.cartShopping,
            size: 18,
            color: _selectedIndex == 3 ? AppColors.primary : Colors.white70,
          ),
          tooltip: 'Marketplace',
        ),

        // NOTIFICATIONS BELL
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () => _showNotificationsOverlay(context),
              icon: const Icon(
                FontAwesomeIcons.solidBell,
                size: 18,
                color: Colors.white70,
              ),
              tooltip: 'Notificaciones',
            ),
            Consumer<AppStore>(
              builder: (context, store, _) {
                if (store.unreadNotificationsCount == 0)
                  return const SizedBox.shrink();
                return Positioned(
                  right: 8,
                  top: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF121212),
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${store.unreadNotificationsCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 1),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              backgroundImage:
                  (user?.avatar != null && user!.avatar!.isNotEmpty)
                  ? _getAvatarImage(user.avatar!)
                  : null,
              child: (user?.avatar == null || user!.avatar!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const MainFeedView();
      case 1:
        return const AthleteProfileView(userData: {});
      case 2:
        return const JobMarketView();
      case 3:
        return const MarketplaceView();
      case 4:
        return const EventsView();
      case 5:
        return const ChatView();
      case 6:
        return const ScoutingView();
      case 7:
        return const StreamingArenaView();
      case 8:
        return const SettingsView();
      default:
        return const MainFeedView();
    }
  }

  Widget _buildSidebarContent(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ATHLETE PROFILE CARD (Compact)
          _AthleteProfileCard(
            user: user,
            getAvatarImage: _getAvatarImage,
            onAvatarTap: () => _pickAndUploadAvatar(context),
          ),
          const SizedBox(height: 30),

          // NAVEGACIÓN
          _buildSidebarLink(FontAwesomeIcons.house, 'Inicio / Muro', 0),
          _buildSidebarLink(
            FontAwesomeIcons.circleUser,
            'Mi Perfil Completo',
            1,
          ),
          _buildSidebarLink(FontAwesomeIcons.briefcase, 'Mercado Laboral', 2),
          _buildSidebarLink(FontAwesomeIcons.cartShopping, 'Marketplace', 3),
          _buildSidebarLink(FontAwesomeIcons.trophy, 'Mis Eventos', 4),
          _buildSidebarLink(FontAwesomeIcons.message, 'Mensajes', 5),
          _buildSidebarLink(FontAwesomeIcons.searchengin, 'Scouting', 6),
          _buildSidebarLink(FontAwesomeIcons.youtube, 'Streaming Arena', 7),
          _buildSidebarLink(FontAwesomeIcons.gear, 'Configuración', 8),

          const Divider(color: Colors.white10, height: 40),

          // OTROS LINKS (desactivados por ahora)
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AppStore>().logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
            icon: const Icon(FontAwesomeIcons.rightFromBracket, size: 14),
            label: const Text('CERRAR SESIÓN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarLink(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return ListTile(
      leading: FaIcon(
        icon,
        size: 18,
        color: isActive ? AppColors.primary : Colors.white60,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white60,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      onTap: () {
        if (index != -1) {
          setState(() => _selectedIndex = index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sección en desarrollo...')),
          );
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      hoverColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildMobileSidebar(BuildContext context, dynamic user) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildSidebarContent(context, user),
        ),
      ),
    );
  }

  void _showNotificationsOverlay(BuildContext context) {
    final store = context.read<AppStore>();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NOTIFICACIONES',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        store.markNotificationsAsRead();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'MARCAR LEÍDAS',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Consumer<AppStore>(
                  builder: (context, store, _) {
                    final notifs = store.notifications;
                    if (notifs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No tienes notificaciones.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final n = notifs[index];
                        return _buildNotificationTile(n);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> n) {
    IconData icon;
    Color color;

    switch (n['type']) {
      case 'job':
        icon = FontAwesomeIcons.briefcase;
        color = Colors.blueAccent;
        break;
      case 'streaming':
        icon = FontAwesomeIcons.video;
        color = Colors.purpleAccent;
        break;
      case 'follow':
      case 'like':
      case 'post':
        icon = n['type'] == 'follow'
            ? FontAwesomeIcons.userPlus
            : FontAwesomeIcons.solidHeart;
        color = AppColors.primary;
        break;
      default:
        icon = FontAwesomeIcons.bell;
        color = Colors.white54;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 14),
      ),
      title: Text(
        n['title'] ?? '',
        style: TextStyle(
          color: n['read'] == true ? Colors.white70 : Colors.white,
          fontWeight: n['read'] == true ? FontWeight.normal : FontWeight.bold,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        n['body'] ?? '',
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
      onTap: () {
        // Handle navigation based on type
        Navigator.pop(context);
      },
    );
  }

  Widget _buildRightSidebar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A QUIÉN SEGUIR',
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _buildUserSuggestion('Canelo Alvarez', 'Boxeador Pro', '🥊'),
        _buildUserSuggestion('Freddie Roach', 'Entrenador', '🧢'),
        _buildUserSuggestion('Eddie Hearn', 'Promotor', '💼'),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const Icon(FontAwesomeIcons.fire, color: Colors.orange, size: 30),
              const SizedBox(height: 15),
              const Text(
                'ÚNETE AL CLUB',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Acceso exclusivo a pesajes y streams.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('GO GOLD'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserSuggestion(String name, String role, String icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            radius: 15,
            child: Text(icon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Seguir',
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final Uint8List fileBytes = result.files.first.bytes!;
        final String base64Image =
            'data:image/png;base64,${base64Encode(fileBytes)}';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronizando avatar...')),
        );

        final store = context.read<AppStore>();
        await store.updateUserProfile({'avatar': base64Image});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Avatar actualizado!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al procesar archivo: $e')));
    }
  }
}

class _AthleteProfileCard extends StatelessWidget {
  final dynamic user;
  final ImageProvider Function(String) getAvatarImage;
  final VoidCallback onAvatarTap;

  const _AthleteProfileCard({
    required this.user,
    required this.getAvatarImage,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    // UNIFICACIÓN DE DATOS (Estrategia "Espejo Limpio")
    final Map<String, dynamic> data = {...user.toJson(), ...user.extraData};

    // Extracción segura
    final String labelName = (data['name'] ?? 'Usuario')
        .toString()
        .toUpperCase();
    final String labelRole = (data['role'] ?? 'Fanático')
        .toString()
        .toUpperCase();
    final String labelNickname = (data['nickname'] ?? '').toString();
    final String labelRecord = (data['record'] ?? '0-0-0').toString();

    final List followers = data['followers'] is List
        ? data['followers'] as List
        : [];
    final List following = data['following'] is List
        ? data['following'] as List
        : [];
    final List blocked = data['blocked'] is List ? data['blocked'] as List : [];

    // Datos Extendidos
    final String location =
        (data['nationality'] ??
                data['location'] ??
                data['currentLocation'] ??
                '')
            .toString();

    final String gym =
        (data['gym'] ?? data['gymName'] ?? data['coachBaseGym'] ?? '')
            .toString();

    final String age = (data['age'] ?? '').toString();
    final String category = (data['weightClass'] ?? data['category'] ?? '')
        .toString();
    final String height = (data['height'] ?? '').toString();
    final String reach = (data['reach'] ?? '').toString();
    final String stance = (data['stance'] ?? '').toString();
    final String trainer = (data['initialTrainer'] ?? data['coach'] ?? '')
        .toString();
    final String email = (data['email'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF8B0000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              labelRole, // --- ROL RESTAURADO ---
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.black,
                      backgroundImage:
                          (user.avatar != null && user.avatar.isNotEmpty)
                          ? getAvatarImage(user.avatar)
                          : null,
                      child: (user.avatar == null || user.avatar.isEmpty)
                          ? const Text('🥊', style: TextStyle(fontSize: 35))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  labelName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (labelNickname.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '"$labelNickname"',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // --- DATOS EXTENDIDOS COMPLETOS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      if (location.isNotEmpty)
                        _buildInfoRow(
                          FontAwesomeIcons.flag,
                          'Representa: $location',
                        ),
                      if (gym.isNotEmpty)
                        _buildInfoRow(FontAwesomeIcons.dumbbell, 'Gym: $gym'),
                      if (trainer.isNotEmpty)
                        _buildInfoRow(
                          FontAwesomeIcons.userTie,
                          'Coach: $trainer',
                        ),

                      const SizedBox(height: 8),

                      if (height.isNotEmpty ||
                          reach.isNotEmpty ||
                          stance.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (height.isNotEmpty)
                                _buildTag('📏 ${height}cm'),
                              if (reach.isNotEmpty) _buildTag('🤜 ${reach}cm'),
                              if (stance.isNotEmpty) _buildTag('🛡️ $stance'),

                              // --- TAGS ESPECÍFICOS DE COACH ---
                              if (user.roleKey == 'coach') ...[
                                ...((data['coachRanks'] ?? []) as List).map(
                                  (r) => _buildTag('🏆 $r'),
                                ),
                                ...((data['coachSpecialties'] ?? []) as List)
                                    .map((s) => _buildTag('🎯 $s')),
                              ],
                            ],
                          ),
                        ),

                      if (age.isNotEmpty || category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              if (age.isNotEmpty)
                                Text(
                                  '$age Años',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              if (category.isNotEmpty)
                                Text(
                                  category,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),

                      if (email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ), // Corrección: Spacer() rompe el layout en SingleChildScrollView
          const Divider(color: Colors.white10),
          if (user.roleKey == 'pro-boxer' ||
              user.roleKey == 'amateur-boxer' ||
              user.roleKey == 'cadet' ||
              user.roleKey == 'retired-boxer' ||
              user.roleKey == 'legend-boxer') ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildMiniStat('RÉCORD', labelRecord),
            ),
            const Divider(color: Colors.white10, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSocialStatItem(
                    context,
                    'FANS',
                    followers.length,
                    data,
                    user.userId == user.userId,
                    0,
                  ), // isMe is true for current card user if we are viewing our own card
                  _buildSocialStatItem(
                    context,
                    'SEGUIDOS',
                    following.length,
                    data,
                    user.userId == user.userId,
                    1,
                  ),
                  if (user.userId ==
                      user.userId) // Adjusting logic: the sidebar card usually shows the logged-in user
                    _buildSocialStatItem(
                      context,
                      'BLOCKS',
                      blocked.length,
                      data,
                      true,
                      2,
                    ),
                ],
              ),
            ),
          ],
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (_, _, _) =>
                        const AuthScreen(initialView: AuthView.registerForm),
                  ),
                );
              },
              child: const Text(
                'EDITAR PERFIL COMPLETO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  Widget _buildSocialStatItem(
    BuildContext context,
    String label,
    int count,
    Map<String, dynamic> userData,
    bool isMe,
    int initialTab,
  ) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.bgElevated,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          isScrollControlled: true,
          builder: (context) => _SocialModalWrapper(
            initialTab: initialTab,
            userData: userData,
            isMe: isMe,
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: _buildMiniStat(label, count.toString()),
      ),
    );
  }
}

class _SocialModalWrapper extends StatelessWidget {
  final int initialTab;
  final Map<String, dynamic> userData;
  final bool isMe;

  const _SocialModalWrapper({
    required this.initialTab,
    required this.userData,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // Re-using the logic from social_stats_widget implicitly would be hard due to private classes,
    // but we can instantiate a dummy SocialStatsWidget just to get its private _SocialModalContent if we made it public,
    // or just use the same pattern. Since I can't easily import private classes from other files,
    // I will use the SocialStatsWidget itself or make the modal content public.
    // Actually, SocialStatsWidget.userData and SocialStatsWidget.isMe are what we need.

    return SocialModalContent(
      initialTab: initialTab,
      userData: userData,
      isMe: isMe,
    );
  }
}
