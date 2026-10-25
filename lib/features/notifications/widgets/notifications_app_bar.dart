import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/providers/notification_provider.dart';
import 'package:dentlink/shared/utils/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const NotificationsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // <-- AppBar'ın varsayılan yüksekliği tanımlandı

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // <-- ref parametresi artık kullanılabilir durumda
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing10,
      ),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Bildirimler',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final messenger = ScaffoldMessenger.of(context);
            ref
                .read(notificationsProvider.notifier)
                .markAllRead()
                .catchError((Object e) => messenger.showSnackBar(
                      SnackBar(content: Text(getErrorMessage(e))),
                    ));
          },
          child: Text(
            'Tümünü Okundu İşaretle',
            style: textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
