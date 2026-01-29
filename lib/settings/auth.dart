import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:tomo/action_button.dart';
import 'package:tomo/app_state.dart';
import 'package:tomo/svg_icon.dart';

import 'package:tomo/platform.dart' as platform;

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.user != null)
              Text(state.user!.email!)
            else
              const Text(
                  'Sign in to synchronize timers between multiple devices.'),
            const SizedBox(height: 10),
            ActionButton(
              onPressed: state.user == null
                  ? () => _signInWithGoogle(context)
                  : () => _signOut(context),
              left: state.user == null
                  ? const SvgIcon('google', useOriginalColor: true)
                  : const SvgIcon("circle-out"),
              center:
                  Text(state.user == null ? 'Sign in with Google' : 'Sign out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
    }
    platform.openWindow();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
