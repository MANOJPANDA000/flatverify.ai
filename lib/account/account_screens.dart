import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../branding.dart';
import 'session_controller.dart';
import 'profile_widgets.dart';
import 'auth_feedback.dart';

void openSignIn(BuildContext context, {bool register = false}) =>
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignInScreen(register: register)),
    );

class SessionGateway extends StatelessWidget {
  final WidgetBuilder appBuilder;
  const SessionGateway({super.key, required this.appBuilder});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: SessionController.instance,
    builder: (context, _) {
      final session = SessionController.instance;
      return session.entered
          ? KeyedSubtree(
              key: ValueKey(session.user?.uid ?? 'guest'),
              child: appBuilder(context),
            )
          : const WelcomeScreen();
    },
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: FLogo(size: 48)),
                const SizedBox(height: 12),
                const Text(
                  'Flatverify.ai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dark,
                  ),
                ),
                const Text(
                  'Understand Your Property',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/branding/floor_plan_hero.png',
                    height: 120,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Know your space.\nUnderstand every square foot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Scan a plan. Check each room. Keep a clear report.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => openSignIn(context, register: true),
                  child: const Text('Get Started'),
                ),
                OutlinedButton(
                  onPressed: () => openSignIn(context),
                  child: const Text('Sign In'),
                ),
                TextButton(
                  onPressed: SessionController.instance.enterGuest,
                  child: const Text('Continue as Guest'),
                ),
                const Text(
                  'Guest reports last for this app session. Download a PDF or register to keep them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class GuestReportNotice extends StatelessWidget {
  const GuestReportNotice({super.key});
  @override
  Widget build(BuildContext context) {
    if (!SessionController.instance.isGuest) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your reports are temporary',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep them by registering, or download a PDF. Guest reports are cleared when a new app session starts.',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          TextButton(
            onPressed: () => openSignIn(context, register: true),
            child: const Text('Register & Keep Reports'),
          ),
        ],
      ),
    );
  }
}

enum _SignInStep { identifier, password, otp, verifyEmail }

class SignInScreen extends StatefulWidget {
  final bool register;
  const SignInScreen({super.key, this.register = false});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const phoneEnabled = bool.fromEnvironment('ENABLE_PHONE_AUTH');
  final identifier = TextEditingController();
  final password = TextEditingController();
  final passwordFocus = FocusNode();
  bool rememberEmail = true;
  final name = TextEditingController();
  final country = TextEditingController(text: '+91');
  final otp = TextEditingController();
  late bool registering;
  _SignInStep step = _SignInStep.identifier;
  bool busy = false;
  bool obscure = true;
  String? message;
  String? verificationId;
  int? resendToken;
  int resendSeconds = 0;
  Timer? timer;
  Timer? emailTimer;
  int emailResendSeconds = 0;
  int phoneRequest = 0;
  bool completing = false;
  SessionController get session => SessionController.instance;
  bool get isEmail => identifier.text.contains('@');
  String get phone => identifier.text.trim().startsWith('+')
      ? identifier.text.replaceAll(RegExp(r'[\s()-]'), '')
      : '${country.text.trim()}${identifier.text.replaceAll(RegExp(r'\D'), '')}';

  @override
  void initState() {
    super.initState();
    registering = widget.register;
    rememberEmail = session.preferences == null || session.rememberEmail;
    if (!registering) identifier.text = session.lastEmail;
  }

  @override
  void dispose() {
    timer?.cancel();
    emailTimer?.cancel();
    passwordFocus.dispose();
    phoneRequest++;
    for (final controller in [identifier, password, name, country, otp]) {
      controller.dispose();
    }
    super.dispose();
  }

  void showMessage(String text) {
    if (mounted) setState(() => message = text);
  }

  bool requireAuthentication() {
    if (session.authenticationReady) return true;
    showMessage('Sign-in is not available yet. Please continue as a guest.');
    return false;
  }

  Future<void> complete(User? user) async {
    if (!mounted || user == null || completing) return;
    completing = true;
    try {
      if (registering && name.text.trim().isNotEmpty) {
        await user.updateDisplayName(name.text.trim());
      }
      await session.activateUser(user);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      completing = false;
    }
  }

