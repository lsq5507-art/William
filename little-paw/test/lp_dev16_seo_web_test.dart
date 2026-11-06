import 'package:flutter_test/flutter_test.dart';
import 'package:little_paw/services/event_log.dart';
import 'package:little_paw/services/first_daily_gate.dart';
import 'package:little_paw/services/seo_web_gate.dart';

class _FakeSink implements AnalyticsSink {
  final List<(String, Map<String, Object>?)> calls = [];
  bool throwOnLog = false;

  @override
  void logEvent(String name, {Map<String, Object>? parameters}) {
    if (throwOnLog) throw StateError('analytics down');
    calls.add((name, parameters));
  }
}

void main() {
  group('SeoWebGate URI', () {
    test('wantsAppShell true for ?app=1', () {
      expect(
        SeoWebGate.wantsAppShell(Uri.parse('https://little-paw-prod.web.app/?app=1')),
        isTrue,
      );
    });

    test('wantsAppShell true for /app path', () {
      expect(
        SeoWebGate.wantsAppShell(Uri.parse('https://little-paw-prod.web.app/app')),
        isTrue,
      );
      expect(
        SeoWebGate.wantsAppShell(Uri.parse('https://little-paw-prod.web.app/app/')),
        isTrue,
      );
    });

    test('wantsAppShell false for marketing root', () {
      expect(
        SeoWebGate.wantsAppShell(Uri.parse('https://little-paw-prod.web.app/')),
        isFalse,
      );
      expect(
        SeoWebGate.wantsAppShell(Uri.parse('https://little-paw-prod.web.app/?utm=x')),
        isFalse,
      );
    });

    test('shouldNoIndex matches app entry', () {
      expect(
        SeoWebGate.shouldNoIndex(Uri.parse('https://x/?app=1')),
        isTrue,
      );
      expect(
        SeoWebGate.shouldNoIndex(Uri.parse('https://x/app')),
        isTrue,
      );
      expect(
        SeoWebGate.shouldNoIndex(Uri.parse('https://x/')),
        isFalse,
      );
    });

    test('shouldHideLandingShell matches wantsAppShell', () {
      expect(SeoWebGate.shouldHideLandingShell(Uri.parse('https://x/?app=1')), isTrue);
      expect(SeoWebGate.shouldHideLandingShell(Uri.parse('https://x/')), isFalse);
    });
  });

  group('SEO event names via EventLog', () {
    test('seoLandingView logs seo_landing_view', () {
      final sink = _FakeSink();
      final log = EventLog(analyticsSink: sink);
      log.seoLandingView();
      expect(log.events.single.event, 'seo_landing_view');
      expect(sink.calls.single.$1, 'seo_landing_view');
    });

    test('seoCtaClick logs seo_cta_click with cta=enter_app', () {
      final sink = _FakeSink();
      final log = EventLog(analyticsSink: sink);
      log.seoCtaClick();
      expect(log.events.single.event, 'seo_cta_click');
      expect(sink.calls.single.$1, 'seo_cta_click');
      expect(sink.calls.single.$2!['cta'], 'enter_app');
    });

    test('seo event dual-write failure does not throw', () {
      final sink = _FakeSink()..throwOnLog = true;
      final log = EventLog(analyticsSink: sink);
      expect(() => log.seoLandingView(), returnsNormally);
      expect(() => log.seoCtaClick(), returnsNormally);
      expect(log.events.map((e) => e.event).toList(), [
        'seo_landing_view',
        'seo_cta_click',
      ]);
    });
  });

  group('SeoWebGate.applyEntry', () {
    test('app entry hides shell and requests noindex; logs cta', () {
      final sink = _FakeSink();
      final log = EventLog(analyticsSink: sink);
      var hidden = false;
      var noindex = false;
      SeoWebGate.applyEntry(
        Uri.parse('https://little-paw-prod.web.app/?app=1'),
        eventLog: log,
        hideLandingShell: () => hidden = true,
        setNoIndex: () => noindex = true,
      );
      expect(hidden, isTrue);
      expect(noindex, isTrue);
      expect(log.events.map((e) => e.event), contains('seo_cta_click'));
      expect(log.events.map((e) => e.event), isNot(contains('seo_landing_view')));
    });

    test('marketing entry keeps shell, no noindex; logs landing view', () {
      final sink = _FakeSink();
      final log = EventLog(analyticsSink: sink);
      var hidden = false;
      var noindex = false;
      SeoWebGate.applyEntry(
        Uri.parse('https://little-paw-prod.web.app/'),
        eventLog: log,
        hideLandingShell: () => hidden = true,
        setNoIndex: () => noindex = true,
      );
      expect(hidden, isFalse);
      expect(noindex, isFalse);
      expect(log.events.map((e) => e.event), contains('seo_landing_view'));
      expect(log.events.map((e) => e.event), isNot(contains('seo_cta_click')));
    });
  });

  test('build stamp constant matches web-shell-center-v0.22', () {
    expect(FirstDailyGate.buildStampForHost('littlepaw.pet'), 'web-shell-center-v0.22');
    expect(FirstDailyGate.buildStampForHost('little-paw-prod.web.app'), 'web-shell-center-v0.22');
    SeoWebGate.hostnameOverride = 'little-paw-prod.web.app';
    expect(SeoWebGate.buildStamp, 'web-shell-center-v0.22');
    SeoWebGate.hostnameOverride = null;
  });
}
