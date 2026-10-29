import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/glass_field.dart';
import '../../core/widgets/gradient_progress_bar.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/select_chips.dart';
import 'profile_controller.dart';
import 'profile_model.dart';

const _roleSuggestions = [
  'Flutter Developer',
  'Backend Developer',
  'Frontend Developer',
  'Data Analyst',
  'Software Engineer',
  'Product Manager',
];

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    this.initial,
    required this.submitLabel,
    this.onSaved,
  });

  final Profile? initial;
  final String submitLabel;
  final VoidCallback? onSaved;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.fullName);
  late final _role = TextEditingController(text: widget.initial?.targetRole);
  late String? _education = _nullIfEmpty(widget.initial?.education);
  late String? _experience = _nullIfEmpty(widget.initial?.experienceLevel);
  bool _submitted = false;
  bool _saving = false;
  bool _saved = false;
  String? _error;

  static String? _nullIfEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  double get _progress {
    var n = 0;
    if (_name.text.trim().isNotEmpty) n++;
    if (_education != null) n++;
    if (_role.text.trim().isNotEmpty) n++;
    if (_experience != null) n++;
    return n / 4;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _education == null || _experience == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    try {
      await ref.read(profileProvider.notifier).save(
            fullName: _name.text.trim(),
            education: _education!,
            targetRole: _role.text.trim(),
            experienceLevel: _experience!,
          );
      if (mounted) {
        setState(() => _saved = true);
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([_name, _role]),
            builder: (_, _) => GradientProgressBar(value: _progress),
          ),
          GlassField(
            controller: _name,
            label: 'Full name',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: Validators.required('name'),
          ),
          _FieldLabel('Education', error: _submitted && _education == null),
          SelectChips<String>(
            options: kEducationOptions,
            value: _education,
            onChanged: (v) => setState(() => _education = v),
          ),
          GlassField(
            controller: _role,
            label: 'Target role',
            icon: Icons.work_outline_rounded,
            textInputAction: TextInputAction.done,
            validator: Validators.required('target role'),
          ),
          ListenableBuilder(
            listenable: _role,
            builder: (_, _) => SelectChips<String>(
              options: {for (final r in _roleSuggestions) r: r},
              value: _role.text.trim(),
              onChanged: (v) => _role.text = v,
            ),
          ),
          _FieldLabel('Experience', error: _submitted && _experience == null),
          SelectChips<String>(
            options: kExperienceOptions,
            value: _experience,
            onChanged: (v) => setState(() => _experience = v),
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
                : _saved
                    ? const InfoChip(
                        label: 'Profile saved',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      )
                    : const SizedBox(width: double.infinity),
          ),
          NeonButton(
            label: widget.submitLabel,
            icon: Icons.arrow_forward_rounded,
            expand: true,
            isLoading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(color: AppColors.textMid, fontWeight: FontWeight.w600),
        ),
        if (error) ...[
          const SizedBox(width: 8),
          const Text('Pick one', style: TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
      ],
    );
  }
}