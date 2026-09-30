import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/providers/auth_provider.dart';

const _iosGoogleClientId = '691622930644-agurfnaal2dd9vihp0fuv0b7op0te75c.apps.googleusercontent.com';
const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _handleGoogleSignIn(WidgetRef ref) async {
    try {
      // NOTE: For iOS/Web, make sure clientId is correctly populated here if needed.
      // But for Android with google-services.json, this is usually enough.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: <String>['email'],
        // iOS has no GoogleService-Info.plist / GIDClientID, and the native SDK
        // aborts the app when signIn() runs without a client id. This is the iOS
        // OAuth client matching REVERSED_CLIENT_ID in ios/Runner/Info.plist.
        // Android keeps using google-services.json.
        clientId: defaultTargetPlatform == TargetPlatform.iOS ? _iosGoogleClientId : null,
        // The server checks the id token audience against its GOOGLE_CLIENT_ID;
        // pass it with --dart-define=GOOGLE_SERVER_CLIENT_ID=... when known.
        serverClientId: _googleServerClientId.isEmpty ? null : _googleServerClientId,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final tokenToSend = googleAuth.idToken ?? googleAuth.accessToken;
        if (tokenToSend != null) {
          // Send idToken or accessToken to Maru Backend
          await ref.read(authProvider.notifier).loginWithBackend('google', tokenToSend);
        } else {
          debugPrint('Google Sign In: both idToken and accessToken are null');
          ref.read(authProvider.notifier).setError('Google sign-in did not return an account token. Please try again.');
        }
      }
    } catch (error) {
      debugPrint('Error signing in with Google: $error');
      ref.read(authProvider.notifier).setError("Google sign-in isn't available right now. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Maru',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                // Slogan (was 'Korean Grammar Lab', which named only one feature)
                'Learn Korean, one piece at a time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              if (authState == AuthState.loading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton.icon(
                  onPressed: () => _handleGoogleSignIn(ref),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final credential = await SignInWithApple.getAppleIDCredential(
                        scopes: [
                          AppleIDAuthorizationScopes.email,
                          AppleIDAuthorizationScopes.fullName,
                        ],
                      );
                      
                      if (credential.identityToken != null) {
                        await ref.read(authProvider.notifier).loginWithBackend('apple', credential.identityToken!);
                      } else {
                        debugPrint('Apple Sign In: identityToken is null');
                        ref.read(authProvider.notifier).setError('Apple sign-in did not return an account token. Please try again.');
                      }
                    } on SignInWithAppleAuthorizationException catch (e) {
                      debugPrint('Apple sign-in: $e');
                      // User closed the Apple sheet: not an error worth showing
                      if (e.code != AuthorizationErrorCode.canceled) {
                        ref.read(authProvider.notifier).setError("Apple sign-in isn't available right now. Please try again.");
                      }
                    } catch (e) {
                      debugPrint('Error signing in with Apple: $e');
                      ref.read(authProvider.notifier).setError("Apple sign-in isn't available right now. Please try again.");
                    }
                  },
                  icon: const Icon(Icons.apple),
                  label: const Text('Sign in with Apple'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              
              if (authState == AuthState.error) ...[
                const SizedBox(height: 16),
                Text(
                  ref.read(authProvider.notifier).errorMessage ?? 'Failed to sign in. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
