import 'package:careerpulse_ai/features/dashboard/practice_grid.dart';
import 'package:careerpulse_ai/features/interview/widgets/chat_bubble.dart';
import 'package:careerpulse_ai/features/interview/widgets/chat_input_bar.dart';
import 'package:careerpulse_ai/features/interview/widgets/question_progress.dart';
import 'package:careerpulse_ai/features/interview/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ChatBubble', () {
    testWidgets('interviewer bubble shows the avatar', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChatBubble(text: 'Tell me about Flutter', isInterviewer: true)),
      );
      expect(find.text('Tell me about Flutter'), findsOneWidget);
      expect(find.byType(InterviewerAvatar), findsOneWidget);
    });

    testWidgets('candidate bubble has no avatar', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChatBubble(text: 'Widgets are...', isInterviewer: false)),
      );
      expect(find.text('Widgets are...'), findsOneWidget);
      expect(find.byType(InterviewerAvatar), findsNothing);
    });
  });

  group('QuestionProgress', () {
    testWidgets('shows the current question and answered count', (tester) async {
      await tester.pumpWidget(_wrap(const QuestionProgress(answered: 1, total: 5)));
      expect(find.text('Question 2 of 5'), findsOneWidget);
      expect(find.text('1 answered'), findsOneWidget);
    });

    testWidgets('never goes past the last question', (tester) async {
      await tester.pumpWidget(_wrap(const QuestionProgress(answered: 5, total: 5)));
      expect(find.text('Question 5 of 5'), findsOneWidget);
    });

    testWidgets('handles a zero total without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const QuestionProgress(answered: 0, total: 0)));
      expect(find.text('Question 0 of 0'), findsOneWidget);
    });
  });

  group('ChatInputBar', () {
    testWidgets('does not send an empty or blank answer', (tester) async {
      var sent = 0;
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _wrap(ChatInputBar(controller: c, enabled: true, onSend: () => sent++)),
      );

      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      expect(sent, 0);
    });

    testWidgets('sends once there is text', (tester) async {
      var sent = 0;
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _wrap(ChatInputBar(controller: c, enabled: true, onSend: () => sent++)),
      );

      await tester.enterText(find.byType(TextField), 'My answer');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      expect(sent, 1);
    });

    testWidgets('is locked while the AI is replying', (tester) async {
      var sent = 0;
      final c = TextEditingController(text: 'draft');
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _wrap(ChatInputBar(controller: c, enabled: false, onSend: () => sent++)),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      expect(sent, 0);
    });
  });

  group('TypingIndicator', () {
    testWidgets('animates without errors', (tester) async {
      await tester.pumpWidget(_wrap(const TypingIndicator()));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TypingIndicator), findsOneWidget);
      expect(find.byType(InterviewerAvatar), findsOneWidget);
    });
  });

  group('PracticeGrid', () {
    testWidgets('shows all four types and reports the picked one', (tester) async {
      String? picked;
      await tester.pumpWidget(_wrap(PracticeGrid(onPick: (id) => picked = id)));

      for (final t in ['Technical', 'HR', 'Behavioral', 'Mixed']) {
        expect(find.text(t), findsOneWidget);
      }
      await tester.tap(find.text('HR'));
      expect(picked, 'hr');
      await tester.tap(find.text('Mixed'));
      expect(picked, 'mixed');
    });
  });
}