import 'package:flutter/material.dart';
import 'package:dentlink/data/models/post_model.dart'; // kendi yoluna göre düzelt
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/shared/widgets/case_card.dart';
import 'package:dentlink/shared/widgets/question_card.dart';

/// Feed ve Profil'in ortak kullandığı tek "PostType -> kart" dönüşüm noktası.
class PostCardFactory {
  const PostCardFactory._();

  static Widget build(
    PostModel post, {
    required VoidCallback onLikeToggle,
    required VoidCallback onBookmarkToggle,
  }) {
    return switch (post.type) {
      PostType.casePost => CaseCard(
        post: post,
        onLikeToggle: onLikeToggle,
        onBookmarkToggle: onBookmarkToggle,
      ),
      PostType.question => QuestionCard(
        post: post,
        onLikeToggle: onLikeToggle,
        onBookmarkToggle: onBookmarkToggle,
      ),
    };
  }
}
