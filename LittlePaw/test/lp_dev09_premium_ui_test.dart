import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/theme/lp_theme.dart';
import 'package:little_paw/widgets/story_ring_row.dart';

void main() {
  test('LP-DS01 theme tokens present on ThemeData', () {
    final theme = LpTheme.light();
    final tokens = theme.extension<LpTokens>();
    expect(tokens, isNotNull);
    expect(tokens!.bgPage, const Color(0xFFF4F2EF));
    expect(tokens.ringUnreadStart, const Color(0xFFE07A3A));
    expect(tokens.ringUnreadEnd, const Color(0xFFD889A8));
    expect(tokens.ringRead, const Color(0xFFC8C4BE));
    expect(tokens.chatBubbleMe, const Color(0xFF1A1A1A));
    expect(tokens.chatBubbleThem, const Color(0xFFECEAE6));
    expect(tokens.ctaInverse, const Color(0xFF1A1A1A));
    expect(tokens.borderHairline, const Color(0xFFE4E1DC));
    expect(tokens.elevCardBlur, 0);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF4F2EF));
    expect(theme.colorScheme.primary, const Color(0xFFC45C26));
    expect(theme.colorScheme.onSurface, const Color(0xFF1A1A1A));
  });

  test('G-01 secondary CTA style is not primary filled', () {
    final theme = LpTheme.light();
    final secondary = lpSecondaryCtaStyle();
    final primary = lpPrimaryCtaStyle();

    final secBg = secondary.backgroundColor?.resolve({});
    final priBg = primary.backgroundColor?.resolve({});

    // Secondary must not resolve to solid near-black / brand filled primary.
    expect(secBg, isNot(priBg));
    expect(secBg, isNot(const Color(0xFF1A1A1A)));
    expect(secBg, isNot(const Color(0xFFC45C26)));

    final filledThemeBg =
        theme.filledButtonTheme.style?.backgroundColor?.resolve({});
    expect(filledThemeBg, const Color(0xFF1A1A1A));
  });

  testWidgets('Story ring unread uses soft orange→pink, not neon purple',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LpTheme.light(),
        home: const Scaffold(
          body: StoryRingRow(
            items: [
              StoryRingItemData(id: 'a', label: '开场', seen: false),
              StoryRingItemData(id: 'b', label: '已读', seen: true),
            ],
          ),
        ),
      ),
    );

    final decorators = tester.widgetList<Container>(find.byType(Container));
    var sawUnread = false;
    var sawRead = false;
    for (final c in decorators) {
      final d = c.decoration;
      if (d is! BoxDecoration || d.shape != BoxShape.circle) continue;
      final g = d.gradient;
      if (g is SweepGradient) {
        final colors = g.colors;
        expect(colors, contains(const Color(0xFFE07A3A)));
        expect(colors, contains(const Color(0xFFD889A8)));
        expect(colors, isNot(contains(const Color(0xFFE040FB))));
        expect(colors, isNot(contains(const Color(0xFF7C4DFF))));
        sawUnread = true;
      }
      if (d.color == const Color(0xFFC8C4BE)) {
        sawRead = true;
      }
    }
    expect(sawUnread, isTrue);
    expect(sawRead, isTrue);
  });

  test('DEF-QA09-01 World/affiliated paths have no legacy 8E8E8E/DBDBDB literals', () {
    // Resolve package root whether cwd is project or test/.
    Directory root = Directory.current;
    if (!File('pubspec.yaml').existsSync()) {
      root = Directory('..');
    }
    const paths = [
      'lib/screens/world_tab.dart',
      'lib/world/screens/world_market_page.dart',
      'lib/world/screens/world_pet_detail_page.dart',
      'lib/world/screens/world_post_detail_page.dart',
      'lib/world/widgets/world_ig_post_card.dart',
      'lib/widgets/interactive_story_card.dart',
      'lib/widgets/status_pill.dart',
    ];
    for (final rel in paths) {
      final f = File('${root.path}/$rel');
      expect(f.existsSync(), isTrue, reason: 'missing $rel');
      final src = f.readAsStringSync();
      expect(src.contains('0xFF8E8E8E'), isFalse, reason: rel);
      expect(src.contains('0xFFDBDBDB'), isFalse, reason: rel);
    }
  });

}
