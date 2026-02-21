import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/app_store.dart';
import 'athlete_profile_view.dart';

class ProfileShowcaseView extends StatefulWidget {
  const ProfileShowcaseView({super.key});

  @override
  State<ProfileShowcaseView> createState() => _ProfileShowcaseViewState();
}

class _ProfileShowcaseViewState extends State<ProfileShowcaseView> {
  Map<String, dynamic>? _selectedUser;

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
              'VOLVER AL CATÁLOGO',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          AthleteProfileView(userData: _selectedUser!),
        ],
      );
    }

    final store = context.watch<AppStore>();
    final users = store.mockUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '📐 CATÁLOGO DE PERFILES',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Text(
          'Selecciona un rol para visualizar su estructura de perfil.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 30),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            mainAxisExtent: 150,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedUser = user),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(user['avatar']),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user['role'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
