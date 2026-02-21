import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/app_store.dart';
import '../theme/app_theme.dart';

class JobMarketView extends StatefulWidget {
  const JobMarketView({super.key});

  @override
  State<JobMarketView> createState() => _JobMarketViewState();
}

class _JobMarketViewState extends State<JobMarketView> {
  String _activeCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final jobPosts = context.watch<AppStore>().jobPosts;
    final filtered = _activeCategory == 'all'
        ? jobPosts
        : jobPosts.where((j) => j['category'] == _activeCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Section
        _buildHero(context),
        const SizedBox(height: 20),

        // Filters
        _buildFilters(filtered.length),
        const SizedBox(height: 20),

        // Job List
        if (filtered.isEmpty) _buildEmptyState() else _buildJobGrid(filtered),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('🥊', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          const Text(
            'No hay anuncios en esta categoría',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 10),
          const Text(
            '¡Sé el primero en publicar!',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _showPostJobDialog(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('PUBLICAR ANUNCIO'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💼 SE BUSCA',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 24,
                  color: AppColors.primary,
                ),
              ),
              ElevatedButton(
                onPressed: () => _showPostJobDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('PUBLICAR ANUNCIO'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Encuentra sparring, rivales, profesionales o patrocinadores',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill('Todos', 'all'),
                _buildCategoryPill('🥊 Sparring', 'sparring'),
                _buildCategoryPill('🔥 Rival', 'rival'),
                _buildCategoryPill('👔 Rincón', 'corner'),
                _buildCategoryPill('💰 Sponsoreo', 'sponsor'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, String categoryId) {
    final bool active = _activeCategory == categoryId;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = categoryId),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(int count) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'Más Recientes',
                dropdownColor: AppColors.bgCard,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: ['Más Recientes', 'Más Antiguos']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Text(
          '$count Anuncios',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildJobGrid(List<Map<String, dynamic>> jobs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildJobCard(context, jobs[index]);
      },
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    final catConfig = {
      'sparring': {'label': '🥊 SPARRING', 'color': Colors.blueAccent},
      'rival': {'label': '🔥 RIVAL', 'color': Colors.redAccent},
      'corner': {'label': '👔 RINCÓN', 'color': Colors.greenAccent},
      'sponsor': {'label': '💰 SPONSOREO', 'color': Colors.amberAccent},
    };

    final config =
        catConfig[job['category']] ??
        {
          'label': job['category'].toString().toUpperCase(),
          'color': Colors.grey,
        };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (config['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  config['label'] as String,
                  style: TextStyle(
                    color: config['color'] as Color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (job['postedByName'] ==
                  context.read<AppStore>().currentUser?.name)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => _confirmDeleteJob(context, job['id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 10),
              const Text(
                'ACTIVO',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job['title'] ?? 'Sin título',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job['description'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.textMuted,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                job['location'] ?? 'Global',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 15),
              const Icon(
                Icons.access_time,
                color: AppColors.textMuted,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Reciente', // Could calculate time ago
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(job['postedByAvatar'] ?? ''),
                backgroundColor: Colors.white10,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job['postedByName'] ?? 'Usuario',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<AppStore>().startChatWithUser(
                    job['postedByName'] ?? 'Usuario',
                    job['postedByAvatar'] ?? '',
                    initialMessage:
                        '¡Hola! Vi tu anuncio: ${job['title']} y me gustaría contactarte. (Desde Bolsa de Trabajo)',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '✅ Solicitud enviada. Redirigiendo al chat...',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: const BorderSide(color: AppColors.primary, width: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('CONTACTAR', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostJobDialog(BuildContext context) {
    final titleController = TextEditingController();
    final locController = TextEditingController();
    final descController = TextEditingController();
    String category = 'sparring';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text(
            'PUBLICAR ANUNCIO',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(
                  'Título',
                  'Ej: Busco sparring 75kg',
                  titleController,
                ),
                _buildField('Ubicación', 'Ciudad, País', locController),
                _buildField(
                  'Descripción',
                  'Detalles del anuncio...',
                  descController,
                  maxLines: 4,
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Categoría',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      dropdownColor: AppColors.bgCard,
                      items: const [
                        DropdownMenuItem(
                          value: 'sparring',
                          child: Text(
                            '🥊 Sparring',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'rival',
                          child: Text(
                            '🔥 Rival',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'corner',
                          child: Text(
                            '👔 Rincón',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'sponsor',
                          child: Text(
                            '💰 Sponsoreo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (val) => setStateDialog(() => category = val!),
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
                final user = context.read<AppStore>().currentUser;
                final newPost = {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'category': category,
                  'title': titleController.text,
                  'location': locController.text,
                  'description': descController.text,
                  'postedByName': user?.name ?? 'Anónimo',
                  'postedByAvatar': user?.avatar ?? '',
                  'createdAt': DateTime.now().millisecondsSinceEpoch,
                };
                context.read<AppStore>().addJobPost(newPost);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Anuncio publicado exitosamente'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('PUBLICAR'),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteJob(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Eliminar Anuncio',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres borrar este anuncio?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStore>().deleteJobPost(jobId);
              Navigator.pop(context);
            },
            child: const Text(
              'BORRAR',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
