/// Fixed sizes for icons and controls.
final class const AppSizeTokens({
  required final double size16,
  required final double size20,
  required final double size24,
  required final double size32,
  required final double size40,
}) {
  factory regular() {
    return const AppSizeTokens(
      size16: 16,
      size20: 20,
      size24: 24,
      size32: 32,
      size40: 40,
    );
  }
}
