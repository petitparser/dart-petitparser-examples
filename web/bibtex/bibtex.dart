import 'dart:async';
import 'dart:js_interop';

import 'package:petitparser_examples/bibtex.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

final bibSource = document.querySelector('#bib-source') as HTMLInputElement;
final loadBtn = document.querySelector('#load-btn') as HTMLButtonElement;

final loadingIndicator =
    document.querySelector('#loading-indicator') as HTMLElement;
final loadingStatus = document.querySelector('#loading-status') as HTMLElement;
final progressBar = document.querySelector('#progress-bar') as HTMLElement;
final errorBox = document.querySelector('#error-box') as HTMLElement;
final stats = document.querySelector('#stats') as HTMLElement;
final controls = document.querySelector('#controls') as HTMLElement;

final searchInput = document.querySelector('#search-input') as HTMLInputElement;
final typeFilter = document.querySelector('#type-filter') as HTMLSelectElement;
final yearFilter = document.querySelector('#year-filter') as HTMLSelectElement;
final sortOrder = document.querySelector('#sort-order') as HTMLSelectElement;

final resultsCount = document.querySelector('#results-count') as HTMLElement;
final pageInfoBottom =
    document.querySelector('#page-info-bottom') as HTMLElement;
final prevPageBottom =
    document.querySelector('#prev-page-bottom') as HTMLButtonElement;
final nextPageBottom =
    document.querySelector('#next-page-bottom') as HTMLButtonElement;

final entriesList = document.querySelector('#entries-list') as HTMLElement;

List<BibTeXEntry> allEntries = [];
List<BibTeXEntry> filteredEntries = [];
int currentPage = 1;
const int pageSize = 25;

final _yearPattern = RegExp(r'^\d{4}$');

String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

int _currentRequestId = 0;
XMLHttpRequest? _activeXhr;

void _updateActiveExample(String currentUrl) {
  final trimmed = currentUrl.trim();
  final buttons = document.querySelectorAll('.source-selector .preset-btn');
  for (var i = 0; i < buttons.length; i++) {
    final btn = buttons.item(i) as HTMLButtonElement;
    final url = btn.getAttribute('data-url');
    btn.classList.toggle('active', url != null && url.trim() == trimmed);
  }
}

Future<void> loadFromUrl(String rawUrl) async {
  final url = rawUrl.trim();
  if (url.isEmpty) return;

  _updateActiveExample(url);

  // Cancel any existing in-flight request
  _activeXhr?.abort();
  _activeXhr = null;

  final requestId = ++_currentRequestId;

  loadingIndicator.style.display = 'block';
  loadingStatus.textContent = 'Connecting to $url...';
  progressBar.style.width = '0%';
  errorBox.style.display = 'none';
  stats.style.display = 'none';
  controls.style.display = 'none';

  final downloadWatch = Stopwatch()..start();
  final completer = Completer<String>();
  final xhr = XMLHttpRequest();
  _activeXhr = xhr;
  xhr.open('GET', url);

  xhr.onprogress = ((ProgressEvent event) {
    if (requestId != _currentRequestId) return;
    if (event.lengthComputable) {
      final percent = ((event.loaded / event.total) * 100).round();
      final loadedMb = (event.loaded / (1024 * 1024)).toStringAsFixed(1);
      final totalMb = (event.total / (1024 * 1024)).toStringAsFixed(1);
      progressBar.style.width = '$percent%';
      loadingStatus.textContent =
          'Downloading: $loadedMb MB / $totalMb MB ($percent%)...';
    } else {
      final loadedMb = (event.loaded / (1024 * 1024)).toStringAsFixed(1);
      loadingStatus.textContent = 'Downloading: $loadedMb MB...';
    }
  }).toJS;

  xhr.onload = ((Event _) {
    if (requestId != _currentRequestId) return;
    if (xhr.status >= 200 && xhr.status < 300) {
      completer.complete(xhr.responseText);
    } else {
      completer.completeError(
        Exception('HTTP error ${xhr.status}: ${xhr.statusText}'),
      );
    }
  }).toJS;

  xhr.onerror = ((Event _) {
    if (requestId != _currentRequestId) return;
    completer.completeError(Exception('Network error while requesting $url'));
  }).toJS;

  xhr.onabort = ((Event _) {
    if (requestId != _currentRequestId) return;
    completer.completeError(Exception('Request was aborted.'));
  }).toJS;

  xhr.send();

  try {
    final text = await completer.future;
    if (requestId != _currentRequestId) return;
    final downloadMs = downloadWatch.elapsedMilliseconds;
    progressBar.style.width = '100%';
    loadingStatus.textContent =
        'Downloaded ${(text.length / (1024 * 1024)).toStringAsFixed(1)} MB. Parsing entries with PetitParser...';
    // Yield to let browser render the updated status before CPU-intensive parse
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (requestId != _currentRequestId) return;
    await parseBibTeX(text, downloadMs: downloadMs, requestId: requestId);
  } catch (e) {
    if (requestId != _currentRequestId) return;
    loadingIndicator.style.display = 'none';
    errorBox.style.display = 'block';
    errorBox.textContent = 'Failed to load or parse: $e';
  } finally {
    if (_activeXhr == xhr) {
      _activeXhr = null;
    }
  }
}

