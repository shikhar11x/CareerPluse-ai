import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ai_orb.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_field.dart';
import '../../core/widgets/gradient_text.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/segmented_pill.dart';
import 'auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setMode(int index) => setState(() {
        _signUp = index == 1;
        _error = null;
        _notice = null;
      });

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    final repo = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    final password = _password.text;
    try {
      if (_signUp) {
        final res = await repo.signUp(email: email, password: password);
        if (res.session == null && mounted) {
          setState(() {
            _notice = 'Account created. Confirm your email from the link we sent, then sign in.';
            _signUp = false;
          });
        }
      } else {
        await repo.signIn(email: email, password: password);
      }
      // With a session, the router redirect takes over (profile setup or home).
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Entrance(child: AiOrb(size: 96)),
                  const SizedBox(height: 18),
                  Entrance(
                    delay: const Duration(milliseconds: 120),
                    child: GradientText(
                      'CareerPulse AI',
                      style: AppText.display(15).copyWith(letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Entrance(
                    delay: const Duration(milliseconds: 200),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _signUp ? 'Create your account' : 'Welcome back',
                        key: ValueKey(_signUp),
                        style: AppText.display(32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _signUp
                        ? 'Start practising in under a minute.'
                        : 'Sign in to continue your interview prep.',
                    style: AppText.muted,
                  ),
                  const SizedBox(height: 24),
                  Entrance(
                    delay: const Duration(milliseconds: 300),
                    child: SegmentedPill(
                      labels: const ['Sign in', 'Sign up'],
                      index: _signUp ? 1 : 0,
                      onChanged: _setMode,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Entrance(
                    delay: const Duration(milliseconds: 380),
                    child: GlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 14,
                          children: [
                            GlassField(
                              controller: _email,
                              label: 'Email',
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                            ),
                            GlassField(
                              controller: _password,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _hidePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: [
                                _signUp ? AutofillHints.newPassword : AutofillHints.password,
                              ],
                              validator: Validators.password,
                              onSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                tooltip: _hidePassword ? 'Show password' : 'Hide password',
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: AppColors.textLo,
                                ),
                                onPressed: () =>
                                    setState(() => _hidePassword = !_hidePassword),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              alignment: Alignment.topCenter,
                              child: _signUp
                                  ? ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _password,
                                      builder: (_, v, _) => _StrengthBar(v.text),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              alignment: Alignment.topCenter,
                              child: _error != null
                                  ? InfoChip(
                                      label: _error!,
                                      icon: Icons.error_outline_rounded,
                                      color: AppColors.danger,
                                      maxLines: 4,
                                    )
                                  : _notice != null
                                      ? InfoChip(
                                          label: _notice!,
                                          icon: Icons.mark_email_read_rounded,
                                          color: AppColors.success,
                                          maxLines: 4,
                                        )
                                      : const SizedBox(width: double.infinity),
                            ),
                            NeonButton(
                              label: _signUp ? 'Create account' : 'Sign in',
                              icon: Icons.arrow_forward_rounded,
                              expand: true,
                              isLoading: _loading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'AI feedback is an estimate to help you practise, not a hiring prediction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textLo, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar(this.password);

  final String password;

  int get _score {
    if (password.isEmpty) return 0;
    var s = 0;
    if (password.length >= 8) s++;
    if (password.length >= 12) s++;
    if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'\d').hasMatch(password) && RegExp(r'[^A-Za-z0-9]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    const colors = [AppColors.danger, AppColors.warning, AppColors.cyan, AppColors.success];
    const labels = ['Too short', 'Weak', 'Okay', 'Good', 'Strong'];
    final score = _score;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 6,
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: i < score
                        ? colors[(score - 1).clamp(0, 3)]
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength: ${labels[score]}',
          style: const TextStyle(color: AppColors.textLo, fontSize: 12),
        ),
      ],
    );
  }
}