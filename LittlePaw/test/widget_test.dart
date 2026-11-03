import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/l10n/strings.dart';

void main() {
  test('non-memorial boundary copy present EN/ZH', () {
    final zh = S(true);
    final en = S(false);
    expect(zh.get('welcome.boundary').contains('告别馆'), true);
    expect(en.get('welcome.boundary').toLowerCase().contains('memorial'), true);
    expect(zh.get('onboarding.stories.cta_done').contains('发第一条'), false);
    expect(en.get('onboarding.stories.cta_done').toLowerCase().contains('post first'), false);
  });
}
