/// Which mascot to draw. 🐰 rabbit = fast/playful performer, 🐢 turtle = calm coach.
enum MaruCharacterKind { rabbit, turtle }

/// Facial expression + body-language set. See CHARACTER_API §2.3.
/// `magic` (v1.2) is appended at the end so existing values/order stay the same.
enum MaruMood { idle, happy, sad, thinking, talking, cheer, magic }

/// Where the character sits relative to the speech bubble.
enum MaruBubbleSide { left, right }
