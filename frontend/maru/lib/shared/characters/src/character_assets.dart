import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'character_types.dart';

/// Knows which character PNGs are actually bundled, so missing files never
/// hit the image loader (no exceptions, no red screen, no console spam).
///
/// Fallback (CHARACTER_API §1): `<kind>_<mood>.png` → `<kind>_idle.png` → code placeholder.
class CharacterAssets {
  CharacterAssets._();

  static const dir = 'assets/characters/';

  /// Gallery/debug switch: draw the code placeholder even when PNGs exist.
  static final ValueNotifier<bool> forcePlaceholder = ValueNotifier(false);

  static Set<String>? _available;
  static Future<Set<String>>? _loading;
  static final _revision = ValueNotifier(0);

  /// Fires when [forcePlaceholder] flips or [reload] finds a new asset list.
  static final Listenable changes = Listenable.merge([forcePlaceholder, _revision]);

  /// Re-read the manifest and drop decoded images, so PNGs added while the app
  /// runs show up after a hot reload (statics survive hot reload). The old list
  /// stays in use until the new one is ready, so nothing flickers.
  static Future<void> reload() async {
    rootBundle.clear(); // AssetManifest.bin is cached by the bundle
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await (_loading = _load()); // _load swaps _available when done
    _revision.value++;
  }

  static String path(MaruCharacterKind kind, String name) => '$dir${kind.name}_$name.png';

  /// Null until the manifest has been read once.
  static Set<String>? get availableSync => _available;

  static Future<Set<String>> ensureLoaded() {
    if (_available != null) return SynchronousFuture(_available!);
    return _loading ??= _load();
  }

  static Future<Set<String>> _load() async {
    Set<String> found;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      found = manifest.listAssets().where((a) => a.startsWith(dir)).toSet();
    } catch (_) {
      // No manifest / no assets section yet → placeholders everywhere.
      found = <String>{};
    }
    _available = found;
    return found;
  }

  /// Image to show for [mood], or null for the code placeholder.
  static String? face(MaruCharacterKind kind, MaruMood mood) {
    final av = _available;
    if (av == null || forcePlaceholder.value) return null;
    final exact = path(kind, mood.name);
    if (av.contains(exact)) return exact;
    final idle = path(kind, MaruMood.idle.name);
    return av.contains(idle) ? idle : null;
  }

  static String? blink(MaruCharacterKind kind) {
    final av = _available;
    if (av == null || forcePlaceholder.value) return null;
    final p = path(kind, 'blink');
    return av.contains(p) ? p : null;
  }

  /// All existing images for [kind] (7 moods + blink).
  static List<String> existingFor(MaruCharacterKind kind) {
    final av = _available ?? const <String>{};
    return [
      for (final name in [...MaruMood.values.map((m) => m.name), 'blink'])
        if (av.contains(path(kind, name))) path(kind, name),
    ];
  }

  /// Warm the image cache; missing/undecodable files are silently ignored.
  static Future<void> precache(BuildContext context, MaruCharacterKind kind, {int? cacheWidth}) async {
    await ensureLoaded();
    if (!context.mounted) return;
    await Future.wait([
      for (final p in existingFor(kind))
        precacheImage(
          ResizeImage.resizeIfNeeded(cacheWidth, null, AssetImage(p)),
          context,
          onError: (_, _) {},
        ),
    ]);
  }

  @visibleForTesting
  static void debugSetAvailable(Set<String>? assets) {
    _available = assets;
    _loading = assets == null ? null : SynchronousFuture(assets);
  }
}
