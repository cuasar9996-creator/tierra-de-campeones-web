import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'services/app_store.dart';
import 'screens/profile_home_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://mjfazkrewgyosvjxgorh.supabase.co',
    anonKey: 'sb_publishable_ox2uyIa1cpu9O-iBiC0jrQ_NgM_8Jo0',
  );

  final appStore = AppStore();
  await appStore.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => appStore,
      child: const TierraDeCampeonesApp(),
    ),
  );
}

class TierraDeCampeonesApp extends StatelessWidget {
  const TierraDeCampeonesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tierra de Campeones',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: context.watch<AppStore>().currentUser != null
          ? const ProfileHomeScreen()
          : const WelcomeScreen(),
    );
  }
}