Future<void> parseBibTeX(
  String content, {
  required int downloadMs,
  required int requestId,
}) async {
  loadingIndicator.style.display = 'block';
  final watch = Stopwatch()..start();
  try {
    final entries = <BibTeXEntry>[];
    allEntries = [];
    filteredEntries = [];
    var count = 0;
    var firstPageShown = false;

    await for (final entry in parseStream(content)) {
      if (requestId != _currentRequestId) return;
      entries.add(entry);
      count++;
      if (count % 200 == 0) {
        loadingStatus.textContent =
            'Parsing entries with PetitParser: $count loaded...';
        if (!firstPageShown && count >= pageSize) {
          firstPageShown = true;
          allEntries = entries;
          populateFilters();
          applyFilters();
          controls.style.display = 'block';
        }
      }
    }

    if (requestId != _currentRequestId) return;
    allEntries = entries;
    final elapsedMs = watch.elapsedMilliseconds;
    loadingIndicator.style.display = 'none';
    stats.style.display = 'block';
    stats.innerHTML =
        'Downloaded in <span>$downloadMs ms</span>, parsed <span>${allEntries.length}</span> entries in <span>$elapsedMs ms</span>.'
            .toJS;

    populateFilters();
    applyFilters();
    controls.style.display = 'block';
  } catch (e) {
    if (requestId != _currentRequestId) return;
    loadingIndicator.style.display = 'none';
    errorBox.style.display = 'block';
    errorBox.textContent = 'Error parsing BibTeX data: $e';
  }
}

void populateFilters() {
  final types = <String>{};
  final years = <String>{};

  for (final entry in allEntries) {
    types.add(entry.type.toLowerCase());
    final year = entry['year'] ?? '';
    if (year.isNotEmpty && _yearPattern.hasMatch(year)) {
      years.add(year);
    }
  }

  // Populate types
  typeFilter.innerHTML = '<option value="">All Types</option>'.toJS;
  final sortedTypes = types.toList()..sort();
  for (final t in sortedTypes) {
    final opt = document.createElement('option') as HTMLOptionElement;
    opt.value = t;
    opt.textContent = '${t[0].toUpperCase()}${t.substring(1)}';
    typeFilter.appendChild(opt);
  }

  // Populate years
  yearFilter.innerHTML = '<option value="">All Years</option>'.toJS;
  final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
  for (final y in sortedYears) {
    final opt = document.createElement('option') as HTMLOptionElement;
    opt.value = y;
    opt.textContent = y;
    yearFilter.appendChild(opt);
  }
}

extension on JSString {
  external JSString normalize([JSString form]);
}

final _combiningMarks = RegExp(r'[\u0300-\u036f]');
final _specialFolds = {
  'ß': 'ss',
  'æ': 'ae',
  'œ': 'oe',
  'ø': 'o',
  'ł': 'l',
  'đ': 'd',
  'ı': 'i',
};
final _specialFoldPattern = RegExp(r'[ßæœøłđı]');

String _foldDiacritics(String text) => text.toJS
    .normalize('NFD'.toJS)
    .toDart
    .replaceAll(_combiningMarks, '')
    .replaceAllMapped(_specialFoldPattern, (m) => _specialFolds[m[0]] ?? m[0]!);

