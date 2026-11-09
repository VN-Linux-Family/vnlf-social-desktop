import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../i18n/vi.dart';
import '../icons/vnlf_icon.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// The website's `--shadow-hard`, used by menus, dialogs and cards that float.
List<BoxShadow> vnlfHardShadow(VnlfColors colors) => colors.isDark
    ? const [
        BoxShadow(
          color: Color(0x8C000000),
          offset: Offset(0, 16),
          blurRadius: 40,
        ),
        BoxShadow(
          color: Color(0x59000000),
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
      ]
    : const [
        BoxShadow(
          color: Color(0x1F101814),
          offset: Offset(0, 12),
          blurRadius: 32,
        ),
        BoxShadow(
          color: Color(0x0F101814),
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ];

/// One row of a post menu.
final class VnlfMenuAction {
  const VnlfMenuAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.danger = false,
    this.enabled = true,
  });

  final VnlfLucide icon;
  final String label;
  final VoidCallback onSelected;
  final bool danger;
  final bool enabled;
}

/// Opens a menu like the website's `PostMenu`: a popover under [anchor] on
/// wider screens and a bottom action sheet on phones. The chosen action runs
/// after the menu has closed, so it can open its own dialog.
/// The website's "…" menus. Posts use a sheet on phones; [dense] is the
/// profile's `.profile-menu`, a smaller dropdown at every width.
Future<void> showVnlfActionMenu(
  BuildContext context, {
  required Rect anchor,
  required List<VnlfMenuAction> actions,
  required String label,
  bool dense = false,
}) async {
  final touch =
      MediaQuery.sizeOf(context).width < VnlfDimensions.tabletMinWidth;
  final phone = touch && !dense;
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final chosen = await showGeneralDialog<VnlfMenuAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: label,
    barrierColor: phone ? const Color(0x610A100C) : Colors.transparent,
    transitionDuration: reduceMotion
        ? Duration.zero
        : Duration(milliseconds: phone ? 180 : 120),
    pageBuilder: (context, _, _) => phone
        ? _MenuSheet(actions: actions, label: label)
        : _MenuPopover(
            anchor: anchor,
            actions: actions,
            label: label,
            dense: dense,
            touch: touch,
          ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: phone
            ? AnimatedBuilder(
                animation: curved,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 24 * (1 - curved.value)),
                  child: child,
                ),
                child: child,
              )
            : child,
      );
    },
  );
  chosen?.onSelected();
}

class _MenuPopover extends StatelessWidget {
  const _MenuPopover({
    required this.anchor,
    required this.actions,
    required this.label,
    required this.dense,
    required this.touch,
  });

