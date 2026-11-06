// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'seo_web_gate.dart';

void seoBindHostname() {
  SeoWebGate.platformHostname = () => html.window.location.hostname ?? '';
}

void seoHideLandingShell() {
  html.document.getElementById(SeoWebGate.landingElementId)?.remove();
}

void seoSetDocumentNoIndex() {
  final head = html.document.head;
  if (head == null) return;
  final existing = head.querySelector('meta[name="robots"]');
  if (existing is html.MetaElement) {
    existing.content = 'noindex, nofollow';
  } else {
    head.append(
      html.MetaElement()
        ..name = 'robots'
        ..content = 'noindex, nofollow',
    );
  }
}

Uri seoCurrentUri() => Uri.parse(html.window.location.href);
