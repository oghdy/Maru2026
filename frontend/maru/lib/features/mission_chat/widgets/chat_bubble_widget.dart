import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

class ChatBubbleWidget extends StatefulWidget {
  final ChatMessage message;

  const ChatBubbleWidget({super.key, required this.message});

  @override
  State<ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';

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
                      color: isUser ? Colors.teal : Colors.grey.shade200,
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
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (!isUser && widget.message.contentEn != null) ...[
                          const SizedBox(height: 8),
                          if (_showTranslation) ...[
                            Divider(color: Colors.grey.shade300),
                            const SizedBox(height: 4),
                            Text(
                              widget.message.contentEn!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
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
                                color: Colors.grey.shade500,
                              ),
                              label: Text(
                                _showTranslation ? 'Hide translation' : 'See translation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                side: BorderSide(color: Colors.grey.shade300),
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
          
          // Turtle Intervention (Side effect)
          if (widget.message.isTurtleIntervention && widget.message.turtleFeedback != null) ...[
            const SizedBox(height: 8),
            Container(
              margin: EdgeInsets.only(left: isUser ? 0 : 32, right: isUser ? 32 : 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
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
                          style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
                        ),
                        if (widget.message.turtleFeedbackEn != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.message.turtleFeedbackEn!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
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
