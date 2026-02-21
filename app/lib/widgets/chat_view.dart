import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import '../core/app_colors.dart';
import '../services/app_store.dart';
import '../widgets/custom_video_player.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Audio Recording State
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _showEmojiPicker = false;
  bool _showParticipants = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final chats = store.chats;
    final activeChatId = store.activeChatId;
    final activeChat = chats.firstWhere(
      (c) => c['id'] == activeChatId,
      orElse: () => chats.first,
    );

    return Container(
      height: MediaQuery.of(context).size.height - 150,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmall = constraints.maxWidth < 600;

          if (isSmall) {
            // Mobile: Stack to Float Participants
            return Stack(
              children: [
                _buildChatWindow(context, activeChat),
                if (_showParticipants)
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withValues(alpha: 0.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 15,
                            offset: const Offset(-5, 0),
                          ),
                        ],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: _buildParticipantsSidebar(context, activeChat),
                    ),
                  ),
              ],
            );
          }

          // Desktop: Existing Row Layout (Titanium Rule)
          return Row(
            children: [
              Expanded(child: _buildChatWindow(context, activeChat)),
              if (_showParticipants) ...[
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                _buildParticipantsSidebar(context, activeChat),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatSidebar(
    BuildContext context,
    List<Map<String, dynamic>> chats,
    String? activeId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          if (true) // Siempre mostrar buscador en el modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar chat...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatItem(false, chat['id'] == activeId, chat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(bool isSmall, bool active, Map<String, dynamic> chat) {
    return GestureDetector(
      onTap: () {
        context.read<AppStore>().setActiveChat(chat['id']);
        // Cierra el modal si está abierto (para móvil/modal view)
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 15,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: active
              ? const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: isSmall
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2A2A2A),
                  backgroundImage: NetworkImage(chat['avatar'] ?? ''),
                ),
                if (chat['status'] == 'active')
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgCard, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            if (!isSmall) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      chat['msgs']?.isNotEmpty == true
                          ? chat['msgs'].last['text']
                          : 'Sin mensajes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (chat['msgs']?.isNotEmpty == true)
                Text(
                  chat['msgs'].last['time'],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatWindow(BuildContext context, Map<String, dynamic> chat) {
    _scrollToBottom();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.people_alt_outlined,
                  color: Colors.white,
                ),
                onPressed: () => _showChatListModal(context),
                tooltip: 'Mis Chats',
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: const Color(0xFF2A2A2A),
                backgroundImage: NetworkImage(chat['avatar'] ?? ''),
              ),
              const SizedBox(width: 15),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      chat['id'] == 'general'
                          ? 'Comunidad'
                          : (chat['status'] == 'active'
                                ? 'En línea'
                                : 'Pendiente'),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.people_alt_outlined,
                  color: _showParticipants
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _showParticipants = !_showParticipants),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),

        // Messages or Status Area
        Expanded(child: _buildChatContent(context, chat)),

        // Input Area
        if (chat['status'] == 'active') _buildChatInput(context, chat['id']),
      ],
    );
  }

  Widget _buildChatContent(BuildContext context, Map<String, dynamic> chat) {
    if (chat['status'] == 'blocked') {
      return const Center(
        child: Text(
          'Has bloqueado a este usuario.',
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (chat['status'] == 'pending') {
      final user = context.read<AppStore>().currentUser;
      if (chat['initiator'] == user?.name) {
        return Center(
          child: Text(
            'Has enviado una solicitud a ${chat['name']}.\nEspera a que acepte para chatear.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(chat['avatar'] ?? ''),
              ),
              const SizedBox(height: 20),
              Text(
                '${chat['name']} quiere chatear contigo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AppStore>().acceptChat(chat['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('ACEPTAR'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {}, // Block logic?
                    child: const Text(
                      'BLOQUEAR',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }

    final List msgs = chat['msgs'] ?? [];
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: msgs.length,
      itemBuilder: (context, index) {
        final msg = msgs[index];
        if (msg['isSystem'] == true) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              msg['text'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          );
        }
        return _buildMessage(context, msg, chatId: chat['id']);
      },
    );
  }

  Widget _buildMessage(
    BuildContext context,
    Map<String, dynamic> msg, {
    required String chatId,
  }) {
    final bool isMe = msg['self'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF2A2A2A),
              child: Text('🥊', style: TextStyle(fontSize: 10)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (true) // Siempre mostrar nombre y rol para mayor claridad
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      '${isMe ? 'Yo' : (msg['user'] ?? '')} ${msg['role'] != null ? ' • ${msg['role']}' : ''}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF005C4B)
                        : const Color(0xFF202C33),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topRight: isMe
                          ? const Radius.circular(0)
                          : const Radius.circular(16),
                      topLeft: !isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg['text'] != null &&
                          msg['text'].toString().isNotEmpty)
                        Text(
                          msg['text'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      if (msg['image'] != null) ...[
                        if (msg['text'] != null &&
                            msg['text'].toString().isNotEmpty)
                          const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: msg['image'].toString().startsWith('data:')
                              ? Image.memory(
                                  base64Decode(
                                    msg['image'].toString().split(',').last,
                                  ),
                                  fit: BoxFit.cover,
                                  width: 200,
                                )
                              : Image.network(
                                  msg['image'],
                                  fit: BoxFit.cover,
                                  width: 200,
                                ),
                        ),
                      ],
                      if (msg['video'] != null) ...[
                        if (msg['text'] != null || msg['image'] != null)
                          const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomVideoPlayer(
                            videoUrl: msg['video'],
                            height: 150,
                            // width se ajusta al contenedor
                          ),
                        ),
                      ],
                      if (msg['audio'] != null) ...[
                        if (msg['text'] != null &&
                            msg['text'].toString().isNotEmpty)
                          const SizedBox(height: 8),
                        _AudioBubblePlayer(audioSource: msg['audio']),
                      ],
                      if (msg['type'] == 'team_request' && !isMe) ...[
                        const SizedBox(height: 15),
                        Consumer<AppStore>(
                          builder: (context, store, child) {
                            final myTeam =
                                store.currentUser?.extraData['team_members']
                                    as List?;
                            final alreadyInTeam =
                                myTeam?.any(
                                  (m) => m['userId'] == msg['senderId'],
                                ) ??
                                false;

                            if (alreadyInTeam) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'SOLICITUD ACEPTADA',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ElevatedButton(
                              onPressed: () {
                                store.acceptTeamRequest(
                                  chatId: chatId,
                                  senderId: msg['senderId'],
                                  senderName: msg['user'],
                                  requestedRole: msg['requestedRole'],
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'ACEPTAR SOLICITUD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      if (msg['type'] == 'sponsor_request' && !isMe) ...[
                        const SizedBox(height: 15),
                        Consumer<AppStore>(
                          builder: (context, store, child) {
                            final mySponsorships =
                                store.currentUser?.extraData['sponsorships']
                                    as List?;
                            final alreadySponsoring =
                                mySponsorships?.any(
                                  (m) => m['userId'] == msg['senderId'],
                                ) ??
                                false;

                            if (alreadySponsoring) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'PATROCINIO ACEPTADO',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ElevatedButton(
                              onPressed: () {
                                store.acceptSponsorRequest(
                                  chatId: chatId,
                                  senderId: msg['senderId'],
                                  senderName: msg['user'],
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'ACEPTAR PATROCINIO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg['time'] ?? '',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _forwardMessage(context, msg),
                        child: const Icon(
                          Icons.forward_outlined,
                          size: 14,
                          color: Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          context.read<AppStore>().deleteMessage(
                            chatId,
                            msg['id'],
                          );
                        },
                        child: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildChatInput(BuildContext context, String chatId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _showEmojiPicker
                      ? Icons.keyboard
                      : Icons.emoji_emotions_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() => _showEmojiPicker = !_showEmojiPicker);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.textMuted,
                ),
                onPressed: () => _pickMultimedia(context, chatId),
              ),
              Expanded(
                child: TextField(
                  controller: _msgController,
                  onChanged: (_) =>
                      setState(() {}), // Trigger recon para icono mic/send
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(context, chatId),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_isRecording)
                IconButton(
                  icon: const Icon(Icons.stop_circle, color: Colors.red),
                  onPressed: () => _stopRecording(context, chatId),
                )
              else if (_msgController.text.trim().isEmpty)
                IconButton(
                  icon: const Icon(Icons.mic, color: AppColors.primary),
                  onPressed: () => _startRecording(),
                )
              else
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () => _sendMessage(context, chatId),
                ),
            ],
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: emoji.EmojiPicker(
                onEmojiSelected: (category, emojItem) {
                  _msgController.text += emojItem.emoji;
                  setState(() {});
                },
                config: emoji.Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: emoji.EmojiViewConfig(
                    backgroundColor: const Color(0xFF1A1A1A),
                    columns: 7,
                    emojiSizeMax: 32,
                    buttonMode: emoji.ButtonMode.MATERIAL,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const config = RecordConfig();
        // En web se usa un path temporal o memory
        await _audioRecorder.start(config, path: '');
        setState(() => _isRecording = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de micrófono denegado 🚫'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al grabar: No se detecta micrófono 🎤'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording(BuildContext context, String chatId) async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        // En web, el path suele ser una URL blob
        final user = context.read<AppStore>().currentUser;
        final msg = {
          'user': user?.name ?? 'Anónimo',
          'text': '',
          'time': TimeOfDay.now().format(context),
          'self': true,
          'audio': path,
        };
        context.read<AppStore>().addMessage(chatId, msg);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  void _forwardMessage(BuildContext context, Map<String, dynamic> msg) {
    final store = context.read<AppStore>();
    final chats = store.chats;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reenviar a...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.share, color: Colors.white, size: 20),
                ),
                title: const Text(
                  'Compartir Externo (WhatsApp, etc)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    '${msg['text'] ?? ''}\nEnviado desde Tierra de Campeones 🥊',
                  );
                },
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(chat['avatar'] ?? ''),
                        backgroundColor: Colors.transparent,
                      ),
                      title: Text(
                        chat['name'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        // Lógica de reenvío: Copiar el mensaje al chat elegido
                        final newMsg = Map<String, dynamic>.from(msg);
                        newMsg['id'] = DateTime.now().millisecondsSinceEpoch
                            .toString();
                        newMsg['time'] = TimeOfDay.now().format(context);
                        newMsg['self'] =
                            true; // El usuario lo está reenviando hoy

                        store.addMessage(chat['id'], newMsg);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reenviado a ${chat['name']} 🥊'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMultimedia(BuildContext context, String chatId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'mp4', 'mov'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final file = result.files.first;
        final extension = file.extension?.toLowerCase() ?? '';
        final isVideo = ['mp4', 'mov'].contains(extension);

        _showMultimediaPreview(
          context,
          chatId,
          file.bytes!,
          extension,
          isVideo,
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _showMultimediaPreview(
    BuildContext context,
    String chatId,
    Uint8List bytes,
    String extension,
    bool isVideo,
  ) {
    final TextEditingController captionController = TextEditingController(
      text: _msgController.text.trim(),
    );
    final mimeType = isVideo ? 'video/$extension' : 'image/$extension';
    final base64String = 'data:$mimeType;base64,${base64Encode(bytes)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Previsualización',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isVideo
                          ? CustomVideoPlayer(
                              videoUrl: base64String, // base64 URL
                              height: 300,
                            )
                          : Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: captionController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Añade un comentario...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) {
                    final user = context.read<AppStore>().currentUser;
                    final msg = {
                      'user': user?.name ?? 'Anónimo',
                      'role': user?.roleName,
                      'text': captionController.text.trim(),
                      'time': TimeOfDay.now().format(context),
                      'self': true,
                      isVideo ? 'video' : 'image': base64String,
                    };
                    context.read<AppStore>().addMessage(chatId, msg);
                    _msgController.clear(); // Limpiamos el input principal
                    Navigator.pop(context);
                    _scrollToBottom();
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    final user = context.read<AppStore>().currentUser;
                    final msg = {
                      'user': user?.name ?? 'Anónimo',
                      'role': user?.roleName,
                      'text': captionController.text.trim(),
                      'time': TimeOfDay.now().format(context),
                      'self': true,
                      isVideo ? 'video' : 'image': base64String,
                    };
                    context.read<AppStore>().addMessage(chatId, msg);
                    _msgController.clear(); // Limpiamos el input principal
                    Navigator.pop(context);
                    _scrollToBottom();
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendMessage(BuildContext context, String chatId) {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AppStore>().currentUser;
    final msg = {
      'user': user?.name ?? 'Anónimo',
      'role': user?.roleName,
      'text': text,
      'time': TimeOfDay.now().format(context),
      'self': true,
    };

    context.read<AppStore>().addMessage(chatId, msg);
    _msgController.clear();
    setState(() {}); // Forzar rebuild para cambio de icono mic/send
    _scrollToBottom();
  }

  void _showChatListModal(BuildContext context) {
    final store = context.read<AppStore>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _buildChatSidebar(
                  context,
                  store.chats,
                  store.activeChatId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantsSidebar(
    BuildContext context,
    Map<String, dynamic> chat,
  ) {
    final List msgs = chat['msgs'] ?? [];
    // Extraer nombres únicos de los mensajes para simular participantes
    final Set<String> participants = {'Admin'};
    for (var m in msgs) {
      if (m['user'] != null) participants.add(m['user']);
    }

    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EN EL RING',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              // Botón de cierre para móvil (Misión Marte)
              Builder(
                builder: (context) {
                  final bool isSmall = MediaQuery.of(context).size.width < 600;
                  if (!isSmall) return const SizedBox.shrink();
                  return IconButton(
                    onPressed: () => setState(() => _showParticipants = false),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: participants.map((name) {
                bool isOnline =
                    name == 'Admin' ||
                    name == 'Neri Muñoz' ||
                    name == 'Coach Rick';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.bgCard,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioBubblePlayer extends StatefulWidget {
  final String audioSource;
  const _AudioBubblePlayer({required this.audioSource});

  @override
  State<_AudioBubblePlayer> createState() => _AudioBubblePlayerState();
}

class _AudioBubblePlayerState extends State<_AudioBubblePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () async {
              if (_isPlaying) {
                await _player.pause();
                setState(() => _isPlaying = false);
              } else {
                await _player.play(UrlSource(widget.audioSource));
                setState(() => _isPlaying = true);
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1,
                activeColor: Colors.white,
                inactiveColor: Colors.white24,
                onChanged: (v) =>
                    _player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
