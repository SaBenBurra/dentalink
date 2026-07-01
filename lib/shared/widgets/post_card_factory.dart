import 'package:flutter/material.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/shared/widgets/case_card.dart';
import 'package:dentlink/shared/widgets/question_card.dart';

class PostCardFactory {
  const PostCardFactory._();

  // Sadece build işlemlerinden sorumlu. Router ve Provider bağımsız. // <--
  static Widget build(
    PostModel post, {
    required VoidCallback onLikeToggle,
    required VoidCallback onBookmarkToggle,
    VoidCallback? onCommentTap,
    VoidCallback? onTap,
  }) {
    return switch (post.type) {
      PostType.casePost => CaseCard(
        post: post,
        onLikeToggle: onLikeToggle,
        onBookmarkToggle: onBookmarkToggle,
        onCommentTap: onCommentTap, // <-- Parametreden gelen değer
        onTap: onTap, // <-- Parametreden gelen değer
      ),
      PostType.question => QuestionCard(
        post: post,
        onLikeToggle: onLikeToggle,
        onBookmarkToggle: onBookmarkToggle,
        onCommentTap: onCommentTap, // <-- Parametreden gelen değer
        onTap: onTap,
      ),
    };
  }
}
