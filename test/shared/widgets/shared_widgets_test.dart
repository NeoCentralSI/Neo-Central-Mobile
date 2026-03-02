import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/shared/widgets/shared_widgets.dart';

/// Helper to wrap a widget in MaterialApp for testing
Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  // ─── AppCard ──────────────────────────────────────────────

  group('AppCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppCard(child: Text('Hello')),
      ));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('handles onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestableWidget(
        AppCard(
          onTap: () => tapped = true,
          child: const Text('Tap me'),
        ),
      ));

      await tester.tap(find.text('Tap me'));
      expect(tapped, true);
    });

    testWidgets('renders without onTap (no GestureDetector)', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppCard(child: Text('No tap')),
      ));

      // Should not have a GestureDetector since no onTap
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('applies custom background color', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppCard(
          backgroundColor: Colors.red,
          child: Text('Red card'),
        ),
      ));

      expect(find.text('Red card'), findsOneWidget);
    });
  });

  // ─── AppBadge ─────────────────────────────────────────────

  group('AppBadge', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppBadge(label: 'Active'),
      ));

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders all badge variants without errors', (tester) async {
      for (final variant in BadgeVariant.values) {
        await tester.pumpWidget(buildTestableWidget(
          AppBadge(label: variant.name, variant: variant),
        ));

        expect(find.text(variant.name), findsOneWidget);
      }
    });

    testWidgets('applies custom fontSize', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppBadge(label: 'Big', fontSize: 20),
      ));

      final text = tester.widget<Text>(find.text('Big'));
      expect(text.style!.fontSize, 20);
    });
  });

  // ─── AppProgressBar ───────────────────────────────────────

  group('AppProgressBar', () {
    testWidgets('renders at 0%', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppProgressBar(value: 0.0),
      ));

      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('renders at 50%', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppProgressBar(value: 0.5),
      ));

      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox).first,
      );
      expect(box.widthFactor, 0.5);
    });

    testWidgets('renders at 100%', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppProgressBar(value: 1.0),
      ));

      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox).first,
      );
      expect(box.widthFactor, 1.0);
    });

    testWidgets('clamps value above 1.0', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppProgressBar(value: 1.5),
      ));

      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox).first,
      );
      expect(box.widthFactor, 1.0);
    });

    testWidgets('clamps value below 0.0', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppProgressBar(value: -0.5),
      ));

      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox).first,
      );
      expect(box.widthFactor, 0.0);
    });
  });

  // ─── SectionHeader ────────────────────────────────────────

  group('SectionHeader', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const SectionHeader(title: 'Section Title'),
      ));

      expect(find.text('Section Title'), findsOneWidget);
    });

    testWidgets('renders action label when provided', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        SectionHeader(
          title: 'Title',
          actionLabel: 'See All',
          onAction: () {},
        ),
      ));

      expect(find.text('See All'), findsOneWidget);
    });

    testWidgets('does not render action when no actionLabel', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const SectionHeader(title: 'Title'),
      ));

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('action button triggers callback', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(buildTestableWidget(
        SectionHeader(
          title: 'Title',
          actionLabel: 'Action',
          onAction: () => actionCalled = true,
        ),
      ));

      await tester.tap(find.text('Action'));
      expect(actionCalled, true);
    });
  });

  // ─── AppButton ────────────────────────────────────────────

  group('AppButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppButton(label: 'Submit'),
      ));

      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildTestableWidget(
        AppButton(label: 'Tap', onPressed: () => pressed = true),
      ));

      await tester.tap(find.text('Tap'));
      expect(pressed, true);
    });

    testWidgets('renders as ElevatedButton by default', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        AppButton(label: 'Default', onPressed: () {}),
      ));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('renders as OutlinedButton when isOutline = true',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        AppButton(label: 'Outline', isOutline: true, onPressed: () {}),
      ));

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppButton(label: 'Loading', isLoading: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('shows icon when provided', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        AppButton(
          label: 'With Icon',
          icon: Icons.add,
          onPressed: () {},
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });
  });

  // ─── AppDivider ───────────────────────────────────────────

  group('AppDivider', () {
    testWidgets('renders a Divider', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const AppDivider(),
      ));

      expect(find.byType(Divider), findsOneWidget);
    });
  });

  // ─── InfoRow ──────────────────────────────────────────────

  group('InfoRow', () {
    testWidgets('renders icon, label, and value', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const InfoRow(
          icon: Icons.person,
          label: 'Name',
          value: 'John Doe',
        ),
      ));

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });
  });
}
