import 'package:flutter/material.dart';

/// Full-width standard button with loading state.
/// Filled by default; [isOutlined] renders the secondary style.
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loading = SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: isOutlined ? scheme.primary : scheme.onPrimary,
      ),
    );
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading ? loading : Text(text),
      );
    }
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? loading : Text(text),
    );
  }
}
