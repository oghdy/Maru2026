import 'package:flutter/material.dart';
import '../models/hangeul_character.dart';

class HangeulSlot extends StatelessWidget {
  final int stepNumber;
  final String label;
  final HangeulCharacter? character;
  final VoidCallback? onClear;
  final bool isActive; // Highlights the slot if it's the current turn

  const HangeulSlot({
    super.key,
    required this.stepNumber,
    required this.label,
    this.character,
    this.onClear,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasCharacter = character != null;

    return GestureDetector(
      onTap: hasCharacter ? onClear : null,
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: [
            if (!hasCharacter && !isActive)
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: hasCharacter
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    character!.char,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.add_circle_outline,
                    color: isActive ? Colors.blue : Colors.grey.shade400,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.blue : Colors.grey.shade500,
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
