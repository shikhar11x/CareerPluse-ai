import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/aurora_background.dart';
import 'core/widgets/glass_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const ProviderScope(child: CareerPulseApp()));
}

Widget _withAurora(BuildContext context, Widget? child) =>
    AuroraBackground(child: child ?? const SizedBox.shrink());

class CareerPulseApp extends ConsumerWidget {
  const CareerPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.isConfigured) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        builder: _withAurora,
        home: const _ConfigMissing(),
      );
    }
    return MaterialApp.router(
      title: 'CareerPulse AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      builder: _withAurora,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _ConfigMissing extends StatelessWidget {
  const _ConfigMissing();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: GlassCard(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key_off_rounded, size: 40, color: AppColors.warning),
                SizedBox(height: 14),
                Text(
                  'Supabase is not configured',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Create env.json in the project root, then run:\n'
                  'flutter run -d chrome --dart-define-from-file=env.json',
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
