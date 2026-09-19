import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../branding.dart';
import 'auth_feedback.dart';
import 'session_controller.dart';

class ProfileAvatar extends StatelessWidget {
  final User? user;
  final double size;
  const ProfileAvatar({super.key, this.user, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final words = (user?.displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
    final fallback = ColoredBox(
      color: AppColors.lightBlue,
      child: Center(
        child: initials.isEmpty
            ? Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: size * .55,
              )
            : Text(
                initials,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: size * .34,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
    final uri = Uri.tryParse(user?.photoURL ?? '');
    final validPhoto = uri?.scheme == 'https' && uri!.host.isNotEmpty;
    return Semantics(
      label: 'Profile photo',
      image: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: validPhoto
              ? Image.network(
                  uri.toString(),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : fallback,
                  errorBuilder: (context, error, stack) => fallback,
                )
              : fallback,
        ),
      ),
    );
  }
}

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});
  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final name = TextEditingController();
  bool busy = false;
  final session = SessionController.instance;
  @override
  void initState() {
    super.initState();
    name.text = session.user?.displayName ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action, String success) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) showAuthFeedback(context, success);
    } catch (error) {
      if (mounted) showAuthFeedback(context, authErrorMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Profile & security',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const OutlinedButton(
            onPressed: null,
            child: Text('Upload / change photo'),
          ),
          const Text(
            'Photo uploads are not available yet. Secure image storage must be connected.',
            style: TextStyle(color: AppColors.secondaryText, height: 1.5),
          ),
          if (session.user?.photoURL?.isNotEmpty == true)
            TextButton(
              onPressed: busy
                  ? null
                  : () => run(session.removePhoto, 'Profile photo removed.'),
              child: const Text('Remove profile photo'),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: name,
            enabled: !busy,
            maxLength: 80,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () {
                    if (name.text.trim().isEmpty) {
                      showAuthFeedback(context, 'Enter your full name.');
                      return;
                    }
                    run(
                      () => session.updateName(name.text),
                      'Profile updated.',
                    );
                  },
            child: Text(busy ? 'Saving…' : 'Save profile'),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 16),
          if (session.user?.providerData.any(
                (provider) => provider.providerId == 'password',
              ) ==
              true)
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Change password'),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remember my email'),
            subtitle: const Text(
              'Prefill after sign-out. Turn off for shared devices.',
            ),
            value: session.rememberEmail,
            onChanged: busy
                ? null
                : (value) => run(
                    () async {
                      await session.setRememberEmail(value);
                      if (value) {
                        await session.rememberSuccessfulEmail(
                          session.user?.email,
                        );
                      }
                    },
                    value
                        ? 'Email preference saved.'
                        : 'Remembered email cleared.',
                  ),
          ),
        ],
      ),
    ),
  );
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(3, (_) => TextEditingController());
  final hidden = [true, true, true];
  bool busy = false;
  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await SessionController.instance.changePassword(
        fields[0].text,
        fields[1].text,
      );
      TextInput.finishAutofillContext(shouldSave: true);
      for (final field in fields) {
        field.clear();
      }
      if (mounted) {
        showAuthFeedback(context, 'Password changed successfully.');
        Navigator.pop(context);
      }
    } catch (error) {
      for (final field in fields) {
        field.clear();
      }
      if (mounted) showAuthFeedback(context, authErrorMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Change password')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Confirm your current password to protect your account.',
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < fields.length; i++) ...[
                    TextFormField(
                      controller: fields[i],
                      obscureText: hidden[i],
                      enabled: !busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [
                        i == 0
                            ? AutofillHints.password
                            : AutofillHints.newPassword,
                      ],
                      textInputAction: i == 2
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onFieldSubmitted: (_) {
                        if (i == 2) save();
                      },
                      decoration: InputDecoration(
                        labelText: [
                          'Current password',
                          'New password',
                          'Confirm new password',
                        ][i],
                        suffixIcon: IconButton(
                          tooltip: hidden[i]
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () =>
                              setState(() => hidden[i] = !hidden[i]),
                          icon: Icon(
                            hidden[i]
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a password.';
                        }
                        if (i == 1 && value.length < 8) {
                          return 'Use at least 8 characters.';
                        }
                        if (i == 1 && value == fields[0].text) {
                          return 'Choose a different password.';
                        }
                        if (i == 2 && value != fields[1].text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: busy ? null : save,
                    child: Text(busy ? 'Updating…' : 'Update password'),
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
