import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/app_store.dart';

class RetiredBoxerProfile extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isMe;

  const RetiredBoxerProfile({
    super.key,
    required this.userData,
    required this.isMe,
  });

  @override
  State<RetiredBoxerProfile> createState() => _RetiredBoxerProfileState();
}

class _RetiredBoxerProfileState extends State<RetiredBoxerProfile> {
  // Helpers para acceder a datos actualizados
  Map<String, dynamic> get effectiveData {
    if (widget.isMe) {
      final store = context.watch<AppStore>();
      return store.currentUser?.toJson() ?? widget.userData;
    }
    return widget.userData;
  }

  Map<String, dynamic> get extraData => effectiveData['extraData'] ?? {};

  void _updateProfile(Map<String, dynamic> newExtraData, {String? newBio}) {
    if (!widget.isMe) return;
    final store = context.read<AppStore>();

    final updatedExtra = Map<String, dynamic>.from(extraData);
    updatedExtra.addAll(newExtraData);

    final Map<String, dynamic> updatePayload = {'extraData': updatedExtra};
    if (newBio != null) {
      updatePayload['bio'] = newBio;
    }

    store.updateUserProfile(updatePayload);
  }

  @override
  Widget build(BuildContext context) {
    // Datos seguros con fallbacks
    final record = extraData['record'] ?? 'Sin Récord';
    final division = extraData['weightClass'] ?? 'Peso Desconocido';
    final stance = extraData['stance'] ?? 'Guardia Desconocida';

    final bio = effectiveData['bio'] ?? 'Ex boxeador profesional retirado.';
    final achievements = extraData['achievements'] ?? 'Campeón Latino';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cabecera ELIMINADA (Ya la provee el padre)
        // _buildHeader(context, location),
        const SizedBox(height: 10),

        // 2. Resumen de Carrera (Estilo PLATA)
        GestureDetector(
          onTap: widget.isMe ? () => _showEditResumeDialog(context) : null,
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              // Gradiente Plata Metálico
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE0E0E0), // Plata brillante
                  const Color(0xFFB0B0B0), // Plata medio
                  const Color(0xFF808080), // Plata oscuro
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CARRERA PROFESIONAL',
                      style: GoogleFonts.lexend(
                        color: Colors.black87, // Texto oscuro sobre plata
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.isMe) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 14, color: Colors.black54),
                    ],
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('RÉCORD FINAL', record, Colors.black),
                    _buildStatColumn('DIVISIÓN', division, Colors.black87),
                    _buildStatColumn('GUARDIA', stance, Colors.black87),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.black.withValues(alpha: 0.1)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.trophy,
                      color: Color(0xFFDAA520), // Oro oscuro para contraste
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (extraData['achievements'] is List)
                            ...(extraData['achievements'] as List).map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  (item['text'] ?? '').toString().toUpperCase(),
                                  style: GoogleFonts.lexend(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else
                            Text(
                              achievements.toString().toUpperCase(),
                              style: GoogleFonts.lexend(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 3. Bio / Historia (Editable)
        GestureDetector(
          onTap: widget.isMe
              ? () {
                  _showEditBioDialog(context, bio);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.format_quote, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    bio,
                    style: GoogleFonts.merriweather(
                      color: Colors.white70,
                      height: 1.6,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.isMe)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 12, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Editar Historia',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        // 4. Actividad Actual / Mentoría (Toggle)
        _buildCurrentStatus(context),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lexend(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
      ],
    );
  }

  Widget _buildCurrentStatus(BuildContext context) {
    final bool isMentorAvailable = extraData['isMentorAvailable'] ?? false;

    return GestureDetector(
      onTap: widget.isMe
          ? () {
              _updateProfile({'isMentorAvailable': !isMentorAvailable});
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isMentorAvailable
              ? AppColors.primary.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMentorAvailable
                ? AppColors.primary.withOpacity(0.3)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              FontAwesomeIcons.handshake,
              color: isMentorAvailable ? AppColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMentorAvailable
                        ? 'DISPONIBLE PARA MENTORÍA'
                        : 'NO DISPONIBLE',
                    style: TextStyle(
                      color: isMentorAvailable
                          ? AppColors.primary
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    isMentorAvailable
                        ? 'Contacta para seminarios o charlas.'
                        : 'Actualmente no aceptando propuestas.',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (widget.isMe)
              Switch(
                value: isMentorAvailable,
                onChanged: (val) {
                  _updateProfile({'isMentorAvailable': val});
                },
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withOpacity(0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.black,
              )
            else if (isMentorAvailable)
              ElevatedButton(
                onPressed: () {
                  context.read<AppStore>().startChatWithUser(
                    effectiveData['name'] ?? 'Boxeador',
                    effectiveData['avatar'] ?? '',
                    initialMessage:
                        '¡Hola! Me gustaría contactarte para una mentoría o charla sobre tu carrera.',
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
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('CONTACTAR', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditResumeDialog(BuildContext context) {
    final recordController = TextEditingController(text: extraData['record']);
    final divisionController = TextEditingController(
      text: extraData['weightClass'],
    );
    final stanceController = TextEditingController(text: extraData['stance']);
    final achievementsController = TextEditingController(
      text: extraData['achievements'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Editar Carrera',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Récord Final', recordController),
              const SizedBox(height: 10),
              _buildTextField('División', divisionController),
              const SizedBox(height: 10),
              _buildTextField('Guardia', stanceController),
              const SizedBox(height: 10),
              _buildTextField('Logro Principal', achievementsController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _updateProfile({
                'record': recordController.text,
                'weightClass': divisionController.text,
                'stance': stanceController.text,
                'achievements': achievementsController.text,
              });
              Navigator.pop(context);
            },
            child: const Text(
              'GUARDAR',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBioDialog(BuildContext context, String currentBio) {
    final bioController = TextEditingController(text: currentBio);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Editar Historia',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: bioController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Escribe sobre tu carrera...',
            hintStyle: TextStyle(color: Colors.white30),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _updateProfile({}, newBio: bioController.text);
              Navigator.pop(context);
            },
            child: const Text(
              'GUARDAR',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
