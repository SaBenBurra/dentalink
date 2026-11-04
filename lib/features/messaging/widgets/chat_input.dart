import 'package:flutter/material.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  /// send_message RPC ile aynı sınır (migration 014).
  static const maxLength = 2000;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacing12,
            AppDimensions.spacing8,
            AppDimensions.spacing8,
            AppDimensions.spacing8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: maxLength,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: l10n.typeMessage,
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXLarge,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing16,
                      vertical: AppDimensions.spacing12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              // Metin boşken buton pasif; yalnızca gönder butonu yeniden çizilir.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend = !isSending && value.text.trim().isNotEmpty;
                  return IconButton.filled(
                    tooltip: l10n.sendMessage,
                    onPressed: canSend ? onSend : null,
                    icon: isSending
                        ? const SizedBox.square(
                            dimension: AppDimensions.iconMedium,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            size: AppDimensions.iconMedium,
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
