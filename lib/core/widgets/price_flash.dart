import 'package:flutter/material.dart';

import '../../domain/entities/price_tick.dart';
import '../theme/app_theme.dart';

class PriceFlash extends StatefulWidget {
  const PriceFlash({
    super.key,
    required this.ltpPaise,
    required this.direction,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
  });

  final int ltpPaise;
  final TickDirection direction;
  final Widget child;
  final Duration duration;

  @override
  State<PriceFlash> createState() => _PriceFlashState();
}

class _PriceFlashState extends State<PriceFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Color?> _color = const AlwaysStoppedAnimation(Colors.transparent);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant PriceFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ltpPaise != oldWidget.ltpPaise) {
      _flash(widget.direction);
    }
  }

  void _flash(TickDirection direction) {
    final target = switch (direction) {
      TickDirection.up => AppColors.gainFlash,
      TickDirection.down => AppColors.lossFlash,
      TickDirection.flat => null,
    };
    if (target == null) return;

    _color = ColorTween(
      begin: target,
      end: Colors.transparent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ColoredBox(
          color: _color.value ?? Colors.transparent,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
