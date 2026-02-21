import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../widgets/athlete_profile_view.dart';

class AppStore extends ChangeNotifier {
  static final AppStore _instance = AppStore._internal();
  factory AppStore() => _instance;
  AppStore._internal();

  UserProfile? _currentUser;

  final List<Map<String, dynamic>> _posts = [
    {
      'id': 'p1',
      'userName': 'Neri Muñoz',
      'userRole': 'Boxeador Profesional',
      'roleKey': 'pro-boxer',
      'content':
          'Dándolo todo en el entrenamiento de hoy. ¡Pronto nuevas noticias sobre mi próxima pelea! 🥊🔥',
      'likes': 12,
      'likedBy': <String>[],
      'comments': [
        {'user': 'Alex Gotti', 'text': '¡Dale campeón! 🥊'},
      ],
      'timestamp': 'Hace 2 horas',
    },
    {
      'id': 'p2',
      'userName': 'Gimnasio KO Club',
      'userRole': 'Dueño de Gimnasio',
      'roleKey': 'gym-owner',
      'content':
          'Nuevas bolsas de entrenamiento instaladas. ¡Vengan a probarlas!',
      'likes': 5,
      'likedBy': <String>[],
      'comments': <Map<String, dynamic>>[],
      'timestamp': 'Hace 5 horas',
    },
  ];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  List<Map<String, dynamic>> get posts => _posts;

  bool isFollowing(String userId) {
    if (_currentUser == null) return false;
    // Buscamos en la caché local (extraData o listado dedicado)
    final List following = _currentUser!.extraData['following'] ?? [];
    return following.contains(userId);
  }

  bool isBlocked(String userId) {
    if (_currentUser == null) return false;
    final List blocked = _currentUser!.extraData['blocked'] ?? [];
    return blocked.contains(userId);
  }

  Future<void> followUser(String userId) async {
    if (_currentUser == null || _currentUser!.userId == userId) return;

    // 1. Local de inmediato
    final List following = List.from(
      _currentUser!.extraData['following'] ?? [],
    );
    if (!following.contains(userId)) {
      following.add(userId);
      _currentUser!.extraData['following'] = following;
      notifyListeners();

      // 2. SUPABASE SYNC
      final bool isDevUser = _currentUser!.userId.startsWith('dev_');
      if (!isDevUser) {
        try {
          await Supabase.instance.client.from('follows').insert({
            'follower_id': _currentUser!.userId,
            'following_id': userId,
          });
          debugPrint('Follow sincronizado en tabla follows');
        } catch (e) {
          debugPrint('followUser Supabase Error: $e');
        }
      }
      await _saveUserToPrefs(_currentUser!);
    }
  }

  Future<void> unfollowUser(String userId) async {
    if (_currentUser == null) return;

    // 1. Local de inmediato
    final List following = List.from(
      _currentUser!.extraData['following'] ?? [],
    );
    if (following.contains(userId)) {
      following.remove(userId);
      _currentUser!.extraData['following'] = following;
      notifyListeners();

      // 2. SUPABASE SYNC
      final bool isDevUser = _currentUser!.userId.startsWith('dev_');
      if (!isDevUser) {
        try {
          await Supabase.instance.client.from('follows').delete().match({
            'follower_id': _currentUser!.userId,
            'following_id': userId,
          });
          debugPrint('Unfollow sincronizado en tabla follows');
        } catch (e) {
          debugPrint('unfollowUser Supabase Error: $e');
        }
      }
      await _saveUserToPrefs(_currentUser!);
    }
  }

  void blockUser(String userId) async {
    if (_currentUser == null || _currentUser!.userId == userId) return;

    final List blocked = List.from(_currentUser!.extraData['blocked'] ?? []);
    if (!blocked.contains(userId)) {
      blocked.add(userId);
      _currentUser!.extraData['blocked'] = blocked;

      // También dejar de seguir si se bloquea
      unfollowUser(userId);

      await _saveUserToPrefs(_currentUser!);

      // SUPABASE SYNC (Regla Titanio: bloqueo local ya ejecutado)
      final bool isDevUser = _currentUser!.userId.startsWith('dev_');
      if (!isDevUser) {
        try {
          await Supabase.instance.client
              .from('profiles')
              .update({'extra_data': _currentUser!.extraData})
              .eq('id', _currentUser!.userId);
          debugPrint('Block sincronizado con Supabase');
        } catch (e) {
          debugPrint(
            'blockUser: Error en Supabase, datos guardados localmente. $e',
          );
        }
      }

      notifyListeners();
    }
  }

  void unblockUser(String userId) async {
    if (_currentUser == null) return;

    final List blocked = List.from(_currentUser!.extraData['blocked'] ?? []);
    if (blocked.contains(userId)) {
      blocked.remove(userId);
      _currentUser!.extraData['blocked'] = blocked;
      await _saveUserToPrefs(_currentUser!);

      // SUPABASE SYNC (Regla Titanio: desbloqueo local ya ejecutado)
      final bool isDevUser = _currentUser!.userId.startsWith('dev_');
      if (!isDevUser) {
        try {
          await Supabase.instance.client
              .from('profiles')
              .update({'extra_data': _currentUser!.extraData})
              .eq('id', _currentUser!.userId);
          debugPrint('Unblock sincronizado con Supabase');
        } catch (e) {
          debugPrint(
            'unblockUser: Error en Supabase, datos guardados localmente. $e',
          );
        }
      }

      notifyListeners();
    }
  }

  Future<void> _saveUserToPrefs(UserProfile user) async {
    Map<String, dynamic> json = user.toJson();

    // Saneamiento Agresivo (Titanium Shield):
    // Barremos el objeto y eliminamos cualquier cosa que ocupe demasiado espacio
    // para que la app NUNCA crashee por cuota de almacenamiento.
    json = _stripLargeData(json);

    await _safeSave(user.userId, jsonEncode(json));
    await _safeSave('active_session', user.userId);
  }

  /// Recorre un mapa y elimina valores de texto extremadamente largos (ej. base64 corruptos)
  Map<String, dynamic> _stripLargeData(Map<String, dynamic> data) {
    final Map<String, dynamic> clean = {};
    data.forEach((key, value) {
      if (value is String) {
        // Si un solo campo de texto pesa más de 50KB, es sospechoso de ser un base64
        // que no debería estar ahí o que saturará el localStorage.
        if (value.length > 50000) {
          debugPrint(
            '✂️ Recortando campo pesado: $key (${value.length} chars)',
          );
          clean[key] = ''; // Lo vaciamos para salvar la sesión
        } else {
          clean[key] = value;
        }
      } else if (value is Map<String, dynamic>) {
        clean[key] = _stripLargeData(value);
      } else if (value is List) {
        // Para listas, procesamos cada elemento si es un mapa
        clean[key] = value.map((item) {
          if (item is Map<String, dynamic>) return _stripLargeData(item);
          return item;
        }).toList();
      } else {
        clean[key] = value;
      }
    });
    return clean;
  }

