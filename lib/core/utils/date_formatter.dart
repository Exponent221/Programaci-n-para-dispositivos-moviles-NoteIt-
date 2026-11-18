/// Formatea una fecha como `dd/MM/aaaa · HH:mm`.
///
/// Se implementa a mano para no añadir el paquete `intl` solo por esto.
String formatDateTime(DateTime date) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}'
      ' · ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}
