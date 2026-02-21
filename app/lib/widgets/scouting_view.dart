import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/app_store.dart';
import 'athlete_profile_view.dart';

class ScoutingView extends StatefulWidget {
  const ScoutingView({super.key});

  @override
  State<ScoutingView> createState() => _ScoutingViewState();
}

class _ScoutingViewState extends State<ScoutingView> {
  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'all';
  String _divisionFilter = 'all';
  String _stanceFilter = 'all';
  // Filtros Geográficos
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedUser;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    _searchController.text = store.searchQuery;
    _fetchResults();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.watch<AppStore>();
    if (store.searchQuery != _searchController.text) {
      _searchController.text = store.searchQuery;
      _fetchResults();
    }
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    final results = await context.read<AppStore>().getScoutingUsers(
      query: _searchController.text,
      role: _roleFilter,
      division: _divisionFilter,
      stance: _stanceFilter,
      country: _countryController.text,
      city: _cityController.text,
    );
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedUser != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _selectedUser = null),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            label: const Text(
              'VOLVER AL BUSCADOR',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          AthleteProfileView(userData: _selectedUser!),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const Text(
          '🔍 SCOUTING GLOBAL',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Encuentra talentos, rivales y profesionales para tu equipo.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 30),

        // Search Bar
        _buildSearchArea(),
        const SizedBox(height: 20),

        // Filters
        _buildFilters(),
        const SizedBox(height: 30),

        // Results
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        else if (_results.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No se encontraron resultados.\nIntenta con otros filtros.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          _buildResultsGrid(),
      ],
    );
  }

  Widget _buildSearchArea() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) => _fetchResults(),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, apodo o ciudad...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgCard,
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        ElevatedButton(
          onPressed: _fetchResults,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'BUSCAR',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        _buildPopupMenuFilter(
          label: _roleFilter == 'all' ? 'Todos los Roles' : _roleFilter,
          options: [
            'all',
            'Boxeador Profesional',
            'Boxeadora Profesional',
            'Boxeador Amateur',
            'Boxeadora Amateur',
            'Cadete Masculino',
            'Cadete Femenino',
            'Entrenador',
            'Preparador Físico',
            'Cutman',
            'Nutricionista',
            'Psicólogo',
            'Promotor',
            'Periodista',
            'Juez',
            'Árbitro',
            'Médico Deportivo',
            'Gimnasio',
          ],
          onSelected: (val) {
            setState(() => _roleFilter = val);
            _fetchResults();
          },
        ),
        if (_isCombatRole(_roleFilter)) ...[
          _buildPopupMenuFilter(
            label: _divisionFilter == 'all'
                ? 'Todas las Divisiones'
                : _divisionFilter,
            options: [
              'all',
              'Pesado',
              'Crucero',
              'Mediopesado',
              'Supermediano',
              'Mediano',
              'Welter',
              'Ligero',
              'Pluma',
              'Mosca',
            ],
            onSelected: (val) {
              setState(() => _divisionFilter = val);
              _fetchResults();
            },
          ),
          _buildPopupMenuFilter(
            label: _stanceFilter == 'all' ? 'Cualquier Guardia' : _stanceFilter,
            options: ['all', 'Ortodoxo', 'Zurdo'],
            onSelected: (val) {
              setState(() => _stanceFilter = val);
              _fetchResults();
            },
          ),
          // Filtros Geográficos Compactos
          SizedBox(
            width: 140,
            height: 40,
            child: _buildCompactFilterInput(
              _countryController,
              'País',
              Icons.flag,
            ),
          ),
          SizedBox(
            width: 140,
            height: 40,
            child: _buildCompactFilterInput(
              _cityController,
              'Ciudad/Zona',
              Icons.location_on,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPopupMenuFilter({
    required String label,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: AppColors.bgCard,
      offset: const Offset(0, 45),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label == 'all' ? 'TODOS' : label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => options
          .map(
            (opt) => PopupMenuItem<String>(
              value: opt,
              child: Text(
                opt == 'all' ? 'TODOS' : opt,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        mainAxisExtent: 320,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_results[index]);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final bool isBoxer = user['role']?.toString().contains('Boxeador') ?? false;
    final String avatar = user['avatar'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Avatar Area
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                    ),
                  ),
                  child: avatar.startsWith('http')
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(avatar, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            isBoxer
                                ? '🥊'
                                : (user['id']?.toString().startsWith('b') ??
                                          false
                                      ? '👤'
                                      : '🏁'),
                            style: const TextStyle(fontSize: 60),
                          ),
                        ),
                ),
                if (user['isReal'] == true)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VERIFICADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // User Info Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  user['name'] ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user['role'] ?? 'Fanático',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isBoxer
                      ? (user['stats'] ?? 'S/D')
                      : (user['location'] ?? 'Global'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedUser = user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'PERFIL',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AppStore>().startChatWithUser(
                            user['name'] ?? 'Usuario',
                            user['avatar'] ?? '',
                          );
                          // Navegar a la pestaña de chat (índice 3 en MainNavigation)
                          context.read<AppStore>().setNavIndex(3);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'CONTACTAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterInput(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      onSubmitted: (_) => _fetchResults(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 14),
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }

  bool _isCombatRole(String role) {
    final lower = role.toLowerCase();
    return lower.contains('boxead') || lower.contains('cadete');
  }
}
