import 'dart:ui';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  // Animation controllers for error shaking
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();

    // Focus listeners to rebuild and trigger scale/shadow transitions
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));

    // Shake animation setup for validation error feedback
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  double _getShakeOffset(double progress) {
    // Generates a sine wave shake pattern: 0 -> -6 -> 6 -> -6 -> 6 -> 0
    final double sine = double.parse((progress * 3 * 3.14159).toString());
    return 8 *
        double.parse((progress < 0.5 ? progress : 1.0 - progress).toString()) *
        double.parse((sine >= 0 ? 1 : -1).toString());
  }

  void _clearErrors() {
    if (_emailError != null || _passwordError != null) {
      setState(() {
        _emailError = null;
        _passwordError = null;
      });
    }
  }

  void _simulateLogin() {
    _clearErrors();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (email.contains('error') || email.isEmpty) {
        // Trigger shake and display errors
        _shakeController.forward();
        setState(() {
          _emailError = 'Please enter a valid clinical email.';
          _passwordError = 'Incorrect password.';
        });
      } else {
        // Successful login mock — ana akışa geç
        if (mounted) context.go('/feed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // ← bunu ekle
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve themed colors
    final backgroundColor = isDark
        ? const Color(0xFF11211F)
        : AppColors.bgGradientStart;
    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);
    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Background Gradients and Decorative Blurred Circles
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.bgGradientStart,
                      AppColors.bgGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

          // Decorative Circle top-left
          Positioned(
            left: -100,
            top: -100,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.primaryLight : AppColors.primary)
                    .withValues(alpha: isDark ? 0.08 : 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // Decorative Circle bottom-right
          Positioned(
            right: -100,
            bottom: -100,
            width: 350,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.secondaryLight : AppColors.secondary)
                    .withValues(alpha: isDark ? 0.06 : 0.10),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Main Scrollable Container
          // LayoutBuilder captures the real available height so we can pass it
          // as minHeight to ConstrainedBox. This lets the Column centre itself
          // vertically when content is shorter than the screen, and scroll
          // naturally when the keyboard pushes it (avoids Spacer/Expanded
          // inside SingleChildScrollView which causes RenderBox crashes).
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing24,
                    vertical: 0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          AppDimensions.spacing24 *
                              2, // subtract vertical padding
                      maxWidth: AppDimensions.maxContentWidth,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppDimensions.maxContentWidth,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tooth Logo Circle Panel
                            _buildLogoHeader(
                              isDark,
                              glassBgColor,
                              glassBorderColor,
                            ),

                            const SizedBox(height: AppDimensions.spacing24),

                            // Text Headers
                            Text(
                              l10n.loginTitle,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: textPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacing8),
                            Text(
                              l10n.loginSubtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: AppDimensions.spacing40),

                            // Login Form Fields
                            AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                final shakeVal = _shakeController.value;
                                final offset = _getShakeOffset(shakeVal);
                                return Transform.translate(
                                  offset: Offset(offset, 0),
                                  child: child,
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email Input
                                  _buildGlassInputField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    placeholder: l10n.emailHint,
                                    icon: Icons.mail_outline,
                                    keyboardType: TextInputType.emailAddress,
                                    errorText: _emailError,
                                    onChanged: (_) => _clearErrors(),
                                    isDark: isDark,
                                    glassBgColor: glassBgColor,
                                    glassBorderColor: glassBorderColor,
                                  ),

                                  if (_emailError != null) ...[
                                    const SizedBox(
                                      height: AppDimensions.spacing6,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: AppDimensions.spacing8,
                                      ),
                                      child: Text(
                                        _emailError!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(
                                    height: AppDimensions.spacing16,
                                  ),

                                  if (_passwordError != null) ...[
                                    const SizedBox(
                                      height: AppDimensions.spacing6,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: AppDimensions.spacing8,
                                      ),
                                      child: Text(
                                        _passwordError!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Submit Button
                                  _buildSubmitButton(),

                                  const SizedBox(
                                    height: AppDimensions.spacing24,
                                  ),

                                  // Divider — "or"
                                  _buildDivider(isDark, textSecondaryColor),

                                  const SizedBox(
                                    height: AppDimensions.spacing24,
                                  ),

                                  // Google Sign-In Button (visual only)
                                  _buildGoogleButton(
                                    isDark,
                                    glassBgColor,
                                    glassBorderColor,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppDimensions.spacing32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader(
    bool isDark,
    Color glassBgColor,
    Color glassBorderColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: glassBgColor,
            border: Border.all(color: glassBorderColor, width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 40,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(48, 48),
              painter: ToothPainter(
                colors: [
                  isDark ? AppColors.primaryLight : const Color(0xFF13B9A5),
                  isDark ? AppColors.secondaryLight : const Color(0xFF3B82F6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
    required bool isDark,
    required Color glassBgColor,
    required Color glassBorderColor,
  }) {
    final hasFocus = focusNode.hasFocus;
    final hasError = errorText != null;

    // Compute interactive colors
    Color borderColor = glassBorderColor;
    Color bgOpacityColor = glassBgColor;
    double scale = 1.0;
    double shadowOpacity = 0.0;

    if (hasError) {
      borderColor = AppColors.error.withValues(alpha: 0.8);
      bgOpacityColor = AppColors.error.withValues(alpha: isDark ? 0.08 : 0.03);
    } else if (hasFocus) {
      borderColor = isDark ? AppColors.primaryLight : const Color(0xFF13B9A5);
      bgOpacityColor =
          (isDark ? AppColors.primaryLight : const Color(0xFF13B9A5))
              .withValues(alpha: isDark ? 0.15 : 0.08);
      scale = 1.015;
      shadowOpacity = 0.15;
    }

    return AnimatedScale(
      scale: scale,
      duration: AppDimensions.animFast,
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: AppDimensions.animFast,
        height: AppDimensions.buttonHeightLarge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          color: bgOpacityColor,
          border: Border.all(color: borderColor, width: hasFocus ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.primaryLight : const Color(0xFF13B9A5))
                  .withValues(alpha: shadowOpacity),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Center(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                keyboardType: keyboardType,
                onChanged: onChanged,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.lightIcon.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    icon,
                    color: hasFocus && !hasError
                        ? (isDark
                              ? AppColors.primaryLight
                              : const Color(0xFF13B9A5))
                        : (hasError ? AppColors.error : AppColors.lightIcon),
                    size: AppDimensions.iconMedium,
                  ),
                  suffixIcon: suffixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryButtonColor = isDark
        ? const Color(0xFF008B7A)
        : const Color(0xFF13B9A5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _simulateLogin,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Ink(
          height: AppDimensions.buttonHeight,
          decoration: BoxDecoration(
            color: primaryButtonColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF13B9A5,
                ).withValues(alpha: isDark ? 0.15 : 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer overlay on hover/active (animated via State/Loader)
              AnimatedOpacity(
                opacity: _isLoading ? 0.0 : 1.0,
                duration: AppDimensions.animFast,
                child: Text(
                  l10n.loginButton,
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Loading Dots
              if (_isLoading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return _LoadingDot(delayMs: index * 200);
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── "ya da" ayırıcı ───────────────────────────────────────────────────
  Widget _buildDivider(bool isDark, Color textSecondaryColor) {
    final l10n = AppLocalizations.of(context);
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);
    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing12,
          ),
          child: Text(
            l10n.textBeetweenLoginAndOauth,
            style: AppTextStyles.bodySmall.copyWith(
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }

  // ── Google butonu (sadece görsel) ──────────────────────────────────────
  Widget _buildGoogleButton(
    bool isDark,
    Color glassBgColor,
    Color glassBorderColor,
  ) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: AppDimensions.buttonHeightLarge,
          decoration: BoxDecoration(
            color: glassBgColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: glassBorderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Google_Favicon_2025.svg/120px-Google_Favicon_2025.svg.png',
                width: 22,
                height: 22,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.language, size: 22, color: Colors.grey),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Text(
                l10n.loginWithGoogle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDot extends StatefulWidget {
  final int delayMs;
  const _LoadingDot({required this.delayMs});

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class ToothPainter extends CustomPainter {
  final List<Color> colors;

  ToothPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Start at top cleft
    path.moveTo(size.width * 0.5, size.height * 0.28);

    // Left crown curve
    path.cubicTo(
      size.width * 0.38,
      size.height * 0.12,
      size.width * 0.12,
      size.height * 0.15,
      size.width * 0.18,
      size.height * 0.45,
    );

    // Left root curve
    path.cubicTo(
      size.width * 0.20,
      size.height * 0.60,
      size.width * 0.22,
      size.height * 0.85,
      size.width * 0.32,
      size.height * 0.88,
    );

    // Left root tip and middle cleft
    path.cubicTo(
      size.width * 0.36,
      size.height * 0.89,
      size.width * 0.44,
      size.height * 0.75,
      size.width * 0.50,
      size.height * 0.75,
    );

    // Right root tip and cleft
    path.cubicTo(
      size.width * 0.56,
      size.height * 0.75,
      size.width * 0.64,
      size.height * 0.89,
      size.width * 0.68,
      size.height * 0.88,
    );

    // Right root curve
    path.cubicTo(
      size.width * 0.78,
      size.height * 0.85,
      size.width * 0.80,
      size.height * 0.60,
      size.width * 0.82,
      size.height * 0.45,
    );

    // Right crown curve
    path.cubicTo(
      size.width * 0.88,
      size.height * 0.15,
      size.width * 0.62,
      size.height * 0.12,
      size.width * 0.50,
      size.height * 0.28,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
