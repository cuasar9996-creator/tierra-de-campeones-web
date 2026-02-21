import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../core/app_colors.dart';
import '../services/app_store.dart';

class SocialStatsWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isMe;

  const SocialStatsWidget({
    super.key,
    required this.userData,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final userId = (userData['userId'] ?? userData['id']).toString();

    return FutureBuilder<Map<String, int>>(
      future: store.getSocialCounts(userId),
      builder: (context, snapshot) {
        final counts =
            snapshot.data ??
            {
              'followers': (userData['followers'] as List?)?.length ?? 0,
              'following': (userData['following'] as List?)?.length ?? 0,
            };
        final List blocked = userData['blocked'] ?? [];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 15,
            children: [
              _buildStatItem(context, 'SEGUIDORES', counts['followers']!, 0),
              _buildStatItem(context, 'SEGUIDOS', counts['following']!, 1),
              if (isMe)
                _buildStatItem(context, 'BLOQUEADOS', blocked.length, 2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int count,
    int initialTab,
  ) {
    return InkWell(
      onTap: () => _showSocialModal(context, initialTab),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 10,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSocialModal(BuildContext context, int initialTab) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SocialModalContent(
        initialTab: initialTab,
        userData: userData,
        isMe: isMe,
      ),
    );
  }
}

class SocialModalContent extends StatefulWidget {
  final int initialTab;
  final Map<String, dynamic> userData;
  final bool isMe;

  const SocialModalContent({
    super.key,
    required this.initialTab,
    required this.userData,
    required this.isMe,
  });

  @override
  State<SocialModalContent> createState() => _SocialModalContentState();
}

class _SocialModalContentState extends State<SocialModalContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isMe ? 3 : 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, widget.isMe ? 2 : 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final userId = (widget.userData['userId'] ?? widget.userData['id'])
        .toString();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              const Tab(text: 'SEGUIDORES'),
              const Tab(text: 'SEGUIDOS'),
              if (widget.isMe) const Tab(text: 'BLOQUEADOS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SupabaseUserList(
                  userId: userId,
                  type: 'followers',
                  future: store.getFollowersList(userId),
                ),
                _SupabaseUserList(
                  userId: userId,
                  type: 'following',
                  future: store.getFollowingList(userId),
                ),
                if (widget.isMe)
                  _UserList(
                    userIds: widget.userData['blocked'] ?? [],
                    type: 'blocked',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupabaseUserList extends StatelessWidget {
  final String userId;
  final String type;
  final Future<List<String>> future;

  const _SupabaseUserList({
    required this.userId,
    required this.type,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final ids = snapshot.data ?? [];
        return _UserList(userIds: ids, type: type);
      },
    );
  }
}

class _UserList extends StatelessWidget {
  final List userIds;
  final String type;

  const _UserList({required this.userIds, required this.type});

  @override
  Widget build(BuildContext context) {
    if (userIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'blocked'
                  ? FontAwesomeIcons.userSlash
                  : FontAwesomeIcons.users,
              size: 40,
              color: Colors.white10,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios en esta lista',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index].toString();
        return FutureBuilder<Map<String, dynamic>?>(
          future: context.read<AppStore>().getUserProfileById(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final user = snapshot.data!;
            return _UserTile(user: user, type: type);
          },
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final String type;

  const _UserTile({required this.user, required this.type});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isFollowing = store.isFollowing(user['userId'] ?? user['id'] ?? '');
    final isMe = store.currentUser?.userId == (user['userId'] ?? user['id']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.bgCard,
            backgroundImage:
                (user['avatar'] != null && user['avatar'].toString().isNotEmpty)
                ? _getAvatarImage(user['avatar'])
                : null,
            child: (user['avatar'] == null || user['avatar'].toString().isEmpty)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user['name'] ?? 'Usuario').toString().toUpperCase(),
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  (user['role'] ?? user['userRole'] ?? 'Campeón')
                      .toString()
                      .toUpperCase(),
                  style: const TextStyle(color: AppColors.accent, fontSize: 10),
                ),
              ],
            ),
          ),
          if (!isMe)
            type == 'blocked'
                ? TextButton(
                    onPressed: () =>
                        store.unblockUser(user['userId'] ?? user['id']),
                    child: const Text(
                      'DESBLOQUEAR',
                      style: TextStyle(color: AppColors.primary, fontSize: 10),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      final uid = (user['userId'] ?? user['id']).toString();
                      if (isFollowing) {
                        store.unfollowUser(uid);
                      } else {
                        store.followUser(uid);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Colors.white10
                          : AppColors.primary,
                      foregroundColor: isFollowing
                          ? Colors.white
                          : Colors.white,
                      minimumSize: const Size(80, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      isFollowing ? 'SIGUIENDO' : 'SEGUIR',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  ImageProvider _getAvatarImage(String avatarData) {
    if (avatarData.startsWith('data:image')) {
      try {
        final base64String = avatarData.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return const NetworkImage('https://via.placeholder.com/150');
      }
    } else {
      return NetworkImage(
        avatarData.isEmpty ? 'https://via.placeholder.com/150' : avatarData,
      );
    }
  }
}
