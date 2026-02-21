import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/app_colors.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentPage = 0;
  bool _audioStarted = false;

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  final List<Map<String, String>> _scenes = [
    {'image': 'boxer.png', 'sound': 'breath.mp3'},
    {'image': 'ring.png', 'sound': 'bell.mp3'},
    {'image': 'gloves.png', 'sound': 'heartbeat.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _startCinematicSequence();
  }

  Future<void> _startCinematicSequence() async {
    // No iniciamos audio aquí automáticamente por políticas del navegador
    _playCurrentScene();
  }

  Future<void> _enableAudio() async {
    if (_audioStarted) return;

    setState(() {
      _audioStarted = true;
    });

    try {
      // 1. Iniciar audio ambiente (Estadio)
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.3);
      await _ambientPlayer.play(AssetSource('sounds/stadium_ambient.mp3'));

      // 2. Reproducir sonido de la escena actual
      await _effectPlayer.setVolume(1.0);
      await _effectPlayer.play(
        AssetSource('assets/sounds/${_scenes[_currentPage]['sound']}'),
      );
    } catch (e) {
      debugPrint("Error al iniciar audio: $e");
    }
  }

  void _playCurrentScene() async {
    if (!mounted) return;

    // Reproducir efecto de la escena solo si el audio ya fue activado por el usuario
    if (_audioStarted) {
      try {
        await _effectPlayer.play(
          AssetSource('sounds/${_scenes[_currentPage]['sound']}'),
        );
      } catch (e) {
        debugPrint("Error play effect: $e");
      }
    }

    // Esperar 5 segundos antes de la siguiente escena (ESTO DEBE EJECUTARSE SIEMPRE)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage + 1) % _scenes.length;
        });
        _playCurrentScene();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ambientPlayer.dispose();
    _effectPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Cinematic Sequence with Cross-Fade
          AnimatedSwitcher(
            duration: const Duration(seconds: 2),
            child: AnimatedBuilder(
              key: ValueKey<int>(_currentPage),
              animation: _animationController,
              builder: (context, child) {
                double scale = 1.0 + (_animationController.value * 0.1);
                return Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    'assets/images/${_scenes[_currentPage]['image']}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) {
                      // Placeholder si no existen los assets aún
                      return Container(
                        color: Colors.black87,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white24,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Overlay Gradient (from CSS .overlay)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tierra de Campeones',
                          style: AppTheme.headingStyle.copyWith(
                            fontSize: 48,
                            height: 1.1,
                            shadows: [
                              const Shadow(
                                blurRadius: 12,
                                color: Colors.black,
                                offset: Offset(0, 4),
                              ),
                              Shadow(
                                blurRadius: 40,
                                color: AppColors.primaryGlow.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: AppTheme.headingStyle.copyWith(
                            fontSize: 48,
                            color: AppColors.primary,
                            shadows: [
                              const Shadow(
                                blurRadius: 20,
                                color: AppColors.primaryGlow,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'EL CONTINENTE DEL BOXEO',
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 18,
                      letterSpacing: 4,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sub-tagline
                  Text(
                    'Conecta. Compite. Crece.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 64),

                  // CTA Buttons
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        _buildButton(
                          text: 'INGRESAR',
                          onPressed: () {
                            _ambientPlayer.stop();
                            _effectPlayer.stop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(
                                  initialView: AuthView.login,
                                ),
                              ),
                            );
                          },
                          isPrimary: true,
                        ),
                        const SizedBox(height: 16),
                        _buildButton(
                          text: 'REGISTRARSE',
                          onPressed: () {
                            _ambientPlayer.stop();
                            _effectPlayer.stop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(
                                  initialView: AuthView.registerRoles,
                                ),
                              ),
                            );
                          },
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Audio Control Button (Top Right)
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _audioStarted = !_audioStarted;
                });
                if (_audioStarted) {
                  _enableAudio();
                } else {
                  _ambientPlayer.stop();
                  _effectPlayer.stop();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _audioStarted
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  _audioStarted ? Icons.volume_up : Icons.volume_off,
                  color: _audioStarted ? AppColors.primary : Colors.white70,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: isPrimary
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFFA01828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: isPrimary
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: AppColors.primaryGlow.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Center(
            child: Text(
              text,
              style: AppTheme.headingStyle.copyWith(
                fontSize: 18,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
