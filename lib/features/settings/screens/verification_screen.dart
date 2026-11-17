import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/image_compress.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/verification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/verification_provider.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/sign_out_dialog.dart';

/// Ayarlar → Hesap doğrulama: mezuniyet ya da öğrenci belgesi yükleme ve isteğin durumu (065).
///
/// [gate]: doğrulanmamış hesabın tek ekranı (`/verify`, 066). Geri yok; menüde
/// destek, çıkış ve hesap silme. Onay gelince router uygulamayı açar.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key, this.gate = false});

  final bool gate;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

enum _GateAction { support, signOut, deleteAccount }

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  // Karar push'u arka plandayken gelir; dönünce durum yeniden okunur.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(verificationProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onGateAction(_GateAction action) {
    switch (action) {
      case _GateAction.support:
        context.push('/support');
      case _GateAction.signOut:
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const SignOutDialog(),
        );
      case _GateAction.deleteAccount:
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const DeleteAccountDialog(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVerified = ref.watch(
      currentUserProvider.select((u) => u?.isVerified ?? false),
    );
    final request = ref.watch(verificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verificationTitle),
        automaticallyImplyLeading: !widget.gate,
        actions: [
          if (widget.gate)
            PopupMenuButton<_GateAction>(
              onSelected: _onGateAction,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _GateAction.support,
                  child: Text(l10n.supportContact),
                ),
                PopupMenuItem(
                  value: _GateAction.signOut,
                  child: Text(l10n.settingsLogout),
                ),
                PopupMenuItem(
                  value: _GateAction.deleteAccount,
                  child: Text(l10n.settingsDeleteAccount),
                ),
              ],
            ),
        ],
      ),
      body: request.when(
        loading: () => const DentigoLoadingSpinner(),
        error: (e, _) => DentigoErrorWidget(
          message: getErrorMessage(l10n, e),
          onRetry: () => ref.invalidate(verificationProvider),
        ),
        data: (r) {
          if (r?.status == VerificationStatus.pending) {
            return _StatusView(
              icon: Icons.hourglass_top_rounded,
              title: l10n.verificationPendingTitle,
              body: l10n.verificationPendingBody(
                DateFormat.yMMMMd(l10n.localeName).format(r!.createdAt),
              ),
              note: l10n.verificationPrivacy,
            );
          }
          if (isVerified) {
            return _StatusView(
              icon: Icons.verified_rounded,
              title: l10n.verifiedAccount,
              body: l10n.verificationApprovedBody,
            );
          }
          return _VerificationForm(
            gate: widget.gate,
            rejection: r?.status == VerificationStatus.rejected ? r : null,
          );
        },
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.title,
    required this.body,
    this.note,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppDimensions.spacing64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (note != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              _PrivacyNote(note!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Belgenin doğrulamadan sonra silineceği bilgisi.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: AppDimensions.iconMedium,
            color: colors.primary,
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationForm extends ConsumerStatefulWidget {
  const _VerificationForm({this.gate = false, this.rejection});

  /// Doğrulanmamış hesabın kilit ekranı: üstte "son bir adım" açıklaması.
  final bool gate;

  /// Önceki istek reddedildiyse gerekçesi üstte gösterilir.
  final VerificationRequest? rejection;

  @override
  ConsumerState<_VerificationForm> createState() => _VerificationFormState();
}

class _VerificationFormState extends ConsumerState<_VerificationForm> {
  // Biri seçilince diğeri temizlenir.
  File? _image;
  PlatformFile? _pdf;
  bool _submitting = false;

  VerificationDocType get _type => VerificationDocType.forTitle(
    ref.read(currentUserProvider)?.title ?? UserTitle.disHekimi,
  );

  void _showError(Object e) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Belge metni okunaklı kalsın: avatardan büyük.
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        setState(() {
          _image = File(image.path);
          _pdf = null;
        });
      }
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _pickPdf() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file != null && mounted) {
        setState(() {
          _pdf = file;
          _image = null;
        });
      }
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _submit() async {
    final image = _image;
    final pdf = _pdf;
    if ((image == null && pdf == null) || _submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final bytes = pdf != null
          ? await pdf.readAsBytes()
          : await encodeJpeg(image!.path);
      if (!mounted) return;
      final String? problem =
          bytes == null || (pdf != null && !looksLikePdf(bytes))
          ? l10n.verificationFileInvalid
          : bytes.length > maxVerificationDocBytes
          ? l10n.verificationFileTooLarge
          : null;
      if (problem != null) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(content: Text(problem)));
        return;
      }
      await ref
          .read(verificationProvider.notifier)
          .submit(bytes!, _type, pdf: pdf != null);
      messenger.showSnackBar(SnackBar(content: Text(l10n.verificationSent)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rejection = widget.rejection;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacing24),
      children: [
        if (rejection != null) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.verificationRejectedTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
                if (rejection.reason != null) ...[
                  const SizedBox(height: AppDimensions.spacing4),
                  Text(
                    rejection.reason!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing24),
        ],
        if (widget.gate) ...[
          Text(
            l10n.verificationGateTitle,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            l10n.verificationGateBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
        ],
        Text(
          _type == VerificationDocType.studentCertificate
              ? l10n.verificationIntroStudent
              : l10n.verificationIntro,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppDimensions.spacing16),
        _PrivacyNote(l10n.verificationPrivacy),
        const SizedBox(height: AppDimensions.spacing24),
        if (_image != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            child: Image.file(_image!, fit: BoxFit.contain),
          ),
          const SizedBox(height: AppDimensions.spacing16),
        ],
        if (_pdf != null) ...[
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: ListTile(
              leading: Icon(
                Icons.picture_as_pdf_outlined,
                color: colors.primary,
              ),
              title: Text(
                _pdf!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _submitting
                    ? null
                    : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l10n.pickFromCamera),
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _submitting
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.pickFromGallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing12),
        OutlinedButton.icon(
          onPressed: _submitting ? null : _pickPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(l10n.verificationPickPdf),
        ),
        const SizedBox(height: AppDimensions.spacing16),
        SizedBox(
          height: AppDimensions.buttonHeight,
          child: FilledButton(
            onPressed: (_image == null && _pdf == null) || _submitting
                ? null
                : _submit,
            child: _submitting
                ? SizedBox.square(
                    dimension: AppDimensions.iconMedium,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimary,
                    ),
                  )
                : Text(l10n.verificationSubmit),
          ),
        ),
      ],
    );
  }
}