void applyFilters() {
  final rawQuery = searchInput.value.trim();
  final normalizedQuery = normalizeFieldValue(rawQuery).toLowerCase();
  final foldedQuery = normalizedQuery.isNotEmpty
      ? _foldDiacritics(normalizedQuery)
      : '';
  final selectedType = typeFilter.value.toLowerCase();
  final selectedYear = yearFilter.value;
  final order = sortOrder.value;

  filteredEntries = allEntries.where((entry) {
    if (selectedType.isNotEmpty && entry.type.toLowerCase() != selectedType) {
      return false;
    }
    final year = entry['year'] ?? '';
    if (selectedYear.isNotEmpty && year != selectedYear) {
      return false;
    }
    if (normalizedQuery.isNotEmpty) {
      final key = entry.key.toLowerCase();
      final title = entry['title'] ?? '';
      final author = entry['author'] ?? '';
      final booktitle = entry['booktitle'] ?? '';
      final journal = entry['journal'] ?? '';
      final annote = entry['annote'] ?? '';

      final targetText = '$key $title $author $booktitle $journal $annote'
          .toLowerCase();

      final matches =
          targetText.contains(normalizedQuery) ||
          _foldDiacritics(targetText).contains(foldedQuery);
      if (!matches) return false;
    }
    return true;
  }).toList();

  // Sorting
  filteredEntries.sort((a, b) {
    switch (order) {
      case 'year-asc':
        return (a['year'] ?? '').compareTo(b['year'] ?? '');
      case 'author-asc':
        return (a['author'] ?? '').compareTo(b['author'] ?? '');
      case 'title-asc':
        return (a['title'] ?? '').compareTo(b['title'] ?? '');
      case 'year-desc':
      default:
        return (b['year'] ?? '').compareTo(a['year'] ?? '');
    }
  });

  currentPage = 1;
  renderPage();
}

