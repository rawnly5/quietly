import 'package:flutter/material.dart';

class PowerButton extends StatelessWidget {
  const PowerButton({super.key, required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color c = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: active
                ? <Color>[c, c.withOpacity(0.7)]
                : <Color>[Colors.grey.shade400, Colors.grey.shade700],
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(color: c.withOpacity(0.5), blurRadius: 40, spreadRadius: 8),
                ]
              : null,
        ),
        child: Icon(
          Icons.power_settings_new,
          size: 72,
          color: Colors.white.withOpacity(0.95),
        ),
      ),
    );
  }
}
