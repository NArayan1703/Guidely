import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidely/main.dart';

void main() {
  testWidgets('starts with traveller welcome and guide registration link', (
    tester,
  ) async {
    await tester.pumpWidget(const GuidelyApp());

    expect(find.text('Guidely'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('validates traveller sign-in credentials', (tester) async {
    await tester.pumpWidget(const GuidelyApp());

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
  });

  testWidgets('collects traveller profile fields during account creation', (
    tester,
  ) async {
    await tester.pumpWidget(const GuidelyApp());

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New to Guidely? Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Preferred language'), findsOneWidget);
  });

  testWidgets('opens the package request flow', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));

    expect(find.text('Hi, Traveller'), findsOneWidget);

    final package = find.text('Sunrise at Poon Hill');
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.tap(package);
    await tester.pumpAndSettle();

    expect(find.text('Request this trip'), findsOneWidget);
    expect(find.text('4.9 (38)'), findsOneWidget);
    await tester.tap(find.text('Request this trip'));
    await tester.pumpAndSettle();
    expect(find.text('Request your trip'), findsOneWidget);
  });

  testWidgets('filters packages by search text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));

    await tester.enterText(find.byKey(const Key('package-search')), 'Pokhara');
    await tester.pump();

    expect(find.text('Old Pokhara, slow and local'), findsOneWidget);
    expect(find.text('Sunrise at Poon Hill'), findsNothing);
  });

  testWidgets('opens Profile from the tourist header', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to view your profile'), findsOneWidget);
  });

  testWidgets('shows account actions in More', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Profile settings'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    await tester.drag(find.text('Sign out'), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('FAQs / Help Center'), findsOneWidget);
  });

  testWidgets('opens guide registration from welcome', (tester) async {
    await tester.pumpWidget(const GuidelyApp());

    await tester.tap(find.text('Are you a local guide? Register as a guide'));
    await tester.pumpAndSettle();

    expect(find.text('Become a local guide'), findsOneWidget);
    expect(find.text('Guide profile'), findsOneWidget);
  });

  testWidgets('keeps one sign-in entry point on welcome', (tester) async {
    await tester.pumpWidget(const GuidelyApp());

    expect(find.text('Already a guide? Sign in'), findsNothing);
  });
}
