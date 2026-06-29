import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/stat_count.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class ProfileStats extends StatelessWidget {
  final UserModel user;

  const ProfileStats({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatCount(
            icon: Icons.article_outlined,
            label: 'Gönderi',
            count: user.postsCount,
          ),
          InkWell(
            onTap: () => context.push('/network/${user.id}?tab=0'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing8),
              child: StatCount(
                icon: Icons.people_outline,
                label: 'Takipçi',
                count: user.followersCount,
              ),
            ),
          ),
          InkWell(
            onTap: () => context.push('/network/${user.id}?tab=1'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing8),
              child: StatCount(
                icon: Icons.person_add_outlined,
                label: 'Takip Edilen',
                count: user.followingCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
