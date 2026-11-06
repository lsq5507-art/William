import 'seo_web_dom_stub.dart'
    if (dart.library.html) 'seo_web_dom_web.dart' as impl;

void seoBindHostname() => impl.seoBindHostname();

void seoHideLandingShell() => impl.seoHideLandingShell();

void seoSetDocumentNoIndex() => impl.seoSetDocumentNoIndex();

Uri seoCurrentUri() => impl.seoCurrentUri();
