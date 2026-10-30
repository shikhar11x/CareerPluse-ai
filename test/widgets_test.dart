import 'package:careerpulse_ai/core/widgets/error_state_card.dart';
import 'package:careerpulse_ai/core/widgets/neon_button.dart';
import 'package:careerpulse_ai/core/widgets/page_dots.dart';
import 'package:careerpulse_ai/core/widgets/segmented_pill.dart';
import 'package:careerpulse_ai/core/widgets/select_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('NeonButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(NeonButton(label: 'Go', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('shows a spinner and ignores taps while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(NeonButton(label: 'Go', isLoading: true, onPressed: () => taps++)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Go'));
      expect(taps, 0);
    });

    testWidgets('does nothing when disabled', (tester) async {
      await tester.pumpWidget(_wrap(const NeonButton(label: 'Go', onPressed: null)));
      await tester.tap(find.text('Go'));
      expect(find.text('Go'), findsOneWidget);
    });
  });

  group('SegmentedPill', () {
    testWidgets('reports the tapped index', (tester) async {
      int? picked;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            child: SegmentedPill(
              labels: const ['Sign in', 'Sign up'],
              index: 0,
              onChanged: (i) => picked = i,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sign up'));
      expect(picked, 1);
    });
  });

  group('SelectChips', () {
    testWidgets('reports the selected value', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _wrap(
          SelectChips<String>(
            options: const {'a': 'Alpha', 'b': 'Beta'},
            value: 'a',
            onChanged: (v) => picked = v,
          ),
        ),
      );
      await tester.tap(find.text('Beta'));
      expect(picked, 'b');
    });
  });

  group('PageDots', () {
    testWidgets('draws one dot per page', (tester) async {
      await tester.pumpWidget(_wrap(const PageDots(count: 3, index: 1)));
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });
  });

  group('ErrorStateCard', () {
    testWidgets('shows the message and retries', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _wrap(ErrorStateCard(message: 'Server is down', onRetry: () => retries++)),
      );
      expect(find.text('Server is down'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });
  });
}