import 'package:flutter/material.dart';

class AnimatedAddToCartButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const AnimatedAddToCartButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  State<AnimatedAddToCartButton> createState() =>
      _AnimatedAddToCartButtonState();
}

class _AnimatedAddToCartButtonState extends State<AnimatedAddToCartButton> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.95);
  void _onTapUp(_) {
    setState(() => _scale = 1.0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(widget.label),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ),
    );
  }
}
