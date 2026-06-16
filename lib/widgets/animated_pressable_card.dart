import 'package:flutter/material.dart';

class AnimatedPressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;

  const AnimatedPressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.borderRadius,
    this.shadows,
    this.padding,
  });

  @override
  State<AnimatedPressableCard> createState() => _AnimatedPressableCardState();
}

class _AnimatedPressableCardState extends State<AnimatedPressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.95 : 1.0;
    
    // Modify shadows to decrease blur/spread and offset when pressed (simulates being pressed down)
    final modifiedShadows = widget.shadows?.map((shadow) {
      if (_isPressed) {
        return BoxShadow(
          color: shadow.color,
          blurRadius: shadow.blurRadius * 0.4, // Subtly decrease blur radius
          spreadRadius: shadow.spreadRadius * 0.4, // Subtly decrease spread radius
          offset: shadow.offset * 0.3, // Move the shadow closer to the widget
        );
      }
      return shadow;
    }).toList();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: widget.borderRadius,
            boxShadow: modifiedShadows,
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}
