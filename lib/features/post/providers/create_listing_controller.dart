import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/image_compress.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/post_model.dart';
import '../../../data/providers/repository_providers.dart';

final createListingProvider =
    AutoDisposeAsyncNotifierProvider<CreateListingController, void>(
      CreateListingController.new,
    );

/// İlan oluşturma: görseller WebP'ye sıkıştırılır (vaka ve forumla aynı), sonra
/// tek RPC (052). Hata state'e yazılır, null döner.
class CreateListingController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<PostModel?> submit({
    required String title,
    required String content,
    required List<File> images,
    required ListingCategory category,
    required ItemCondition condition,
    required String city,
    int? price,
  }) async {
    state = const AsyncLoading();
    try {
      final post = await ref
          .read(listingRepositoryProvider)
          .createListing(
            title: title,
            content: content,
            images: await compressToWebp(images),
            category: category,
            condition: condition,
            city: city,
            price: price,
          );
      state = const AsyncData(null);
      return post;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