void renderPage() {
  final total = filteredEntries.length;
  final totalPages = (total / pageSize).ceil().clamp(1, 999999);

  if (currentPage > totalPages) currentPage = totalPages;
  if (currentPage < 1) currentPage = 1;

  resultsCount.textContent = 'Found $total entries';
  final pageStr = 'Page $currentPage of $totalPages';
  pageInfoBottom.textContent = pageStr;

  prevPageBottom.disabled = currentPage <= 1;
  nextPageBottom.disabled = currentPage >= totalPages;

  entriesList.innerHTML = ''.toJS;

  if (total == 0) {
    final empty = document.createElement('div');
    empty.className = 'status-card';
    empty.textContent = 'No matching entries found.';
    entriesList.appendChild(empty);
    return;
  }

  final startIndex = (currentPage - 1) * pageSize;
  final endIndex = (startIndex + pageSize).clamp(0, total);
  final pageEntries = filteredEntries.sublist(startIndex, endIndex);

  for (final entry in pageEntries) {
    final card = document.createElement('div');
    card.className = 'entry-card';

    final typeLower = entry.type.toLowerCase();
    final title = entry['title'] ?? '';
    final author = entry['author'] ?? '';
    final year = entry['year'] ?? '';
    final journal = entry['journal'] ?? '';
    final booktitle = entry['booktitle'] ?? '';
    final publisher = entry['publisher'] ?? '';
    final school = entry['school'] ?? '';
    final institution = entry['institution'] ?? '';
    final url = entry['url'] ?? '';
    final doi = entry['doi'] ?? '';
    final effectiveUrl = url.isNotEmpty
        ? url
        : (doi.isNotEmpty
              ? (doi.startsWith('http') ? doi : 'https://doi.org/$doi')
              : '');

    final venueParts = <String>[];
    if (journal.isNotEmpty) venueParts.add(journal);
    if (booktitle.isNotEmpty) venueParts.add(booktitle);
    if (publisher.isNotEmpty) venueParts.add(publisher);
    if (school.isNotEmpty) venueParts.add(school);
    if (institution.isNotEmpty) venueParts.add(institution);
    if (year.isNotEmpty) venueParts.add(year);
    final venueStr = venueParts.join(', ');

    final header = document.createElement('div');
    header.className = 'entry-header';
    header.innerHTML =
        '''
      <div>
        <span class="entry-badge $typeLower">${escapeHtml(entry.type)}</span>
        <span class="entry-citekey">${escapeHtml(entry.key)}</span>
      </div>
      <div>${year.isNotEmpty ? '<strong style="color: #7f8c8d;">$year</strong>' : ''}</div>
    '''
            .toJS;
    card.appendChild(header);

    if (title.isNotEmpty) {
      final titleEl = document.createElement('div');
      titleEl.className = 'entry-title';
      titleEl.textContent = title;
      card.appendChild(titleEl);
    }

    if (author.isNotEmpty) {
      final authorEl = document.createElement('div');
      authorEl.className = 'entry-authors';
      authorEl.textContent = author;
      card.appendChild(authorEl);
    }

    if (venueStr.isNotEmpty) {
      final venueEl = document.createElement('div');
      venueEl.className = 'entry-venue';
      venueEl.textContent = venueStr;
      card.appendChild(venueEl);
    }

    final actions = document.createElement('div');
    actions.className = 'entry-actions';

    final toggleBtn = document.createElement('button');
    toggleBtn.className = 'button button-outline toggle-btn';
    toggleBtn.textContent = 'Show BibTeX';

    final copyBtn = document.createElement('button');
    copyBtn.className = 'button button-outline copy-btn';
    copyBtn.textContent = 'Copy';

    actions.appendChild(toggleBtn);
    actions.appendChild(copyBtn);

    if (effectiveUrl.isNotEmpty) {
      final link = document.createElement('a') as HTMLAnchorElement;
      link.className = 'url-link';
      link.href = effectiveUrl;
      link.target = '_blank';
      link.textContent = url.isNotEmpty ? 'PDF / Link ↗' : 'DOI ↗';
      actions.appendChild(link);
    }
    card.appendChild(actions);

    final rawBib = document.createElement('div') as HTMLDivElement;
    rawBib.className = 'raw-bibtex';
    rawBib.textContent = entry.toString();
    card.appendChild(rawBib);

    toggleBtn.onClick.listen((_) {
      if (rawBib.style.display == 'block') {
        rawBib.style.display = 'none';
        toggleBtn.textContent = 'Show BibTeX';
      } else {
        rawBib.style.display = 'block';
        toggleBtn.textContent = 'Hide BibTeX';
      }
    });

    copyBtn.onClick.listen((_) {
      window.navigator.clipboard.writeText(entry.toString());
      copyBtn.textContent = 'Copied!';
      window.setTimeout(
        (() {
          copyBtn.textContent = 'Copy';
        }).toJS,
        1500.toJS,
      );
    });

    entriesList.appendChild(card);
  }
}

void main() {
  initShared();

  loadBtn.onClick.listen((_) {
    final url = bibSource.value.trim();
    if (url.isNotEmpty) loadFromUrl(url);
  });

  bibSource.onKeyDown.listen((KeyboardEvent event) {
    if (event.key == 'Enter') {
      event.preventDefault();
      final url = bibSource.value.trim();
      if (url.isNotEmpty) loadFromUrl(url);
    }
  });

  bibSource.onInput.listen((_) => _updateActiveExample(bibSource.value.trim()));

  final exampleButtons = document.querySelectorAll(
    '.source-selector .preset-btn',
  );
  for (var i = 0; i < exampleButtons.length; i++) {
    final btn = exampleButtons.item(i) as HTMLButtonElement;
    btn.onClick.listen((_) {
      final url = btn.getAttribute('data-url');
      if (url != null && url.isNotEmpty) {
        bibSource.value = url;
        loadFromUrl(url);
      }
    });
  }

  searchInput.onInput.listen((_) => applyFilters());
  typeFilter.onChange.listen((_) => applyFilters());
  yearFilter.onChange.listen((_) => applyFilters());
  sortOrder.onChange.listen((_) => applyFilters());

  prevPageBottom.onClick.listen((_) {
    if (currentPage > 1) {
      currentPage--;
      renderPage();
      window.scrollTo(0.toJS, 0);
    }
  });

  nextPageBottom.onClick.listen((_) {
    currentPage++;
    renderPage();
    window.scrollTo(0.toJS, 0);
  });

  // Download and parse default bibliography on startup
  loadFromUrl(bibSource.value);
}
