import 'package:flutter/material.dart';

/// Vista centrada con icono, mensaje y una acción opcional.
///
/// Se reutiliza para los estados "lista vacía" y "error" de la pantalla
/// principal, y para el detalle cuando no recibe un pendiente.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
