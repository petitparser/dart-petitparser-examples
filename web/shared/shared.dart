import 'dart:js_interop';

import 'package:petitparser_examples/markdown.dart';
import 'package:web/web.dart';

/// Injects the Google Tag Manager analytics scripts into `<head>`.
void _injectAnalytics() {
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
void _renderMarkdownElements() {
  final elements = document.querySelectorAll('[data-markdown]');
  for (var i = 0; i < elements.length; i++) {
    final element = elements.item(i) as HTMLElement;
    final rawText = element.textContent?.trim();
    if (rawText != null && rawText.isNotEmpty) {
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

void main() {
  _injectAnalytics();
  _renderMarkdownElements();
}
