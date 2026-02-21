import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/app_roles.dart';
import '../theme/app_theme.dart';
import 'profile_home_screen.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../models/user_profile.dart';
import '../core/role_helper.dart';
import 'dart:math';

enum AuthView { login, registerRoles, registerForm }

class AuthScreen extends StatefulWidget {
  final AuthView initialView;
  const AuthScreen({super.key, this.initialView = AuthView.login});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthView _currentView;
  RoleDefinition? _selectedRole;

  // Controllers for the form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, List<String>> _selectedChips = {};

  String? _selectedStage;

  // ADN Pentalogía: Logros múltiples por etapa
  final Map<String, List<Map<String, dynamic>>> _allAchievements = {};
  final _newAchievementController = TextEditingController();
  int _selectedAchievementIconIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;

    // Pre-cargar datos si ya hay un usuario logueado (Modo Edición)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<AppStore>();
      if (store.currentUser != null) {
        final user = store.currentUser!;
        _nameController.text = user.name;
        _emailController.text = user.email;

        // Intentar encontrar el rol actual de forma más robusta
        final currentRole = appRoles.firstWhere((r) {
          final String cleanUserRole =
              (user.roleKey.isEmpty ? user.roleName : user.roleKey)
                  .toLowerCase();
          final String cleanRoleKey = r.key.toLowerCase();
          final String cleanRoleName = r.name.toLowerCase();

          return cleanUserRole.contains(cleanRoleKey) ||
              cleanRoleName.contains(cleanUserRole) ||
              cleanUserRole.contains(cleanRoleName);
        }, orElse: () => appRoles.first);

        setState(() {
          _selectedRole = currentRole;
          _selectedStage =
              user.extraData['careerStage']?.toString() ??
              (user.roleKey.isNotEmpty ? user.roleKey : null);

          // Inicializar logros (Migración Titanium)
          final history = user.extraData['career_history'] ?? {};
          final stages = [
            'cadet',
            'amateur-boxer',
            'pro-boxer',
            'retired-boxer',
            'legend-boxer',
          ];
          for (var s in stages) {
            _allAchievements[s] = [];
            // Intentar cargar lista nueva
            final list = user.extraData['achievements_$s'];
            if (list is List) {
              _allAchievements[s] = List<Map<String, dynamic>>.from(list);
            } else {
              // Migración: Si hay un logro viejo, lo movemos a la lista
              String oldText = '';
              String oldIcon = '0';
              if (s == user.roleKey) {
                oldText = user.extraData['achievement_text']?.toString() ?? '';
                oldIcon =
                    user.extraData['achievement_icon_id']?.toString() ?? '0';
              } else if (history is Map &&
                  (history[s] is Map ||
                      history[s.replaceAll('-boxer', '')] is Map)) {
                final stageData =
                    history[s] ?? history[s.replaceAll('-boxer', '')];
                oldText = stageData['achievement_text']?.toString() ?? '';
                oldIcon = stageData['achievement_icon_id']?.toString() ?? '0';
              }
              if (oldText.isNotEmpty) {
                _allAchievements[s]!.add({'text': oldText, 'icon_id': oldIcon});
              }
            }
          }

          // Inicializar controladores específicos
          _bioController.text = (user.extraData['bio'] ?? '').toString();

          // Si entramos directo a roles pero ya tenemos uno, podemos pre-configurar los campos
          for (var field in currentRole.fields) {
            if (field.type == 'chips') {
              final val = user.extraData[field.id];
              if (val is List) {
                _selectedChips[field.id] = List<String>.from(val);
              } else {
                _selectedChips[field.id] = [];
              }
            } else {
              _dynamicControllers[field.id] = TextEditingController(
                text: user.extraData[field.id]?.toString() ?? '',
              );
            }
          }
        });
      }
    });
  }

  Widget _buildAuthBackground() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurry Background (Modal Overlay effect)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: kIsWeb
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withValues(alpha: 0.96),
                    child: _buildAuthBackground(),
                  )
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: _buildAuthBackground(),
                  ),
          ),

          // Modal Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
              child: _buildModalContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalContent() {
    switch (_currentView) {
      case AuthView.login:
        return _buildLoginView();
      case AuthView.registerRoles:
        return _buildRegisterRolesView();
      case AuthView.registerForm:
        return _buildRegisterFormView();
    }
  }

  Widget _buildModalCard({
    required List<Widget> children,
    double maxWidth = 450,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFA141414), Color(0xFA0F0F0F)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 1,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildLoginView() {
    return _buildModalCard(
      children: [
        _buildCloseButton(),
        Text(
          'INGRESAR AL RING',
          style: AppTheme.headingStyle.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Email',
          hint: 'tu@email.com',
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Contraseña',
          hint: '••••••••',
          controller: _passwordController,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          text: 'INICIAR SESIÓN',
          onPressed: () async {
            try {
              await context.read<AppStore>().login(
                _emailController.text,
                _passwordController.text,
              );
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileHomeScreen(),
                  ),
                  (route) => false,
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.roboto(color: AppColors.textMuted, fontSize: 13),
            children: [
              const TextSpan(text: '¿Olvidaste tu contraseña? '),
              TextSpan(
                text: 'Recuperar',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _showForgotPasswordDialog(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Divider(color: Colors.white12),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text(
              '🛠️ DEV TOOLS - ACCESO RÁPIDO',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDevLoginBtn('Boxeador Pro', 'pro-boxer'),
                  _buildDevLoginBtn('Amateur', 'amateur-boxer'),
                  _buildDevLoginBtn('Cadete', 'cadet'), // Agregado Cadete
                  _buildDevLoginBtn(
                    'Retirado',
                    'retired-boxer',
                  ), // Agregado Retirado
                  _buildDevLoginBtn(
                    'Leyenda',
                    'legend-boxer',
                  ), // Agregado Leyenda
                  _buildDevLoginBtn('Fanático', 'fan'),
                  _buildDevLoginBtn('Coach', 'coach'),
                  _buildDevLoginBtn('Dueño Gym', 'gym-owner'),
                  _buildDevLoginBtn('Promotor', 'promoter'),
                  _buildDevLoginBtn('Periodista', 'journalist'),
                  _buildDevLoginBtn('Juez', 'judge'),
                  _buildDevLoginBtn('Nutricionista', 'nutritionist'),
                  _buildDevLoginBtn('Médico', 'medic'),
                  _buildDevLoginBtn('Psicólogo', 'psychologist'),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text(
                  'BORRAR TODO (PURGAR PERSISTENCIA)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed: () async {
                  await context.read<AppStore>().clearAllData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PERSISTENCIA PURGADA FÍSICAMENTE'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        _buildLegalLinks(),
      ],
    );
  }

  Widget _buildLegalLinks() {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFooterLinkSmall('Términos', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Términos de Uso próximamente')),
            );
          }),
          const Text(
            ' • ',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
          _buildFooterLinkSmall('Privacidad', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Política de Privacidad próximamente'),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooterLinkSmall(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final recoverEmailController = TextEditingController(
      text: _emailController.text,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'RECUPERAR CLAVE 🥊',
          style: AppTheme.headingStyle.copyWith(fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu email y te enviaremos un enlace para que puedas elegir una nueva contraseña.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Tu Email',
              hint: 'correo@ejemplo.com',
              controller: recoverEmailController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final email = recoverEmailController.text.trim();
              if (email.isEmpty) return;

              try {
                await context.read<AppStore>().resetPassword(email);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '📬 ¡Enlace enviado! Revisa tu bandeja de entrada o spam.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('ENVIAR ENLACE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDevLoginBtn(String label, String roleKey) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () async {
        try {
          final roleDef = appRoles.firstWhere(
            (r) => r.key == roleKey,
            orElse: () => appRoles.first,
          );

          // Datos base realistas
          final Map<String, dynamic> extraData = {
            'followers': [],
            'following': [],
            'bio':
                'Perfil de prueba para el rol de ${roleDef.name}. En Tierra de Campeones forjamos el futuro del boxeo.',
            'location': 'Buenos Aires, Argentina',
          };

          // Datos específicos por rol
          if (roleKey.contains('boxer')) {
            extraData.addAll({
              'record': '12-2-1',
              'kos': '8',
              'weightClass': 'Peso Welter',
              'stance': 'Ortodoxo',
              'height': '175',
              'reach': '180',
            });
          } else if (roleKey == 'coach') {
            extraData.addAll({
              'coachRanks': ['Provincial', 'Nacional'],
              'coachBaseGym': 'Boxing Club Tierra de Campeones',
              'coachSpecialties': ['Pro', 'Amateur', 'Recreativo'],
              'birthPlace': 'La Habana, Cuba',
              'representation': '🇲🇽 México',
              'bio':
                  'Entrenador con más de 15 años de experiencia formando campeones mundiales. Especialista en técnica y estrategia.',
            });
          } else if (roleKey == 'gym-owner') {
            extraData.addAll({
              'gymName': 'Arena de Campeones',
              'services': ['Boxeo Recreativo', 'Competencia', 'Sparring'],
            });
          }

          final tempId =
              'dev_${roleKey}_${DateTime.now().millisecondsSinceEpoch}';
          final tempProfile = UserProfile(
            userId: tempId,
            name: 'Dev ${roleDef.name}',
            email: 'dev+$roleKey@test.com',
            roleName: roleDef.name,
            roleKey: roleKey,
            createdAt: DateTime.now().toIso8601String(),
            extraData: extraData,
          );

          // 🔑 LOGIN LOCAL: 100% en memoria, sin tocar Supabase (evita 429/401)
          await context.read<AppStore>().loginLocal(tempProfile);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileHomeScreen(),
              ),
              (route) => false,
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error Dev Login: $e')));
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildRegisterRolesView() {
    return _buildModalCard(
      maxWidth: 900,
      children: [
        _buildCloseButton(),
        Text(
          'ELIGE TU ROL',
          style: AppTheme.headingStyle.copyWith(fontSize: 28),
        ),
        Text(
          '¿Quién eres en el mundo del boxeo?',
          style: GoogleFonts.roboto(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: appRoles.length,
          itemBuilder: (context, index) {
            final role = appRoles[index];
            return _buildRoleCard(role);
          },
        ),
      ],
    );
  }

  Widget _buildRegisterFormView() {
    final store = context.read<AppStore>();
    final bool isEditing = store.currentUser != null;

    return _buildModalCard(
      children: [
        _buildBackButton(),
        _buildCloseButton(),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              isEditing ? 'EDITAR PERFIL: ' : 'REGISTRO: ',
              style: AppTheme.headingStyle.copyWith(fontSize: 18),
            ),
            Text(
              _selectedRole?.name ?? '',
              style: AppTheme.headingStyle.copyWith(
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        // CAMPOS BASE (Nombre y Bio siempre presentes) - AHORA AL PRINCIPIO
        _buildTextField(
          label: 'Nombre completo o público',
          controller: _nameController,
          hint: 'Ej. Juan Pérez o "El Rayo"',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Biografía / Descripción',
          controller: _bioController,
          hint: 'Cuéntanos un poco sobre ti...',
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // LÓGICA DE BLOQUES (ADN DEL BOXEADOR & PENTALOGÍA TITANIO) 🛡️
        if (_isBoxerFlow) ...[
          _buildUniversalBoxerBlock(store),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Text(
            'HITOS Y LOGROS DE CARRERA',
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildBoxerCareerBlocks(store),
        ] else
          // Lógica Estándar para Roles Simples (Coach, Médico, etc.)
          ...(_selectedRole?.fields
                  .where((f) {
                    // FILTRO TITANIO: No mostrar campos que ya se gestionan en la "Vidriera" del perfil
                    final roleKey = _selectedRole?.key ?? '';
                    if (roleKey == 'judge' ||
                        roleKey == 'coach' ||
                        roleKey == 'nutritionist' ||
                        roleKey == 'medic' ||
                        roleKey == 'psychologist' ||
                        roleKey == 'cutman' ||
                        roleKey == 'physical-trainer' ||
                        roleKey == 'manager' ||
                        roleKey == 'promoter' ||
                        roleKey == 'gym-owner') {
                      // Ocultar campos de chips y módulos que están en la vidriera
                      if (f.type == 'chips') return false;
                      if (f.id.contains('module')) return false;
                      if (f.id == 'license') return false;
                      if (f.id == 'official_fights_count') return false;
                    }
                    return true;
                  })
                  .map((field) {
                    if (!_dynamicControllers.containsKey(field.id)) {
                      _dynamicControllers[field.id] = TextEditingController();
                    }
                    if (field.type == 'select') {
                      final currentValue = _dynamicControllers[field.id]?.text;
                      final initialValue =
                          (field.options?.contains(currentValue) ?? false)
                          ? currentValue!
                          : (field.options?.isNotEmpty ?? false
                                ? field.options!.first
                                : '');

                      return _buildDropdownField(
                        label: field.label,
                        options: field.options ?? [],
                        value: initialValue,
                        onChanged: (val) {
                          setState(() {
                            _dynamicControllers[field.id]?.text = val ?? '';
                          });
                        },
                      );
                    } else if (field.type == 'chips') {
                      return _buildChipsField(
                        label: field.label,
                        options: field.options ?? [],
                        selected: _selectedChips[field.id] ?? [],
                        onChanged: (newSelected) {
                          setState(() {
                            _selectedChips[field.id] = newSelected;
                          });
                        },
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTextField(
                        label: field.label,
                        hint: field.placeholder ?? '',
                        controller: _dynamicControllers[field.id]!,
                      ),
                    );
                  })
                  .toList() ??
              []),

        if (isEditing &&
            (_selectedRole?.key.contains('boxer') == true ||
                _selectedRole?.key.contains('cadet') == true)) ...[
          _buildEvolutionSelector(),
          const SizedBox(height: 16),
        ],

        _buildTextField(label: 'Email', hint: '', controller: _emailController),
        const SizedBox(height: 24),

        if (!isEditing) ...[
          _buildTextField(
            label: 'Contraseña',
            hint: '',
            controller: _passwordController,
            isPassword: true,
          ),
          const SizedBox(height: 24),
        ],

        _buildActionButton(
          text: isEditing ? 'GUARDAR CAMBIOS' : 'CREAR CUENTA',
          onPressed: () async {
            try {
              // Recolectar datos dinámicos estándar (excluyendo históricos por ahora)
              final Map<String, dynamic> extraDataMap = {};
              _dynamicControllers.forEach((key, controller) {
                if (!key.startsWith('hist_')) {
                  extraDataMap[key] = controller.text;
                }
              });

              // LÓGICA DE GUARDADO PENTALOGÍA 🛡️
              if (_isBoxerFlow) {
                // 1. Recuperar historial actual para no borrar datos previos
                Map<String, dynamic> careerHistory = {};
                if (store.currentUser?.extraData['career_history'] != null) {
                  // Copia superficial suficiente si solo agregamos claves
                  careerHistory = Map<String, dynamic>.from(
                    store.currentUser!.extraData['career_history'],
                  );
                }

                // 1.1 Inyectar logros múltiples en extraDataMap
                _allAchievements.forEach((stage, list) {
                  extraDataMap['achievements_$stage'] = list;
                });
                // 2. Procesar controladores históricos (hist_stageKey_fieldId)
                _dynamicControllers.forEach((key, controller) {
                  if (key.startsWith('hist_')) {
                    final parts = key.split('_');
                    if (parts.length >= 3) {
                      final stageKey = parts[1];
                      final fieldId = parts.sublist(2).join('_');

                      if (careerHistory[stageKey] == null) {
                        careerHistory[stageKey] = <String, dynamic>{};
                      }
                      (careerHistory[stageKey] as Map)[fieldId] =
                          controller.text;
                    }
                  }
                });

                // 2.1 Inyectar logros múltiples dentro del historial (Titanio)
                _allAchievements.forEach((stage, list) {
                  if (careerHistory[stage] == null) {
                    careerHistory[stage] = <String, dynamic>{};
                  }
                  (careerHistory[stage] as Map)['achievements'] = list;
                  // También mantenemos la copia en raíz para acceso rápido
                  extraDataMap['achievements_$stage'] = list;
                });

                // 3. Inyectamos historial limpio en el mapa maestro
                extraDataMap['career_history'] = careerHistory;
              } else {
                _dynamicControllers.forEach((key, controller) {
                  if (!extraDataMap.containsKey(key)) {
                    extraDataMap[key] = controller.text;
                  }
                });

                // RECOLECTAR CHIPS (Módulos técnicos, etc)
                _selectedChips.forEach((key, list) {
                  extraDataMap[key] = list;
                });
              }

              if (isEditing) {
                // RUTA DE ESPEJO: Guardado robusto
                final Map<String, dynamic> newExtraData = {
                  ...store.currentUser!.extraData,
                  'bio': _bioController.text,
                  'careerStage': _selectedStage,
                  ...extraDataMap,
                };

                final String gender = _dynamicControllers['gender']?.text ?? '';

                await store.updateUserProfile({
                  'name': _nameController.text,
                  'email': _emailController.text,
                  'gender': gender,
                  'role': RoleGenderHelper.getRoleName(
                    _selectedStage ?? _selectedRole?.key ?? '',
                    gender,
                  ),
                  'extraData': newExtraData,
                });

                if (context.mounted) Navigator.pop(context);
              } else {
                // LÓGICA DE REGISTRO NUEVO
                final String userId =
                    'u_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

                final String gender = _dynamicControllers['gender']?.text ?? '';

                final profile = UserProfile(
                  userId: userId,
                  name: _nameController.text,
                  email: _emailController.text,
                  gender: gender,
                  roleName: RoleGenderHelper.getRoleName(
                    _selectedRole?.key ?? 'fan',
                    gender,
                  ),
                  roleKey: _selectedRole?.key ?? 'fan',
                  createdAt: DateTime.now().toIso8601String(),
                  extraData: {
                    ...extraDataMap,
                    'followers': [],
                    'following': [],
                  },
                );

                await store.register(profile, _passwordController.text);

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileHomeScreen(),
                    ),
                    (route) => false,
                  );
                }
              }
            } catch (e) {
              final msg = e.toString();
              // Detectar si es un mensaje de confirmación de email (no es un error real)
              if (msg.contains('confirmación') ||
                  msg.contains('confirmar') ||
                  msg.contains('Registro casi listo')) {
                if (mounted) {
                  // Cerrar el modal de registro
                  Navigator.pop(context);
                  // Mostrar diálogo premium de confirmación
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => Dialog(
                      backgroundColor: const Color(0xFF141414),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📧', style: TextStyle(fontSize: 52)),
                            const SizedBox(height: 16),
                            Text(
                              '¡CASI LISTO, CAMPEÓN!',
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Te enviamos un correo de confirmación. '
                              'Revisá tu bandeja de entrada (o spam) y '
                              'hacé clic en el enlace para activar tu cuenta.',
                              style: GoogleFonts.roboto(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'ENTENDIDO, VOY A REVISAR',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg.replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }
          },
        ),
        _buildLegalLinks(),
      ],
    );
  }

  Widget _buildRoleCard(RoleDefinition role) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _currentView = AuthView.registerForm;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(role.icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              role.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2A2A).withOpacity(0.6),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> options,
    String? value,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              items: options
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: onChanged,
              value: value ?? (options.isNotEmpty ? options.first : null),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFA01828)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: AppTheme.headingStyle.copyWith(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textMuted),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: TextButton.icon(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textMuted,
          size: 16,
        ),
        label: Text(
          'VOLVER A ROLES',
          style: GoogleFonts.roboto(color: AppColors.textMuted, fontSize: 12),
        ),
        onPressed: () {
          setState(() {
            _currentView = AuthView.registerRoles;
          });
        },
      ),
    );
  }

  String _getDisplayRoleNombre(String? stage, String? gender) {
    if (stage == null) return _selectedRole?.name ?? 'Boxeador';
    final genderKey = (gender?.toLowerCase() == 'femenino') ? 'female' : 'male';
    return RoleGenderHelper.getRoleName(stage, genderKey);
  }

  Widget _buildEvolutionSelector() {
    final stages = [
      {'name': 'Cadete (👦)', 'key': 'cadet'},
      {'name': 'Amateur (🥇)', 'key': 'amateur-boxer'},
      {'name': 'Pro (🥊)', 'key': 'pro-boxer'},
      {'name': 'Retirado (🕰️)', 'key': 'retired-boxer'},
      {'name': 'Leyenda (🏆)', 'key': 'legend-boxer'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'MI NIVEL DE CARRERA',
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            _getDisplayRoleNombre(
              _selectedStage,
              _dynamicControllers['gender']?.text,
            ).toUpperCase(),
            style: const TextStyle(color: AppColors.primary, fontSize: 10),
          ),
          children: stages.map((stage) {
            final bool isSel = _selectedStage == stage['key'];
            return ListTile(
              onTap: () {
                setState(() => _selectedStage = stage['key'] as String);
              },
              title: Text(
                stage['name'] as String,
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSel
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- ARQUITECTURA PENTALOGÍA (NUEVA LÓGICA AISLADA) 🛡️ ---

  /// Solo los boxeadores en estados activos (Pro, Amateur, Semillero)
  /// usan el bloque universal de métricas físicas.
  /// Retirados y Leyendas usan el flujo DINÁMICO de campos.
  bool get _isBoxerFlow {
    if (_selectedRole == null) return false;
    final k = _selectedRole!.key;
    return k == 'pro-boxer' || k == 'amateur-boxer' || k == 'cadet';
  }

  Widget _buildUniversalBoxerBlock(AppStore store) {
    // Lista de campos que se vuelven universales (se mueven de los bloques individuales al maestro)
    final user = store.currentUser;
    final data = user?.extraData ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATOS DE IDENTIDAD (UNIVERSALES)',
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // APODO - AHORA AL PRINCIPIO DEL BLOQUE BOXEADOR
        _buildTextField(
          label: 'Apodo (ej. El Chino)',
          hint: 'Cómo te conocen en el ring',
          controller: _getOrCreateController(
            'nickname',
            data['nickname']?.toString() ?? '',
          ),
        ),
        const SizedBox(height: 16),

        // GÉNERO
        _buildDropdownField(
          label: 'Tu Género / Identificación',
          options: ['Masculino', 'Femenino'],
          value: _dynamicControllers['gender']?.text.isEmpty == true
              ? (data['gender'] ?? 'Masculino')
              : _dynamicControllers['gender']?.text,
          onChanged: (val) {
            setState(() {
              if (!_dynamicControllers.containsKey('gender')) {
                _dynamicControllers['gender'] = TextEditingController(
                  text: val,
                );
              } else {
                _dynamicControllers['gender']?.text = val ?? 'Masculino';
              }
            });
          },
        ),
        const SizedBox(height: 16),

        // DATOS FÍSICOS
        Row(
          children: [
            Expanded(child: _buildUniversalField('age', 'Edad', '25', data)),
            const SizedBox(width: 10),
            Expanded(
              child: _buildUniversalField('height', 'Altura (cm)', '175', data),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildUniversalField('reach', 'Alcance (cm)', '180', data),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // GUARDIA
        _buildDropdownField(
          label: 'Guardia',
          options: ['Ortodoxo', 'Zurdo'],
          value: _dynamicControllers['stance']?.text.isEmpty == true
              ? (data['stance'] ?? 'Ortodoxo')
              : _dynamicControllers['stance']?.text,
          onChanged: (val) {
            setState(() {
              if (!_dynamicControllers.containsKey('stance')) {
                _dynamicControllers['stance'] = TextEditingController(
                  text: val,
                );
              } else {
                _dynamicControllers['stance']?.text = val ?? 'Ortodoxo';
              }
            });
          },
        ),
        const SizedBox(height: 16),

        // RÉCORD UNIVERSAL (LA GRILLA TITANIO) 🛡️
        Text(
          'RÉCORD ACTUAL (G-P-E-NC-KO)',
          style: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRecordInput('wins', 'G', data),
            _buildRecordInput('losses', 'P', data),
            _buildRecordInput('draws', 'E', data),
            _buildRecordInput('nc', 'NC', data),
            _buildRecordInput('kos', 'KO', data),
          ],
        ),
        const SizedBox(height: 20),

        // UBICACIÓN Y ENTORNO
        _buildUniversalDropdown('nationality', 'País de Nacimiento', [
          'Argentina 🇦🇷',
          'México 🇲🇽',
          'USA 🇺🇸',
          'España 🇪🇸',
          'Cuba 🇨🇺',
          'Puerto Rico 🇵🇷',
          'Senegal 🇸🇳',
          'UK 🇬🇧',
          'Japón 🇯🇵',
        ], data),
        _buildUniversalDropdown('represents', 'País que Representa', [
          'Argentina 🇦🇷',
          'México 🇲🇽',
          'USA 🇺🇸',
          'España 🇪🇸',
          'Cuba 🇨🇺',
          'Puerto Rico 🇵🇷',
          'Senegal 🇸🇳',
          'UK 🇬🇧',
          'Japón 🇯🇵',
        ], data),
        _buildUniversalField(
          'currentLocation',
          'Ciudad de Residencia',
          'CABA, México DF...',
          data,
        ),
        _buildUniversalField(
          'gym',
          'Gimnasio / Club Actual',
          'Boxing Club...',
          data,
        ),
        _buildUniversalField(
          'trainer',
          'Entrenador Principal',
          'Nombre del técnico',
          data,
        ),
        _buildUniversalField(
          'boxrecUrl',
          'URL de BoxRec (Opcional)',
          'https://boxrec.com/...',
          data,
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 24),

        // REDES SOCIALES COLAPSABLES
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              'REDES SOCIALES',
              style: GoogleFonts.lexend(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            subtitle: const Text(
              'Instagram, Facebook, Twitter...',
              style: TextStyle(fontSize: 9, color: Colors.white38),
            ),
            children: [
              const SizedBox(height: 8),
              _buildUniversalField(
                'instagram',
                'Instagram',
                'usuario o link',
                data,
              ),
              _buildUniversalField(
                'facebook',
                'Facebook',
                'link a tu perfil',
                data,
              ),
              _buildUniversalField(
                'twitter',
                'X / Twitter',
                'usuario o link',
                data,
              ),
              _buildUniversalField(
                'youtube',
                'YouTube',
                'link a tu canal',
                data,
              ),
              _buildUniversalField('tiktok', 'TikTok', 'usuario o link', data),
              _buildUniversalField('twitch', 'Twitch', 'link o usuario', data),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  TextEditingController _getOrCreateController(String id, String initialValue) {
    if (!_dynamicControllers.containsKey(id)) {
      _dynamicControllers[id] = TextEditingController(text: initialValue);
    }
    return _dynamicControllers[id]!;
  }

  Widget _buildUniversalField(
    String id,
    String label,
    String hint,
    Map<String, dynamic> data,
  ) {
    final controller = _getOrCreateController(id, data[id]?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildTextField(label: label, hint: hint, controller: controller),
    );
  }

  Widget _buildChipsField({
    required String label,
    required List<String> options,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            return FilterChip(
              label: Text(
                opt.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white.withOpacity(0.05),
              onSelected: (val) {
                final List<String> next = List<String>.from(selected);
                if (val) {
                  next.add(opt);
                } else {
                  next.remove(opt);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUniversalDropdown(
    String id,
    String label,
    List<String> options,
    Map<String, dynamic> data,
  ) {
    final controller = _getOrCreateController(
      id,
      data[id]?.toString() ?? options.first,
    );
    return _buildDropdownField(
      label: label,
      options: options,
      value: controller.text.isEmpty ? options.first : controller.text,
      onChanged: (val) {
        setState(() {
          controller.text = val ?? options.first;
        });
      },
    );
  }

  Widget _buildRecordInput(String id, String label, Map<String, dynamic> data) {
    final controller = _getOrCreateController(id, data[id]?.toString() ?? '0');
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxerCareerBlocks(AppStore store) {
    // Las 5 Etapas Sagradas
    final stages = [
      {
        'key': 'cadet',
        'label': '👦 ETAPA CADETE / SEMILLERO',
        'roleKey': 'cadet',
      },
      {
        'key': 'amateur',
        'label': '🥇 ETAPA AMATEUR',
        'roleKey': 'amateur-boxer',
      },
      {'key': 'pro', 'label': '🥊 ETAPA PROFESIONAL', 'roleKey': 'pro-boxer'},
      {
        'key': 'retired',
        'label': '🕰️ ETAPA RETIRO',
        'roleKey': 'retired-boxer',
      },
      {'key': 'legend', 'label': '🏆 ETAPA LEYENDA', 'roleKey': 'legend-boxer'},
    ];

    final currentRoleKey = _selectedRole?.key ?? '';

    return Column(
      children: stages.map((stage) {
        final stageKey = stage['key']!;
        final roleDefKey = stage['roleKey']!;

        // Buscamos la definición real de campos para esta etapa en appRoles
        final roleDef = appRoles.firstWhere(
          (r) => r.key == roleDefKey,
          orElse: () => appRoles.first,
        );

        // ¿Es esta la etapa actual del usuario?
        final isCurrentStage = currentRoleKey == roleDefKey;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCurrentStage
                ? AppColors.primary.withOpacity(0.1)
                : Colors.black26,
            border: Border.all(
              color: isCurrentStage ? AppColors.primary : Colors.white10,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            initiallyExpanded:
                isCurrentStage, // Solo abrimos la actual por defecto
            collapsedIconColor: isCurrentStage
                ? AppColors.primary
                : Colors.white54,
            iconColor: AppColors.primary,
            title: Text(
              stage['label']!,
              style: TextStyle(
                color: isCurrentStage ? AppColors.primary : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            subtitle: isCurrentStage
                ? const Text(
                    'Tu etapa activa',
                    style: TextStyle(color: AppColors.primary, fontSize: 10),
                  )
                : null,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black12,
                child: Column(
                  children: [
                    // Solo mostramos los campos que NO son universales (logros)
                    ...roleDef.fields
                        .where(
                          (f) =>
                              f.id != 'nationality' &&
                              f.id != 'represents' &&
                              f.id != 'nickname' &&
                              f.id != 'age' &&
                              f.id != 'height' &&
                              f.id != 'reach' &&
                              f.id != 'stance' &&
                              f.id != 'record' &&
                              f.id != 'kos' &&
                              f.id != 'currentLocation' &&
                              f.id != 'boxrecUrl' &&
                              f.id != 'initialTrainer' &&
                              f.id != 'initialSponsor' &&
                              f.id != 'gym' &&
                              f.id != 'weightClass',
                        )
                        .map((field) {
                          // CLAVE DEL ÉXITO: Gestión de Controladores Pentalogía
                          String controllerKey;
                          String initialValue = '';

                          if (isCurrentStage) {
                            controllerKey = field.id;
                          } else {
                            controllerKey = 'hist_$stageKey${'_'}${field.id}';
                            // Recuperar valor del historial existente
                            if (store.currentUser != null) {
                              final history = store
                                  .currentUser!
                                  .extraData['career_history'];
                              if (history is Map) {
                                final stageData = history[stageKey];
                                if (stageData is Map) {
                                  initialValue =
                                      stageData[field.id]?.toString() ?? '';
                                }
                              }
                            }
                          }

                          if (!_dynamicControllers.containsKey(controllerKey)) {
                            _dynamicControllers[controllerKey] =
                                TextEditingController(text: initialValue);
                          }

                          if (field.type == 'select') {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildDropdownField(
                                label: field.label,
                                options: field.options ?? [],
                                value:
                                    _dynamicControllers[controllerKey]
                                            ?.text
                                            .isEmpty ==
                                        true
                                    ? null
                                    : _dynamicControllers[controllerKey]?.text,
                                onChanged: (val) {
                                  setState(() {
                                    _dynamicControllers[controllerKey]?.text =
                                        val ?? '';
                                  });
                                },
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildTextField(
                              label: field.label,
                              hint: field.placeholder ?? '',
                              controller: _dynamicControllers[controllerKey]!,
                            ),
                          );
                        }),

                    // --- NUEVA SECCIÓN: LOGROS (SISTEMA TITANIO) 🛡️ ---
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 10),
                    _buildAchievementEditor(stageKey, isCurrentStage, store),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementEditor(
    String stageKey,
    bool isCurrentStage,
    AppStore store,
  ) {
    final achievements = _allAchievements[stageKey] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Text(
              'AÑADIR LOGROS / HITOS'.toUpperCase(),
              style: GoogleFonts.lexend(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Campo de entrada para nuevo logro
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Nuevo Logro',
                hint: 'Ej: Campeón Nacional...',
                controller: _newAchievementController,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 25),
              child: ElevatedButton(
                onPressed: () {
                  if (_newAchievementController.text.trim().isEmpty) return;
                  setState(() {
                    _allAchievements[stageKey] ??= [];
                    _allAchievements[stageKey]!.add({
                      'text': _newAchievementController.text.trim(),
                      'icon_id': _selectedAchievementIconIndex.toString(),
                    });
                    _newAchievementController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(40, 48),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Text(
          'ELIGE LA INSIGNIA PARA ESTE LOGRO',
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 8),
        _buildIconSelector(stageKey, ''), // iconKey ya no es necesario aquí

        if (achievements.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'LOGROS REGISTRADOS:',
            style: GoogleFonts.lexend(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 8),
          ...achievements.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final iconSets = {
              'cadet': ['🏆', '🥇', '🥈', '🥉', '🏅'],
              'amateur': ['🏆', '🥇', '🥈', '🥉', '🏅'],
              'pro': ['👑', '🥊', '🎖️', '💎', '🌟'],
              'retired': ['👑', '🥊', '🎖️', '💎', '🌟'],
              'legend': ['👑', '🥊', '🎖️', '💎', '🌟'],
            };
            final set = iconSets[stageKey] ?? iconSets['pro']!;
            final iconIdx = int.tryParse(item['icon_id'].toString()) ?? 0;
            final icon = iconIdx < set.length ? set[iconIdx] : '🏆';

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['text'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    onPressed: () {
                      setState(() {
                        _allAchievements[stageKey]!.removeAt(idx);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildIconSelector(String stageKey, String unused) {
    final Map<String, List<String>> iconSets = {
      'cadet': ['🏆', '🥇', '🥈', '🥉', '🏅'],
      'amateur': ['🏆', '🥇', '🥈', '🥉', '🏅'],
      'pro': ['👑', '🥊', '🎖️', '💎', '🌟'],
      'retired': ['👑', '🥊', '🎖️', '💎', '🌟'],
      'legend': ['👑', '🥊', '🎖️', '💎', '🌟'],
    };

    final set = iconSets[stageKey] ?? iconSets['pro']!;
    final int selectedIndex = _selectedAchievementIconIndex;

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: set.length,
        itemBuilder: (context, index) {
          final bool isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAchievementIconIndex = index;
              });
            },
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white10,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: isSelected ? 1.0 : 0.3,
                  child: Text(set[index], style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
