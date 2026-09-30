import 'package:flutter/material.dart';
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
    final isUser = widget.message.role == 'user';
    final colors = Theme.of(context).colorScheme;
    // Rejected / unsent user messages are shown faded so it's clear they didn't count.
    final isMuted = widget.message.isRejected || widget.message.sendFailed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const Text('🐰', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    if (!isUser && widget.message.contentEn != null) {
                      setState(() {
                        _showTranslation = !_showTranslation;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (isMuted ? colors.primary.withValues(alpha: 0.45) : colors.primary)
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: isUser ? colors.onPrimary : colors.onSurface,
                          ),
                        ),
                        if (!isUser && widget.message.contentEn != null) ...[
                          const SizedBox(height: 8),
                          if (_showTranslation) ...[
                            Divider(color: colors.outlineVariant),
                            const SizedBox(height: 4),
                            Text(
                              widget.message.contentEn!,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showTranslation = !_showTranslation;
                                });
                              },
                              icon: Icon(
                                _showTranslation ? Icons.visibility_off : Icons.translate,
                                size: 14,
                                color: colors.onSurfaceVariant,
                              ),
                              label: Text(
                                _showTranslation ? 'Hide translation' : 'See translation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                side: BorderSide(color: colors.outlineVariant),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (isUser && widget.message.isRejected)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '🐢 Not sent — try saying it again',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
          if (isUser && widget.message.sendFailed)
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

          // Turtle Intervention (Side effect)
          if (widget.message.isTurtleIntervention && widget.message.turtleFeedback != null) ...[
            const SizedBox(height: 8),
            Container(
              margin: EdgeInsets.only(left: isUser ? 0 : 32, right: isUser ? 32 : 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🐢', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message.turtleFeedback!,
                          style: TextStyle(fontSize: 14, color: colors.onTertiaryContainer),
                        ),
                        if (widget.message.turtleFeedbackEn != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.message.turtleFeedbackEn!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onTertiaryContainer.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
