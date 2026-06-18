import 'package:flutter/material.dart';

/// Ana akış ekranı — Faz 2'de mock vaka/soru kartlarıyla doldurulacak.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                Icons.medical_services_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'DentLink',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
              tooltip: 'Bildirimler',
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Kronolojik'),
              Tab(text: 'Algoritmik'),
            ],
            indicatorColor: colorScheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlaceholderFeed(context, 'Kronolojik Akış'),
            _buildPlaceholderFeed(context, 'Algoritmik Akış'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderFeed(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dynamic_feed_outlined,
            size: 72,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Faz 2\'de vaka ve soru kartları burada görünecek.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
