import 'package:flutter/material.dart';

import '../../../design_system/tokens/vnlf_colors.dart';
import '../../../design_system/tokens/vnlf_dimensions.dart';
import '../../../design_system/tokens/vnlf_typography.dart';
import '../domain/community_status.dart';

/// A compact, localized notice for connection states that need attention.
final class CommunityConnectionNotice extends StatelessWidget {
  const CommunityConnectionNotice({
    required this.status,
    this.onRetry,
    super.key,
  });

  final CommunitySocketStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final phase = status.phase;
    if (phase != CommunityConnectionPhase.connecting &&
        phase != CommunityConnectionPhase.reconnecting &&
        phase != CommunityConnectionPhase.failed &&
        phase != CommunityConnectionPhase.revoked) {
      return const SizedBox.shrink();
    }

    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final message = _message(phase, isEnglish);
    final iconColor = switch (phase) {
      CommunityConnectionPhase.failed => colors.red,
      CommunityConnectionPhase.revoked => colors.orange,
      _ => colors.brand,
    };
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label: message,
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: _StatusGlyph(
                      phase: phase,
                      color: iconColor,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      softWrap: true,
                      style: VnlfTypography.body(colors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (phase == CommunityConnectionPhase.failed && onRetry != null)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: colors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: VnlfTypography.control(
                    colors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                  minimumSize: const Size(48, 48),
                ),
                child: Text(isEnglish ? 'Retry' : 'Thử lại'),
              ),
            ),
        ],
      ),
    );
  }

  static String _message(CommunityConnectionPhase phase, bool isEnglish) {
    return switch ((phase, isEnglish)) {
      (CommunityConnectionPhase.connecting, true) =>
        'Connecting to update messages.',
      (CommunityConnectionPhase.reconnecting, true) =>
        'Reconnecting to update messages.',
      (CommunityConnectionPhase.failed, true) =>
        'Incoming messages cannot update right now.',
      (CommunityConnectionPhase.revoked, true) =>
        'Your session has expired. Please sign in again.',
      (CommunityConnectionPhase.connecting, false) =>
        'Đang kết nối để cập nhật tin nhắn.',
      (CommunityConnectionPhase.reconnecting, false) =>
        'Đang kết nối lại để cập nhật tin nhắn.',
      (CommunityConnectionPhase.failed, false) =>
        'Tin nhắn mới chưa thể cập nhật lúc này.',
      (CommunityConnectionPhase.revoked, false) =>
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      _ => '',
    };
  }
}

final class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({
    required this.phase,
    required this.color,
    required this.reduceMotion,
  });

  final CommunityConnectionPhase phase;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (phase == CommunityConnectionPhase.connecting ||
        phase == CommunityConnectionPhase.reconnecting) {
      if (reduceMotion) {
        return Icon(Icons.sync, size: 18, color: color);
      }
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    return Icon(
      phase == CommunityConnectionPhase.failed
          ? Icons.cloud_off_outlined
          : Icons.lock_outline,
      size: 18,
      color: color,
    );
  }
}
