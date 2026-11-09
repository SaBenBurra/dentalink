import 'package:flutter/material.dart';
import 'package:dentigo/data/models/post_model.dart';
import 'package:dentigo/shared/widgets/case_card.dart';
import 'package:dentigo/shared/widgets/listing_card.dart';
import 'package:dentigo/shared/widgets/question_card.dart';

class PostCardFactory {
  const PostCardFactory._();

  // Sadece build işlemlerinden sorumlu. Router ve Provider bağımsız.
  static Widget build(
    PostModel post, {
    required VoidCallback onLikeToggle,
    required VoidCallback onBookmarkToggle,
    VoidCallback? onCommentTap,
    VoidCallback? onTap,
    bool expanded = false,
  }) {
    return switch (post) {
      CasePostModel() => CaseCard(
        post: post,
        onLikeToggle: onLikeToggle,
        onBookmarkToggle: onBookmarkToggle,
        onCommentTap: onCommentTap,
        onTap: onTap,
        expanded: expanded,
      ),
      QuestionPostModel() => QuestionCard(
        post: post,
        onLikeToggle: onLikeToggle,
        onBookmarkToggle: onBookmarkToggle,
        onCommentTap: onCommentTap,
        onTap: onTap,
        expanded: expanded,
      ),
      // Beğeni ve yorum yok (052).
      ListingPostModel() => ListingCard(
        post: post,
        onBookmarkToggle: onBookmarkToggle,
        onTap: onTap,
        expanded: expanded,
      ),
    };
  }
}