  String errorText(Object error) => authErrorMessage(error);
  Future<void> submit() async {
    if (busy) return;
    setState(() => message = null);
    if (step == _SignInStep.identifier) {
      if (registering && name.text.trim().isEmpty) {
        showMessage('Enter your name.');
        return;
      }
      if (!phoneEnabled && !isEmail) {
        showMessage('Enter a valid email address.');
        return;
      }
      if (isEmail) {
        if (!RegExp(
          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
        ).hasMatch(identifier.text.trim())) {
          showMessage('Enter a valid email address.');
          return;
        }
        setState(() => step = _SignInStep.password);
      } else {
        if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
          showMessage('Enter a valid mobile number and country code.');
          return;
        }
        await sendCode();
      }
      return;
    }
    if (!requireAuthentication()) return;
    if (step == _SignInStep.password &&
        (password.text.isEmpty || (registering && password.text.length < 8))) {
      showMessage(
        registering
            ? 'Use at least 8 characters for your password.'
            : 'Enter your password.',
      );
      return;
    }
    if (step == _SignInStep.otp && !RegExp(r'^\d{6}$').hasMatch(otp.text)) {
      showMessage('Enter the 6-digit code.');
      return;
    }
    setState(() => busy = true);
    try {
      if (step == _SignInStep.password) {
        final credential = registering
            ? await session.auth!.createUserWithEmailAndPassword(
                email: identifier.text.trim(),
                password: password.text,
              )
            : await session.auth!.signInWithEmailAndPassword(
                email: identifier.text.trim(),
                password: password.text,
              );
        TextInput.finishAutofillContext(shouldSave: true);
        password.clear();
        if (!credential.user!.emailVerified) {
          await showEmailVerification(credential.user!, send: registering);
        } else {
          await complete(credential.user);
        }
      } else if (step == _SignInStep.otp) {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId!,
          smsCode: otp.text,
        );
        final result = await session.auth!.signInWithCredential(credential);
        await complete(result.user);
      } else {
        await session.auth!.currentUser?.reload();
        final user = session.auth!.currentUser;
        if (user?.emailVerified == true) {
          await complete(user);
        } else {
          showMessage(
            'Your email is not verified yet. Open the link in your inbox, then try again.',
          );
        }
      }
    } catch (error) {
      showMessage(errorText(error));
      if (step == _SignInStep.password &&
          error is FirebaseAuthException &&
          [
            'wrong-password',
            'invalid-credential',
            'user-not-found',
          ].contains(error.code)) {
        password.clear();
        passwordFocus.requestFocus();
        if (mounted) showAuthFeedback(context, errorText(error));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> sendCode() async {
    if (busy || !requireAuthentication()) return;
    final request = ++phoneRequest;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await session.auth!.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: resendToken,
        verificationCompleted: (credential) async {
          if (!mounted || request != phoneRequest) return;
          try {
            await complete(
              (await session.auth!.signInWithCredential(credential)).user,
            );
          } catch (error) {
            showMessage(errorText(error));
          }
        },
        verificationFailed: (error) {
          if (!mounted || request != phoneRequest) return;
          setState(() {
            busy = false;
            message = errorText(error);
          });
        },
        codeSent: (id, token) {
          if (!mounted || request != phoneRequest) return;
          setState(() {
            verificationId = id;
            resendToken = token;
            busy = false;
            step = _SignInStep.otp;
            resendSeconds = 30;
          });
          timer?.cancel();
          timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!mounted || resendSeconds <= 1) {
              timer.cancel();
              if (mounted) setState(() => resendSeconds = 0);
            } else {
              setState(() => resendSeconds--);
            }
          });
        },
        codeAutoRetrievalTimeout: (id) {
          if (mounted && request == phoneRequest) {
            setState(() {
              verificationId = id;
              busy = false;
            });
          }
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          busy = false;
          message = errorText(error);
        });
      }
    }
  }

  void startEmailCooldown(int seconds) {
    emailTimer?.cancel();
    if (!mounted) return;
    setState(() => emailResendSeconds = seconds);
    emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => emailResendSeconds--);
      if (emailResendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> showEmailVerification(User user, {required bool send}) async {
    if (!mounted) return;
    // Account creation succeeded even if sending the verification email fails.
    setState(() => step = _SignInStep.verifyEmail);
    if (send) await sendVerificationEmail(user);
  }

  Future<void> sendVerificationEmail(User user) async {
    if (!mounted || emailResendSeconds > 0) return;
    startEmailCooldown(60);
    try {
      await user.sendEmailVerification();
      showMessage('Verification email sent. Check your inbox and spam folder.');
    } catch (error) {
      if (error is FirebaseAuthException && error.code == 'too-many-requests') {
        startEmailCooldown(300);
        showMessage(
          'Verification email requests are temporarily limited. Check your inbox '
          'and spam folder for an earlier link. Wait before requesting another '
          'email. The resend timer is an app precaution; Firebase may require '
          'a longer wait.',
        );
      } else {
        showMessage(errorText(error));
      }
    }
  }

  Future<void> emailAction({bool reset = false}) async {
    if (!reset && emailResendSeconds > 0) return;
    if (busy || !requireAuthentication()) return;
    setState(() => busy = true);
    try {
      if (reset) {
        await session.auth!.sendPasswordResetEmail(
          email: identifier.text.trim(),
        );
        showMessage(
          'If this address has an account, a password reset email will arrive shortly.',
        );
      } else {
        final user = session.auth!.currentUser;
        if (user == null) {
          showMessage(
            'Please sign in again before requesting a verification email.',
          );
          return;
        }
        await sendVerificationEmail(user);
      }
    } catch (error) {
      showMessage(errorText(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(registering ? 'Create account' : 'Sign in')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: FLogo(size: 44),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    step == _SignInStep.otp
                        ? 'Verify your mobile'
                        : step == _SignInStep.verifyEmail
                        ? 'Check your inbox'
                        : registering
                        ? 'Keep your property reports'
                        : 'Welcome back',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    phoneEnabled
                        ? 'Mobile number + OTP, or email + password.'
                        : 'Your measurements, reports, and next property decision — in one place.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  if (!phoneEnabled && step == _SignInStep.identifier) ...[
                    const SizedBox(height: 16),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: Icon(Icons.mail_outline, size: 16),
                          label: Text('Email sign-in'),
                        ),
                        Chip(
                          avatar: Icon(Icons.folder_outlined, size: 16),
                          label: Text('Keep reports'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (step == _SignInStep.identifier) ...[
                    if (registering) ...[
                      TextField(
                        controller: name,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: identifier,
                      keyboardType: phoneEnabled
                          ? TextInputType.text
                          : TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => submit(),
                      onChanged: (_) => setState(() {}),
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: phoneEnabled
                            ? 'Mobile number or email'
                            : 'Email address',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    if (phoneEnabled &&
                        !isEmail &&
                        identifier.text.isNotEmpty &&
                        !identifier.text.startsWith('+')) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: country,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Country code',
                          helperText: 'For example +91 for India',
                        ),
                      ),
                    ],
                  ] else ...[
                    if (step == _SignInStep.password && isEmail)
                      TextField(
                        controller: identifier,
                        readOnly: true,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                        ),
                      )
                    else
                      Text(
                        step == _SignInStep.otp
                            ? phone
                            : identifier.text.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              phoneRequest++;
                              timer?.cancel();
                              setState(() {
                                step = _SignInStep.identifier;
                                otp.clear();
                                password.clear();
                                obscure = true;
                                verificationId = null;
                                resendToken = null;
                                message = null;
                              });
                            },
                      child: const Text(
                        phoneEnabled
                            ? 'Change mobile number or email'
                            : 'Use a different email',
                      ),
                    ),
                    if (step == _SignInStep.password) ...[
                      TextField(
                        controller: password,
                        focusNode: passwordFocus,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => submit(),
                        obscureText: obscure,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: [
                          registering
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: obscure
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: rememberEmail,
                        title: const Text('Remember my email on this device'),
                        subtitle: const Text(
                          'Turn off on a shared device. Passwords are never saved by this app.',
                        ),
                        onChanged: busy
                            ? null
                            : (value) async {
                                try {
                                  await session.setRememberEmail(
                                    value ?? false,
                                  );
                                  if (mounted) {
                                    setState(
                                      () => rememberEmail = value ?? false,
                                    );
                                  }
                                } catch (_) {
                                  showMessage(
                                    'Could not save this preference. Please try again.',
                                  );
                                }
                              },
                      ),
                      if (!registering)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => emailAction(reset: true),
                          child: const Text('Forgot password?'),
                        ),
                    ],
                    if (step == _SignInStep.otp) ...[
                      const Text('Enter the 6-digit code sent to your mobile.'),
                      TextField(
                        controller: otp,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                        ),
                      ),
                      TextButton(
                        onPressed: busy || resendSeconds > 0 ? null : sendCode,
                        child: Text(
                          resendSeconds > 0
                              ? 'Resend code in ${resendSeconds}s'
                              : 'Resend code',
                        ),
                      ),
                    ],
                    if (step == _SignInStep.verifyEmail) ...[
                      const Text(
                        'Open the verification link in your email, then return here. '
                        'Check your Spam folder too. No code is needed.',
                      ),
                      TextButton(
                        onPressed: busy || emailResendSeconds > 0
                            ? null
                            : () => emailAction(),
                        child: Text(
                          emailResendSeconds > 0
                              ? 'Send again in ${emailResendSeconds}s'
                              : 'Send verification email',
                        ),
                      ),
                    ],
                  ],
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        message!,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      busy
                          ? 'Please wait…'
                          : step == _SignInStep.identifier
                          ? 'Continue'
                          : step == _SignInStep.otp
                          ? 'Verify & Sign In'
                          : step == _SignInStep.verifyEmail
                          ? 'I have verified my email'
                          : registering
                          ? 'Create Account'
                          : 'Sign In',
                    ),
                  ),
                  if (step == _SignInStep.identifier)
                    TextButton(
                      onPressed: () => setState(() {
                        registering = !registering;
                        message = null;
                      }),
                      child: Text(
                        registering
                            ? 'Already registered? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            session.enterGuest();
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                    child: const Text('Continue as Guest'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Guest reports are temporary. Account reports stay on this device until you delete them. Cloud backup is not enabled.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const BrandHeader(compact: true),
            const SizedBox(height: 24),
            const Text(
              'Your account',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: ProfileAvatar(user: session.user, size: 64)),
                    const SizedBox(height: 12),
                    Text(
                      session.isGuest
                          ? 'Guest'
                          : session.user!.displayName ?? 'Your account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      session.isGuest
                          ? 'Temporary session'
                          : session.user!.email ??
                                session.user!.phoneNumber ??
                                '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (session.isGuest) ...[
              const GuestReportNotice(),
              FilledButton(
                onPressed: () => openSignIn(context),
                child: const Text('Sign In'),
              ),
            ] else ...[
              const ProfileSettings(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Your reports are saved on this device for this account. Cloud backup is not enabled.',
                ),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy & storage'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _information(
                context,
                'Privacy & storage',
                'Reports and floor-plan images are stored on this device. Guest reports are cleared on the next app launch. Account reports remain available after sign-in. Downloaded PDFs remain wherever you saved them.\n\nWhen sign-in is enabled, Firebase processes authentication information. Mobile numbers are sent to Google for authentication and abuse prevention. Passwords and OTPs are not stored in the report database. If Remember my email is enabled, the last successfully verified email is stored on this device. Turn it off in Account to clear the remembered address.\n\nThe app owner’s contact details and full privacy policy are required before public release.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Flatverify.ai'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _information(
                context,
                'Flatverify.ai',
                'Understand Your Property\n\nScan floor plans, review measurements, and export property-area reports.\n\nOCR estimates require review. Reports are informational and do not replace a professional survey.',
              ),
            ),
            if (!session.isGuest)
              OutlinedButton(
                onPressed: () async {
                  try {
                    await session.signOut();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not sign out. Please try again.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sign Out'),
              ),
          ],
        ),
      ),
    );
  }

  void _information(BuildContext context, String title, String text) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(text, style: const TextStyle(height: 1.6)),
            ),
          ),
        ),
      );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & Support')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'How can we help?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 20),
        ExpansionTile(
          title: Text('Scan a floor plan'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Open Verify → Scan Floor Plan. Add a clear photo from your camera or gallery. Review each detected room and tap Confirm to add it to the total.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Correct missing measurements'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tap the room card to edit its name, length, and width. Use metres, cm, mm, feet, or inches. Rooms marked Needs measurement do not contribute until completed and confirmed.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Convert units'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Use the m² / sq ft switch in Verify. It converts the display without changing your original measurements.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Keep or download a report'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Save an audit, open its report, then tap Preview → Download. Guest reports last for the current app session. Register or sign in to move current guest reports into your account on this device.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('Manual and photo workspaces'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Each workspace keeps separate rooms and totals. Finish a manually added room before adding another. Switching modes preserves both drafts while the app remains open.',
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Contact support\n\nA support contact has not been published yet. This section will be updated before public release.',
            ),
          ),
        ),
      ],
    ),
  );
}
