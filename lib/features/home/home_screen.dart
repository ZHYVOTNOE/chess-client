import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('home_title')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, locale),
          ),
        ],
      ),
      body: Column(
        children: [
          // Слайдшоу событий — растягиваем на доступное пространство
          Expanded(
            child: _EventCarousel(locale: locale),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, LocaleProvider locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.get('logout_title')),
        content: Text(locale.get('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              // TODO: очистить токен, перейти на welcome
              context.go('/');
            },
            child: Text(locale.get('logout')),
          ),
        ],
      ),
    );
  }
}

// Слайдшоу событий дня
class _EventCarousel extends StatefulWidget {
  final LocaleProvider locale;

  const _EventCarousel({required this.locale});

  @override
  State<_EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<_EventCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  // TODO: загружать с сервера
  final List<_DailyEvent> _events = [
    _DailyEvent(
      title: 'Турнир "Весенний блиц"',
      description: 'Призовой фонд 1000 рублей',
      color: Colors.orange,
      icon: Icons.emoji_events,
    ),
    _DailyEvent(
      title: 'Новый урок: Сицилианская защита',
      description: 'Изучите популярный дебют',
      color: Colors.blue,
      icon: Icons.school,
    ),
    _DailyEvent(
      title: 'Дневная задача',
      description: 'Решите 5 задач, получите бонус',
      color: Colors.green,
      icon: Icons.extension,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      final nextPage = (_currentPage + 1) % _events.length;

      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  // Остановка автопрокрутки при ручном свайпе
  void _onUserInteraction() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _onUserInteraction();
              }
              return true;
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              itemCount: _events.length,
              itemBuilder: (context, index) => _EventCard(event: _events[index]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Индикаторы страниц
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _events.length,
                (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final _DailyEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              event.color,
              event.color.withOpacity(0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(event.icon, size: 64, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                event.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  // TODO: действие по событию
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: event.color,
                ),
                child: const Text('Участвовать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyEvent {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  _DailyEvent({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });
}