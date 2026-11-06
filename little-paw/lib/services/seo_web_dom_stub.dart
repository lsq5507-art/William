import 'seo_web_gate.dart';

/// Non-web stub: no DOM. Empty hostname → experiment on (debug).
void seoBindHostname() {
  SeoWebGate.platformHostname = () => '';
}

void seoHideLandingShell() {}

void seoSetDocumentNoIndex() {}

Uri seoCurrentUri() => Uri.parse('https://little-paw-prod.web.app/');
