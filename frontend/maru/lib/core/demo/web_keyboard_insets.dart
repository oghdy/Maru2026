import 'package:flutter/widgets.dart';

/// Above this bottom inset the on-screen keyboard is up. Smaller values come from browser toolbars
/// or from the bar alone when a hardware keyboard is attached.
const double kKeyboardOpenInset = 100;

/// The inset is all a page needs to stay clear of the keyboard. On iOS 26 the browser's visualViewport
/// already ends above the floating accessory bar (and above Safari's address pill), so Flutter's inset
/// covers them too: measured on an iPhone 17 Pro with iOS 26.2 (LOG WEB-5.17.7).
bool isKeyboardOpen(BuildContext context) => MediaQuery.viewInsetsOf(context).bottom > kKeyboardOpenInset;
