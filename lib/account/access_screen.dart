import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../branding.dart';
import '../area_check/check_ui.dart';
import 'session_controller.dart';
import 'auth_feedback.dart';
import 'biometric_login_service.dart';

const guestStorageMessage =
    'You can use Flatverify.ai without an account. Guest calculations are stored only on this device and may be lost if the application is removed or its data is cleared.';

class AccessScreen extends StatefulWidget {
  const AccessScreen({
    super.key,
    this.register = false,
    this.controller,
    this.termsUrl = const String.fromEnvironment('TERMS_URL'),
    this.privacyUrl = const String.fromEnvironment('PRIVACY_URL'),
  });
  final bool register;
  final SessionController? controller;
  final String termsUrl, privacyUrl;
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final name = TextEditingController();
  final passwordFocus = FocusNode();
  SessionController get session =>
      widget.controller ?? SessionController.instance;
  late bool register = widget.register;
  bool busy = false,
      obscure = true,
      accepted = false,
      remember = true,
      verifying = false;
  String? feedback, emailError, passwordError, biometricLabel;
  Timer? cooldown;
  int resendSeconds = 0;
  String get termsUrl => widget.termsUrl;
  String get privacyUrl => widget.privacyUrl;
  bool get policiesReady => [termsUrl, privacyUrl].every(
    (value) =>
        Uri.tryParse(value)?.scheme == 'https' &&
        (Uri.tryParse(value)?.host.isNotEmpty ?? false),
  );
  @override
  void initState() {
    super.initState();
    remember = session.rememberSession;
    if (!register) email.text = session.lastEmail;
    loadBiometrics();
  }

  Future<void> loadBiometrics() async {
    final label = await session.biometricButtonLabel();
    if (mounted) setState(() => biometricLabel = label);
  }

  @override
  void dispose() {
    cooldown?.cancel();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    name.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    if (register &&
        (value.length < 8 ||
            !RegExp(r'[A-Za-z]').hasMatch(value) ||
            !RegExp(r'[0-9]').hasMatch(value))) {
      return 'Use at least 8 characters, including a letter and a number.';
    }
    return null;
  }

  void failure(Object error) {
    final text = error is BiometricFailure
        ? error.message
        : authErrorMessage(error);
    if (!mounted) return;
    setState(() {
      feedback = text;
      if (error is FirebaseAuthException &&
          ['invalid-email', 'email-already-in-use'].contains(error.code)) {
        emailError = text;
      }
      if (error is FirebaseAuthException &&
          [
            'wrong-password',
            'invalid-credential',
            'user-not-found',
            'weak-password',
          ].contains(error.code)) {
        passwordError = text;
        password.clear();
        confirmation.clear();
        passwordFocus.requestFocus();
      }
    });
  }

