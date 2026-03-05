import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/locale_provider.dart';

class OpeningsScreen extends StatelessWidget {
  const OpeningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    final openings = [
      // Белые начала
      {
        'category': 'Белые',
        'items': [
          {'eco': 'E4', 'name': 'Королевский гамбит', 'moves': '1.e4 e5 2.f4', 'popularity': 95, 'winRate': 52},
          {'eco': 'D4', 'name': 'Ферзевый гамбит', 'moves': '1.d4 d5 2.c4', 'popularity': 88, 'winRate': 54},
          {'eco': 'E4', 'name': 'Итальянская партия', 'moves': '1.e4 e5 2.Nf3 Nc6 3.Bc4', 'popularity': 92, 'winRate': 53},
          {'eco': 'E4', 'name': 'Испанская партия', 'moves': '1.e4 e5 2.Nf3 Nc6 3.Bb5', 'popularity': 90, 'winRate': 55},
          {'eco': 'E4', 'name': 'Сицилианская защита', 'moves': '1.e4 c5', 'popularity': 98, 'winRate': 50, 'note': 'Чёрные'},
          {'eco': 'D4', 'name': 'Английское начало', 'moves': '1.c4', 'popularity': 75, 'winRate': 53},
        ],
      },
      // Чёрные защиты
      {
        'category': 'Чёрные',
        'items': [
          {'eco': 'E5', 'name': 'Сицилианская защита', 'moves': '1.e4 c5', 'popularity': 98, 'winRate': 50},
          {'eco': 'E5', 'name': 'Французская защита', 'moves': '1.e4 e6', 'popularity': 85, 'winRate': 49},
          {'eco': 'E5', 'name': 'Каро-Канн', 'moves': '1.e4 c6', 'popularity': 82, 'winRate': 51},
          {'eco': 'E5', 'name': 'Пирц-Уфимцев', 'moves': '1.e4 d6', 'popularity': 70, 'winRate': 48},
          {'eco': 'D5', 'name': 'Славянская защита', 'moves': '1.d4 d5 2.c4 c6', 'popularity': 88, 'winRate': 50},
          {'eco': 'D5', 'name': 'Защита Нимцовича', 'moves': '1.d4 Nf6 2.c4 e6 3.Nc3 Bb4', 'popularity': 86, 'winRate': 51},
        ],
      },
      // Универсальные
      {
        'category': 'Универсальные',
        'items': [
          {'eco': 'A0', 'name': 'Рети', 'moves': '1.Nf3', 'popularity': 78, 'winRate': 53},
          {'eco': 'A0', 'name': 'Английское начало', 'moves': '1.c4', 'popularity': 75, 'winRate': 53},
          {'eco': 'A0', 'name': 'Бенони', 'moves': '1.d4 Nf6 2.c4 c5', 'popularity': 65, 'winRate': 49},
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('openings_title')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, // TODO: поиск дебютов
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: openings.length,
        itemBuilder: (context, index) {
          final category = openings[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок категории
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Text(
                  category['category'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Сетка дебютов
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: (category['items'] as List).length,
                itemBuilder: (context, itemIndex) {
                  final opening = (category['items'] as List)[itemIndex];
                  return _OpeningCard(
                    eco: opening['eco'] as String,
                    name: opening['name'] as String,
                    moves: opening['moves'] as String,
                    popularity: opening['popularity'] as int,
                    winRate: opening['winRate'] as int,
                    onTap: () => context.push('/learn/openings/${opening['eco']}'),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _OpeningCard extends StatelessWidget {
  final String eco;
  final String name;
  final String moves;
  final int popularity;
  final int winRate;
  final VoidCallback onTap;

  const _OpeningCard({
    required this.eco,
    required this.name,
    required this.moves,
    required this.popularity,
    required this.winRate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ECO код и популярность
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      eco,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        '$popularity%',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Название дебюта
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              // Ходы
              Text(
                moves,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Винрейт
              Row(
                children: [
                  const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '$winRate%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}