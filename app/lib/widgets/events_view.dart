import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/app_store.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  String _activeTab = 'Próximos';

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AppStore>().events;

    // Simple filter for future/past
    final today = DateTime.now();
    final filtered = events.where((e) {
      try {
        final evDate = DateTime.parse(e['date'].toString());
        if (_activeTab == 'Próximos') {
          return evDate.isAfter(today.subtract(const Duration(days: 1)));
        }
        return evDate.isBefore(today);
      } catch (_) {
        return _activeTab == 'Próximos';
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📅 CALENDARIO DE EVENTOS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Próximas veladas y torneos confirmados',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => _showCreateEventDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('NUEVO EVENTO'),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Tabs
        Row(
          children: [
            _buildEventTab('Próximos'),
            const SizedBox(width: 20),
            _buildEventTab('Pasados'),
          ],
        ),
        const SizedBox(height: 20),

        // Grid
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Text(
                'No hay eventos ${_activeTab.toLowerCase()}.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          _buildEventsGrid(filtered),
      ],
    );
  }

  Widget _buildEventTab(String label) {
    final bool active = _activeTab == label;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsGrid(List<Map<String, dynamic>> events) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 600,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        mainAxisExtent: 340,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(context, events[index]);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    DateTime? dt;
    try {
      dt = DateTime.parse(event['date'].toString());
    } catch (_) {}

    final day = dt?.day.toString() ?? '??';
    final month = _getMonthAbbr(dt?.month ?? 0);
    final year = dt?.year.toString() ?? '2025';

    final isUserEvent =
        event['id'].toString().startsWith('u_') ||
        !event['id'].toString().startsWith('demo');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Date Area
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  ),
                ),
                Text(
                  year,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Info Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event['img'] != null &&
                      event['img'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildEventImage(event['img'].toString()),
                      ),
                    ),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['location'] ?? 'A confirmar',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event['price'] == '0' || event['price'] == 'Gratis')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'GRATIS',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event['title'] ?? 'Evento',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (event['authorName'] != null)
                    Text(
                      'Publicado por: ${event['authorName']}${event['authorRole'] != null ? ' • ${event['authorRole']}' : ''}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    event['desc'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event['time'] ?? '??:??',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 15),
                      TextButton.icon(
                        onPressed: () async {
                          final loc = event['location'] ?? '';
                          if (loc.isNotEmpty) {
                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(loc)}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.directions,
                          size: 14,
                          color: Colors.blueAccent,
                        ),
                        label: const Text(
                          'CÓMO LLEGAR',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 11,
                          ),
                        ),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                      const SizedBox(width: 10),
                      if (!isUserEvent && event['authorName'] != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<AppStore>().startChatWithUser(
                              event['authorName'],
                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(event['authorName'])}&background=random',
                              initialMessage:
                                  '¡Hola! Quisiera más información sobre el evento: ${event['title']}',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '✅ Solicitud enviada. Serás redirigido al chat.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_outlined, size: 12),
                          label: const Text(
                            'CONTACTAR',
                            style: TextStyle(fontSize: 10),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 30),
                          ),
                        ),
                      const Spacer(),
                      if (isUserEvent)
                        TextButton(
                          onPressed: () =>
                              _confirmDelete(context, event['id'].toString()),
                          child: const Text(
                            'BORRAR',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            if (event['authorName'] != null) {
                              context.read<AppStore>().startChatWithUser(
                                event['authorName'],
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(event['authorName'])}&background=random',
                                initialMessage:
                                    '¡Hola! Estoy interesado en tu evento: ${event['title']}. (Desde Eventos)',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✅ Solicitud enviada. Serás redirigido al chat.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 0.5,
                            ),
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text(
                            'CONTACTAR',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      '',
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    if (month < 1 || month > 12) return '???';
    return months[month];
  }

  Widget _buildEventImage(String imgData) {
    if (imgData.startsWith('data:image')) {
      try {
        final base64String = imgData.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      } catch (e) {
        return const SizedBox.shrink();
      }
    } else {
      return Image.network(
        imgData,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          '¿Eliminar evento?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStore>().deleteEvent(id);
              Navigator.pop(context);
            },
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final locController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String? base64Image;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text(
            'NUEVO EVENTO',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500, // Limitar ancho para evitar problemas en web
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField('Título', 'Ej: Velada de Boxeo', titleController),
                  _buildField('Ubicación', 'Ej: Gym Knockout', locController),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      '⚠️ Este evento se eliminará automáticamente 12 horas después de su finalización para mantener el calendario limpio.',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Imagen del Evento',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                        withData: true,
                      );
                      if (result != null && result.files.first.bytes != null) {
                        setStateDialog(() {
                          base64Image =
                              'data:image/png;base64,${base64Encode(result.files.first.bytes!)}';
                        });
                      }
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: base64Image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: _buildEventImage(base64Image!),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.white54),
                                SizedBox(height: 8),
                                Text(
                                  'Toca para seleccionar imagen',
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerField(
                          'Fecha',
                          selectedDate.toString().split(' ')[0],
                          () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (d != null)
                              setStateDialog(() => selectedDate = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPickerField(
                          'Hora',
                          selectedTime.format(context),
                          () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (t != null)
                              setStateDialog(() => selectedTime = t);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildField('Precio', 'Ej: 500 o Gratis', priceController),
                  _buildField(
                    'Descripción',
                    'Detalles del evento...',
                    descController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () {
                final user = context.read<AppStore>().currentUser;
                final newEv = {
                  'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
                  'title': titleController.text,
                  'location': locController.text,
                  'desc': descController.text,
                  'price': priceController.text.isEmpty
                      ? 'Gratis'
                      : priceController.text,
                  'date': selectedDate.toIso8601String().split('T')[0],
                  'time': selectedTime.format(context),
                  'img': base64Image ?? '',
                  'authorName': user?.name ?? 'Anónimo',
                  'authorRole': user?.roleName,
                };
                context.read<AppStore>().addEvent(newEv);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Evento publicado exitosamente'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('PUBLICAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
