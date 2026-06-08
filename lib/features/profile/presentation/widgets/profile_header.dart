import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            // Аватарка
            CircleAvatar(
              radius: 50.r,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                  ? Icon(Icons.person, size: 50.r, color: Colors.white)
                  : null,
            ),
            SizedBox(height: 16.h),

            // Блок: Титул + Ник + Флаг
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w, // Отступ между элементами
              children: [
                // ТИТУЛ (показывается только если не null и не пустой)
                if (profile.title != null && profile.title!.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700, // Стиль Chess.com
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      profile.title!.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // НИКНЕЙМ
                Text(
                  profile.nickname,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ФЛАГ
                if (profile.countryCode != null && profile.countryCode!.isNotEmpty)
                  Text(
                    _getEmojiFlag(profile.countryCode),
                    style: TextStyle(fontSize: 22.sp),
                  ),
              ],
            ),

            SizedBox(height: 8.h),

            // Игровой ID
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'ID: ${profile.displayId}',
                style: TextStyle(
                  fontSize: 13.sp,
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
