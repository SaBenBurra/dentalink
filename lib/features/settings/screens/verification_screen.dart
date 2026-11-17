import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/image_compress.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/verification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/welcome_provider.dart';
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

    // Onaydan sonra bir kez: "Hoş geldin" (router yalnızca görülene kadar burada tutar).
    if (widget.gate && isVerified) return const _WelcomeView();

    return Scaffold(
      appBar: AppBar(
        title: widget.gate ? null : Text(l10n.verificationTitle),
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
              body: l10n.verificationPendingBody,
              showPrivacy: true,
            );
          }
          if (isVerified) {
            return _StatusView(
              icon: Icons.verified_rounded,
              title: l10n.verifiedAccount,
            );
          }
          return _VerificationForm(
            rejection: r?.status == VerificationStatus.rejected ? r : null,
          );
        },
      ),
    );
  }
}

/// Yavaşça süzülen, renkli halkalı büyük ikon. Hareket azaltma açıksa durur.
class _Hero extends StatefulWidget {
  const _Hero(this.icon);

  final IconData icon;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: AppDimensions.animSlow,
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: AnimatedBuilder(
        animation: _float,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            0,
            -AppDimensions.spacing8 * Curves.easeInOut.transform(_float.value),
          ),
          child: child,
        ),
        child: Container(
          width: AppDimensions.avatarProfile + AppDimensions.spacing20,
          height: AppDimensions.avatarProfile + AppDimensions.spacing20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primaryContainer, colors.secondaryContainer],
            ),
          ),
          child: Icon(
            widget.icon,
            size: AppDimensions.spacing56,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.title,
    this.body,
    this.showPrivacy = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final bool showPrivacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Hero(icon),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                body!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showPrivacy) ...[
              const SizedBox(height: AppDimensions.spacing32),
              const _PrivacyNote(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Belgenin doğrulamadan sonra silineceği bilgisi (KVKK), tek satır.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: AppDimensions.iconSmall,
          color: color,
        ),
        const SizedBox(width: AppDimensions.spacing6),
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.verificationPrivacy,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

enum _Source { camera, gallery, pdf }

class _VerificationForm extends ConsumerStatefulWidget {
  const _VerificationForm({this.rejection});

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

  Future<void> _chooseSource() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<_Source>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.pickFromCamera),
              onTap: () => Navigator.pop(context, _Source.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.pickFromGallery),
              onTap: () => Navigator.pop(context, _Source.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.verificationPickPdf),
              onTap: () => Navigator.pop(context, _Source.pdf),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    switch (source) {
      case _Source.camera:
        await _pickImage(ImageSource.camera);
      case _Source.gallery:
        await _pickImage(ImageSource.gallery);
      case _Source.pdf:
        await _pickPdf();
    }
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
    final student = _type == VerificationDocType.studentCertificate;
    final hasDoc = _image != null || _pdf != null;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing24,
        vertical: AppDimensions.spacing16,
      ),
      children: [
        Center(
          child: _Hero(
            student ? Icons.school_rounded : Icons.workspace_premium_rounded,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing24),
        Text(
          l10n.verificationGateTitle,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Text(
          student ? l10n.verificationIntroStudent : l10n.verificationIntro,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (rejection != null) ...[
          const SizedBox(height: AppDimensions.spacing16),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: Text(
              rejection.reason == null
                  ? l10n.verificationRejectedTitle
                  : '${l10n.verificationRejectedTitle}: ${rejection.reason}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.spacing24),
        _DocCard(
          image: _image,
          pdf: _pdf,
          onTap: _submitting ? null : _chooseSource,
        ),
        const SizedBox(height: AppDimensions.spacing16),
        SizedBox(
          height: AppDimensions.buttonHeightLarge,
          child: FilledButton(
            onPressed: !hasDoc || _submitting ? null : _submit,
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
        const SizedBox(height: AppDimensions.spacing16),
        const Center(child: _PrivacyNote()),
      ],
    );
  }
}

/// Belge kartı: boşken "Belgeni ekle", seçilince önizleme + "Değiştir".
/// Dokununca kamera / galeri / PDF seçimi açılır.
class _DocCard extends StatelessWidget {
  const _DocCard({this.image, this.pdf, this.onTap});

  final File? image;
  final PlatformFile? pdf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppDimensions.radiusXLarge);
    final hasDoc = image != null || pdf != null;

    final Widget content;
    if (image != null) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: AppDimensions.imageMaxHeight,
        ),
        child: Image.file(image!, fit: BoxFit.contain),
      );
    } else if (pdf != null) {
      content = Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: AppDimensions.spacing48,
              color: colors.primary,
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              pdf!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing40),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              size: AppDimensions.spacing48,
              color: colors.primary,
            ),
            const SizedBox(height: AppDimensions.spacing12),
            Text(l10n.verificationAddDoc, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimensions.spacing4),
            Text(
              l10n.verificationAddDocHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: colors.primary.withValues(alpha: hasDoc ? 0.6 : 0.3),
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: AppDimensions.animNormal,
                child: KeyedSubtree(
                  key: ValueKey(image?.path ?? pdf?.name),
                  child: Center(child: content),
                ),
              ),
            ),
            if (hasDoc)
              Positioned(
                top: AppDimensions.spacing8,
                right: AppDimensions.spacing8,
                child: Chip(
                  avatar: const Icon(Icons.swap_horiz_rounded),
                  label: Text(l10n.verificationChangeDoc),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Onaydan sonra bir kez açılan kutlama: konfeti, ad ile karşılama, tek buton.
/// Buton `/feed`'e `go` ile gider; router da bu ekrana bir daha döndürmez.
class _WelcomeView extends ConsumerStatefulWidget {
  const _WelcomeView();

  @override
  ConsumerState<_WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends ConsumerState<_WelcomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && !_confetti.isCompleted) {
      _confetti.forward();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _enter() {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    HapticFeedback.mediumImpact();
    ref.read(welcomedUsersProvider.notifier).markWelcomed(uid);
    context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = ref.watch(
      currentUserProvider.select((u) => u?.fullName.split(' ').first ?? ''),
    );

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing32),
              child: Column(
                children: [
                  const Spacer(),
                  const _Hero(Icons.celebration_rounded),
                  const SizedBox(height: AppDimensions.spacing32),
                  Text(
                    l10n.welcomeTitle(name),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacing12),
                  Text(
                    l10n.welcomeBody,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightLarge,
                    child: FilledButton.icon(
                      onPressed: _enter,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      iconAlignment: IconAlignment.end,
                      label: Text(
                        l10n.welcomeEnter,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Konfeti dokunuşları engellemesin.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _confetti.value,
                    colors: [
                      colors.primary,
                      colors.secondary,
                      colors.tertiary,
                      colors.primaryContainer,
                      colors.secondaryContainer,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Üstten dağılıp düşen, dönen kâğıt parçaları; [progress] 0 → 1.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  static const _count = 70;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    // Sabit tohum: her karede aynı parçalar, yalnızca konumları ilerler.
    final rnd = Random(7);
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final startX = rnd.nextDouble() * size.width;
      final drift = (rnd.nextDouble() - 0.5) * size.width * 0.4;
      final delay = rnd.nextDouble() * 0.3;
      final speed = 0.8 + rnd.nextDouble() * 0.6;
      final spin = (rnd.nextDouble() - 0.5) * 12;
      final w = 6 + rnd.nextDouble() * 6;
      final color = colors[i % colors.length];

      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t == 0) continue;
      final y = -20 + t * speed * (size.height + 40);
      final x = startX + drift * t + sin(t * 10 + i) * 12;

      paint.color = color.withValues(alpha: 1 - Curves.easeIn.transform(t));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
