import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/app_store.dart';
import 'custom_video_player.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class StreamingArenaView extends StatefulWidget {
  const StreamingArenaView({super.key});

  @override
  State<StreamingArenaView> createState() => _StreamingArenaViewState();
}

class _StreamingArenaViewState extends State<StreamingArenaView> {
  String _activeFilter = 'all';
  String _selectedCategory = 'all';
  String _arenaSearchQuery = '';
  String? _playingEventId;
  Timer? _viewTimer;
  int _playerNonce = 0;

  @override
  void initState() {
    super.initState();
    _startViewSimulation();
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    super.dispose();
  }

  void _startViewSimulation() {
    _viewTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final store = context.read<AppStore>();
      final liveOnes = store.liveEvents
          .where((e) => e['type'] == 'VIVO')
          .toList();
      if (liveOnes.isNotEmpty) {
        for (var event in liveOnes) {
          final r = (DateTime.now().millisecond % 100) / 100.0;
          if (r > 0.5) {
            store.updateLiveViews(event['id'], 1 + (DateTime.now().second % 3));
          } else if (r < 0.2 && (event['views'] ?? 0) > 20) {
            store.updateLiveViews(event['id'], -1);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final allEvents = store.liveEvents;

    final filtered = allEvents.where((e) {
      // Lógica de 12 horas: si es VIVO pero muy viejo, se trata como REPETICION
      String effectiveType = e['type'];
      if (effectiveType == 'VIVO') {
        try {
          final date = DateTime.parse(e['date']);
          if (DateTime.now().difference(date).inHours > 12) {
            effectiveType = 'REPETICION';
          }
        } catch (_) {}
      }

      // 1. Filtro por tipo (Vivo/Repetición)
      final bool matchesType =
          _activeFilter == 'all' || effectiveType == _activeFilter;
      // 2. Filtro por categoría (Combates, Sparring, etc)
      final bool matchesCategory =
          _selectedCategory == 'all' ||
          (e['category']?.toString().toUpperCase() ==
              _selectedCategory.toUpperCase());

      // 3. Filtro por búsqueda de texto
      final String query = _arenaSearchQuery.toLowerCase();
      final String title = (e['title'] ?? '').toString().toLowerCase();
      final String creator = (e['creatorName'] ?? '').toString().toLowerCase();
      final String gym = (e['gym'] ?? '').toString().toLowerCase();
      final String desc = (e['desc'] ?? '').toString().toLowerCase();

      final bool matchesSearch =
          query.isEmpty ||
          title.contains(query) ||
          creator.contains(query) ||
          gym.contains(query) ||
          desc.contains(query);

      return matchesType && matchesCategory && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) {
                      final bool isSmall =
                          MediaQuery.of(context).size.width < 600;
                      return Image.asset(
                        'assets/images/logo.png',
                        height: isSmall ? 45 : 80,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                  const Spacer(),
                  const Text(
                    'TIERRA DE CAMPEONES',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateStreamDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('EVENTO', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _arenaSearchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por título, gimnasio o protagonista...',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white24,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Transmisiones en vivo y repeticiones premium',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 30),

              // Live Filters
              Row(
                children: [
                  _buildFilterTab('all', 'Todos'),
                  const SizedBox(width: 15),
                  _buildFilterTab('VIVO', '🔴 En Vivo'),
                  const SizedBox(width: 15),
                  _buildFilterTab('REPETICION', '⭐ Repeticiones'),
                ],
              ),
              const SizedBox(height: 30),

              // Featured Stream
              if (allEvents.isNotEmpty)
                Builder(
                  builder: (context) {
                    final featured = allEvents.firstWhere(
                      (e) => e['id'] == _playingEventId,
                      orElse: () => allEvents.firstWhere((e) {
                        // Lógica de fallback: si tiene más de 12h, ya no lo tratamos como VIVO prioritario
                        if (e['type'] == 'VIVO') {
                          try {
                            final date = DateTime.parse(e['date']);
                            if (DateTime.now().difference(date).inHours > 12)
                              return false;
                          } catch (_) {}
                          return true;
                        }
                        return false;
                      }, orElse: () => allEvents.first),
                    );
                    return _buildFeaturedStream(featured);
                  },
                ),

              const SizedBox(height: 30),

              const Text(
                'EXPLORAR CATEGORÍAS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 15),
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildStreamCategory('COMBATE', Icons.sports_mma),
                      _buildStreamCategory(
                        'ENTRENAMIENTO',
                        Icons.fitness_center,
                      ),
                      _buildStreamCategory(
                        'SPARRING',
                        FontAwesomeIcons.handFist,
                      ),
                      _buildStreamCategory('ENTREVISTA', Icons.mic),
                      _buildStreamCategory('DOCUMENTAL', Icons.video_library),
                      _buildStreamCategory('VIVO', Icons.live_tv),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Text(
                _activeFilter == 'all'
                    ? 'ÚLTIMAS TRANSMISIONES'
                    : (_activeFilter == 'VIVO'
                          ? 'PELEAS EN VIVO'
                          : 'REPETICIONES PREMIUM'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 15),

              if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Text(
                      'El ring está tranquilo por ahora...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                _buildStreamGrid(filtered),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String id, String label) {
    final bool active = _activeFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(Map<String, dynamic> event) {
    final bool isUnderReview = event['isUnderReview'] == true;

    if (isUnderReview) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.shieldHalved,
                color: Colors.orange,
                size: 50,
              ),
              SizedBox(height: 15),
              Text(
                'CONTENIDO BAJO REVISIÓN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: Text(
                  'Este video ha sido reportado por la comunidad y está siendo revisado por moderadores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isPlaying = _playingEventId == event['id'];
    final url = event['videoId'] ?? '';
    final plataforma = clasificarLink(url);

    if (!isPlaying) {
      return GestureDetector(
        onTap: () => setState(() {
          _playingEventId = event['id'];
          _playerNonce++;
        }),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(_getThumbnail(url)),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black, blurRadius: 20),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      );
    }

    switch (plataforma) {
      case TipoPlataforma.youtube:
      case TipoPlataforma.twitch:
        return CustomVideoPlayer(
          key: ValueKey('player_${url}_$_playerNonce'),
          videoUrl: url,
          height: 400,
        );
      case TipoPlataforma.noCompatible:
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 50,
                ),
                SizedBox(height: 15),
                Text(
                  'PLATAFORMA NO COMPATIBLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Container(
          color: Colors.black,
          child: const Center(
            child: Text('Cargando...', style: TextStyle(color: Colors.white)),
          ),
        );
    }
  }

  Widget _buildFeaturedStream(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            ReproductorWrapper(
              eventId: event['id'],
              tuReproductorActual: _buildMediaContent(event),
              vistas: event['views'] ?? 0,
              likes: event['likes'] ?? event['punches'] ?? 0,
              onPunch: () => context.read<AppStore>().punchEvent(event['id']),
              onReport: () => _showReportDialog(context, event),
            ),
            _buildStreamInfoCard(event),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamInfoCard(Map<String, dynamic> event) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.black.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  (event['creatorName'] ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['creatorName'] ?? 'Anon',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          event['country'] ?? '🏳️',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event['city'] ?? 'Localidad no especificada',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        _buildPlatformBadge(event['videoId'] ?? ''),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: AppColors.primary,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event['gym'] ?? 'Gimnasio Independiente',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (event['desc'] != null && event['desc'].toString().isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              event['desc'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Transmitido el ${event['date'] ?? 'Recientemente'}',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (context.read<AppStore>().currentUser?.userId ==
                  event['creatorId'] &&
              event['type'] == 'VIVO') ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Lógica para finalizar vivo -> convertir en repetición
                  context.read<AppStore>().finishLiveStream(event['id']);
                },
                icon: const Icon(Icons.stop_circle, size: 16),
                label: const Text(
                  'FINALIZAR VIVO Y GUARDAR REPETICIÓN',
                  style: TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, Map<String, dynamic> event) {
    String? selectedCategory;
    final reasonController = TextEditingController();
    final List<String> categories = [
      'SPAM / PUBLICIDAD INAPROPIADA',
      'DISCURSO DE ODIO / VIOLENCIA',
      'RACISMO / DISCRIMINACIÓN',
      'CONTENIDO SENSIBLE / SEXUAL',
      'OTRO',
    ];

    showDialog(
      context: context,
      builder: (context) => PointerInterceptor(
        child: StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: const Text(
              'DENUNCIAR CONTENIDO',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Por qué deseas denunciar este video?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  ...categories.map(
                    (cat) => RadioListTile<String>(
                      title: Text(
                        cat,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      value: cat,
                      groupValue: selectedCategory,
                      onChanged: (val) =>
                          setStateDialog(() => selectedCategory = val),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Motivo de la denuncia (opcional):',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ej: El video muestra peleas callejeras...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: selectedCategory == null
                    ? null
                    : () async {
                        final store = context.read<AppStore>();
                        await store.reportLiveEvent(
                          event['id'],
                          selectedCategory!,
                          reasonController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✅ Gracias por cuidar la comunidad. Denuncia recibida.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.1),
                ),
                child: const Text('ENVIAR DENUNCIA'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamCategory(String label, IconData icon) {
    final bool active = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCategory == label) {
            _selectedCategory = 'all';
          } else {
            _selectedCategory = label;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        width: 140,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? Colors.white : AppColors.primary,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamGrid(List<Map<String, dynamic>> events) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        mainAxisExtent: 280,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildStreamCard(events[index]),
    );
  }

  Widget _buildStreamCard(Map<String, dynamic> event) {
    final bool isPlaying = _playingEventId == event['id'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _playingEventId = event['id'];
                        _playerNonce++;
                      });
                      PrimaryScrollController.of(context).animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            _getThumbnail(event['videoId'] ?? ''),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // views
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatLargeNumber(event['views']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Platform icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildPlatformBadge(event['videoId'] ?? ''),
                  ),
                  // Punches (Likes)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🥊', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            _formatLargeNumber(event['punches']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              event['title'] ?? 'Evento',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLargeNumber(dynamic n) {
    if (n == null) return '0';
    int val = n is int ? n : int.tryParse(n.toString()) ?? 0;
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}k';
    return val.toString();
  }

  String _getThumbnail(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final id = YoutubePlayerController.convertUrlToId(url);
      if (id != null) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    return 'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?auto=format&fit=crop&q=80';
  }

  void _showCreateStreamDialog(BuildContext context) {
    final titleController = TextEditingController();
    final linkController = TextEditingController();
    final descController = TextEditingController();
    final cityController = TextEditingController();
    final gymController = TextEditingController();
    String type = 'VIVO';
    String category = 'COMBATE';
    String selectedCountry = 'Argentina 🇦🇷';
    final List<String> countries = [
      'Argentina 🇦🇷',
      'México 🇲🇽',
      'USA 🇺🇸',
      'España 🇪🇸',
      'Cuba 🇨🇺',
      'Puerto Rico 🇵🇷',
      'Senegal 🇸🇳',
      'UK 🇬🇧',
      'Japón 🇯🇵',
      'Colombia 🇨🇴',
      'Chile 🇨🇱',
    ];
    final List<String> categories = [
      'COMBATE',
      'ENTRENAMIENTO',
      'SPARRING',
      'ENTREVISTA',
      'DOCUMENTAL',
      'VIVO',
    ];

    showDialog(
      context: context,
      builder: (context) => PointerInterceptor(
        child: StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: const Text(
              'TRANSMITIR EVENTO',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(
                    'Título del Evento',
                    'Ej: Sparring Nahuel Vera',
                    titleController,
                  ),
                  _buildField(
                    'Link de YouTube / Twitch',
                    'Pega el enlace aquí...',
                    linkController,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bandera/País',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCountry,
                                  dropdownColor: AppColors.bgCard,
                                  isExpanded: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  items: countries.map((String c) {
                                    return DropdownMenuItem<String>(
                                      value: c,
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? val) {
                                    if (val != null)
                                      setStateDialog(
                                        () => selectedCountry = val,
                                      );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _buildField(
                          'Localidad',
                          'Ej: Lanús',
                          cityController,
                        ),
                      ),
                    ],
                  ),
                  _buildField(
                    'Gimnasio',
                    'Nombre del gimnasio...',
                    gymController,
                  ),
                  _buildField(
                    'Descripción',
                    'Detalles premium...',
                    descController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildTypeOption(
                        'VIVO',
                        '🔴 En Vivo',
                        type,
                        (val) => setStateDialog(() => type = val),
                      ),
                      const SizedBox(width: 10),
                      _buildTypeOption(
                        'REPETICION',
                        '⭐ Repetición',
                        type,
                        (val) => setStateDialog(() => type = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Categoría',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: category,
                        dropdownColor: AppColors.bgCard,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        isExpanded: true,
                        items: categories.map((String c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (String? newVal) {
                          if (newVal != null)
                            setStateDialog(() => category = newVal);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  final String title = titleController.text.trim();
                  if (title.isEmpty) return;

                  final String link = linkController.text.trim();
                  if (link.isEmpty) return;

                  // Cerramos el primer modal antes de abrir el de responsabilidad
                  Navigator.pop(context);

                  // Abrimos el modal de compromiso legal/comunitario
                  _showResponsibilityDialog(context, {
                    'type': type,
                    'category': category == 'COMBATES'
                        ? _autoCategorize(title)
                        : category,
                    'title': title,
                    'desc': descController.text,
                    'videoId': link,
                    'country': selectedCountry,
                    'city': cityController.text,
                    'gym': gymController.text,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('CONTINUAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResponsibilityDialog(
    BuildContext context,
    Map<String, dynamic> streamData,
  ) {
    bool hasAgreedAll = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PointerInterceptor(
        child: StatefulBuilder(
          builder: (context, setStateRes) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: const Row(
              children: [
                Icon(FontAwesomeIcons.shieldHalved, color: Colors.orange),
                SizedBox(width: 10),
                Text(
                  'COMPROMISO DE SEGURIDAD',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Para mantener el Arena seguro, por favor confirma lo siguiente:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: hasAgreedAll,
                  onChanged: (val) =>
                      setStateRes(() => hasAgreedAll = val ?? false),
                  title: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '• Confirmo que este contenido cumple con las normas de la comunidad (no spam, no odio, no contenido sensible).\n\n',
                        ),
                        TextSpan(
                          text:
                              '• Acepto que soy responsable de compartir este enlace y que el contenido es de libre acceso en su plataforma original.',
                        ),
                      ],
                    ),
                  ),
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: (hasAgreedAll)
                    ? () {
                        final store = context.read<AppStore>();
                        store.addLiveEvent({
                          ...streamData,
                          'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
                          'views': 0,
                          'punches': 0,
                          'creatorId': store.currentUser?.userId,
                          'creatorName': store.currentUser?.name ?? 'Anon',
                          'date': DateTime.now().toIso8601String().split(
                            'T',
                          )[0],
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ ¡Evento publicado en el Arena!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.1),
                ),
                child: const Text('FINALIZAR Y PUBLICAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    String id,
    String label,
    String current,
    Function(String) onSelect,
  ) {
    final active = id == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.black26,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active ? AppColors.primary : Colors.white10,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// --- HELPERS ---

enum TipoPlataforma { youtube, twitch, noCompatible, vacio }

TipoPlataforma clasificarLink(String url) {
  if (url.isEmpty) return TipoPlataforma.vacio;
  final String lowerUrl = url.toLowerCase();
  if (lowerUrl.contains("youtube.com") ||
      lowerUrl.contains("youtu.be") ||
      !lowerUrl.contains(".")) {
    return TipoPlataforma.youtube;
  }
  if (lowerUrl.contains("twitch.tv")) return TipoPlataforma.twitch;
  return TipoPlataforma.noCompatible;
}

String _autoCategorize(String title) {
  final String t = title.toUpperCase();
  if (t.contains('SPARRING')) return 'SPARRING';
  if (t.contains('ENTRENAMIENTO') || t.contains('TRAINING'))
    return 'ENTRENAMIENTO';
  if (t.contains('ENTREVISTA') || t.contains('INTERVIEW')) return 'ENTREVISTA';
  if (t.contains('DOCUMENTAL') || t.contains('DOCU')) return 'DOCUMENTAL';
  if (t.contains('VIVO') || t.contains('LIVE')) return 'VIVO';
  return 'COMBATE'; // Default
}

Widget _buildPlatformBadge(String url) {
  final plataforma = clasificarLink(url);
  IconData icon;
  Color color;
  String label;

  switch (plataforma) {
    case TipoPlataforma.youtube:
      icon = FontAwesomeIcons.youtube;
      color = Colors.red;
      label = 'YOUTUBE';
      break;
    case TipoPlataforma.twitch:
      icon = FontAwesomeIcons.twitch;
      color = Colors.purple;
      label = 'TWITCH';
      break;
    default:
      return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class ReproductorWrapper extends StatefulWidget {
  final String eventId; // Requerido para actualizar vistas/likes
  final Widget tuReproductorActual;
  final String nombreApp;
  final int vistas;
  final int likes;
  final VoidCallback? onReport;
  final VoidCallback? onPunch;

  const ReproductorWrapper({
    super.key,
    required this.eventId,
    required this.tuReproductorActual,
    this.nombreApp = "TIERRA DE CAMPEONES",
    this.vistas = 0,
    this.likes = 0,
    this.onReport,
    this.onPunch,
  });

  @override
  State<ReproductorWrapper> createState() => _ReproductorWrapperState();
}

class _ReproductorWrapperState extends State<ReproductorWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Incrementamos vista automáticamente al entrar/reproducir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().updateLiveViews(widget.eventId, 1);
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(child: widget.tuReproductorActual),
          Positioned(
            top: 15,
            left: 15,
            child: PointerInterceptor(
              child: Text(
                widget.nombreApp,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: PointerInterceptor(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: _animation,
                      child: const Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 8,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'EN VIVO',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 15,
            child: PointerInterceptor(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${widget.vistas}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: widget.onPunch,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          const Text('🥊'),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.likes}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: PointerInterceptor(
              child: IconButton(
                icon: const Icon(Icons.report, color: Colors.white60),
                onPressed: widget.onReport,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseBadge extends StatefulWidget {
  final String label;
  const _PulseBadge({required this.label});
  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        padding: const EdgeInsets.all(4),
        color: Colors.red,
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
