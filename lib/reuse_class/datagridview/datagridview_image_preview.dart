import 'package:flutter/material.dart';

class DataGridViewImagePreview extends StatefulWidget {
  final String? imageUrl;
  final String semanticLabel;
  final double size;
  final bool muted;
  final double hoverPreviewSize;

  const DataGridViewImagePreview({
    super.key,
    required this.imageUrl,
    this.semanticLabel = 'Anteprima immagine',
    this.size = 48,
    this.muted = false,
    this.hoverPreviewSize = 260,
  });

  @override
  State<DataGridViewImagePreview> createState() =>
      _DataGridViewImagePreviewState();
}

class _DataGridViewImagePreviewState extends State<DataGridViewImagePreview> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _hovered = false;

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  Future<void> _showOverlay() async {
    final url = (widget.imageUrl ?? '').trim();
    if (url.isEmpty || !mounted || _overlayEntry != null) return;

    final provider = NetworkImage(url);
    if (!mounted || !_hovered || _overlayEntry != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final size = widget.hoverPreviewSize;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fill(
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(
                    widget.size + 16,
                    -(size / 2) + (widget.size / 2),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    elevation: 12,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: size,
                        maxHeight: size,
                      ),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              semanticLabel: widget.semanticLabel,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => _placeholder(theme),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
    precacheImage(provider, context).catchError((_) {
      // Preview still opens; the image widget will handle the error state.
    });
    if (!_hovered) {
      _hideOverlay();
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _placeholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: widget.hoverPreviewSize * 0.18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = (widget.imageUrl ?? '').trim();
    final preview = Container(
      width: widget.size,
      height: widget.size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: url.isEmpty
              ? _placeholder(theme)
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  semanticLabel: widget.semanticLabel,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => _placeholder(theme),
                ),
        ),
      ),
    );

    final child = widget.muted
        ? Opacity(opacity: 0.55, child: preview)
        : preview;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        onEnter: (_) {
          _hovered = true;
          _showOverlay();
        },
        onExit: (_) {
          _hovered = false;
          _hideOverlay();
        },
        child: child,
      ),
    );
  }
}
