import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../core/theme/plumora_colors.dart';
import '../../../../core/widgets/plumora_logo_mark.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    required this.child,
    this.topPadding = 24,
    this.horizontalPadding = 14,
    this.bottomPadding = 28,
    this.maxPanelWidth = 430,
    super.key,
  });

  final Widget child;
  final double topPadding;
  final double horizontalPadding;
  final double bottomPadding;
  final double maxPanelWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlumoraColors.appOutside,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 520;
            final outerInset = isCompact ? 0.0 : 8.0;
            final availableWidth = math.max(
              0.0,
              constraints.maxWidth - (outerInset * 2),
            );
            final panelWidth = isCompact
                ? constraints.maxWidth
                : math.min(maxPanelWidth, availableWidth);
            final panelRadius = isCompact ? 0.0 : 28.0;
            final heightScale = constraints.maxHeight < 720 ? 0.78 : 1.0;
            final effectiveHorizontalPadding = math.min(
              horizontalPadding,
              math.max(14.0, panelWidth * 0.08),
            );

            return SingleChildScrollView(
              padding: EdgeInsets.all(outerInset),
              child: Center(
                child: SizedBox(
                  width: panelWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (outerInset * 2),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: PlumoraColors.background,
                        borderRadius: BorderRadius.circular(panelRadius),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          effectiveHorizontalPadding,
                          topPadding * heightScale,
                          effectiveHorizontalPadding,
                          bottomPadding,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    required this.child,
    this.padding = const EdgeInsets.all(26),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PlumoraColors.cards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PlumoraColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class BrandIconBox extends StatelessWidget {
  const BrandIconBox({
    this.size = 50,
    this.iconSize = 31,
    this.backgroundColor = PlumoraColors.primary,
    this.iconColor = Colors.white,
    this.hasShadow = true,
    super.key,
  });

  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: hasShadow
            ? const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Center(
        child: PlumoraLogoMark(
          size: iconSize,
          color: iconColor,
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          PlumoraLogoMark(
            size: compact ? 26 : 43,
            color: PlumoraColors.primary,
            strokeWidth: compact ? 1.9 : 1.8,
          ),
          SizedBox(width: compact ? 7 : 9),
          Text(
            'Plumora',
            style: TextStyle(
              color: PlumoraColors.primary,
              fontSize: compact ? 30 : 48,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class PlumoraTextField extends StatelessWidget {
  const PlumoraTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 16, color: PlumoraColors.textPrimary),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: PlumoraColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: PlumoraColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider(color: PlumoraColors.border)),
      ],
    );
  }
}

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({this.size = 18, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.16;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paints = {
      0xFF4285F4: Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
      0xFF34A853: Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
      0xFFFBBC05: Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
      0xFFEA4335: Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    };

    canvas.drawArc(rect, -0.05, 1.45, false, paints[0xFF4285F4]!);
    canvas.drawArc(rect, 1.32, 1.20, false, paints[0xFF34A853]!);
    canvas.drawArc(rect, 2.45, 1.18, false, paints[0xFFFBBC05]!);
    canvas.drawArc(rect, 3.48, 1.62, false, paints[0xFFEA4335]!);

    final bluePaint = paints[0xFF4285F4]!;
    final center = Offset(size.width * 0.52, size.height * 0.52);
    canvas.drawLine(
      center,
      Offset(size.width * 0.92, size.height * 0.52),
      bluePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.92, size.height * 0.52),
      Offset(size.width * 0.92, size.height * 0.40),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlumoraLogo extends StatelessWidget {
  const PlumoraLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppWordmark(compact: compact);
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LoadingButtonChild extends StatelessWidget {
  const LoadingButtonChild({
    required this.label,
    required this.isLoading,
    super.key,
  });

  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return Text(label);
    }

    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
