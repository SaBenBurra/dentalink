import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../shared/utils/error_messages.dart';

class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final WidgetRef ref;
  
  // searchFieldLabel verilmez: MaterialLocalizations'ın yerelleştirilmiş "Ara" etiketi kullanılır.
  UserSearchDelegate(this.ref);

  Future<List<UserModel>>? _future;
  String _lastQuery = '';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (query.trim().length < 2) {
      return Center(child: Text(l10n.searchMinChars));
    }

    if (query != _lastQuery) {
      final q = _lastQuery = query;
      // Debounce: superseded futures skip the request; FutureBuilder ignores their result.
      _future = Future.delayed(const Duration(milliseconds: 300), () {
        if (q != _lastQuery) return const <UserModel>[];
        return ref.read(userRepositoryProvider).searchUsers(q);
      });
    }

    return FutureBuilder<List<UserModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final msg = getErrorMessage(l10n, snapshot.error!);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(msg),
                TextButton(
                  onPressed: () {
                    _lastQuery = ''; // force retry
                    query = query; // trigger rebuild
                  },
                  child: Text(l10n.retry),
                )
              ],
            ),
          );
        }
        
        final users = snapshot.data ?? [];
        
        if (users.isEmpty) {
          return Center(child: Text(l10n.userNotFound));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty 
                    ? NetworkImage(user.avatarUrl!) 
                    : null,
                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) 
                    ? const Icon(Icons.person) 
                    : null,
              ),
              title: Text(user.fullName),
              subtitle: Text('@${user.username}'),
              onTap: () {
                close(context, user);
              },
            );
          },
        );
      },
    );
  }
}
