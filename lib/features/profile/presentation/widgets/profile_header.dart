import 'package:flutter/material.dart';
import '../../domain/entities/profile_user.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  // Метод для конвертации ISO кода (RU, US) в Emoji флаг
  String _getEmojiFlag(String? countryCode) {
    if (countryCode == null || countryCode.length != 2) return '';
    return countryCode.toUpperCase().replaceAllMapped(
      RegExp(r'[A-Z]'),
          (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Аватарка
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),

            // Блок: Титул + Ник + Флаг
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8, // Отступ между элементами
              children: [
                // ТИТУЛ (показывается только если не null и не пустой)
                if (profile.title != null && profile.title!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700, // Стиль Chess.com
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      profile.title!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // НИКНЕЙМ
                Text(
                  profile.nickname,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ФЛАГ
                if (profile.countryCode != null && profile.countryCode!.isNotEmpty)
                  Text(
                    _getEmojiFlag(profile.countryCode),
                    style: const TextStyle(fontSize: 22),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Игровой ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'ID: ${profile.displayId}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
