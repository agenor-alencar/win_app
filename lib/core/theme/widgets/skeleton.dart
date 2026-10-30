import 'package:flutter/material.dart';

/// Placeholder de carregamento (skeleton) com pulso suave, sem dependências
/// externas. Use enquanto dados da API carregam, no lugar de spinners.
class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white10 : Colors.black12;
    final highlight = isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.06);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(base, highlight, _controller.value),
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}
