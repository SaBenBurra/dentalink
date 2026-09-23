import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_failures.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/repository_providers.dart';

class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final WidgetRef ref;
  
  UserSearchDelegate(this.ref) : super(searchFieldLabel: 'Kullanıcı ara...');

  Future<List<UserModel>>? _future;
  String _lastQuery = '';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.trim().length < 2) {
      return const Center(child: Text('Aramak için en az 2 karakter girin.'));
    }

    if (query != _lastQuery) {
      _lastQuery = query;
      // Debounce and memoize
      _future = Future.delayed(const Duration(milliseconds: 300), () {
        return ref.read(userRepositoryProvider).searchUsers(query);
      });
    }

    return FutureBuilder<List<UserModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final msg = switch (error) {
            ValidationFailure(:final message) => message,
            ServerFailure(:final message) => message ?? 'Arama sırasında bir hata oluştu.',
            NetworkFailure() => 'İnternet bağlantınızı kontrol edin.',
            _ => 'Arama sırasında bir hata oluştu.',
          };
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
                  child: const Text('Tekrar Dene'),
                )
              ],
            ),
          );
        }
        
        final users = snapshot.data ?? [];
        
        if (users.isEmpty) {
          return const Center(child: Text('Kullanıcı bulunamadı.'));
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
