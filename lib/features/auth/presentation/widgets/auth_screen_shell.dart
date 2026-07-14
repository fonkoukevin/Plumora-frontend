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
    this.maxPanelWidth = 448,
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
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heightScale = constraints.maxHeight < 720 ? 0.78 : 1.0;
            final sidePadding = math.max(16.0, horizontalPadding);
            final verticalPadding = topPadding * heightScale;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                sidePadding,
                verticalPadding,
                sidePadding,
                bottomPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight - verticalPadding - bottomPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxPanelWidth),
                    child: child,
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
        color: context.colors.cards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
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
    this.backgroundColor,
    this.iconColor = Colors.white,
    this.hasShadow = true,
    super.key,
  });

  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color iconColor;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.primary,
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
  const AppWordmark({
    this.compact = false,
    this.iconSize,
    this.textSize,
    this.gap,
    super.key,
  });

  final bool compact;
  final double? iconSize;
  final double? textSize;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          PlumoraLogoMark(
            size: iconSize ?? (compact ? 26 : 43),
            color: context.colors.primary,
            strokeWidth: compact ? 1.9 : 1.8,
          ),
          SizedBox(width: gap ?? (compact ? 7 : 9)),
          Text(
            'Plumora',
            style: TextStyle(
              color: context.colors.primary,
              fontSize: textSize ?? (compact ? 30 : 48),
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
    this.maxLines = 1,
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
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          maxLines: obscureText ? 1 : maxLines,
          style: TextStyle(fontSize: 16, color: context.colors.textPrimary),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.colors.border)),
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
