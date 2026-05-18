import 'package:flutter/material.dart';
import '../viewmodels/hangeul_view_model.dart';

/// Reusable widget for individual Jamo (consonant or vowel) card
/// Supports drag and drop interaction with smooth animations
class JamoCardWidget extends StatefulWidget {
  final JamoData jamo;
  final Function(DraggableDetails) onDragEnd;
  final Function(DragUpdateDetails) onDragUpdate;

  const JamoCardWidget({
    Key? key,
    required this.jamo,
    required this.onDragEnd,
    required this.onDragUpdate,
  }) : super(key: key);

  @override
  State<JamoCardWidget> createState() => _JamoCardWidgetState();
}

class _JamoCardWidgetState extends State<JamoCardWidget>
    with SingleTickerProviderStateMixin {

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    // Animation for scale effect when dragging
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<JamoData>(
      data: widget.jamo,

      // Feedback widget shown while dragging (what user sees during drag)
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: _buildCard(isDragging: true),
        ),
      ),

      // Child when dragging (shows placeholder in original position)
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCard(isDragging: false),
      ),

      // Normal state (card at rest)
      child: _buildCard(isDragging: false),

      // Callbacks
      onDragStarted: () {
        setState(() {
          _isDragging = true;
        });
        _scaleController.forward();

        // Optional: Add haptic feedback for better UX
        // HapticFeedback.mediumImpact();
      },

      onDragEnd: (details) {
        setState(() {
          _isDragging = false;
        });
        _scaleController.reverse();
        widget.onDragEnd(details);
      },

      onDragUpdate: (details) {
        widget.onDragUpdate(details);
      },
    );
  }

  /// Builds the card UI with appropriate styling
  /// Different colors for consonants (blue) and vowels (pink)
  Widget _buildCard({required bool isDragging}) {
    // Different colors for consonants and vowels
    final isConsonant = widget.jamo.type == 'consonant';
    final backgroundColor = isConsonant
        ? const Color(0xFF3B82F6) // Blue for consonants
        : const Color(0xFFEC4899); // Pink for vowels

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isDragging ? _scaleAnimation.value : 1.0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDragging
                  ? [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main character (자음 or 모음)
                Center(
                  child: Text(
                    widget.jamo.character,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Type indicator badge (small label showing romanization)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.jamo.sound,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget for drop target area
/// Used to detect when a draggable Jamo card is dropped onto it
/// This creates the "magnetic" effect when cards get close
class JamoDropTarget extends StatefulWidget {
  final JamoData? targetJamo;
  final Function(JamoData draggedJamo)? onAccept;
  final Widget child;

  const JamoDropTarget({
    Key? key,
    this.targetJamo,
    this.onAccept,
    required this.child,
  }) : super(key: key);

  @override
  State<JamoDropTarget> createState() => _JamoDropTargetState();
}

class _JamoDropTargetState extends State<JamoDropTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<JamoData>(
      // Determine if this target will accept the dragged data
      onWillAccept: (data) {
        // Accept if dragged item is compatible
        if (widget.targetJamo == null || data == null) return false;

        // Consonant + Vowel or Vowel + Consonant combinations only
        final isDifferentType = data.type != widget.targetJamo!.type;
        return isDifferentType;
      },

      // Called when user releases drag over this target
      onAccept: (data) {
        setState(() {
          _isHovering = false;
        });

        if (widget.onAccept != null) {
          widget.onAccept!(data);
        }
      },

      // Called while dragging over this target
      onMove: (details) {
        if (!_isHovering) {
          setState(() {
            _isHovering = true;
          });
        }
      },

      // Called when drag leaves this target
      onLeave: (data) {
        setState(() {
          _isHovering = false;
        });
      },

      // Build the visual representation
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: _isHovering
                ? Border.all(
              color: const Color(0xFF6366F1),
              width: 3,
            )
                : null,
          ),
          child: widget.child,
        );
      },
    );
  }
}

