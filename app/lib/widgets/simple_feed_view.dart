import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../core/app_colors.dart';

class SimpleFeedView extends StatelessWidget {
  const SimpleFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<AppStore>().posts;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          _buildCreatePostCard(context),
          const SizedBox(height: 20),
          ...posts.map((post) => PostCard(postData: post)),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard(BuildContext context) {
    final TextEditingController postController = TextEditingController();
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
                  controller: postController,
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
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          Row(
            children: [
              _buildPostAction(FontAwesomeIcons.image, 'Imagen'),
              const SizedBox(width: 10),
              _buildPostAction(FontAwesomeIcons.video, 'Video'),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (postController.text.isNotEmpty) {
                    context.read<AppStore>().addPost(postController.text);
                    postController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('PUBLICAR'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label) {
    return TextButton.icon(
      icon: FaIcon(icon, size: 14, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      onPressed: () {},
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
    final post = widget.postData;
    final String postId = post['id'];
    final int likes = post['likes'] ?? 0;
    final List comments = post['comments'] ?? [];
    final bool isLiked = (post['likedBy'] as List).contains(
      context.watch<AppStore>().currentUser?.name,
    );

    Color likeColor = AppColors.textMuted;
    if (likes >= 1) likeColor = Colors.red;

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
                CircleAvatar(
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: Text(_getRoleEmoji(post['roleKey'])),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['userName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      post['userRole'],
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
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
                  onPressed: isLiked
                      ? null
                      : () => context.read<AppStore>().toggleLike(postId),
                ),
                _buildInteractionBtn(
                  FontAwesomeIcons.comment,
                  'COMENTAR',
                  count: comments.length,
                  onPressed: () =>
                      setState(() => _showComments = !_showComments),
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
                      child: Text(
                        '${c['user']}: ${c['text']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
                            hintText: 'Comentar...',
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
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          if (_commentController.text.isNotEmpty) {
                            context.read<AppStore>().addComment(
                              postId,
                              _commentController.text,
                            );
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
}
