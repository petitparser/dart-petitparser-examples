import 'dart:js_interop';

import 'package:petitparser_examples/markdown.dart';
import 'package:web/web.dart';

/// Injects the Google Tag Manager analytics scripts into `<head>`.
void injectAnalytics() {
  const gtmId = 'G-QK0KCHXW3F';
  final head = document.head;
  if (head == null) return;

  final existing = document.querySelector('script[src*="$gtmId"]');
  if (existing == null) {
    final gtmScript = document.createElement('script') as HTMLScriptElement;
    gtmScript.async = true;
    gtmScript.src = 'https://www.googletagmanager.com/gtag/js?id=$gtmId';
    head.appendChild(gtmScript);

    final initScript = document.createElement('script') as HTMLScriptElement;
    initScript.textContent =
        '''
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', '$gtmId');
        ''';
    head.appendChild(initScript);
  }
}

/// Renders all `[data-markdown]` containers using PetitParser's markdownToHtml.
void renderMarkdownElements() {
  final elements = document.querySelectorAll('[data-markdown]');
  for (var i = 0; i < elements.length; i++) {
    final element = elements.item(i) as HTMLElement;
    final rawText = element.innerHTML.toString().trim();
    if (rawText.isNotEmpty) {
      try {
        final html = markdownToHtml(rawText);
        element.innerHTML = html.toJS;
        element.classList.add('markdown-body');
      } catch (_) {
        // Fallback: leave content intact
      }
    }
  }
}

/// Automatically initializes tab components matching `.tabs`.
///
/// Detects tab buttons within `.tab-buttons` (or `.tab-button`) and
/// tab bodies within `.tab-bodies` (or `.tab-body`) purely by index.
void setupTabs() {
  final tabContainers = document.querySelectorAll('.tabs');
  for (var i = 0; i < tabContainers.length; i++) {
    final container = tabContainers.item(i) as HTMLElement;
    final buttons = container.querySelectorAll('.tab-buttons > *, .tab-button');
    final bodies = container.querySelectorAll('.tab-bodies > *, .tab-body');
    if (buttons.length == 0 || buttons.length != bodies.length) continue;

    void selectTab(int index) {
      for (var j = 0; j < buttons.length; j++) {
        final btn = buttons.item(j) as HTMLElement;
        final body = bodies.item(j) as HTMLElement;
        btn.classList.toggle('active', j == index);
        body.classList.toggle('active', j == index);
      }
    }

    var initialIndex = 0;
    for (var j = 0; j < buttons.length; j++) {
      final btn = buttons.item(j) as HTMLElement;
      if (btn.classList.contains('active')) {
        initialIndex = j;
      }
      final index = j;
      btn.onClick.listen((_) => selectTab(index));
    }
    selectTab(initialIndex);
  }
}

/// Makes `.showcase-card` elements clickable to navigate to their primary action link.
void setupShowcaseCards() {
  final cards = document.querySelectorAll('.showcase-card');
  for (var i = 0; i < cards.length; i++) {
    final card = cards.item(i) as HTMLElement;
    card.onClick.listen((event) {
      final target = event.target as Element?;
      if (target != null && target.closest('a, button') != null) return;
      final link = card.querySelector('a.button') as HTMLAnchorElement?;
      link?.click();
    });
  }
}

/// Initializes all shared features: analytics, markdown rendering, tabs, and showcase cards.
void initShared() {
  injectAnalytics();
  renderMarkdownElements();
  setupTabs();
  setupShowcaseCards();
}

/// Main entry point for the standalone shared web script.
void main() {
  initShared();
}
