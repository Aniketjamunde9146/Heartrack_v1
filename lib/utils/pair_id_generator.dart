import 'dart:math';

String generatePairId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random();

  return List.generate(
    6,
    (_) => chars[rand.nextInt(chars.length)],
  ).join();
}
