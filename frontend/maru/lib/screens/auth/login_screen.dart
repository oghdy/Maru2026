import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _handleGoogleSignIn(WidgetRef ref) async {
    try {
      // NOTE: For iOS/Web, make sure clientId is correctly populated here if needed.
      // But for Android with google-services.json, this is usually enough.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: <String>['email'],
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
          ref.read(authProvider.notifier).setError('Tokens are null');
        }
      }
    } catch (error) {
      debugPrint('Error signing in with Google: $error');
      // Opt: show SnackBar
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
              const Text(
                'Maru',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Korean Grammar Lab',
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
                        ref.read(authProvider.notifier).setError('Apple identity token is null');
                      }
                    } catch (e) {
                      debugPrint('Error signing in with Apple: $e');
                      ref.read(authProvider.notifier).setError(e.toString());
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
                const Text(
                  'Failed to sign in. Please try again.',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
