import 'dart:js_interop';

@JS('navigator.userAgent')
external String get _userAgent;

@JS('CSS.supports')
external bool _cssSupports(String property, String value);

/// Height the floating form accessory bar (the up, down and check pill) covers above the keyboard,
/// in logical pixels. Measured on an iPhone screenshot: a 50 pt pill plus an 8 pt gap to the keyboard.
const double _floatingBarHeight = 58;

/// iOS 26 draws the accessory bar as a pill floating over the page, and Flutter's keyboard height
/// (from visualViewport) ends at the top of the keyboard, so the pill lands on our input.
/// Earlier iOS versions draw a solid bar that visualViewport already leaves out, so they need nothing.
///
/// The version comes from a WebKit 26 CSS feature rather than the user agent: Safari freezes the
/// OS version in its user agent, and Chrome and other in-app browsers on iOS share the same engine.
double floatingAccessoryBarHeight() {
  try {
    if (!_userAgent.contains('iPhone')) return 0;
    return _cssSupports('position-area', 'top') ? _floatingBarHeight : 0;
  } catch (_) {
    return 0;
  }
}
