import 'package:flutter/material.dart';

/// Botón de dictado con indicador de escucha.
///
/// Solo dibuja el estado que recibe ([isListening]); la lógica del
/// micrófono vive en la pantalla y en `SpeechService`.
class DictationButton extends StatefulWidget {
  const DictationButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.enabled = true,
  });

  final bool isListening;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<DictationButton>
    with SingleTickerProviderStateMixin {
  /// Animación del halo rojo mientras se escucha.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant DictationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  /// Arranca o detiene el halo según [DictationButton.isListening].
  void _syncAnimation() {
    if (widget.isListening && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isListening && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final listening = widget.isListening;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = _pulse.value;
            return Container(
              padding: EdgeInsets.all(listening ? 4 + t * 6 : 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: listening
                    ? Colors.redAccent.withAlpha((30 + 60 * (1 - t)).round())
                    : Colors.transparent,
              ),
              child: child,
            );
          },
          child: IconButton.filled(
            tooltip: listening ? 'Detener dictado' : 'Dictar notas',
            onPressed: widget.enabled ? widget.onPressed : null,
            style: IconButton.styleFrom(
              backgroundColor: listening ? Colors.redAccent : scheme.primary,
              foregroundColor: listening ? Colors.white : scheme.onPrimary,
            ),
            icon: Icon(listening ? Icons.stop : Icons.mic),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          listening ? 'Escuchando…' : 'Dictar',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: listening ? Colors.redAccent : null,
              ),
        ),
      ],
    );
  }
}