  /// Helper para guardar en SharedPreferences sin crashear si el disco está lleno (Web Quota)
  Future<void> _safeSave(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('❌ Error de almacenamiento (QuotaExceeded?): $e');
      if (kIsWeb && e.toString().contains('QuotaExceededError')) {
        // Si falló por cuota, intentamos limpiar caches viejos y reintentar una vez
        try {
          final prefs = await SharedPreferences.getInstance();
          // Opcional: limpiar solo lo no esencial
          await prefs.remove('cached_posts');
          await prefs.remove('cached_events');
          await prefs.setString(key, value);
          debugPrint('✅ Recuperación de cuota exitosa tras limpieza parcial');
        } catch (retryError) {
          debugPrint('🛑 Fallo definitivo de persistencia local: $retryError');
        }
      }
    }
  }

  UserProfile? get currentUser => _currentUser;

  // Mock data for initial app state
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'b1',
      'name': 'Tyson "Iron" Fury',
      'role': 'Boxeador Profesional',
      'roleKey': 'boxer_pro',
      'avatar':
          'https://ui-avatars.com/api/?name=Tyson+Fury&background=0D8ABC&color=fff',
      'location': 'Manchester, UK',
      'stats': '33-0-1',
      'division': 'Pesado',
      'stance': 'Ortodoxo',
    },
    {
      'id': 'b2',
      'name': 'Canelo Álvarez',
      'role': 'Boxeador Profesional',
      'roleKey': 'boxer_pro',
      'avatar':
          'https://ui-avatars.com/api/?name=Canelo&background=d32f2f&color=fff',
      'location': 'Guadalajara, MX',
      'stats': '59-2-2',
      'division': 'Supermediano',
      'stance': 'Ortodoxo',
    },
    {
      'id': 'e1',
      'name': 'Eddy Reynoso',
      'role': 'Entrenador',
      'roleKey': 'coach',
      'avatar':
          'https://ui-avatars.com/api/?name=Eddy+R&background=000&color=fff',
      'location': 'Guadalajara, MX',
      'specialty': 'Técnica y Estrategia',
    },
    {
      'id': 'n1',
      'name': 'Dra. Fit Nutrition',
      'role': 'Nutricionista',
      'roleKey': 'nutritionist',
      'avatar':
          'https://ui-avatars.com/api/?name=Nutri&background=emerald&color=fff',
      'location': 'Buenos Aires, AR',
      'specialty': 'Corte de peso profesional',
    },
    {
      'id': 'g1',
      'name': 'Wild Card Boxing Club',
      'role': 'Gimnasio',
      'roleKey': 'gym',
      'avatar':
          'https://ui-avatars.com/api/?name=Wild+Card&background=333&color=fff',
      'location': 'Los Angeles, USA',
      'address': 'Vine St, Hollywood',
    },
    {
      'id': 'p1_prom',
      'name': 'Matchroom Boxing',
      'role': 'Promotor',
      'roleKey': 'promoter',
      'avatar':
          'https://ui-avatars.com/api/?name=Matchroom&background=red&color=fff',
      'location': 'Essex, UK',
    },
  ];

  List<Map<String, dynamic>> get mockUsers => _mockUsers;

  Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    // 1. Usuario actual (más rápido, sin red)
    if (_currentUser?.userId == userId) return _currentUser?.toJson();

    // 2. Caché local (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString(userId);
    if (userDataStr != null) {
      return jsonDecode(userDataStr);
    }

    // 3. SUPABASE (Regla Titanio: si falla, seguimos con mocks)
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('id, name, email, role_key, avatar_url, extra_data')
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        final Map<String, dynamic> extra =
            (data['extra_data'] as Map<String, dynamic>?) ?? {};

        // Normalizamos al formato estándar de la app
        final Map<String, dynamic> normalized = {
          'userId': data['id'],
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'role': extra['role'] ?? data['role_key'] ?? '',
          'roleKey': data['role_key'] ?? '',
          'avatar': data['avatar_url'] ?? extra['avatar'] ?? '',
          'extraData': extra,
          'createdAt': '',
        };

        // Guardar en caché local para no volver a consultar Supabase
        await prefs.setString(userId, jsonEncode(normalized));
        return normalized;
      }
    } catch (e) {
      debugPrint('getUserProfileById: Error en Supabase para $userId. $e');
    }

    // 4. Fallback: mocks (demo)
    final mock = _mockUsers.firstWhere(
      (m) => m['id'] == userId,
      orElse: () => {},
    );
    if (mock.isNotEmpty) return mock;

    return null;
  }

  Future<List<Map<String, dynamic>>> getScoutingUsers({
    String query = '',
    String role = 'all',
    String division = 'all',
    String stance = 'all',
    String country = '',
    String city = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Base: mocks siempre disponibles como fallback
    List<Map<String, dynamic>> allUsers = List.from(_mockUsers);

    // 1. CAPA SUPABASE (Regla Titanio: si falla, no rompe nada)
    try {
      final List<dynamic> supabaseProfiles = await Supabase.instance.client
          .from('profiles')
          .select('id, name, email, role_key, avatar_url, extra_data')
          .limit(100);

      final String? currentId = _currentUser?.userId;

      for (final p in supabaseProfiles) {
        // No incluir al usuario actual en la lista de Scouting
        if (p['id'] == currentId) continue;

        final Map<String, dynamic> extra =
            (p['extra_data'] as Map<String, dynamic>?) ?? {};

        allUsers.add({
          'id': p['id'],
          'name': p['name'] ?? 'Usuario',
          'role': extra['role'] ?? p['role_key'] ?? '',
          'roleKey': p['role_key'] ?? '',
          'avatar': p['avatar_url'] ?? extra['avatar'] ?? '',
          'location':
              extra['nationality'] ?? extra['representation'] ?? 'Global',
          'city': extra['currentLocation'] ?? '',
          'stats': extra['record'] ?? extra['fights'] ?? 'S/D',
          'division': extra['weightClass'] ?? '',
          'stance': extra['stance'] ?? '',
          'gym': extra['gym'] ?? '',
          'isReal': true,
          'isVerified': false, // Desactivado hasta que exista la columna en DB
          'isSupabase': true, // Marcador para identificar usuarios reales
        });
      }
      debugPrint(
        'Scouting: ${supabaseProfiles.length} perfiles cargados desde Supabase',
      );
    } catch (e) {
      debugPrint(
        'Scouting: Error al cargar desde Supabase, usando datos locales. $e',
      );
    }

    // 2. CAPA LOCAL (usuarios registrados en este dispositivo)
    final usersListJson = prefs.getString('users_list');
    if (usersListJson != null) {
      final List<dynamic> realUsersList = jsonDecode(usersListJson);
      for (var u in realUsersList) {
        final String userId = u['userId'];
        // Evitar duplicados con Supabase
        if (allUsers.any((existing) => existing['id'] == userId)) continue;
        final userDataStr = prefs.getString(userId);
        if (userDataStr != null) {
          final Map<String, dynamic> userData = jsonDecode(userDataStr);
          allUsers.add({
            'id': userId,
            'name': userData['name'] ?? 'Usuario',
            'role': userData['role'] ?? 'Fanático',
            'roleKey': userData['roleKey'] ?? '',
            'avatar': userData['avatar'],
            'location':
                userData['extraData']?['nationality'] ??
                userData['extraData']?['representation'] ??
                'Global',
            'city': userData['extraData']?['currentLocation'] ?? '',
            'stats':
                userData['extraData']?['record'] ??
                userData['extraData']?['fights'] ??
                'S/D',
            'division': userData['extraData']?['weightClass'] ?? '',
            'stance': userData['extraData']?['stance'] ?? '',
            'isReal': true,
            'gym': userData['extraData']?['gym'] ?? '',
          });
        }
      }
    }

    // 2. Filtrado Exhaustivo
    return allUsers.where((u) {
      final String uName = (u['name'] ?? '').toString().toLowerCase();
      final String uRole = (u['role'] ?? '').toString().toLowerCase();
      final String uLocation = (u['location'] ?? '').toString().toLowerCase();
      final String uCity = (u['city'] ?? '').toString().toLowerCase();
      final String uGym = (u['gym'] ?? '').toString().toLowerCase();

      final String q = query.toLowerCase().trim();

      // Filtro de Texto General (Búsqueda Inteligente)
      if (q.isNotEmpty) {
        final bool matchesQuery =
            uName.contains(q) ||
            uRole.contains(q) ||
            uLocation.contains(q) ||
            uCity.contains(q) ||
            uGym.contains(q);
        if (!matchesQuery) return false;
      }

      // EXCLUSIÓN AUTOMÁTICA DE AFICIONADOS Y RECREATIVOS (Regla del Usuario)
      final String roleKey = u['roleKey']?.toString().toLowerCase() ?? '';
      if (roleKey == 'fan' || roleKey == 'recreational') {
        return false;
      }

      // Filtro de Rol
      if (role != 'all') {
        final String targetRole = role.toLowerCase();
        // Lógica permisiva: si busco "Boxeador", incluye "Boxeador Amateur", "Profesional", etc.
        // Pero si busco "Boxeadora", excluye "Boxeador" (distinción de género simple)
        if (targetRole == 'boxeadora') {
          if (!uRole.contains('boxeadora')) return false;
        } else if (targetRole == 'boxeador') {
          if (!uRole.contains('boxeador') || uRole.contains('boxeadora'))
            return false;
        } else {
          if (!uRole.contains(targetRole)) return false;
        }
      }

      // Filtros Específicos de Combate (Boxeadores/Cadetes)
      final bool isCombat = uRole.contains('box') || uRole.contains('cadete');

      if (isCombat) {
        if (division != 'all') {
          final String uDiv = (u['division'] ?? '').toString().toLowerCase();
          if (!uDiv.contains(division.toLowerCase())) return false;
        }
        if (stance != 'all') {
          final String uStance = (u['stance'] ?? '').toString().toLowerCase();
          if (uStance != stance.toLowerCase()) return false;
        }
      }

      // Filtros Geográficos (Permisivos)
      if (country.isNotEmpty) {
        if (!uLocation.contains(country.toLowerCase())) return false;
      }
      if (city.isNotEmpty) {
        // Busca en ciudad o en ubicación general
        if (!uCity.contains(city.toLowerCase()) &&
            !uLocation.contains(city.toLowerCase()))
          return false;
      }

      return true;
    }).toList();
  }

  final List<Map<String, dynamic>> _products = [
    {
      'id': 'p1',
      'title': 'Guantes Everlast 14oz',
      'price': 45.0,
      'cat': 'equipment',
      'desc': 'Prácticamente nuevos, solo 2 usos.',
      'img': 'https://images.unsplash.com/photo-1552072805-2a9039d00e57?w=400',
      'seller': 'Neri Muñoz',
      'sellerPic':
          'https://ui-avatars.com/api/?name=Neri+Munoz&background=random',
      'date': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
    },
    {
      'id': 'p2',
      'title': 'Vendas Adidas (Par)',
      'price': 12.5,
      'cat': 'equipment',
      'desc': 'Vendas rojas 4.5m.',
      'img': 'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?w=400',
      'seller': 'Coach Rick',
      'sellerPic':
          'https://ui-avatars.com/api/?name=Coach+Rick&background=random',
      'date': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(),
    },
    {
      'id': 'p3',
      'title': 'Entrada: Fury vs Usyk',
      'price': 150.0,
      'cat': 'tickets',
      'desc': 'Sector B, fila 4.',
      'img':
          'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=400',
      'seller': 'Gym KO Club',
      'sellerPic': 'https://ui-avatars.com/api/?name=Gym+KO&background=random',
      'date': DateTime.now()
          .subtract(const Duration(hours: 12))
          .toIso8601String(),
    },
  ];

  List<Map<String, dynamic>> get products => _products;

  Future<void> addProduct(Map<String, dynamic> product) async {
    // 1. Insertar localmente de inmediato (UI responsiva)
    _products.insert(0, product);
    notifyListeners();

    // 2. SUPABASE SYNC (Regla Titanio: si falla, el producto local ya existe)
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isDevUser) {
      try {
        final inserted = await Supabase.instance.client
            .from('products')
            .insert({
              'seller_id': _currentUser!.userId,
              'title': product['title'],
              'description': product['desc'] ?? product['description'],
              'price': product['price'],
              'category': product['cat'] ?? product['category'],
              'image_url': product['img'],
              'seller_name': product['seller'],
            })
            .select()
            .single();

        // Actualizar el ID local con el ID real de Supabase
        final index = _products.indexWhere((p) => p['id'] == product['id']);
        if (index != -1) {
          _products[index] = {..._products[index], 'id': inserted['id']};
          notifyListeners();
        }
        debugPrint('Producto publicado en Supabase: ${inserted['id']}');
      } catch (e) {
        debugPrint(
          'addProduct: Error en Supabase, producto guardado localmente. $e',
        );
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    // 1. Borrar localmente de inmediato
    _products.removeWhere((p) => p['id'] == id);
    notifyListeners();

    // 2. SUPABASE SYNC: solo si no es un ID local
    final bool isLocalId = id.startsWith('local_') || id.startsWith('p');
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isLocalId && !isDevUser) {
      try {
        await Supabase.instance.client.from('products').delete().eq('id', id);
        debugPrint('Producto eliminado de Supabase: $id');
      } catch (e) {
        debugPrint('deleteProduct: Error en Supabase. $e');
      }
    }
  }

  /// Carga productos reales desde Supabase y los combina con los mocks
  Future<void> _loadProducts() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('*, profiles:seller_id(name, avatar_url)')
          .order('created_at', ascending: false)
          .limit(50);

      final List<Map<String, dynamic>> supabaseProducts = [];
      for (final p in response) {
        final profile = p['profiles'] as Map<String, dynamic>?;
        supabaseProducts.add({
          'id': p['id'],
          'title': p['title'] ?? '',
          'price': (p['price'] ?? 0).toDouble(),
          'cat': p['category'] ?? 'equipment',
          'desc': p['description'] ?? '',
          'img': p['image_url'] ?? '',
          'seller': profile?['name'] ?? p['seller_name'] ?? 'Vendedor',
          'sellerPic': profile?['avatar_url'] ?? '',
          'date': p['created_at'],
          'seller_id': p['seller_id'],
          'isReal': true,
        });
      }

      // Combinar: Supabase primero, luego mocks que no se pisen
      final mockIds = {'p1', 'p2', 'p3'};
      final combined = [
        ...supabaseProducts,
        ..._products.where((p) => mockIds.contains(p['id'])),
      ];
      _products
        ..clear()
        ..addAll(combined);
      notifyListeners();
      debugPrint(
        'Marketplace: ${supabaseProducts.length} productos cargados desde Supabase',
      );
    } catch (e) {
      debugPrint('_loadProducts: Error en Supabase, usando datos locales. $e');
    }
  }

  List<Map<String, dynamic>> _notifications = [
    {
      'id': 'mock_job_1',
      'title': 'Nueva Oferta de Trabajo',
      'body': 'Se busca Cutman para evento en Buenos Aires.',
      'type': 'job',
      'read': false,
      'timestamp': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
    },
    {
      'id': 'mock_stream_1',
      'title': '¡EN VIVO AHORA!',
      'body': 'Sparring session: Canelo vs Benavidez.',
      'type': 'streaming',
      'read': false,
      'timestamp': DateTime.now()
          .subtract(const Duration(minutes: 15))
          .toIso8601String(),
    },
  ];
  List<Map<String, dynamic>> get notifications => _notifications;

  // Seguimiento de últimas visitas para insignias (Badges)
  final Map<String, DateTime> _lastVisits = {};

  int get unreadNotificationsCount =>
      _notifications.where((n) => n['read'] == false).length;

  int get unreadMessagesCount {
    if (_currentUser == null) return 0;
    int unread = 0;
    for (var chat in _chats) {
      final List msgs = chat['msgs'] ?? [];
      if (msgs.isNotEmpty) {
        final lastMsg = msgs.last;
        final bool isFromSelf = lastMsg['self'] ?? false;
        final timestampStr = lastMsg['timestamp'] ?? '';
        if (!isFromSelf && timestampStr.isNotEmpty) {
          final lastMsgTime = DateTime.parse(timestampStr);
          final lastVisit =
              _lastVisits['chat'] ?? DateTime.fromMillisecondsSinceEpoch(0);
          if (lastMsgTime.isAfter(lastVisit)) {
            unread++;
          }
        }
      }
    }
    return unread;
  }

  int get newJobsCount {
    final lastVisit =
        _lastVisits['jobs'] ?? DateTime.fromMillisecondsSinceEpoch(0);
    return _jobPosts.where((j) {
      final createdAt = j['created_at'];
      if (createdAt == null) return false;
      return DateTime.parse(createdAt).isAfter(lastVisit);
    }).length;
  }

  int get newMarketplaceCount {
    final lastVisit =
        _lastVisits['marketplace'] ?? DateTime.fromMillisecondsSinceEpoch(0);
    return _products.where((p) {
      final createdAt = p['created_at'];
      if (createdAt == null) return false;
      return DateTime.parse(createdAt).isAfter(lastVisit);
    }).length;
  }

  int get newEventsCount {
    final lastVisit =
        _lastVisits['events'] ?? DateTime.fromMillisecondsSinceEpoch(0);
    return _events.where((e) {
      final createdAt = e['created_at'];
      if (createdAt == null) return false;
      return DateTime.parse(createdAt).isAfter(lastVisit);
    }).length;
  }

  int get newStreamingCount {
    final lastVisit =
        _lastVisits['streaming'] ?? DateTime.fromMillisecondsSinceEpoch(0);
    return _liveEvents.where((s) {
      final createdAt = s['created_at'];
      if (createdAt == null) return false;
      return DateTime.parse(createdAt).isAfter(lastVisit);
    }).length;
  }

  Future<void> markSectionVisited(String section) async {
    _lastVisits[section] = DateTime.now();
    notifyListeners();
    final now = _lastVisits[section]!.toIso8601String();
    await _safeSave('last_visit_$section', now);
  }

  Future<void> _loadLastVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final sections = ['chat', 'jobs', 'marketplace', 'events', 'streaming'];
    for (var s in sections) {
      final val = prefs.getString('last_visit_$s');
      if (val != null) {
        _lastVisits[s] = DateTime.parse(val);
      }
    }
  }

  void addNotification({
    required String title,
    required String body,
    required String type, // 'like', 'follow', 'post', etc.
    String? relatedId,
  }) async {
    final localId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
    _notifications.insert(0, {
      'id': localId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'read': false,
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();

    // SUPABASE SYNC
    if (_currentUser != null && !_currentUser!.userId.startsWith('dev_')) {
      try {
        await Supabase.instance.client.from('notifications').insert({
          'user_id': _currentUser!.userId,
          'title': title,
          'body': body,
          'type': type,
          'related_id': relatedId,
        });
      } catch (e) {
        debugPrint('addNotification Supabase Error: $e');
      }
    }
  }

  void markNotificationsAsRead() {
    for (var n in _notifications) {
      n['read'] = true;
    }
    notifyListeners();
  }

  final List<Map<String, dynamic>> _jobPosts = [];

  List<Map<String, dynamic>> get jobPosts => _jobPosts;

  Future<void> addJobPost(Map<String, dynamic> post) async {
    // 1. Insertar localmente de inmediato (UI responsiva)
    _jobPosts.insert(0, post);
    notifyListeners();

    // 2. SUPABASE SYNC (Regla Titanio: si falla, la oferta local ya existe)
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isDevUser) {
      try {
        final inserted = await Supabase.instance.client
            .from('job_posts')
            .insert({
              'poster_id': _currentUser!.userId,
              'title': post['title'],
              'description': post['desc'] ?? post['description'],
              'role_required': post['role'] ?? post['roleRequired'],
              'location': post['location'],
              'salary': post['salary'],
              'contract_type': post['contractType'] ?? post['tipo'],
              'poster_name':
                  post['postedByName'] ??
                  post['postedBy'] ??
                  _currentUser!.name,
            })
            .select()
            .single();

        // Actualizar ID local con el ID real de Supabase
        final index = _jobPosts.indexWhere((j) => j['id'] == post['id']);
        if (index != -1) {
          _jobPosts[index] = {..._jobPosts[index], 'id': inserted['id']};
          notifyListeners();
        }
        debugPrint('Oferta publicada en Supabase: ${inserted['id']}');
      } catch (e) {
        debugPrint(
          'addJobPost: Error en Supabase, oferta guardada localmente. $e',
        );
      }
    }
  }

  Future<void> deleteJobPost(String id) async {
    // 1. Borrar localmente de inmediato
    _jobPosts.removeWhere((j) => j['id'] == id);
    notifyListeners();

    // 2. SUPABASE SYNC: solo si no es un ID local o mock
    final bool isLocalId = id.startsWith('local_') || id.startsWith('j');
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isLocalId && !isDevUser) {
      try {
        await Supabase.instance.client.from('job_posts').delete().eq('id', id);
        debugPrint('Oferta eliminada de Supabase: $id');
      } catch (e) {
        debugPrint('deleteJobPost: Error en Supabase. $e');
      }
    }
  }

  /// Carga ofertas de trabajo reales desde Supabase
  Future<void> _loadJobPosts() async {
    try {
      final response = await Supabase.instance.client
          .from('job_posts')
          .select('*, profiles:poster_id(name, avatar_url, role_key)')
          .order('created_at', ascending: false)
          .limit(50);

      final List<Map<String, dynamic>> supabaseJobs = [];
      for (final j in response) {
        final profile = j['profiles'] as Map<String, dynamic>?;
        supabaseJobs.add({
          'id': j['id'],
          'title': j['title'] ?? '',
          'description': j['description'] ?? '',
          'category': j['category'] ?? '',
          'location': j['location'] ?? '',
          'salary': j['salary'] ?? '',
          'tipo': j['contract_type'] ?? '',
          'postedByName': profile?['name'] ?? j['poster_name'] ?? 'Usuario',
          'postedByAvatar': profile?['avatar_url'] ?? '',
          'posterRole': _getRoleNameFromKey(profile?['role_key'] ?? ''),
          'date': j['created_at'],
          'createdAt': DateTime.parse(j['created_at']).millisecondsSinceEpoch,
          'poster_id': j['poster_id'],
          'isReal': true,
        });
      }

      // Combinar: reales de Supabase primero, luego los mocks locales
      final combined = [
        ...supabaseJobs,
        ..._jobPosts.where((j) => !(j['isReal'] == true)),
      ];
      _jobPosts
        ..clear()
        ..addAll(combined);
      notifyListeners();
      debugPrint(
        'Job Board: ${supabaseJobs.length} ofertas cargadas desde Supabase',
      );
    } catch (e) {
      debugPrint('_loadJobPosts: Error en Supabase, usando datos locales. $e');
    }
  }

  final List<Map<String, dynamic>> _chats = [
    {
      'id': 'general',
      'name': '🥊 Comunidad Tierra de Campeones',
      'avatar':
          'https://ui-avatars.com/api/?name=TC&background=e63946&color=fff',
      'status': 'active',
      'msgs': [
        {
          'id': 'm1',
          'user': 'Admin',
          'text': '¡Bienvenidos al chat general!',
          'time': '10:00',
          'self': false,
          'isSystem': true,
        },
        {
          'id': 'm2',
          'user': 'Neri Muñoz',
          'text': '¡Hola a todos! Preparando el próximo campamento.',
          'time': '10:05',
          'self': false,
        },
      ],
    },
    {
      'id': 'c1',
      'name': 'Coach Rick',
      'avatar': 'https://ui-avatars.com/api/?name=Coach+Rick&background=random',
      'status': 'active',
      'msgs': [
        {
          'id': 'm3',
          'user': 'Coach Rick',
          'text': 'Mañana 8:00 AM en el gimnasio.',
          'time': '18:30',
          'self': false,
        },
        {
          'id': 'm4',
          'user': 'Usuario',
          'text': '¡Recibido coach!',
          'time': '18:35',
          'self': true,
        },
      ],
    },
    {
      'id': 'c2',
      'name': 'Lex Gotti',
      'avatar': 'https://ui-avatars.com/api/?name=Lex+Gotti&background=random',
      'status': 'pending',
      'initiator': 'Lex Gotti',
      'msgs': [],
    },
  ];

  String? _activeChatId = 'general';

  List<Map<String, dynamic>> get chats => _chats;
  String? get activeChatId => _activeChatId;

  void setActiveChat(String? id) {
    _activeChatId = id;
    notifyListeners();
  }

  void sendTeamRequest({
    required String toUserId,
    required String toUserName,
    required String toAvatar,
    required String role,
  }) async {
    if (_currentUser == null) return;

    // 1. Iniciamos o buscamos el chat vía Supabase (reusando lógica de startChatWithUser)
    // Buscamos si ya existe el chat entre ambos
    final userId = _currentUser!.userId;
    String? realChatId;

    try {
      var chatRecord = await Supabase.instance.client
          .from('chats')
          .select()
          .or(
            'and(participant_1.eq.$userId,participant_2.eq.$toUserId),and(participant_1.eq.$toUserId,participant_2.eq.$userId)',
          )
          .maybeSingle();

      if (chatRecord == null) {
        // Crear chat
        chatRecord = await Supabase.instance.client
            .from('chats')
            .insert({'participant_1': userId, 'participant_2': toUserId})
            .select()
            .single();
      }
      realChatId = chatRecord['id'];
    } catch (e) {
      debugPrint('sendTeamRequest Supabase Error: $e');
      // Fallback local si falla Supabase
      realChatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    }

    // 2. Aseguramos que esté en la lista local
    if (!_chats.any((c) => c['id'] == realChatId)) {
      _chats.insert(0, {
        'id': realChatId,
        'name': toUserName,
        'avatar': toAvatar,
        'status': 'active',
        'msgs': [],
      });
    }

    // 3. Enviamos el mensaje de solicitud (ya está sincronizado con Supabase en addMessage)
    addMessage(realChatId!, {
      'user': _currentUser!.name,
      'text': '¡Hola! Me gustaría que seas parte de mi equipo como: $role',
      'time':
          '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'self': true,
      'type': 'team_request',
      'requestedRole': role,
      'senderId': _currentUser!.userId,
    });

    // 4. Cambiamos a la pestaña de mensajes
    setNavIndex(3);
    setActiveChat(realChatId);
    notifyListeners();

    // 5. Notificación al destinatario
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': toUserId,
        'title': 'Solicitud de Equipo 🤝',
        'body': '${_currentUser!.name} quiere que seas su $role.',
        'type': 'team_request',
        'related_id': realChatId,
      });
    } catch (e) {
      debugPrint('Error enviando notificación de solicitud: $e');
    }
  }

  void acceptTeamRequest({
    required String chatId,
    required String senderId,
    required String senderName,
    required String requestedRole,
  }) async {
    if (_currentUser == null) return;

    // 1. Vinculación en MI perfil (el que acepta)
    final List myTeam = List.from(
      _currentUser!.extraData['team_members'] ?? [],
    );
    if (!myTeam.any((m) => m['userId'] == senderId)) {
      myTeam.add({'userId': senderId, 'role': 'Miembro del Equipo'});
      final Map<String, dynamic> updates = {'team_members': myTeam};
      await updateUserProfile({'extraData': updates});
    }

    // 2. Vinculación en el perfil del REMITENTE (el que invitó) - SUPABASE SYNC
    if (!_currentUser!.userId.startsWith('dev_')) {
      try {
        final senderResponse = await Supabase.instance.client
            .from('profiles')
            .select('extra_data, role_key')
            .eq('id', senderId)
            .single();

        final Map<String, dynamic> senderExtra = Map<String, dynamic>.from(
          senderResponse['extra_data'] ?? {},
        );
        final String senderRoleKey = senderResponse['role_key'] ?? '';
        final String senderRoleName = _getRoleNameFromKey(senderRoleKey);

        // 2a. Actualizar mi lista local con el rol real del remitente
        final List updatedMyTeam = List.from(
          _currentUser!.extraData['team_members'] ?? [],
        );
        updatedMyTeam.removeWhere((m) => m['userId'] == senderId);
        updatedMyTeam.add({'userId': senderId, 'role': senderRoleName});
        await updateUserProfile({
          'extraData': {'team_members': updatedMyTeam},
        });

        // 2b. Actualizar perfil del remitente
        final List senderTeam = List.from(senderExtra['team_members'] ?? []);
        if (!senderTeam.any((m) => m['userId'] == _currentUser!.userId)) {
          senderTeam.add({
            'userId': _currentUser!.userId,
            'role': requestedRole,
          });
          senderExtra['team_members'] = senderTeam;

          await Supabase.instance.client
              .from('profiles')
              .update({'extra_data': senderExtra})
              .eq('id', senderId);

          // 2c. Tambien me verifico a mi mismo (el que acepta)
          await updateUserProfile({'isVerified': true});

          debugPrint(
            'Perfil del remitente actualizado y verificado en Supabase',
          );
        }
      } catch (e) {
        debugPrint('Error actualizando perfil del remitente: $e');
      }
    }

    // 3. Enviamos el mensaje de "MATCH" (ya sincronizado con Supabase en addMessage)
    addMessage(chatId, {
      'user': _currentUser!.name,
      'text': '¡Orgulloso de ser parte de tu equipo! 🥊',
      'time':
          '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'self': true,
    });

    notifyListeners();
  }

  void leaveTeam(String targetUserId) async {
    if (_currentUser == null) return;

    // 1. Eliminar de MI perfil (Team, Sponsors, Sponsorships)
    final Map<String, dynamic> myExtra = Map<String, dynamic>.from(
      _currentUser!.extraData,
    );
    final List myTeam = List.from(myExtra['team_members'] ?? []);
    final List mySponsors = List.from(myExtra['sponsors'] ?? []);
    final List mySponsorships = List.from(myExtra['sponsorships'] ?? []);

    myTeam.removeWhere((m) => m['userId'] == targetUserId);
    mySponsors.removeWhere((m) => m['userId'] == targetUserId);
    mySponsorships.removeWhere((m) => m['userId'] == targetUserId);

    myExtra['team_members'] = myTeam;
    myExtra['sponsors'] = mySponsors;
    myExtra['sponsorships'] = mySponsorships;

    await updateUserProfile({'extraData': myExtra});

    // 2. Eliminar del perfil del OTRO - SUPABASE SYNC
    if (!_currentUser!.userId.startsWith('dev_')) {
      try {
        final otherResponse = await Supabase.instance.client
            .from('profiles')
            .select('extra_data')
            .eq('id', targetUserId)
            .single();

        final Map<String, dynamic> otherExtra = Map<String, dynamic>.from(
          otherResponse['extra_data'] ?? {},
        );
        final List otherTeam = List.from(otherExtra['team_members'] ?? []);
        final List otherSponsors = List.from(otherExtra['sponsors'] ?? []);
        final List otherSponsorships = List.from(
          otherExtra['sponsorships'] ?? [],
        );

        otherTeam.removeWhere((m) => m['userId'] == _currentUser!.userId);
        otherSponsors.removeWhere((m) => m['userId'] == _currentUser!.userId);
        otherSponsorships.removeWhere(
          (m) => m['userId'] == _currentUser!.userId,
        );

        otherExtra['team_members'] = otherTeam;
        otherExtra['sponsors'] = otherSponsors;
        otherExtra['sponsorships'] = otherSponsorships;

        await Supabase.instance.client
            .from('profiles')
            .update({'extra_data': otherExtra})
            .eq('id', targetUserId);

        debugPrint('Relación eliminada en Supabase para ambos (Unilateral)');
      } catch (e) {
        debugPrint('Error eliminando del perfil del otro en Supabase: $e');
      }
    }
    notifyListeners();
  }

  void sendSponsorRequest({
    required String toUserId,
    required String toUserName,
    required String toAvatar,
  }) async {
    if (_currentUser == null) return;

    // 1. Iniciamos o buscamos el chat vía Supabase
    final userId = _currentUser!.userId;
    String? realChatId;

    try {
      var chatRecord = await Supabase.instance.client
          .from('chats')
          .select()
          .or(
            'and(participant_1.eq.$userId,participant_2.eq.$toUserId),and(participant_1.eq.$toUserId,participant_2.eq.$userId)',
          )
          .maybeSingle();

      if (chatRecord == null) {
        chatRecord = await Supabase.instance.client
            .from('chats')
            .insert({'participant_1': userId, 'participant_2': toUserId})
            .select()
            .single();
      }
      realChatId = chatRecord['id'];
    } catch (e) {
      debugPrint('sendSponsorRequest Supabase Error: $e');
      realChatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    }

    if (!_chats.any((c) => c['id'] == realChatId)) {
      _chats.insert(0, {
        'id': realChatId,
        'name': toUserName,
        'avatar': toAvatar,
        'status': 'active',
        'msgs': [],
      });
    }

    // 2. Lógica de mensaje según el rol
    final bool isBrand =
        _currentUser!.roleKey.contains('promoter') ||
        _currentUser!.roleKey.contains('manager') ||
        _currentUser!.roleKey.contains('gym');

    final String invitationText = isBrand
        ? '¡Hola! Estoy interesado en darte apoyo.'
        : '¡Hola! Me gustaría que seas mi patrocinador oficial.';

    addMessage(realChatId!, {
      'user': _currentUser!.name,
      'text': invitationText,
      'time':
          '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'self': true,
      'type': 'sponsor_request',
      'senderId': _currentUser!.userId,
    });

    setNavIndex(3);
    setActiveChat(realChatId);
    notifyListeners();

    // 3. Notificación al destinatario
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': toUserId,
        'title': 'Propuesta de Patrocinio 🛡️',
        'body': '${_currentUser!.name} te ha enviado una propuesta.',
        'type': 'sponsor_request',
        'related_id': realChatId,
      });
    } catch (e) {
      debugPrint('Error enviando notificación de patrocinio: $e');
    }
  }

  void acceptSponsorRequest({
    required String chatId,
    required String senderId,
    required String senderName,
  }) async {
    if (_currentUser == null) return;

    // 1. Vinculación en MI perfil
    final List mySponsorships = List.from(
      _currentUser!.extraData['sponsorships'] ?? [],
    );
    final List mySponsors = List.from(
      _currentUser!.extraData['sponsors'] ?? [],
    );

    final bool isBrand =
        _currentUser!.roleKey.contains('promoter') ||
        _currentUser!.roleKey.contains('manager') ||
        _currentUser!.roleKey.contains('gym');

    if (isBrand) {
      if (!mySponsorships.any((m) => m['userId'] == senderId)) {
        mySponsorships.add({'userId': senderId});
        await updateUserProfile({
          'extraData': {'sponsorships': mySponsorships},
        });
      }
    } else {
      if (!mySponsors.any((m) => m['userId'] == senderId)) {
        mySponsors.add({'userId': senderId});
        await updateUserProfile({
          'extraData': {'sponsors': mySponsors},
        });
      }
    }

    // 2. Vinculación en el perfil del REMITENTE - SUPABASE SYNC
    if (!_currentUser!.userId.startsWith('dev_')) {
      try {
        final senderResponse = await Supabase.instance.client
            .from('profiles')
            .select('extra_data')
            .eq('id', senderId)
            .single();

        final Map<String, dynamic> senderExtra = Map<String, dynamic>.from(
          senderResponse['extra_data'] ?? {},
        );
        final List senderSponsors = List.from(senderExtra['sponsors'] ?? []);
        final List senderSponsorships = List.from(
          senderExtra['sponsorships'] ?? [],
        );

        if (isBrand) {
          if (!senderSponsors.any((m) => m['userId'] == _currentUser!.userId)) {
            senderSponsors.add({'userId': _currentUser!.userId});
            senderExtra['sponsors'] = senderSponsors;
          }
        } else {
          if (!senderSponsorships.any(
            (m) => m['userId'] == _currentUser!.userId,
          )) {
            senderSponsorships.add({'userId': _currentUser!.userId});
            senderExtra['sponsorships'] = senderSponsorships;
          }
        }

        await Supabase.instance.client
            .from('profiles')
            .update({'extra_data': senderExtra})
            .eq('id', senderId);
        debugPrint('Relación de patrocinio sincronizada en Supabase');
      } catch (e) {
        debugPrint('Error sincronizando patrocinio del remitente: $e');
      }
    }

    // 3. Mensaje de respuesta
    final String responseText = isBrand
        ? '¡Es un honor apoyar tu carrera! 🥊✨'
        : '¡Gracias por confiar en mí! 🙏🥊';

    addMessage(chatId, {
      'user': _currentUser!.name,
      'text': responseText,
      'time':
          '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'self': true,
    });

    notifyListeners();
  }

  void stopSponsoring(String targetIdOrName) async {
    if (_currentUser == null) return;

    // 1. Limpieza en mi perfil
    final List mySponsors = List.from(
      _currentUser!.extraData['sponsors'] ?? [],
    );
    final List mySponsorships = List.from(
      _currentUser!.extraData['sponsorships'] ?? [],
    );

    mySponsors.removeWhere(
      (m) => m['userId'] == targetIdOrName || m['name'] == targetIdOrName,
    );
    mySponsorships.removeWhere(
      (m) => m['userId'] == targetIdOrName || m['name'] == targetIdOrName,
    );

    await updateUserProfile({
      'extraData': {'sponsors': mySponsors, 'sponsorships': mySponsorships},
    });

    // 2. Limpieza en el perfil del otro - SUPABASE SYNC
    if (!_currentUser!.userId.startsWith('dev_') &&
        !targetIdOrName.startsWith('demo')) {
      try {
        final otherResponse = await Supabase.instance.client
            .from('profiles')
            .select('extra_data')
            .eq('id', targetIdOrName)
            .maybeSingle();

        if (otherResponse != null) {
          final Map<String, dynamic> otherExtra = Map<String, dynamic>.from(
            otherResponse['extra_data'] ?? {},
          );
          final List otherSponsors = List.from(otherExtra['sponsors'] ?? []);
          final List otherSponsorships = List.from(
            otherExtra['sponsorships'] ?? [],
          );

          otherSponsors.removeWhere((m) => m['userId'] == _currentUser!.userId);
          otherSponsorships.removeWhere(
            (m) => m['userId'] == _currentUser!.userId,
          );

          otherExtra['sponsors'] = otherSponsors;
          otherExtra['sponsorships'] = otherSponsorships;

          await Supabase.instance.client
              .from('profiles')
              .update({'extra_data': otherExtra})
              .eq('id', targetIdOrName);
          debugPrint('Sponsoring detenido en Supabase para ambos');
        }
      } catch (e) {
        debugPrint('Error deteniendo patrocinio en Supabase: $e');
      }
    }
    notifyListeners();
  }

  void addExternalSponsor(String name, String url) async {
    if (_currentUser == null) return;
    final List sponsors = List.from(_currentUser!.extraData['sponsors'] ?? []);
    sponsors.add({'name': name, 'url': url, 'logo': '🔗'});
    final Map<String, dynamic> updates = {'sponsors': sponsors};
    await updateUserProfile({'extraData': updates});
  }

  void addMessage(String chatId, Map<String, dynamic> msg) async {
    final chatIndex = _chats.indexWhere((c) => c['id'] == chatId);
    if (chatIndex != -1) {
      final msgs = List<Map<String, dynamic>>.from(_chats[chatIndex]['msgs']);
      final localId = DateTime.now().millisecondsSinceEpoch.toString();
      msgs.add({'id': localId, ...msg});
      _chats[chatIndex] = {..._chats[chatIndex], 'msgs': msgs};
      notifyListeners();

      // SUPABASE SYNC
      final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
      final bool isRealChat = !chatId.startsWith(
        'chat_',
      ); // Chats reales tienen UUID

      if (!isDevUser && isRealChat) {
        try {
          await Supabase.instance.client.from('messages').insert({
            'chat_id': chatId,
            'sender_id': _currentUser!.userId,
            'content': msg['text'] ?? '',
          });
          debugPrint('Mensaje sincronizado con Supabase');
        } catch (e) {
          debugPrint('addMessage Supabase Error: $e');
        }
      }
      await _saveChats();
    }
  }

  void deleteMessage(String chatId, String messageId) async {
    final chatIndex = _chats.indexWhere((c) => c['id'] == chatId);
    if (chatIndex != -1) {
      final msgs = List<Map<String, dynamic>>.from(_chats[chatIndex]['msgs']);
      msgs.removeWhere((m) => m['id'] == messageId);
      _chats[chatIndex] = {..._chats[chatIndex], 'msgs': msgs};
      await _saveChats();
      notifyListeners();
    }
  }

  void acceptChat(String chatId) async {
    final chatIndex = _chats.indexWhere((c) => c['id'] == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = {..._chats[chatIndex], 'status': 'active'};

      // Sincronización con Supabase
      final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
      if (!isDevUser && !chatId.startsWith('chat_')) {
        try {
          await Supabase.instance.client
              .from('chats')
              .update({'status': 'active'})
              .eq('id', chatId);
          debugPrint('Chat aceptado en Supabase');
        } catch (e) {
          debugPrint('Error al aceptar chat en Supabase: $e');
        }
      }

      await _saveChats();
      notifyListeners();
    }
  }

  void startChatWithUser(
    String userName,
    String avatar, {
    String? initialMessage,
  }) async {
    // 1. Buscar en memoria local primero
    final existingLocalIndex = _chats.indexWhere((c) => c['name'] == userName);
    if (existingLocalIndex != -1) {
      _activeChatId = _chats[existingLocalIndex]['id'];
      setNavIndex(3);
      notifyListeners();
      return;
    }

    // 2. SUPABASE SYNC: Buscar o crear chat en el servidor
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isDevUser) {
      try {
        final userId = _currentUser!.userId;
        // Buscamos si ya existe el chat entre ambos (no importa el orden de los participantes)
        // Podríamos obtener el targetUserId si lo tuviéramos, pero si no, buscamos por nombre o perfil
        // Como no tenemos el targetUserId aquí (Legacy API), primero intentamos buscar por nombre
        final targetProfile = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('name', userName)
            .maybeSingle();

        if (targetProfile != null) {
          final String targetId = targetProfile['id'];

          // Buscar chat existente
          var chatRecord = await Supabase.instance.client
              .from('chats')
              .select()
              .or(
                'and(participant_1.eq.$userId,participant_2.eq.$targetId),and(participant_1.eq.$targetId,participant_2.eq.$userId)',
              )
              .maybeSingle();

          if (chatRecord == null) {
            // Crear chat con estado PENDIENTE e INICIADOR
            chatRecord = await Supabase.instance.client
                .from('chats')
                .insert({
                  'participant_1': userId,
                  'participant_2': targetId,
                  'status': 'pending',
                  'initiator_id': userId,
                })
                .select()
                .single();
          }

          final String realChatId = chatRecord['id'];
          final String status = chatRecord['status'] ?? 'pending';
          final String? initiatorId = chatRecord['initiator_id'];

          // Agregar a la lista local si no estaba (o recargar todo)
          if (!_chats.any((c) => c['id'] == realChatId)) {
            _chats.insert(0, {
              'id': realChatId,
              'name': userName,
              'avatar': avatar,
              'status': status,
              'initiator_id': initiatorId,
              'msgs': [],
            });
          }

          _activeChatId = realChatId;
          if (initialMessage != null) {
            addMessage(realChatId, {
              'user': _currentUser!.name,
              'text': initialMessage,
              'self': true,
              'time':
                  '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            });
          }
          setNavIndex(3);
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('startChatWithUser Supabase Error: $e');
      }
    }

    // Fallback Legacy (Local)
    final chatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    _chats.add({
      'id': chatId,
      'name': userName,
      'avatar': avatar,
      'status': 'pending',
      'initiator_id': _currentUser?.userId,
      'msgs': [],
    });
    _activeChatId = chatId;

    // Si hay un mensaje inicial, lo enviamos localmente
    if (initialMessage != null && initialMessage.isNotEmpty) {
      addMessage(chatId, {
        'user': _currentUser?.name ?? 'Anónimo',
        'text': initialMessage,
        'self': true,
        'time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
    }

    setNavIndex(3);
    await _saveChats();
    notifyListeners();
  }

  final List<Map<String, dynamic>> _events = [];

  List<Map<String, dynamic>> get events => _events;

  Future<void> addEvent(Map<String, dynamic> event) async {
    // 1. Local de inmediato
    _events.insert(0, event);
    _events.sort(
      (a, b) => a['date'].toString().compareTo(b['date'].toString()),
    );
    notifyListeners();

    // 2. SUPABASE SYNC
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isDevUser) {
      try {
        await Supabase.instance.client.from('events').insert({
          'creator_id': _currentUser!.userId,
          'title': event['title'],
          'location': event['location'],
          'description': event['desc'],
          'price': event['price'],
          'event_date': event['date'],
          'event_time': event['time'],
          'image_url': event['img'],
          'creator_name': event['authorName'],
          'creator_role': event['authorRole'],
        });
        debugPrint('Evento sincronizado con Supabase');
      } catch (e) {
        debugPrint('addEvent Supabase Error: $e');
      }
    }
    await _saveEvents(); // Fallback local persistente
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e['id'] == id);

    // SUPABASE SYNC
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isDevUser && !id.startsWith('demo')) {
      try {
        await Supabase.instance.client.from('events').delete().eq('id', id);
        debugPrint('Evento eliminado de Supabase: $id');
      } catch (e) {
        debugPrint('Error eliminando evento de Supabase: $e');
      }
    }

    await _saveEvents();
    notifyListeners();
  }

  final List<Map<String, dynamic>> _liveEvents = [];

  List<Map<String, dynamic>> get liveEvents => _liveEvents;

  Future<void> addLiveEvent(Map<String, dynamic> event) async {
    // 1. Local de inmediato
    final newEvent = {'category': 'COMBATES', ...event};
    _liveEvents.insert(0, newEvent);
    notifyListeners();

    // 2. SUPABASE SYNC
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isDevUser) {
      try {
        final inserted = await Supabase.instance.client
            .from('live_events')
            .insert({
              'creator_id': _currentUser!.userId,
              'type': event['type'],
              'category': event['category'] ?? 'COMBATES',
              'title': event['title'],
              'description': event['desc'],
              'video_id': event['videoId'],
              'country': event['country'],
              'city': event['city'],
              'gym': event['gym'],
              'views': event['views'] ?? 0,
              'punches': event['punches'] ?? 0,
              'creator_name': event['creatorName'],
              'event_date': event['date'],
              'event_time': event['time'] ?? '00:00',
            })
            .select()
            .single();

        // Actualizar ID local con el de Supabase
        final index = _liveEvents.indexWhere((e) => e['id'] == event['id']);
        if (index != -1) {
          _liveEvents[index] = {..._liveEvents[index], 'id': inserted['id']};
          notifyListeners();
        }
      } catch (e) {
        debugPrint('addLiveEvent Supabase Error: $e');
      }
    }
    await _saveLiveEvents();
  }

  Future<void> deleteLiveEvent(String id) async {
    try {
      // 1. Borrar de Supabase
      await Supabase.instance.client.from('live_events').delete().eq('id', id);

      // 2. Borrar reportes asociados en Supabase
      await Supabase.instance.client
          .from('content_reports')
          .delete()
          .eq('content_id', id);

      // 3. Borrar localmente
      _liveEvents.removeWhere((e) => e['id'] == id);
      notifyListeners();
      await _saveLiveEvents();
    } catch (e) {
      debugPrint('deleteLiveEvent Error: $e');
    }
  }

  Future<void> toggleLikeStream(String streamId) async {
    if (_currentUser == null) return;

    final index = _liveEvents.indexWhere((e) => e['id'] == streamId);
    if (index == -1) return;

    final event = _liveEvents[index];
    final List<String> likedBy = List<String>.from(event['likedBy'] ?? []);
    final bool alreadyLiked = likedBy.contains(_currentUser!.userId);

    int currentPunches = (event['punches'] ?? 0) as int;

    if (alreadyLiked) {
      likedBy.remove(_currentUser!.userId);
      currentPunches = (currentPunches - 1).clamp(0, 1000000);
    } else {
      likedBy.add(_currentUser!.userId);
      currentPunches++;
    }

    // Actualización local optimista
    _liveEvents[index] = {
      ...event,
      'punches': currentPunches,
      'likedBy': likedBy,
    };
    notifyListeners();

    // Sincronización con Supabase
    final bool isLocal =
        streamId.startsWith('live') || streamId.startsWith('local_');
    if (!isLocal) {
      try {
        await Supabase.instance.client
            .from('live_events')
            .update({'punches': currentPunches, 'likedBy': likedBy})
            .eq('id', streamId);
      } catch (e) {
        debugPrint('toggleLikeStream Supabase Error: $e');
      }
    }
  }

  // Mantenemos punchEvent por compatibilidad pero redirigimos o marcamos como obsoleto
  void punchEvent(String id) => toggleLikeStream(id);

  void finishLiveStream(String id) async {
    final index = _liveEvents.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      _liveEvents[index] = {..._liveEvents[index], 'type': 'REPETICION'};
      notifyListeners();

      // SUPABASE SYNC
      final bool isLocal = id.startsWith('live') || id.startsWith('local_');
      if (!isLocal) {
        try {
          await Supabase.instance.client
              .from('live_events')
              .update({'type': 'REPETICION'})
              .eq('id', id);
          debugPrint('Live stream finalizado en Supabase: $id');
        } catch (e) {
          debugPrint('finishLiveStream Supabase Error: $e');
        }
      }
      await _saveLiveEvents();
    }
  }

  void updateLiveViews(String id, int change) async {
    final index = _liveEvents.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      final current = (_liveEvents[index]['views'] ?? 0) as int;
      final newValue = (current + change).clamp(0, 1000000);
      _liveEvents[index] = {..._liveEvents[index], 'views': newValue};
      notifyListeners();

      // SUPABASE SYNC (Optimista local ya hecho)
      final bool isLocal = id.startsWith('live') || id.startsWith('local_');
      if (!isLocal && change > 0) {
        try {
          // Usamos rpc si estuviera disponible, o un update simple
          // Para no complicar con RPC, hacemos un update basado en lo que sabemos
          await Supabase.instance.client
              .from('live_events')
              .update({'views': newValue})
              .eq('id', id);
        } catch (e) {
          debugPrint('updateLiveViews Supabase Error: $e');
        }
      }
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Intentar recuperar sesión desde SharedPreferences (Quick Load)
    final session = prefs.getString('active_session');
    if (session != null) {
      final userData = prefs.getString(session);
      if (userData != null) {
        try {
          _currentUser = UserProfile.fromJson(jsonDecode(userData));
          debugPrint(
            'Sesión cargada desde SharedPreferences: ${_currentUser?.email}',
          );
        } catch (e) {
          debugPrint('Error decodificando sesión local: $e');
        }
      }
    }

    // 2. Escuchar cambios de autenticación en tiempo real (Supabase Persistence)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? currentSession = data.session;

      debugPrint('Supabase Auth Event: $event');

      if (event == AuthChangeEvent.signedIn && currentSession != null) {
        if (_currentUser?.userId != currentSession.user.id) {
          await _loadUserProfile(currentSession.user.id);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });

    // 3. Verificación forzada de sesión actual Supabase (Hard Check)
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    if (supabaseSession != null && _currentUser == null) {
      debugPrint('Sesión Supabase activa detectada. Cargando perfil...');
      await _loadUserProfile(supabaseSession.user.id);
    }

    // Cargar datos persistentes
    await _loadLastVisits();
    await _loadPosts();
    await _loadProducts();
    await _loadJobPosts();
    await _loadChats();
    await _loadEvents();
    await _loadLiveEvents();

    notifyListeners();
  }

  // Persistencia de Posts
  Future<void> _savePosts() async {
    await _safeSave('tc_posts', jsonEncode(_posts));
  }

  Future<void> _loadPosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('*, profiles:user_id(name, avatar_url, role_key)')
          .order('created_at', ascending: false)
          .limit(50);

      final List<Map<String, dynamic>> loadedPosts = [];
      final List<String> postIds = response
          .map((p) => p['id'] as String)
          .toList();

      // OPTIMIZACIÓN: Verificamos todos los likes del usuario para estos posts en una sola consulta
      final Set<String> likedPostIds = {};
      if (_currentUser != null && postIds.isNotEmpty) {
        try {
          final likesRecords = await Supabase.instance.client
              .from('likes')
              .select('post_id')
              .eq('user_id', _currentUser!.userId)
              .inFilter('post_id', postIds);

          for (var like in (likesRecords as List)) {
            likedPostIds.add(like['post_id'] as String);
          }
        } catch (e) {
          debugPrint('Error batching likes: $e');
        }
      }

      for (var p in response) {
        final profile = p['profiles'] as Map<String, dynamic>?;

        loadedPosts.add({
          'id': p['id'],
          'user_id': p['user_id'], // Importante para isOwner
          'user': profile?['name'] ?? 'Usuario',
          'userAvatar': profile?['avatar_url'] ?? '',
          'role': _getRoleNameFromKey(profile?['role_key'] ?? ''),
          'roleKey': profile?['role_key'] ?? '',
          'content': p['content'] ?? '',
          'image': p['image_url'],
          'video': p['video_url'],
          'likes': p['likes_count'] ?? 0,
          'comments': <Map<String, dynamic>>[], // Siempre iniciamos vacío
          'commentsCount': p['comments_count'] ?? 0,
          'isVerified': false,
          'time': _formatTimeAgo(DateTime.parse(p['created_at'])),
          'isLiked': likedPostIds.contains(p['id']),
          'timestamp': p['created_at'],
        });
      }

      _posts.clear();
      _posts.addAll(loadedPosts);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading posts from Supabase: $e');
    }
  }

  /// Carga los comentarios de un post específico bajo demanda
  Future<void> loadCommentsForPost(String postId) async {
    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return;

    // Si ya hay comentarios y no es id local, podríamos saltar si queremos,
    // pero mejor recargar para ver si hay nuevos.
    if (postId.startsWith('local_')) return;

    try {
      final response = await Supabase.instance.client
          .from('comments')
          .select('*, profiles:user_id(name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> postComments = [];
      for (var c in response) {
        final profile = c['profiles'] as Map<String, dynamic>?;
        postComments.add({
          'id': c['id'],
          'user': profile?['name'] ?? 'Usuario',
          'text': c['content'] ?? '',
          'isVerified': false,
          'timestamp': c['created_at'],
        });
      }

      _posts[index] = {
        ..._posts[index],
        'comments': postComments,
        'commentsCount': postComments.length,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading comments for post $postId: $e');
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'hace ${diff.inMinutes}m';
    return 'hace momentos';
  }

  Future<void> addPost(String content, {String? image, String? video}) async {
    if (_currentUser == null) return;

    // DEV MODE: Si el userId no es un UUID real, guardamos localmente
    final bool isDevUser = _currentUser!.userId.startsWith('dev_');

    if (isDevUser) {
      final newPost = {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': _currentUser!.userId, // Para que isOwner funcione
        'user': _currentUser!.name,
        'userAvatar': _currentUser!.avatar,
        'role': _currentUser!.roleName,
        'content': content,
        'image': image,
        'video': video,
        'likes': 0,
        'comments': [],
        'commentsCount': 0,
        'time': 'hace momentos',
        'isLiked': false,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _posts.insert(0, newPost);
      await _savePosts();
      notifyListeners();
      return;
    }

    try {
      await Supabase.instance.client.from('posts').insert({
        'user_id': _currentUser!.userId,
        'content': content,
        'image_url': image,
        'video_url': video,
      });

      // Recargar feed para ver el nuevo post
      await _loadPosts();
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('No se pudo publicar');
    }
  }

  Future<void> toggleLike(String postId) async {
    if (_currentUser == null) return;

    final bool isDevUser = _currentUser!.userId.startsWith('dev_');

    // DEV MODE: toggle like localmente
    if (isDevUser) {
      final index = _posts.indexWhere((p) => p['id'] == postId);
      if (index != -1) {
        final currentLikes = (_posts[index]['likes'] ?? 0) as int;
        final currentLiked = (_posts[index]['isLiked'] ?? false) as bool;
        _posts[index] = {
          ..._posts[index],
          'likes': currentLiked ? currentLikes - 1 : currentLikes + 1,
          'isLiked': !currentLiked,
        };
        notifyListeners();
      }
      return;
    }

    // --- OPTIMISTIC UPDATE START ---
    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      final currentPost = _posts[index];
      final bool currentLiked = (currentPost['isLiked'] ?? false) as bool;
      final int currentLikes = (currentPost['likes'] ?? 0) as int;

      _posts[index] = {
        ...currentPost,
        'likes': currentLiked
            ? (currentLikes - 1).clamp(0, 999999)
            : currentLikes + 1,
        'isLiked': !currentLiked,
      };
      notifyListeners();
    }
    // --- OPTIMISTIC UPDATE END ---

    try {
      final userId = _currentUser!.userId;
      final client = Supabase.instance.client;

      // Check if already liked
      final existing = await client
          .from('likes')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        await client.from('likes').delete().eq('id', existing['id']);
      } else {
        // Like
        await client.from('likes').insert({
          'user_id': userId,
          'post_id': postId,
        });

        // NOTIFICACIÓN AL AUTOR
        final post = _posts.firstWhere(
          (p) => p['id'] == postId,
          orElse: () => {},
        );
        final authorId = post['user_id'] ?? post['ownerId'];
        if (authorId != null && authorId != userId) {
          try {
            await client.from('notifications').insert({
              'user_id': authorId,
              'title': '¡Nuevo Like! 🥊',
              'body': '${_currentUser!.name} le dio like a tu publicación.',
              'type': 'like',
              'related_id': postId,
            });
          } catch (e) {
            debugPrint('Error enviando notificación de Like: $e');
          }
        }
      }

      // Reload in background to ensure sync with Supabase counts/state
      _loadPosts();
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revertir cambio local si hay error (opcional pero recomendado)
      await _loadPosts();
    }
  }

  Future<void> addComment(String postId, String text) async {
    if (_currentUser == null) return;

    final bool isDevUser = _currentUser!.userId.startsWith('dev_');

    if (isDevUser) {
      // DEV MODE: agregar comentario localmente
      final index = _posts.indexWhere((p) => p['id'] == postId);
      if (index != -1) {
        final comments = List<Map<String, dynamic>>.from(
          _posts[index]['comments'] as List? ?? [],
        );
        comments.add({'user': _currentUser!.name, 'text': text});
        _posts[index] = {..._posts[index], 'comments': comments};
        await _savePosts();
        notifyListeners();
      }
      return;
    }

    try {
      await Supabase.instance.client.from('comments').insert({
        'user_id': _currentUser!.userId,
        'post_id': postId,
        'content': text,
      });

      // Recargamos SOLO los comentarios de este post, no todo el feed
      await loadCommentsForPost(postId);
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    // Posts locales (Dev mode) se borran solo en memoria
    final isLocal = postId.startsWith('local_');
    if (isLocal) {
      _posts.removeWhere((p) => p['id'] == postId);
      await _savePosts();
      notifyListeners();
      return;
    }

    try {
      await Supabase.instance.client.from('posts').delete().eq('id', postId);
      // Borrado local ya realizado arriba o lo hacemos aquí para seguridad
      _posts.removeWhere((p) => p['id'] == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  // Helper para persistencia local de Live Events
  Future<void> _saveLiveEvents() async {
    await _safeSave('tc_live_events', jsonEncode(_liveEvents));
  }

  // Persistencia de Chats
  Future<void> _saveChats() async {
    await _safeSave('tc_chats', jsonEncode(_chats));
  }

  Future<void> _loadChats() async {
    if (_currentUser == null) return;

    try {
      final userId = _currentUser!.userId;
      // Cargar chats donde el usuario participa
      final response = await Supabase.instance.client
          .from('chats')
          .select(
            '*, p1:participant_1(name, avatar_url), p2:participant_2(name, avatar_url)',
          )
          .or('participant_1.eq.$userId, participant_2.eq.$userId');

      final List<Map<String, dynamic>> loadedChats = [];

      for (var c in response) {
        final String chatId = c['id'];
        final bool isP1 = c['participant_1'] == userId;
        final otherProfile = isP1 ? c['p2'] : c['p1'];

        // Cargar últimos 50 mensajes de este chat
        final msgResponse = await Supabase.instance.client
            .from('messages')
            .select()
            .eq('chat_id', chatId)
            .order('created_at', ascending: true)
            .limit(50);

        final List<Map<String, dynamic>> msgs = [];
        for (var m in msgResponse) {
          final bool isSelf = m['sender_id'] == userId;
          final date = DateTime.parse(m['created_at']);
          msgs.add({
            'id': m['id'],
            'text': m['content'] ?? '',
            'self': isSelf,
            'time': '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
            'timestamp': m['created_at'],
          });
        }

        loadedChats.add({
          'id': chatId,
          'name': otherProfile?['name'] ?? 'Usuario',
          'avatar': otherProfile?['avatar_url'] ?? '',
          'status': c['status'] ?? 'active',
          'initiator_id': c['initiator_id'],
          'msgs': msgs,
        });
      }

      if (loadedChats.isNotEmpty) {
        _chats.clear();
        _chats.addAll(loadedChats);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading chats from Supabase: $e');
    }

    // Fallback: local storage (Titanium Rule)
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('tc_chats');
    if (data != null && _chats.isEmpty) {
      _chats.addAll(List<Map<String, dynamic>>.from(jsonDecode(data)));
      notifyListeners();
    }
  }

  // Persistencia de Eventos
  // Persistencia de Eventos (Local por ahora)
  Future<void> _saveEvents() async {
    await _safeSave('tc_events', jsonEncode(_events));
  }

  Future<void> _loadEvents() async {
    // 1. Limpieza de eventos expirados (Titanium Maintenance)
    await _cleanExpiredEvents();

    try {
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .order('event_date', ascending: true);

      final List<Map<String, dynamic>> loaded = [];
      for (var e in response) {
        loaded.add({
          'id': e['id'],
          'title': e['title'] ?? '',
          'location': e['location'] ?? '',
          'desc': e['description'] ?? '',
          'price': e['price'] ?? 'Gratis',
          'date': e['event_date'],
          'time': e['event_time'] ?? '00:00',
          'img': e['image_url'] ?? '',
          'authorName': e['creator_name'],
          'authorRole': e['creator_role'],
          'isReal': true,
        });
      }

      if (loaded.isNotEmpty) {
        _events.clear();
        _events.addAll(loaded);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Error loading events from Supabase: $e');
    }

    // Fallback: local storage
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('tc_events');
    if (data != null) {
      _events.clear();
      _events.addAll(List<Map<String, dynamic>>.from(jsonDecode(data)));
    } else {
      // Mocks iniciales si no hay nada
      _events.addAll([
        {
          'id': 'demo1',
          'title': 'Velada Gallo de Oro',
          'date': '2025-05-15',
          'time': '20:00',
          'location': 'Estadio Central',
          'price': '500',
          'img':
              'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
          'desc': 'Gran exhibición anual de prospectos locales.',
        },
        {
          'id': 'demo2',
          'title': 'Clase Abierta de Defensa',
          'date': '2025-06-20',
          'time': '12:00',
          'location': 'Parque Central',
          'price': 'Gratis',
          'img':
              'https://images.unsplash.com/photo-1555597673-b21d5c935865?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
          'desc':
              'Clase gratuita para principiantes enfocada en desplazamientos.',
        },
      ]);
    }
    notifyListeners();
  }

  Future<void> _loadLiveEvents() async {
    try {
      final response = await Supabase.instance.client
          .from('live_events')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> loaded = [];
      for (var e in response) {
        loaded.add({
          'id': e['id'],
          'type': e['type'] ?? 'REPETICION',
          'category': e['category'] ?? 'COMBATES',
          'title': e['title'] ?? '',
          'desc': e['description'] ?? '',
          'videoId': e['video_id'] ?? '',
          'country': e['country'] ?? '',
          'city': e['city'] ?? '',
          'gym': e['gym'] ?? '',
          'views': e['views'] ?? 0,
          'punches': e['punches'] ?? 0,
          'creatorId': e['creator_id'],
          'creatorName': e['creator_name'] ?? 'Usuario',
          'date': e['event_date'],
          'time': e['event_time'],
          'isUnderReview': e['is_under_review'] ?? false,
          'isReal': true,
        });
      }

      if (loaded.isNotEmpty) {
        _liveEvents.clear();
        _liveEvents.addAll(loaded);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Error loading live events from Supabase: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('tc_live_events');
    if (data != null) {
      _liveEvents.clear();
      _liveEvents.addAll(List<Map<String, dynamic>>.from(jsonDecode(data)));
    } else {
      // Mocks iniciales
      _liveEvents.addAll([
        {
          'id': 'live1',
          'type': 'VIVO',
          'category': 'COMBATES',
          'platform': 'youtube',
          'videoId': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title': 'CAMPEONATO MUNDIAL: VELÁZQUEZ VS SMITH',
          'desc': 'Directo desde el MGM Grand, Las Vegas.',
          'date': '2025-06-15',
          'time': '21:00',
          'country': '🇺🇸 USA',
          'city': 'Las Vegas',
          'views': 3400,
          'punches': 120,
          'creatorName': 'Tierra de Campeones',
        },
        {
          'id': 'live2',
          'type': 'REPETICION',
          'category': 'ENTRENAMIENTOS',
          'platform': 'youtube',
          'videoId': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title': 'Técnicas de Hook con "The Punisher"',
          'desc': 'Clase magistral de golpeo.',
          'date': '2025-06-10',
          'time': '18:00',
          'country': '🇦🇷 ARG',
          'city': 'Buenos Aires',
          'views': 1200,
          'punches': 450,
          'creatorName': 'Lex Gotti',
        },
      ]);
    }
    notifyListeners();
  }

  Future<Map<String, int>> getSocialCounts(String userId) async {
    try {
      // Usamos una consulta simple que devuelve el conteo
      final followerData = await Supabase.instance.client
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);

      final followingData = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      return {
        'followers': (followerData as List).length,
        'following': (followingData as List).length,
      };
    } catch (e) {
      debugPrint('Error fetching social counts: $e');
      return {'followers': 0, 'following': 0};
    }
  }

  Future<List<String>> getFollowersList(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);
      return (res as List).map((f) => f['follower_id'].toString()).toList();
    } catch (e) {
      debugPrint('Error getFollowersList: $e');
      return [];
    }
  }

  Future<List<String>> getFollowingList(String userId) async {
    try {
      final res = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);
      return (res as List).map((f) => f['following_id'].toString()).toList();
    } catch (e) {
      debugPrint('Error getFollowingList: $e');
      return [];
    }
  }

  void navigateToProfile(
    BuildContext context,
    String userId, {
    Map<String, dynamic>? fallbackData,
  }) async {
    // 1. Mostrar loader si es necesario o cargar directo
    final profile = await getUserProfileById(userId);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(
                profile?['name']?.toString().toUpperCase() ?? 'PERFIL',
              ),
            ),
            body: SingleChildScrollView(
              child: AthleteProfileView(
                userData: profile ?? fallbackData ?? {},
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> finishLiveEvent(String eventId) async {
    _liveEvents.removeWhere((e) => e['id'] == eventId);
    await _saveLiveEvents();
    notifyListeners();
  }

  Future<void> reportLiveEvent(
    String eventId,
    String category,
    String reason,
  ) async {
    final bool isDevUser = _currentUser?.userId.startsWith('dev_') ?? true;
    if (!isDevUser) {
      try {
        final client = Supabase.instance.client;

        // 1. Registrar la denuncia detallada
        await client.from('content_reports').insert({
          'reporter_id': _currentUser!.userId,
          'content_id': eventId,
          'content_type': 'live_event',
          'category': category,
          'reason': reason,
        });

        // 2. Obtener conteo de denuncias para este video
        final reportsResponse = await client
            .from('content_reports')
            .select('id')
            .eq('content_id', eventId);

        final int reportCount = (reportsResponse as List).length;

        // 3. Bloqueo preventivo si llega a 3 strikes
        if (reportCount >= 3) {
          await client
              .from('live_events')
              .update({'is_under_review': true})
              .eq('id', eventId);

          // 4. Notificar al creador
          final event = _liveEvents.firstWhere(
            (e) => e['id'] == eventId,
            orElse: () => {},
          );
          if (event['creatorId'] != null) {
            await client.from('notifications').insert({
              'user_id': event['creatorId'],
              'title': 'Contenido en revisión 🛡️',
              'body':
                  'Tu video "${event['title']}" está en revisión preventiva tras recibir múltiples denuncias.',
              'type': 'system',
            });
          }

          // Actualizar estado local
          final index = _liveEvents.indexWhere((e) => e['id'] == eventId);
          if (index != -1) {
            _liveEvents[index] = {..._liveEvents[index], 'isUnderReview': true};
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('reportLiveEvent Supabase Error: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getContentReports() async {
    try {
      final response = await Supabase.instance.client
          .from('content_reports')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getContentReports Error: $e');
      return [];
    }
  }

  Future<void> resolveReport(String reportId) async {
    try {
      await Supabase.instance.client
          .from('content_reports')
          .delete()
          .eq('id', reportId);
      // No necesitamos lógica compleja aquí, solo limpiar la tabla de denuncias
    } catch (e) {
      debugPrint('resolveReport Error: $e');
    }
  }

  Future<void> unblockLiveEvent(String eventId) async {
    try {
      await Supabase.instance.client
          .from('live_events')
          .update({'is_under_review': false})
          .eq('id', eventId);

      // Limpiar denuncias para empezar de cero
      await Supabase.instance.client
          .from('content_reports')
          .delete()
          .eq('content_id', eventId);

      // Actualizar localmente
      final index = _liveEvents.indexWhere((e) => e['id'] == eventId);
      if (index != -1) {
        _liveEvents[index] = {..._liveEvents[index], 'isUnderReview': false};
        notifyListeners();
      }
    } catch (e) {
      debugPrint('unblockLiveEvent Error: $e');
    }
  }

  /// DEV ONLY: Crea una sesión local simulada sin tocar Supabase.
  /// Útil para probar roles sin necesidad de cuenta real.
  Future<void> loginLocal(UserProfile profile) async {
    _currentUser = profile;
    await _saveUserToPrefs(profile);
    _loadProducts(); // Cargar marketplace (mostrará mocks en Dev Mode)
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      if (res.user != null) {
        await _loadUserProfile(res.user!.id);
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        throw Exception(
          'Debes confirmar tu email antes de entrar. Revisa tu bandeja de entrada o spam. 📧',
        );
      }
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw Exception(
          'Email o contraseña incorrectos. Revisa bien los datos. 🥊',
        );
      }
      throw Exception('Error de entrada: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión: ${e.toString()}');
    }
  }

  /// Recupera la contraseña enviando un email de reinicio vía Supabase 🥊📧
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) throw Exception('Por favor, ingresa tu email.');
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'tierra-de-campeones://reset-callback',
      );
    } catch (e) {
      throw Exception('Error al solicitar recuperación: ${e.toString()}');
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final Map<String, dynamic> userMap = {
        'userId': data['id'],
        'email': data['email'],
        'name': data['name'],
        'role': _getRoleNameFromKey(data['role_key']),
        'roleKey': data['role_key'],
        'avatar': data['avatar_url'] ?? '',
        'extraData': data['extra_data'] ?? {},
      };

      _currentUser = UserProfile.fromJson(userMap);

      // Persist active session locally for offline support or quick load
      await _saveUserToPrefs(_currentUser!);

      // Cargar datos del ecosistema
      _loadProducts(); // Marketplace desde Supabase (no bloqueante)
      _loadJobPosts(); // Job Board desde Supabase (no bloqueante)

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
      throw Exception('Error al cargar perfil del usuario');
    }
  }

  String _getRoleNameFromKey(String key) {
    // Map key back to readable name (simplified for now)
    // In a real app this might come from a config or constants
    if (key.contains('boxer')) return 'Boxeador';
    if (key.contains('coach')) return 'Entrenador';
    if (key.contains('fan')) return 'Fanático';
    return 'Usuario';
  }

  Future<void> register(UserProfile profile, String password) async {
    try {
      // 1. Create Auth User
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: profile.email,
        password: password,
        data: {'name': profile.name, 'role_key': profile.roleKey},
      );

      if (res.user == null) throw Exception('Error al crear usuario en Auth');

      final String userId = res.user!.id;

      // Si no hay sesión, es muy probable que requiera confirmación de email
      final bool needsConfirmation = res.session == null;

      // 2. Prepare Extra Data (Injection logic)
      final Map<String, dynamic> extraData = Map<String, dynamic>.from(
        profile.extraData,
      );

      // INYECCIÓN DE NODOS DEMO (Manteniendo la lógica original)
      if (profile.roleKey.contains('boxer') ||
          profile.roleKey.contains('cadet')) {
        if (extraData['team_members'] == null) {
          extraData['team_members'] = [
            {'userId': 'e1', 'role': 'Entrenador Principal'},
            {'userId': 'n1', 'role': 'Nutricionista'},
          ];
        }
        if (extraData['sponsors'] == null) {
          extraData['sponsors'] = [
            {'name': 'Everlast', 'logo': '🥊', 'url': 'https://everlast.com'},
            {'name': 'Nike', 'logo': '✔️', 'url': 'https://nike.com'},
          ];
        }
      }

      // 3. Create Profile in DB
      await Supabase.instance.client.from('profiles').insert({
        'id': userId,
        'email': profile.email,
        'name': profile.name,
        'role_key': profile.roleKey,
        'avatar_url': profile.avatar,
        'extra_data': extraData,
      });

      // 4. Si necesita confirmación, no podemos cargar el perfil todavía porque no hay sesión
      if (needsConfirmation) {
        throw Exception(
          '¡Registro casi listo! 📧 Te enviamos un mail de confirmación. Por favor, revísalo para activar tu cuenta.',
        );
      }

      await _loadUserProfile(userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'Este email ya está registrado o hay un conflicto con los datos. Intenta iniciar sesión. 🥊',
        );
      }
      throw Exception('Error en base de datos: ${e.message}');
    } catch (e) {
      throw Exception('Error en registro: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_session');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUserPassword(String newPassword) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      debugPrint('updateUserPassword Error: $e');
      rethrow;
    }
  }

  /// LIMPIEZA QUIRÚRGICA: Borra toda la persistencia física
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Borra FÍSICAMENTE todo el storage
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    // 1. Obtenemos el JSON actual
    final Map<String, dynamic> json = _currentUser!.toJson();

    // 2. Si las actualizaciones contienen 'extraData' anidado, lo aplanamos
    if (updates.containsKey('extraData') && updates['extraData'] is Map) {
      final Map<String, dynamic> extraUpdates = Map<String, dynamic>.from(
        updates['extraData'] as Map,
      );
      updates.remove('extraData');
      updates.addAll(extraUpdates);
    }

    // 3. Aplicamos las nuevas actualizaciones
    json.addAll(updates);

    // 4. LIMPIEZA AGRESIVA (Sanitización):
    // Si algún campo que debería ser texto terminó siendo un Mapa por errores previos,
    // extraemos el valor real o lo convertimos a String limpio.
    final List<String> textFields = [
      'name',
      'bio',
      'nickname',
      'apodo',
      'record',
      'fights',
      'role',
      'roleKey',
      'age',
      'height',
      'reach',
      'weightClass',
      'stance',
      'nationality',
      'represents',
      'currentLocation',
      'initialTrainer',
      'initialSponsor',
    ];

    json.forEach((key, value) {
      if (textFields.contains(key) && value is Map) {
        // Intentamos rescatar el valor si está una capa adentro
        if (value.containsKey(key)) {
          final extracted = value[key];
          json[key] = extracted is String ? extracted : extracted.toString();
        } else if (value.containsKey('value')) {
          final extracted = value['value'];
          json[key] = extracted is String ? extracted : extracted.toString();
        } else if (value.containsKey('text')) {
          final extracted = value['text'];
          json[key] = extracted is String ? extracted : extracted.toString();
        } else {
          // Si es un mapa genérico sin estructura conocida, lo descartamos y dejamos vacío
          // para evitar mostrar código en la UI
          json[key] = '';
        }
      }
    });

    // 5. Re-creamos el perfil con los datos ya saneados
    _currentUser = UserProfile.fromJson(json);

    // 6. Persistencia Local Segura (Web Friendly)
    await _saveUserToPrefs(_currentUser!);

    // 7. Sincronización con Supabase (Solo si no es usuario DEV)
    final bool isDevUser = _currentUser!.userId.startsWith('dev_');
    if (!isDevUser) {
      try {
        // Preparamos los campos base para Supabase
        final Map<String, dynamic> dbUpdates = {
          'name': _currentUser!.name,
          'email': _currentUser!.email,
          'role_key': _currentUser!.roleKey,
          'avatar_url':
              _currentUser!.extraData['avatar'] ??
              _currentUser!.extraData['avatar_url'],
          'extra_data': _currentUser!.extraData,
        };

        await Supabase.instance.client
            .from('profiles')
            .update(dbUpdates)
            .eq('id', _currentUser!.userId);

        debugPrint('Perfil sincronizado con Supabase con éxito');
      } catch (e) {
        debugPrint('Error al sincronizar perfil con Supabase: $e');
        // No lanzamos excepción para no bloquear la UI si falla el red,
        // ya que la persistencia local funcionó.
      }
    }

    notifyListeners();
  }

  /// EVOLUCIÓN DE CARRERA: Cambia el nivel del boxeador (Cadete -> Amateur -> Pro)
  /// Se guarda de forma independiente para no interferir con otros datos.
  Future<void> updateBoxerLevel(String roleName, String roleKey) async {
    if (_currentUser == null) return;

    final Map<String, dynamic> updates = {'role': roleName, 'roleKey': roleKey};

    await updateUserProfile(updates);
  }

  /// Limpia eventos que pasaron hace más de 12 horas (Titanium Maintenance)
  Future<void> _cleanExpiredEvents() async {
    final now = DateTime.now();
    final List<String> toDelete = [];

    // Copiamos la lista para evitar errores de concurrencia
    final currentEvents = List<Map<String, dynamic>>.from(_events);

    for (var event in currentEvents) {
      final String id = event['id'].toString();
      if (id.startsWith('demo')) continue;

      try {
        final String dateStr = event['date'].toString();
        // Aseguramos que el formato sea YYYY-MM-DD
        final String timeStr = event['time']?.toString() ?? '00:00';
        final DateTime evtDateTime = DateTime.parse("$dateStr $timeStr");

        // Margen de 12 horas después del inicio del evento
        if (now.isAfter(evtDateTime.add(const Duration(hours: 12)))) {
          toDelete.add(id);
        }
      } catch (e) {
        // No borramos si hay error de parsing para evitar falsos positivos
      }
    }

    if (toDelete.isNotEmpty) {
      debugPrint(
        'Mantenimiento: Limpiando ${toDelete.length} eventos expirados...',
      );
      for (var id in toDelete) {
        await deleteEvent(id);
      }
    }
  }
}
