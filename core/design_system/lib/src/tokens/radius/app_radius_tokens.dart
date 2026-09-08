/// The corner-radius scale.
final class const AppRadiusTokens({
  required final double radiusNone,
  required final double radiusXs,
  required final double radiusSm,
  required final double radiusMd,
  required final double radiusLg,
  required final double radiusXl,
  required final double radiusFull,
}) {
  factory regular() {
    return const AppRadiusTokens(
      radiusNone: 0,
      radiusXs: 4,
      radiusSm: 6,
      radiusMd: 8,
      radiusLg: 10,
      radiusXl: 12,
      radiusFull: 9999,
    );
  }
}
