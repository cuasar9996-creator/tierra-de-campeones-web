import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../core/app_colors.dart';
import '../screens/auth_screen.dart'; // Import para navegación
import 'package:url_launcher/url_launcher.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'admin_reports_view.dart'; // Import para el panel admin
import 'legal_content_view.dart'; // Import para textos legales

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚙️ CONFIGURACIÓN',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 30),

        // --- PANEL DE ADMINISTRADOR ---
        if (context.read<AppStore>().currentUser?.email ==
                'tierradecampeonesapp@gmail.com' ||
            context.read<AppStore>().currentUser?.email ==
                'cuasar9996@gimal.com' ||
            context.read<AppStore>().currentUser?.email ==
                'cuasar9996@gmail.com' ||
            (context.read<AppStore>().currentUser?.userId.startsWith('dev_') ??
                false)) ...[
          _buildSettingsGroup('🛡️ PANEL DE ADMINISTRADOR', [
            _buildSettingsItem(
              FontAwesomeIcons.shieldHalved,
              'Revisar Denuncias (Streaming)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminReportsView(),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 30),
        ],

        _buildSettingsGroup('Cuenta y Perfil', [
          _buildSettingsItem(
            FontAwesomeIcons.userPen,
            'Editar Información Personal',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, _, _) =>
                      const AuthScreen(initialView: AuthView.registerForm),
                ),
              );
            },
          ),
          _buildSettingsItem(
            FontAwesomeIcons.lock,
            'Cambiar Contraseña',
            onTap: () => _showChangePasswordDialog(context),
          ),
          _buildSettingsItem(
            FontAwesomeIcons.bell,
            'Notificaciones',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '🔔 Notificaciones de Likes, Seguidores, Marketplace y Mensajes activas por defecto.',
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ]),

        const SizedBox(height: 30),

        _buildSettingsGroup('Apariencia', [
          _buildSettingsItem(
            FontAwesomeIcons.palette,
            'Tema de la Aplicación',
            trailing: 'Modo Oscuro',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Beta: Solo Modo Oscuro disponible por ahora 🥊',
                  ),
                ),
              );
            },
          ),
          _buildSettingsItem(
            FontAwesomeIcons.language,
            'Idioma',
            trailing: 'Español',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Beta: Solo Español disponible por ahora 🥊'),
                ),
              );
            },
          ),
        ]),

        const SizedBox(height: 30),

        // --- MODO DESARROLLO: CAMBIO DE ROL INSTANTÁNEO ---
        if ((context.read<AppStore>().currentUser?.userId.startsWith('dev_') ??
                false) ||
            context.read<AppStore>().currentUser?.email ==
                'tierradecampeonesapp@gmail.com' ||
            context.read<AppStore>().currentUser?.email ==
                'cuasar9996@gimal.com' ||
            context.read<AppStore>().currentUser?.email ==
                'cuasar9996@gmail.com') ...[
          const Text(
            '🛠️ MODO DESARROLLO (BETA)',
            style: TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cambia de rol al vuelo para probar perfiles sin usar múltiples cuentas.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildRoleSwitcher(
                context,
                'Boxeador Pro',
                'boxer_pro',
                'Boxeador Profesional',
              ),
              _buildRoleSwitcher(
                context,
                'Amateur',
                'boxer_amateur',
                'Boxeador Amateur',
              ),
              _buildRoleSwitcher(context, 'Coach', 'coach', 'Entrenador'),
              _buildRoleSwitcher(context, 'Promotor', 'promoter', 'Promotor'),
              _buildRoleSwitcher(context, 'Juez', 'judge', 'Juez'),
              _buildRoleSwitcher(context, 'Cutman', 'cutman', 'Cutman'),
              _buildRoleSwitcher(
                context,
                'Nutricionista',
                'nutritionist',
                'Nutricionista Dep.',
              ),
              _buildRoleSwitcher(
                context,
                'Psicólogo',
                'psychologist',
                'Psicólogo Dep.',
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],

        _buildSettingsGroup('Información Legal y Soporte', [
          _buildSettingsItem(
            FontAwesomeIcons.fileContract,
            'Términos de Uso',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalContentView(
                    title: 'Términos de Uso',
                    content: LegalContentView.termsOfUse,
                  ),
                ),
              );
            },
          ),
          _buildSettingsItem(
            FontAwesomeIcons.shieldHalved,
            'Política de Privacidad',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalContentView(
                    title: 'Política de Privacidad',
                    content: LegalContentView.privacyPolicy,
                  ),
                ),
              );
            },
          ),
          _buildSettingsItem(
            FontAwesomeIcons.envelope,
            'Contactar Soporte',
            trailing: 'tierradecampeonesapp@gmail.com',
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'tierradecampeonesapp@gmail.com',
                queryParameters: {'subject': 'Soporte Tierra de Campeones'},
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              }
            },
          ),
        ]),

        const SizedBox(height: 30),

        const Text(
          '⚠️ ZONA DE PELIGRO',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Si tienes problemas con la aplicación, puedes borrar los datos locales.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  title: const Text(
                    '¿Estás seguro?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Esto borrará todos los datos locales y cerrará la sesión. Esta acción no se puede deshacer.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCELAR'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'RESETEAR',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                // For now, logout is enough to "reset" the current session
                // We could also clear shared preferences entirely
                await context.read<AppStore>().logout();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text('RESETEAR DATOS Y REINICIAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => PointerInterceptor(
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text(
            'CAMBIAR CONTRASEÑA',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu nueva contraseña (mínimo 6 caracteres).',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nueva contraseña',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPass = passwordController.text.trim();
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contraseña demasiado corta')),
                  );
                  return;
                }
                try {
                  await context.read<AppStore>().updateUserPassword(newPass);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Contraseña actualizada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('ACTUALIZAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String label, {
    String? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: FaIcon(icon, color: AppColors.primary, size: 18),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textMuted,
            size: 14,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildRoleSwitcher(
    BuildContext context,
    String label,
    String roleKey,
    String roleName,
  ) {
    return ActionChip(
      avatar: const Icon(
        FontAwesomeIcons.userAstronaut,
        size: 14,
        color: AppColors.primary,
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: Colors.white10,
      side: BorderSide.none,
      onPressed: () async {
        final store = context.read<AppStore>();
        await store.updateUserProfile({
          'role': roleKey, // Clave interna para lógica
          'roleKey': roleKey,
          'roleName': roleName, // Nombre visible
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎭 ¡Transformado en $roleName!'),
              backgroundColor: Colors.cyan,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }
}
