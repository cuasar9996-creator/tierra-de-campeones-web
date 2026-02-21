import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../services/app_store.dart';
import '../core/app_colors.dart';
// import 'athlete_profile_view.dart';
import 'custom_video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MainFeedView extends StatelessWidget {
  const MainFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<AppStore>().posts;
    return Column(
      children: [
        // Posts scrolleables
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            reverse: false,
            itemCount: posts.length,
            itemBuilder: (context, index) => PostCard(postData: posts[index]),
          ),
        ),
        // Barra de publicación fija ABAJO 📌
        const CreatePostArea(),
      ],
    );
  }
}

class CreatePostArea extends StatefulWidget {
  const CreatePostArea({super.key});

  @override
  State<CreatePostArea> createState() => _CreatePostAreaState();
}

class _CreatePostAreaState extends State<CreatePostArea> {
  final TextEditingController _postController = TextEditingController();
  String? _selectedImage;
  String? _selectedVideo;

  // Speech to Text 🎤
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _baseText = ''; // Texto antes de empezar a escuchar
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await _speech.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          debugPrint('Speech error: $val');
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          // Guardar el texto actual como base
          _baseText = _postController.text;
          if (_baseText.isNotEmpty && !_baseText.endsWith(' ')) {
            _baseText += ' ';
          }
        });

        _speech.listen(
          localeId: 'es_ES', // Forzar español para mejor precisión
          onResult: (val) => setState(() {
            if (val.recognizedWords.isNotEmpty) {
              // Reemplazar el texto final con base + lo reconocido ACTUAL
              _postController.text = _baseText + val.recognizedWords;

              // Mover cursor al final
              _postController.selection = TextSelection.fromPosition(
                TextPosition(offset: _postController.text.length),
              );
            }
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _pickFile(bool isVideo) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: isVideo ? FileType.video : FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final platformFile = result.files.first;
        final bytes = platformFile.bytes!;
        final extension = platformFile.extension ?? (isVideo ? 'mp4' : 'png');
        final mimeType = isVideo ? 'video/$extension' : 'image/$extension';
        final base64String = 'data:$mimeType;base64,${base64Encode(bytes)}';

        setState(() {
          if (isVideo) {
            _selectedVideo = base64String;
            _selectedImage = null;
          } else {
            _selectedImage = base64String;
            _selectedVideo = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2A2A2A),
                child: Text(
                  context.watch<AppStore>().currentUser?.roleKey == 'pro-boxer'
                      ? '🥊'
                      : '👤',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _postController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '¿Qué hay de nuevo en el ring?',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón de Micro 🎤
              GestureDetector(
                onTap: _listen,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.red.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isListening ? Colors.red : AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedImage != null || _selectedVideo != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black26,
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(_selectedImage!.split(',').last),
                            fit: BoxFit.cover,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomVideoPlayer(
                            key: ValueKey(_selectedVideo),
                            videoUrl: _selectedVideo!,
                            height: 150,
                          ),
                        ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedImage = null;
                      _selectedVideo = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          Row(
            children: [
              _buildPostAction(
                FontAwesomeIcons.image,
                'Imagen',
                () => _pickFile(false),
              ),
              const SizedBox(width: 10),
              _buildPostAction(
                FontAwesomeIcons.video,
                'Video',
                () => _pickFile(true),
              ),
              const SizedBox(width: 10),
              _buildPostAction(FontAwesomeIcons.calendarCheck, 'Evento', () {}),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  if (_postController.text.isNotEmpty ||
                      _selectedImage != null ||
                      _selectedVideo != null) {
                    // Mostrar indicador de carga simple o snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Publicando...')),
                    );

                    try {
                      await context.read<AppStore>().addPost(
                        _postController.text,
                        image: _selectedImage,
                        video: _selectedVideo,
                      );

                      _postController.clear();
                      setState(() {
                        _selectedImage = null;
                        _selectedVideo = null;
                      });
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al publicar: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text(
                  'PUBLICAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label, VoidCallback onTap) {
    return TextButton.icon(
      icon: FaIcon(icon, size: 14, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostCard({super.key, required this.postData});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final post = widget.postData;
    final String postId = post['id'];
    final int likes = post['likes'] ?? 0;
    final List comments = post['comments'] ?? [];
    // Soporta tanto 'isLiked' (Supabase) como 'likedBy' (legacy local)
    final bool isLiked =
        post['isLiked'] == true ||
        ((post['likedBy'] as List?) ?? []).contains(store.currentUser?.name);
    // Soporta tanto campos de Supabase (user/role) como Dev mode (userName/userRole)
    final String authorName = post['user'] ?? post['userName'] ?? 'Usuario';
    final String authorRole = post['role'] ?? post['userRole'] ?? '';
    final String authorRoleKey = post['roleKey'] ?? '';
    final String? authorAvatar = post['userAvatar'];
    final bool isOwner =
        post['user_id'] == store.currentUser?.userId ||
        post['ownerId'] == store.currentUser?.userId;

    // Dynamic like color based on original JS logic
    Color likeColor = AppColors.textMuted;
    if (likes >= 1 && likes < 2) {
      likeColor = Colors.red;
    } else if (likes >= 2 && likes < 3) {
      likeColor = Colors.amber.shade900;
    } else if (likes >= 3 && likes < 4) {
      likeColor = Colors.blueGrey.shade300;
    } else if (likes >= 4 && likes < 5) {
      likeColor = Colors.yellow;
    } else if (likes >= 5 && likes < 6) {
      likeColor = Colors.tealAccent;
    } else if (likes >= 6) {
      likeColor = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    final store = context.read<AppStore>();
                    final authorId =
                        post['user_id'] ?? post['ownerId'] ?? post['id'];
                    store.navigateToProfile(
                      context,
                      authorId,
                      fallbackData: {
                        'name': authorName,
                        'role': authorRole,
                        'roleKey': authorRoleKey,
                        'avatar': authorAvatar ?? '',
                      },
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2A2A2A),
                        child: Text(_getRoleEmoji(authorRoleKey)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                authorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (post['isVerified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 14,
                                ),
                              ],
                              const SizedBox(width: 5),
                              Text(
                                _getRoleEmoji(authorRoleKey),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          Text(
                            authorRole,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isOwner)
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.trashCan,
                      size: 14,
                      color: Colors.white24,
                    ),
                    onPressed: () => _confirmDelete(context, postId),
                  ),
                const Icon(Icons.more_horiz, color: AppColors.textMuted),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              post['content'],
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          if (post['image'] != null && post['image'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: post['image'].toString().startsWith('data:image')
                    ? Image.memory(
                        base64Decode(post['image']!.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        post['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
              ),
            ),
          if (post['video'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomVideoPlayer(videoUrl: post['video'], height: 250),
              ),
            ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInteractionBtn(
                  null,
                  'CHOCAR',
                  customIcon: const Text('🥊', style: TextStyle(fontSize: 16)),
                  color: isLiked ? Colors.red : likeColor,
                  count: likes,
                  onPressed: () => store.toggleLike(postId),
                ),
                _buildInteractionBtn(
                  FontAwesomeIcons.comment,
                  'COMENTAR',
                  count: comments.length,
                  onPressed: () {
                    final newState = !_showComments;
                    if (newState) {
                      store.loadCommentsForPost(postId);
                    }
                    setState(() => _showComments = newState);
                  },
                ),
                _buildInteractionBtn(
                  FontAwesomeIcons.shareFromSquare,
                  'COMPARTIR',
                  onPressed: () {
                    final String shareText =
                        'Mira este post de ${post['userName']} en Tierra de Campeones: ${post['content']}';
                    Share.share(shareText);
                  },
                ),
              ],
            ),
          ),
          if (_showComments) ...[
            const Divider(color: Colors.white10, height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...comments.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${c['user']}: ',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: c['text'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Escribe un comentario...',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: Colors.black26,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          if (_commentController.text.isNotEmpty) {
                            store.addComment(postId, _commentController.text);
                            _commentController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionBtn(
    IconData? icon,
    String label, {
    Widget? customIcon,
    Color? color,
    int? count,
    VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon:
          customIcon ??
          FaIcon(icon!, size: 14, color: color ?? AppColors.textMuted),
      label: Text(
        count != null && count > 0 ? '$count' : label,
        style: TextStyle(color: color ?? AppColors.textMuted, fontSize: 12),
      ),
    );
  }

  String _getRoleEmoji(String? roleKey) {
    const map = {
      'pro-boxer': '🥊',
      'amateur-boxer': '🥇',
      'coach': '🧢',
      'fan': '🎟️',
      'promoter': '💼',
      'cutman': '🩹',
      'gym-owner': '🏢',
      'cadet': '👦',
      'recreational': '🏋️‍♂️',
      'medic': '🩺',
      'nutritionist': '🥗',
      'psychologist': '🧠',
      'journalist': '🎤',
      'judge': '⚖️',
    };
    return map[roleKey] ?? '👤';
  }

  void _confirmDelete(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '¿Eliminar publicación?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStore>().deletePost(postId);
              Navigator.pop(context);
            },
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
