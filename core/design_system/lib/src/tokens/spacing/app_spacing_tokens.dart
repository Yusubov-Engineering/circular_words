/// The spacing scale. Use these instead of raw numbers.
///
/// The scale is short on purpose — extend it where your layouts genuinely
/// need another step, rather than shipping steps nothing uses.
final class const AppSpacingTokens({
  required final double spacingNone,
  required final double spacingXxs,
  required final double spacingXs,
  required final double spacingSm,
  required final double spacingMd,
  required final double spacingLg,
  required final double spacingXl,
  required final double spacing2Xl,
  required final double spacing3Xl,
  required final double spacing4Xl,
}) {
  factory regular() {
    return const AppSpacingTokens(
      spacingNone: 0,
      spacingXxs: 2,
      spacingXs: 4,
      spacingSm: 6,
      spacingMd: 8,
      spacingLg: 12,
      spacingXl: 16,
      spacing2Xl: 20,
      spacing3Xl: 24,
      spacing4Xl: 32,
    );
  }
}