  Future<void> finish(User user) async {
    if (!remember && session.biometricEnabled) {
      await session.disableBiometrics();
    }
    await session.setRememberSession(remember);
    await session.setRememberEmail(remember);
    await session.activateUser(user);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> submit() async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      feedback = null;
      emailError = null;
      passwordError = null;
    });
    if (!verifying && !form.currentState!.validate()) return;
    if (register && !verifying && !accepted) {
      setState(
        () => feedback = 'Accept the Terms and Privacy Policy to continue.',
      );
      return;
    }
    if (!session.authenticationReady) {
      setState(
        () => feedback =
            'Account sign-in is not configured yet. You can continue as a guest.',
      );
      return;
    }
    // TODO(owner): supply the published HTTPS TERMS_URL and PRIVACY_URL before public registration.
    if (register && !verifying && !policiesReady) {
      setState(
        () => feedback =
            'Account registration will be available after the app owner publishes the Terms and Privacy Policy.',
      );
      return;
    }
    setState(() => busy = true);
    try {
      if (verifying) {
        await session.auth!.currentUser?.reload();
        final current = session.auth!.currentUser;
        if (current?.emailVerified != true) {
          setState(
            () => feedback =
                'Your email is not verified yet. Open the link in your inbox, then try again.',
          );
          return;
        }
        await finish(current!);
        return;
      }
      final result = register
          ? await session.auth!.createUserWithEmailAndPassword(
              email: email.text.trim(),
              password: password.text,
            )
          : await session.auth!.signInWithEmailAndPassword(
              email: email.text.trim(),
              password: password.text,
            );
      final user = result.user;
      if (user == null) {
        throw const BiometricFailure(
          'Sign-in could not be completed. Please try again.',
        );
      }
      TextInput.finishAutofillContext(shouldSave: remember);
      password.clear();
      confirmation.clear();
      if (register) await user.updateDisplayName(name.text.trim());
      if (!user.emailVerified) {
        setState(() => verifying = true);
        if (register) {
          await sendVerification();
        } else {
          setState(
            () => feedback =
                'Verify your email before signing in. You can request another verification link below.',
          );
        }
      } else {
        await finish(user);
      }
    } catch (error) {
      failure(error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> sendVerification() async {
    if (resendSeconds > 0) return;
    setState(() => resendSeconds = 60);
    cooldown?.cancel();
    cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => resendSeconds--);
      if (resendSeconds == 0) timer.cancel();
    });
    try {
      await session.auth!.currentUser!.sendEmailVerification();
      if (mounted) {
        setState(
          () => feedback =
              'Verification email sent. Check your inbox and spam folder.',
        );
      }
    } catch (error) {
      failure(error);
    }
  }

  Future<void> resetPassword() async {
    if (busy) return;
    final validation = validateEmail(email.text);
    if (validation != null) {
      setState(() => emailError = validation);
      return;
    }
    if (!session.authenticationReady) {
      setState(
        () => feedback =
            'Password recovery is not configured yet. You can continue as a guest.',
      );
      return;
    }
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      await session.auth!.sendPasswordResetEmail(email: email.text.trim());
      if (mounted) {
        setState(
          () => feedback =
              'If this address has an account, a password reset email will arrive shortly.',
        );
      }
    } catch (error) {
      failure(error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> biometricSignIn() async {
    if (busy) return;
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      await session.signInWithBiometrics();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      failure(error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> guest() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await session.enterGuest();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        setState(
          () => feedback = 'Could not open guest mode. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openPolicy(String url) async {
    try {
      if (!policiesReady ||
          !await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          )) {
        throw StateError('Unavailable');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => feedback =
              'The app owner has not made the full Terms and Privacy Policy available yet. Registration is not enabled until they are published.',
        );
      }
    }
  }

  Widget input(
    TextEditingController controller,
    String label, {
    bool secret = false,
    String? Function(String?)? validator,
    String? error,
    List<String>? autofill,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: controller,
      enabled: !busy,
      focusNode: controller == password ? passwordFocus : null,
      obscureText: secret && obscure,
      autocorrect: false,
      enableSuggestions: !secret,
      keyboardType: controller == email
          ? TextInputType.emailAddress
          : TextInputType.text,
      autofillHints: autofill,
      textInputAction: secret ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: secret ? (_) => submit() : null,
      validator: validator,
      onChanged: (_) {
        if (controller == email && emailError != null) {
          setState(() => emailError = null);
        }
        if (controller == password && passwordError != null) {
          setState(() => passwordError = null);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        errorMaxLines: 3,
        prefixIcon: Icon(
          controller == email
              ? Icons.mail_outline
              : secret
              ? Icons.lock_outline
              : Icons.person_outline,
        ),
        suffixIcon: secret
            ? IconButton(
                tooltip: obscure ? 'Show password' : 'Hide password',
                onPressed: busy
                    ? null
                    : () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: Text(register ? 'Create account' : 'Sign in')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: FLogo(size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        verifying
                            ? 'Check your inbox.'
                            : register
                            ? 'Your next chapter\nstarts with clarity.'
                            : 'Welcome back.',
                        style: const TextStyle(
                          fontSize: 29,
                          letterSpacing: -.7,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        verifying
                            ? 'Open the verification link sent to ${email.text.trim()}, then return here.'
                            : register
                            ? 'Create your Flatverify.ai account. Your calculator is always free.'
                            : 'Sign in to your account, or explore at your own pace as a guest.',
                        style: const TextStyle(
                          color: CheckPalette.muted,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!session.authenticationReady)
                        const CheckHint(
                          'Account sign-in is not configured in this build. The calculator works in guest mode.',
                        ),
                      if (!verifying) ...[
                        if (register)
                          input(
                            name,
                            'Full name',
                            autofill: const [AutofillHints.name],
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter your full name.'
                                : null,
                          ),
                        input(
                          email,
                          'Email address',
                          error: emailError,
                          validator: validateEmail,
                          autofill: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                        ),
                        input(
                          password,
                          'Password',
                          secret: true,
                          error: passwordError,
                          validator: validatePassword,
                          autofill: [
                            register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                        ),
                        if (register) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 18),
                            child: Text(
                              'Use 8 or more characters with letters and numbers. A longer, unique passphrase is stronger.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: CheckPalette.muted,
                              ),
                            ),
                          ),
                          input(
                            confirmation,
                            'Confirm password',
                            secret: true,
                            validator: (v) =>
                                v != password.text || (v?.isEmpty ?? true)
                                ? 'Passwords must match.'
                                : null,
                            autofill: const [AutofillHints.newPassword],
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: accepted,
                            onChanged: busy
                                ? null
                                : (v) => setState(() => accepted = v!),
                            title: const Text(
                              'I accept the Terms and Privacy Policy.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          Wrap(
                            children: [
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => openPolicy(termsUrl),
                                child: const Text('Terms'),
                              ),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => openPolicy(privacyUrl),
                                child: const Text('Privacy Policy'),
                              ),
                            ],
                          ),
                          if (!policiesReady)
                            const CheckHint(
                              'The app owner must publish the Terms and Privacy Policy before registration can be enabled.',
                            ),
                        ] else ...[
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: remember,
                            onChanged: busy
                                ? null
                                : (v) => setState(() => remember = v!),
                            title: const Text('Remember Me'),
                            subtitle: const Text(
                              'Keep me signed in on this device. Never save my password.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: busy ? null : resetPassword,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ],
                      ],
                      if (feedback != null)
                        Semantics(
                          liveRegion: true,
                          child: CheckHint(feedback!, warning: true),
                        ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: busy ? null : submit,
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                  semanticsLabel: 'Authenticating',
                                ),
                              )
                            : Text(
                                verifying
                                    ? 'I have verified my email'
                                    : register
                                    ? 'Create Account'
                                    : 'Sign In',
                              ),
                      ),
                      if (verifying)
                        TextButton(
                          onPressed: busy || resendSeconds > 0
                              ? null
                              : () async {
                                  setState(() => busy = true);
                                  await sendVerification();
                                  if (mounted) setState(() => busy = false);
                                },
                          child: Text(
                            resendSeconds > 0
                                ? 'Resend in ${resendSeconds}s'
                                : 'Resend verification email',
                          ),
                        ),
                      if (!register &&
                          !verifying &&
                          biometricLabel != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: busy ? null : biometricSignIn,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(biometricLabel!),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (!verifying)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () {
                                  setState(() {
                                    register = !register;
                                    accepted = false;
                                    feedback = null;
                                    emailError = null;
                                    passwordError = null;
                                    password.clear();
                                    confirmation.clear();
                                    form.currentState?.reset();
                                  });
                                },
                          child: Text(
                            register
                                ? 'Already have an account? Sign In'
                                : 'Create a New Account',
                          ),
                        ),
                      TextButton(
                        onPressed: busy ? null : guest,
                        child: const Text('Continue as Guest'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        guestStorageMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: CheckPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class BiometricLoginSetting extends StatefulWidget {
  const BiometricLoginSetting({super.key});
  @override
  State<BiometricLoginSetting> createState() => _BiometricLoginSettingState();
}

class _BiometricLoginSettingState extends State<BiometricLoginSetting> {
  bool available = false, busy = false;
  SessionController get session => SessionController.instance;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final types = await session.biometrics.available();
    if (mounted) setState(() => available = types.isNotEmpty);
  }

  Future<void> toggle(bool enabled) async {
    if (busy) return;
    if (enabled) {
      final consent = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Enable Biometric Login?'),
          content: const Text(
            'Anyone with biometrics enrolled on this device may unlock your account. Flatverify.ai never receives fingerprint or face data. Your existing Firebase session is used after a successful device check. Logging out disables biometric login.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      if (consent != true || !mounted) return;
    }
    setState(() => busy = true);
    try {
      if (enabled) {
        await session.enableBiometrics();
      } else {
        await session.disableBiometrics();
      }
    } catch (error) {
      if (mounted) {
        showAuthFeedback(
          context,
          error is BiometricFailure
              ? error.message
              : 'Could not change biometric login. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: SwitchListTile(
      secondary: const Icon(Icons.fingerprint, color: CheckPalette.blue),
      title: const Text('Enable Biometric Login'),
      subtitle: Text(
        !available
            ? 'Enrol fingerprint or face authentication in device settings to use this feature.'
            : !session.credentialAuthenticated && !session.biometricEnabled
            ? 'Sign in with your password before enabling.'
            : 'Use this device’s biometrics on your next visit.',
      ),
      value: session.biometricEnabled,
      onChanged: busy || (!available && !session.biometricEnabled)
          ? null
          : toggle,
    ),
  );
}
