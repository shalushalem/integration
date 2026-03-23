part of 'profile.dart';

class _PressScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const _PressScaleWidget({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<_PressScaleWidget> createState() => _PressScaleWidgetState();
}

class _PressScaleWidgetState extends State<_PressScaleWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown:
    widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
    onTapUp: (_) => setState(() => _pressed = false),
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _FocusTextField â€” animated focus ring
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FocusTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _FocusTextField({
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  State<_FocusTextField> createState() => _FocusTextFieldState();
}

class _FocusTextFieldState extends State<_FocusTextField> {
  late final FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => setState(() => _isFocused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accentPrimary = t.accent.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _isFocused ? t.panelBorder : t.panel,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: _isFocused
                ? accentPrimary.withValues(alpha: 0.28)
                : t.cardBorder),
        boxShadow: _isFocused
            ? [
          BoxShadow(
              color: accentPrimary.withValues(alpha: 0.10),
              blurRadius: 4,
              spreadRadius: 3),
        ]
            : null,
      ),
      child: TextField(
        focusNode: _focus,
        controller: widget.controller,
        onChanged: widget.onChanged,
        style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 15,
            fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
              color: t.mutedText,
              fontWeight: FontWeight.w300),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// _ConfirmButton â€” loading state on confirm actions
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ConfirmButton extends StatefulWidget {
  final String label;
  final String loadingLabel;
  final bool danger;
  final VoidCallback onConfirmed;

  const _ConfirmButton({
    required this.label,
    required this.loadingLabel,
    required this.danger,
    required this.onConfirmed,
  });

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final accentPrimary = t.accent.primary;
    final accentSecondary = t.accent.secondary;
    return GestureDetector(
      onTap: _loading
          ? null
          : () async {
        setState(() => _loading = true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) widget.onConfirmed();
        if (mounted) setState(() => _loading = false);
      },
      child: AnimatedOpacity(
        opacity: _loading ? 0.65 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: widget.danger ? t.accent.tertiary : null,
            gradient: widget.danger
                ? null
                : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentPrimary, accentSecondary]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (widget.danger
                    ? t.accent.tertiary
                    : accentPrimary)
                    .withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            _loading ? widget.loadingLabel : widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.themeTokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin<_KeepAliveWrapper> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