  final Rect anchor;
  final List<VnlfMenuAction> actions;
  final String label;
  final bool dense;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return CustomSingleChildLayout(
      delegate: _PopoverLayout(anchor, gap: dense ? 7 : 6),
      child: Semantics(
        label: label,
        scopesRoute: true,
        explicitChildNodes: true,
        child: Container(
          width: dense ? 210 : 232,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            boxShadow: vnlfHardShadow(colors),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: _MenuItems(
              actions: actions,
              phone: false,
              dense: dense,
              touch: touch,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [builder] in a panel anchored to [anchor] like the website's
/// `Popover`: [gap] below the trigger and right-aligned, or above it when
/// there is no room, never closer than 8px to the window edge.
///
/// The panel is [width] wide when the window allows, at most [maxHeight]
/// tall, with [radius] corners and [padding] inside.
Future<T?> showVnlfPopover<T>(
  BuildContext context, {
  required Rect anchor,
  required String label,
  required WidgetBuilder builder,
  double width = 360,
  double gap = 6,
  double? maxHeight,
  double radius = VnlfDimensions.radiusLg,
  EdgeInsetsGeometry padding = const EdgeInsets.all(12),
}) {
  final screen = MediaQuery.sizeOf(context).width;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: label,
    barrierColor: Colors.transparent,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120),
    pageBuilder: (context, _, _) {
      final colors = VnlfColors.of(context);
      return CustomSingleChildLayout(
        delegate: _PopoverLayout(anchor, gap: gap),
        child: Semantics(
          label: label,
          scopesRoute: true,
          explicitChildNodes: true,
          child: Container(
            width: (screen - 16).clamp(0, width).toDouble(),
            constraints: maxHeight == null
                ? null
                : BoxConstraints(maxHeight: maxHeight),
            padding: padding,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: vnlfHardShadow(colors),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: builder(context),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Below the trigger and right-aligned to it, or above when there is no room,
/// always 8px inside the window.
class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout(this.anchor, {required this.gap});
  final Rect anchor;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest)
          .deflate(const EdgeInsets.all(8));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (anchor.right - child.width).clamp(
      8.0,
      (size.width - 8 - child.width).clamp(8.0, double.infinity),
    );
    var y = anchor.bottom + gap;
    if (y + child.height > size.height - 8) {
      y = anchor.top - gap - child.height;
    }
    return Offset(
      x,
      y.clamp(
        8.0,
        (size.height - 8 - child.height).clamp(8.0, double.infinity),
      ),
    );
  }

  @override
  bool shouldRelayout(_PopoverLayout oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.gap != gap;
}

class _MenuSheet extends StatelessWidget {
  const _MenuSheet({required this.actions, required this.label});

  final List<VnlfMenuAction> actions;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final media = MediaQuery.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, 8 + media.padding.bottom),
        child: Semantics(
          label: label,
          scopesRoute: true,
          explicitChildNodes: true,
          child: Container(
            constraints: BoxConstraints(maxHeight: media.size.height * .7),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: SingleChildScrollView(
                child: _MenuItems(actions: actions, phone: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItems extends StatelessWidget {
  const _MenuItems({
    required this.actions,
    required this.phone,
    this.dense = false,
    this.touch = false,
  });

  final List<VnlfMenuAction> actions;
  final bool phone;
  final bool dense;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      },
      child: FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < actions.length; i++)
              _MenuItem(
                action: actions[i],
                phone: phone,
                dense: dense,
                touch: touch,
                autofocus: i == 0,
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.action,
    required this.phone,
    required this.autofocus,
    this.dense = false,
    this.touch = false,
  });

  final VnlfMenuAction action;
  final bool phone;
  final bool autofocus;

  /// `.profile-menu` rows: padding 9, radius 6, a 15px icon, and a soft
  /// grey on hover. [touch] keeps them 48 tall on phones.
  final bool dense;
  final bool touch;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _lit = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final action = widget.action;
    final dense = widget.dense;
    final radius = BorderRadius.circular(
      dense
          ? 6
          : widget.phone
          ? 12
          : 10,
    );
    final color = action.danger
        ? colors.red
        : _lit
        ? colors.brand
        : colors.ink;
    return Opacity(
      opacity: action.enabled ? 1 : .5,
      child: InkWell(
        autofocus: widget.autofocus && action.enabled,
        borderRadius: radius,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        onHover: (value) => setState(() => _lit = value),
        onFocusChange: (value) => setState(() => _lit = value),
        onTap: action.enabled ? () => Navigator.of(context).pop(action) : null,
        child: Container(
          constraints: BoxConstraints(
            minHeight: dense
                ? (widget.touch ? 48 : 34)
                : widget.phone
                ? 50
                : 42,
          ),
          padding: dense
              ? const EdgeInsets.all(9)
              : EdgeInsets.symmetric(
                  horizontal: widget.phone ? 14 : 12,
                  vertical: widget.phone ? 14 : 10,
                ),
          decoration: BoxDecoration(
            color: _lit
                ? (dense ? colors.surfaceSoft : colors.brandSoft)
                : null,
            borderRadius: radius,
          ),
          child: Row(
            spacing: dense
                ? 8
                : widget.phone
                ? 12
                : 9,
            children: [
              VnlfIcon(action.icon, size: dense ? 15 : 16, color: color),
              Expanded(
                child: Text(
                  action.label,
                  style: dense
                      ? VnlfTypography.plain(color)
                      : VnlfTypography.body(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The website's `confirm()` dialog. Resolves to true only when the person
/// chose [confirmLabel].
Future<bool> showVnlfConfirm(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  bool danger = true,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: vi.dialog.dongHopThoai,
    barrierColor: const Color(0x66101A14),
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150),
    pageBuilder: (context, _, _) => _ConfirmDialog(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      danger: danger,
    ),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.danger,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width <= 520;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(narrow ? 16 : 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
                side: BorderSide(color: colors.line),
              ),
              elevation: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
                  boxShadow: vnlfHardShadow(colors),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: VnlfTypography.body(colors.ink).copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          VnlfCloseButton(
                            size: 20,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 22),
                        child: Text(
                          description,
                          style: VnlfTypography.body(colors.muted)
                              .copyWith(height: 1.6),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          VnlfOutlineButton(
                            label: vi.common.huy,
                            autofocus: true,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          VnlfSolidButton(
                            label: confirmLabel,
                            danger: danger,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The website's `.button-outline`: a bordered surface button.
class VnlfOutlineButton extends StatelessWidget {
  const VnlfOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return OutlinedButton(
      autofocus: autofocus,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        foregroundColor: colors.ink,
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        ),
        textStyle: VnlfTypography.body(colors.ink)
            .copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// A filled button: brand by default, the website's `.ui-danger-button`
/// (#b43b36) when [danger].
class VnlfSolidButton extends StatelessWidget {
  const VnlfSolidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final VnlfLucide? icon;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final background = danger ? const Color(0xFFB43B36) : colors.brand;
    final foreground = danger || !colors.isDark
        ? Colors.white
        : const Color(0xFF102116);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: .5),
        disabledForegroundColor: foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        ),
        textStyle: VnlfTypography.body(foreground)
            .copyWith(fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Text(label),
          if (icon != null) VnlfIcon(icon!, size: 15, color: foreground),
        ],
      ),
    );
  }
}

/// The X used by the website's dialogs.
class VnlfCloseButton extends StatelessWidget {
  const VnlfCloseButton({super.key, required this.onPressed, this.size = 18});

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return IconButton(
      tooltip: vi.dialog.dongHopThoai,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        ),
      ),
      icon: VnlfIcon(VnlfLucide.x, size: size, color: colors.muted),
    );
  }
}

/// Opens a website-style modal (share, report): a blurred backdrop and a
/// centred box, or a sheet at the bottom of phones narrower than 521px.
Future<T?> showVnlfModal<T>(
  BuildContext context, {
  required String label,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: label,
    barrierColor: Colors.transparent,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 160),
    pageBuilder: (context, _, _) => _ModalScaffold(child: builder(context)),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _ModalScaffold extends StatelessWidget {
  const _ModalScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final sheet = size.width <= 520;
    final box = Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: sheet
            ? const BorderRadius.vertical(
                top: Radius.circular(VnlfDimensions.radiusLg),
              )
            : BorderRadius.circular(VnlfDimensions.radiusLg),
        side: BorderSide(color: colors.line),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          22 + (sheet ? MediaQuery.paddingOf(context).bottom : 0),
        ),
        child: child,
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const ColoredBox(color: Color(0x73152219)),
            ),
          ),
        ),
        if (sheet)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: box,
            ),
          )
        else
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (size.width - 28).clamp(0, 480).toDouble(),
                ),
                child: box,
              ),
            ),
          ),
      ],
    );
  }
}

/// The header of a website modal: eyebrow, title, optional subtitle and X.
class VnlfModalHeader extends StatelessWidget {
  const VnlfModalHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Text(
                eyebrow,
                style: VnlfTypography.body(colors.textSubtle)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: VnlfTypography.body(colors.ink)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: VnlfTypography.body(colors.muted)),
            ],
          ),
        ),
        VnlfCloseButton(onPressed: () => Navigator.of(context).maybePop()),
      ],
    );
  }
}

OverlayEntry? _toast;
Timer? _toastTimer;

/// The website's toast: a dark green pill near the bottom for 2.4 seconds.
void showVnlfToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _toastTimer?.cancel();
  _toast?.remove();
  final colors = VnlfColors.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 16,
      right: 16,
      bottom: 24 + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.brandStrong,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
              boxShadow: vnlfHardShadow(colors),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                const VnlfIcon(
                  VnlfLucide.circleCheck,
                  size: 16,
                  color: Colors.white,
                ),
                Flexible(
                  child: Text(
                    message,
                    style: VnlfTypography.body(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  _toast = entry;
  overlay.insert(entry);
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
  _toastTimer = Timer(const Duration(milliseconds: 2400), () {
    if (_toast == entry) {
      entry.remove();
      _toast = null;
    }
  });
}
