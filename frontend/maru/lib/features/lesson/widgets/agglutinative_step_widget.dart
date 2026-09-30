import 'package:flutter/material.dart';
import '../models/agglutinative_quiz_model.dart';

class AgglutinativeStepWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onNext;

  const AgglutinativeStepWidget({
    super.key,
    required this.content,
    required this.onNext,
  });

  @override
  State<AgglutinativeStepWidget> createState() => _AgglutinativeStepWidgetState();
}

class _AgglutinativeStepWidgetState extends State<AgglutinativeStepWidget>
    with SingleTickerProviderStateMixin {
  late AgglutinativeQuizData data;

  // Phase 1 = Rabbit (chunk), Phase 2 = Turtle (morpheme)
  bool isTurtleMode = false;
  bool _rabbitPhaseComplete = false;

  Map<String, AgglutinativeOption?> droppedAnswers = {};

  // Inline feedback shown above the Check button (snackbars used to cover it)
  String? _feedback;
  bool _feedbackIsError = false;

  late AnimationController _phaseTransitionController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    data = AgglutinativeQuizData.fromJson(widget.content);
    _phaseTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _phaseTransitionController,
      curve: Curves.easeInOut,
    );
    _phaseTransitionController.forward();
  }

  @override
  void dispose() {
    _phaseTransitionController.dispose();
    super.dispose();
  }

  bool _isAnswerCorrect() {
    for (var element in data.elements) {
      if (element.isTarget) {
        if (!isTurtleMode) {
          final dropped = droppedAnswers[element.id];
          if (dropped == null || !element.correctRabbit.contains(dropped.text)) {
            return false;
          }
        } else {
          for (int i = 0; i < element.correctTurtle.length; i++) {
            final dropped = droppedAnswers['${element.id}_$i'];
            if (dropped == null || element.correctTurtle[i] != dropped.text) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  bool _isAllSlotsFilled() {
    for (var element in data.elements) {
      if (element.isTarget) {
        if (!isTurtleMode) {
          if (!droppedAnswers.containsKey(element.id) || droppedAnswers[element.id] == null) {
            return false;
          }
        } else {
          for (int i = 0; i < element.correctTurtle.length; i++) {
            if (!droppedAnswers.containsKey('${element.id}_$i') ||
                droppedAnswers['${element.id}_$i'] == null) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  void _onCheckPressed() {
    if (_isAnswerCorrect()) {
      if (!isTurtleMode) {
        // Phase 1 complete → auto-advance to Turtle mode
        _phaseTransitionController.reverse().then((_) {
          if (!mounted) return;
          setState(() {
            _rabbitPhaseComplete = true;
            isTurtleMode = true;
            droppedAnswers.clear();
            _feedback = 'Great! Now split each block into its smallest parts.';
            _feedbackIsError = false;
          });
          _phaseTransitionController.forward();
        });
      } else {
        // Phase 2 complete → move to next step
        widget.onNext();
      }
    } else {
      setState(() {
        _feedback = 'Not quite. Tap a placed block to remove it and try again.';
        _feedbackIsError = true;
      });
    }
  }

  void _clearErrorFeedback() {
    if (_feedbackIsError) _feedback = null;
  }

  @override
  Widget build(BuildContext context) {
    final activeOptions = data.options.where((opt) {
      bool modeMatches = opt.mode == (isTurtleMode ? 'turtle' : 'rabbit');
      bool isDropped = droppedAnswers.values.any((dropped) => dropped?.id == opt.id);
      return modeMatches && !isDropped;
    }).toList();

    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Phase indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        _buildPhaseChip(
                          label: '① Chunk',
                          icon: '🐰',
                          active: !isTurtleMode,
                          done: _rabbitPhaseComplete,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        ),
                        _buildPhaseChip(
                          label: '② Morpheme',
                          icon: '🐢',
                          active: isTurtleMode,
                          done: false,
                        ),
                      ],
                    ),
                  ),

                  // Instruction / target sentence card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          isTurtleMode ? 'Now split each block into morphemes!' : 'Build the sentence',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data.translation,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Sentence Board
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: data.elements.map((el) => _buildElementBlock(el)).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Options Tray
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: activeOptions.isEmpty
                        ? Text(
                            'All blocks placed',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: activeOptions.map((opt) => _buildDraggableOption(opt)).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Inline feedback + Check (always visible, never covered)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_feedback != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _feedbackIsError
                          ? colorScheme.errorContainer
                          : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (_feedbackIsError ? '🤔 ' : '✅ ') + _feedback!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _feedbackIsError ? colorScheme.onErrorContainer : Colors.green.shade800,
                      ),
                    ),
                  ),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isAllSlotsFilled() ? _onCheckPressed : null,
                    child: Text(
                      isTurtleMode ? 'Check & Finish' : 'Check',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChip({
    required String label,
    required String icon,
    required bool active,
    required bool done,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.shade50
            : (active ? const Color(0xFF6B4EFF).withValues(alpha: 0.1) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done
              ? Colors.green
              : (active ? const Color(0xFF6B4EFF) : Colors.grey.shade300),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            done ? '$label ✓' : label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active || done ? FontWeight.bold : FontWeight.normal,
              color: done
                  ? Colors.green.shade700
                  : (active ? const Color(0xFF6B4EFF) : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementBlock(AgglutinativeElement element) {
    if (!element.isTarget) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          element.text ?? '',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (!isTurtleMode) {
      return _buildDropZone(element.id, '...');
    } else {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(
          element.correctTurtle.length,
          (index) => _buildDropZone('${element.id}_$index', '?'),
        ),
      );
    }
  }

  Widget _buildDropZone(String slotKey, String placeholder) {
    return DragTarget<AgglutinativeOption>(
      onAcceptWithDetails: (details) {
        setState(() {
          droppedAnswers[slotKey] = details.data;
          _clearErrorFeedback();
        });
      },
      builder: (context, candidateData, rejectedData) {
        final dropped = droppedAnswers[slotKey];
        final isHovering = candidateData.isNotEmpty;

        return InkWell(
          onTap: dropped != null
              ? () {
                  setState(() {
                    droppedAnswers.remove(slotKey);
                    _clearErrorFeedback();
                  });
                }
              : null,
          child: Container(
            constraints: const BoxConstraints(minWidth: 70),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: dropped != null
                  ? const Color(0xFF6B4EFF).withValues(alpha: 0.1)
                  : (isHovering ? const Color(0xFF6B4EFF).withValues(alpha: 0.05) : Colors.grey.shade50),
              border: Border.all(
                color: dropped != null
                    ? const Color(0xFF6B4EFF)
                    : (isHovering ? const Color(0xFF6B4EFF) : Colors.grey.shade300),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dropped?.text ?? placeholder,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dropped != null ? const Color(0xFF6B4EFF) : Colors.grey.shade400,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableOption(AgglutinativeOption option) {
    final block = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EFF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        option.text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    return Draggable<AgglutinativeOption>(
      data: option,
      feedback: Material(
        color: Colors.transparent,
        child: block,
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: block,
      ),
      child: block,
    );
  }
}
