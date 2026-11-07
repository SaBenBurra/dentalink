import 'package:flutter/material.dart';
import 'package:dentigo/data/models/post_model.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/shared/widgets/case_card.dart';
import 'package:dentigo/shared/widgets/question_card.dart';

class PostCardFactory {
  const PostCardFactory._();

  // Sadece build işlemlerinden sorumlu. Router ve Provider bağımsız. // <--
  static Widget build(
    PostModel post, {
    required VoidCallback onLikeToggle,
    required VoidCallback onBookmarkToggle,
    VoidCallback? onCommentTap,
    VoidCallback? onTap,
    bool expanded = false,
  }) {
    return switch (post.type) {
      PostType.casePost => CaseCard(
        post: post as CasePostModel,
        onLikeToggle: onLikeToggle,
        onBookmarkToggle: onBookmarkToggle,
        onCommentTap: onCommentTap, // <-- Parametreden gelen değer
        onTap: onTap, // <-- Parametreden gelen değer
        expanded: expanded,
      ),
      PostType.question => QuestionCard(
        post: post as QuestionPostModel,
        onLikeToggle: onLikeToggle,
        onBookmarkToggle: onBookmarkToggle,
        onCommentTap: onCommentTap, // <-- Parametreden gelen değer
        onTap: onTap,
        expanded: expanded,
      ),
    };
  }
}
