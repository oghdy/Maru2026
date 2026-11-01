import 'package:flutter/widgets.dart';

import 'browser_accessory_bar_stub.dart' if (dart.library.js_interop) 'browser_accessory_bar_web.dart';

/// Above this bottom inset the on-screen keyboard is up. Smaller values come from browser toolbars
/// or from the bar alone when a hardware keyboard is attached.
const double kKeyboardOpenInset = 100;

bool isKeyboardOpen(BuildContext context) => MediaQuery.viewInsetsOf(context).bottom > kKeyboardOpenInset;

final double _browserBarHeight = floatingAccessoryBarHeight();

/// Put above a Scaffold that has a text field. Adds what the browser's floating accessory bar covers to
/// the keyboard height, so the layout ends above the bar. Outside iOS 26 browsers this returns [child] as is.
class WebKeyboardInsets extends StatelessWidget {
  final Widget child;
  final double? barHeight;

  const WebKeyboardInsets({super.key, required this.child, @visibleForTesting this.barHeight});

  @override
  Widget build(BuildContext context) {
    final bar = barHeight ?? _browserBarHeight;
    if (bar == 0) return child;

    final media = MediaQuery.of(context);
    // Landscape has no height to spare: keep what the browser reports.
    final addBar = isKeyboardOpen(context) && media.size.height > media.size.width;
    return MediaQuery(
      data: media.copyWith(
        viewInsets: media.viewInsets.copyWith(bottom: media.viewInsets.bottom + (addBar ? bar : 0)),
      ),
      child: child,
    );
  }
}
