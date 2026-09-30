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
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: hasCharacter ? onClear : null,
      child: Container(
        // Width comes from the parent (Expanded in HangeulLabScreen) so it fits narrow screens.
        height: 100,
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer.withValues(alpha: 0.35) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? cs.primary : cs.outlineVariant, width: isActive ? 2 : 1.5),
          boxShadow: [
            if (!hasCharacter && !isActive)
              BoxShadow(color: cs.shadow.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: hasCharacter
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    character!.char,
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                  Positioned(top: 6, right: 6, child: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant)),
                ],
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: isActive ? cs.primary : cs.outline, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '$stepNumber',
                          style: TextStyle(color: cs.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.add_circle_outline, color: isActive ? cs.primary : cs.outline, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
