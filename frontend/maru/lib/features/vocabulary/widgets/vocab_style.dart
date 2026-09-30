import 'package:flutter/material.dart';

/// 단어장 공용 비주얼: 덱별 아이콘·강조색, 등장 애니메이션 (VOC-1.5.1).
/// 강조색은 하드코딩 팔레트 대신 브랜드 primary 의 색상(hue)을 돌려서 만든다.
class DeckVisual {
  final IconData icon;
  final Color accent;
  final Color accentSoft;

  const DeckVisual(this.icon, this.accent, this.accentSoft);

  static const Map<String, (IconData, int)> _byKoreanTitle = {
    // (아이콘, primary 기준 hue 이동 단계)
    '쇼핑/경제': (Icons.shopping_bag_rounded, 0),
    '가족/인물': (Icons.family_restroom_rounded, 1),
    '기타/사물': (Icons.category_rounded, 2),
    '동작/상태': (Icons.directions_run_rounded, 3),
    '시간': (Icons.schedule_rounded, 4),
    '감정': (Icons.mood_rounded, 5),
    '학교/교육': (Icons.school_rounded, 6),
    '날씨/자연': (Icons.wb_sunny_rounded, 7),
    '직업/사회': (Icons.work_rounded, 8),
    '신체': (Icons.accessibility_new_rounded, 9),
    '음식': (Icons.restaurant_rounded, 10),
    '동물/식물': (Icons.pets_rounded, 11),
    '숫자/수량': (Icons.numbers_rounded, 12),
    '장소': (Icons.place_rounded, 13),
  };

  static DeckVisual of(BuildContext context, String koreanTitle) {
    final primary = Theme.of(context).colorScheme.primary;
    final entry = _byKoreanTitle[koreanTitle];
    final step = entry?.$2 ?? koreanTitle.hashCode.abs() % 14;
    // 14덱을 색상환에 고르게 (보라 → 파랑 → 청록 … 순), 채도·명도는 읽기 좋게 고정
    final hsl = HSLColor.fromColor(primary);
    final hue = (hsl.hue + step * (360 / 14)) % 360;
    // 노랑~연두 계열은 같은 명도에서 흐려 보여 더 어둡게
    final lightness = (hue >= 35 && hue <= 120) ? 0.40 : 0.52;
    final accent = HSLColor.fromAHSL(1, hue, 0.62, lightness).toColor();
    final soft = HSLColor.fromAHSL(1, hue, 0.75, 0.94).toColor();
    return DeckVisual(entry?.$1 ?? Icons.menu_book_rounded, accent, soft);
  }
}

/// Match Madness 강조색: primary 에서 hue +120° (따뜻한 코랄) — 학습(보라)과 구분되는 게임 톤
Color gameAccent(BuildContext context) {
  final hsl = HSLColor.fromColor(Theme.of(context).colorScheme.primary);
  return HSLColor.fromAHSL(1, (hsl.hue + 120) % 360, 0.85, 0.58).toColor();
}

/// 목록 항목이 순서대로 살짝 올라오며 나타나는 등장 효과.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration step;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 45),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    // 너무 뒤 항목까지 기다리지 않도록 지연은 최대 10단계
    final delay = widget.step * widget.index.clamp(0, 10);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// 누르면 살짝 눌리는(scale) 카드 래퍼.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
