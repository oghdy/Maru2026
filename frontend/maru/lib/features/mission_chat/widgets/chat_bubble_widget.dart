import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';
import 'chat_correction_card.dart';
import '../models/chat_message_model.dart';

class ChatBubbleWidget extends StatefulWidget {
  final ChatMessage message;
  // Set for a user message that failed to send.
  final VoidCallback? onRetry;

  const ChatBubbleWidget({super.key, required this.message, this.onRetry});

  @override
  State<ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = message.role == 'user';
    final colors = Theme.of(context).colorScheme;
    // Rejected / unsent user messages are shown faded so it's clear they didn't count.
    final isMuted = message.isRejected || message.sendFailed;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.74;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.idle, size: 40, interactive: false),
                const SizedBox(width: 8),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                child: isUser ? _userBubble(colors, isMuted) : _partnerBubble(colors),
              ),
            ],
          ),

          if (isUser && message.isRejected)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Text(
                '🐢 Not sent — try saying it again',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
          if (isUser && message.sendFailed)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 16, color: colors.error),
                  const SizedBox(width: 4),
                  Text("Couldn't send", style: TextStyle(fontSize: 12, color: colors.error)),
                  if (widget.onRetry != null)
                    TextButton(
                      onPressed: widget.onRetry,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),

          // Turtle side correction = yellow card (MSN-1.7.3)
          if (message.isTurtleIntervention && message.turtleFeedback != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: ChatCorrectionCard(
                type: CorrectionCardType.yellow,
                issueLabel: correctionIssueLabel(message.turtleIssueType ?? ''),
                message: message.turtleFeedback,
                messageEn: message.turtleFeedbackEn,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _userBubble(ColorScheme colors, bool isMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        gradient: isMuted
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primary, Color.lerp(colors.primary, const Color(0xFF3D1FD6), 0.45)!],
              ),
        color: isMuted ? colors.primary.withValues(alpha: 0.35) : null,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(6),
        ),
        boxShadow: isMuted
            ? null
            : [BoxShadow(color: colors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Text(
        widget.message.content,
        style: TextStyle(fontSize: 16, height: 1.4, color: colors.onPrimary),
      ),
    );
  }

  Widget _partnerBubble(ColorScheme colors) {
    final en = widget.message.contentEn;
    return GestureDetector(
      onTap: en == null ? null : () => setState(() => _showTranslation = !_showTranslation),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: colors.primary.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message.content,
              style: TextStyle(fontSize: 16, height: 1.45, color: colors.onSurface),
            ),
            if (en != null) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topLeft,
                child: _showTranslation
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: colors.primary.withValues(alpha: 0.35), width: 2)),
                          ),
                          child: Text(
                            en,
                            style: TextStyle(fontSize: 13.5, height: 1.4, color: colors.onSurfaceVariant),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 8),
              // Small pill instead of a full-width button (MSN-1.7.6).
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTranslation ? Icons.visibility_off_outlined : Icons.translate_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showTranslation ? 'Hide' : 'Translate',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
