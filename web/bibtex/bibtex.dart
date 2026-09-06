import 'dart:async';
import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:web/web.dart';

final bibSource = document.querySelector('#bib-source') as HTMLInputElement;
final loadBtn = document.querySelector('#load-btn') as HTMLButtonElement;

final loadingIndicator =
    document.querySelector('#loading-indicator') as HTMLElement;
final loadingStatus = document.querySelector('#loading-status') as HTMLElement;
final progressBar = document.querySelector('#progress-bar') as HTMLElement;
final errorBox = document.querySelector('#error-box') as HTMLElement;
final statusBox = document.querySelector('#status-box') as HTMLElement;
final controls = document.querySelector('#controls') as HTMLElement;

final searchInput = document.querySelector('#search-input') as HTMLInputElement;
final typeFilter = document.querySelector('#type-filter') as HTMLSelectElement;
final yearFilter = document.querySelector('#year-filter') as HTMLSelectElement;
final sortOrder = document.querySelector('#sort-order') as HTMLSelectElement;

final resultsCount = document.querySelector('#results-count') as HTMLElement;
final pageInfo = document.querySelector('#page-info') as HTMLElement;
final pageInfoBottom =
    document.querySelector('#page-info-bottom') as HTMLElement;
final prevPage = document.querySelector('#prev-page') as HTMLButtonElement;
final nextPage = document.querySelector('#next-page') as HTMLButtonElement;
final prevPageBottom =
    document.querySelector('#prev-page-bottom') as HTMLButtonElement;
final nextPageBottom =
    document.querySelector('#next-page-bottom') as HTMLButtonElement;

final entriesList = document.querySelector('#entries-list') as HTMLElement;

final parser = BibTeXDefinition().build();

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

Future<void> loadFromUrl(String url) async {
  loadingIndicator.style.display = 'block';
  loadingStatus.textContent = 'Connecting to $url...';
  progressBar.style.width = '0%';
  errorBox.style.display = 'none';
  statusBox.style.display = 'none';
  controls.style.display = 'none';

  final completer = Completer<String>();
  final xhr = XMLHttpRequest();
  xhr.open('GET', url);

  xhr.onprogress = ((ProgressEvent event) {
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
    if (xhr.status >= 200 && xhr.status < 300) {
      completer.complete(xhr.responseText);
    } else {
      completer.completeError(
        Exception('HTTP error ${xhr.status}: ${xhr.statusText}'),
      );
    }
  }).toJS;

  xhr.onerror = ((Event _) {
    completer.completeError(Exception('Network error while requesting $url'));
  }).toJS;

  xhr.onabort = ((Event _) {
    completer.completeError(Exception('Request was aborted.'));
  }).toJS;

  xhr.send();

  try {
    final text = await completer.future;
    progressBar.style.width = '100%';
    loadingStatus.textContent =
        'Downloaded ${(text.length / (1024 * 1024)).toStringAsFixed(1)} MB. Parsing entries with PetitParser...';
    // Yield to let browser render the updated status before CPU-intensive parse
    await Future<void>.delayed(const Duration(milliseconds: 20));
    parseBibTeX(text, 'Source: $url (${(text.length / 1024).round()} KB)');
  } catch (e) {
    loadingIndicator.style.display = 'none';
    errorBox.style.display = 'block';
    errorBox.textContent = 'Failed to load or parse: $e';
  }
}

void parseBibTeX(String content, String sourceLabel) {
  loadingIndicator.style.display = 'block';
  final watch = Stopwatch()..start();
  try {
    final result = parser.parse(content);
    final elapsedMs = watch.elapsedMilliseconds;
    if (result is Failure) {
      throw Exception('${result.message} at line ${result.toPositionString()}');
    }

    allEntries = result.value;
    loadingIndicator.style.display = 'none';
    statusBox.style.display = 'block';
    statusBox.innerHTML =
        '<strong>Parsed ${allEntries.length} entries</strong> in <strong>${elapsedMs}ms</strong>. $sourceLabel'
            .toJS;

    populateFilters();
    applyFilters();
    controls.style.display = 'block';
  } catch (e) {
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
    final year = entry.normalized['Year'] ?? '';
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

void applyFilters() {
  final query = searchInput.value.toLowerCase().trim();
  final selectedType = typeFilter.value.toLowerCase();
  final selectedYear = yearFilter.value;
  final order = sortOrder.value;

  filteredEntries = allEntries.where((entry) {
    if (selectedType.isNotEmpty && entry.type.toLowerCase() != selectedType) {
      return false;
    }
    final year = entry.normalized['Year'] ?? '';
    if (selectedYear.isNotEmpty && year != selectedYear) {
      return false;
    }
    if (query.isNotEmpty) {
      final key = entry.key.toLowerCase();
      final title = (entry.normalized['Title'] ?? '').toLowerCase();
      final author = (entry.normalized['Author'] ?? '').toLowerCase();
      final booktitle = (entry.normalized['Booktitle'] ?? '').toLowerCase();
      final journal = (entry.normalized['Journal'] ?? '').toLowerCase();
      final annote = (entry.normalized['Annote'] ?? '').toLowerCase();

      final matches =
          key.contains(query) ||
          title.contains(query) ||
          author.contains(query) ||
          booktitle.contains(query) ||
          journal.contains(query) ||
          annote.contains(query);
      if (!matches) return false;
    }
    return true;
  }).toList();

  // Sorting
  filteredEntries.sort((a, b) {
    switch (order) {
      case 'year-asc':
        return (a.normalized['Year'] ?? '').compareTo(
          b.normalized['Year'] ?? '',
        );
      case 'author-asc':
        return (a.normalized['Author'] ?? '').compareTo(
          b.normalized['Author'] ?? '',
        );
      case 'title-asc':
        return (a.normalized['Title'] ?? '').compareTo(
          b.normalized['Title'] ?? '',
        );
      case 'year-desc':
      default:
        return (b.normalized['Year'] ?? '').compareTo(
          a.normalized['Year'] ?? '',
        );
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
  pageInfo.textContent = pageStr;
  pageInfoBottom.textContent = pageStr;

  prevPage.disabled = currentPage <= 1;
  prevPageBottom.disabled = currentPage <= 1;
  nextPage.disabled = currentPage >= totalPages;
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
    final title = entry.normalized['Title'] ?? '';
    final author = entry.normalized['Author'] ?? '';
    final year = entry.normalized['Year'] ?? '';
    final journal = entry.normalized['Journal'] ?? '';
    final booktitle = entry.normalized['Booktitle'] ?? '';
    final publisher = entry.normalized['Publisher'] ?? '';
    final school = entry.normalized['School'] ?? '';
    final institution = entry.normalized['Institution'] ?? '';
    final url = entry.normalized['Url'] ?? '';

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

    if (url.isNotEmpty) {
      final link = document.createElement('a') as HTMLAnchorElement;
      link.className = 'url-link';
      link.href = url;
      link.target = '_blank';
      link.textContent = 'PDF / Link ↗';
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
  loadBtn.onClick.listen((_) {
    final url = bibSource.value.trim();
    if (url.isNotEmpty) loadFromUrl(url);
  });

  searchInput.onInput.listen((_) => applyFilters());
  typeFilter.onChange.listen((_) => applyFilters());
  yearFilter.onChange.listen((_) => applyFilters());
  sortOrder.onChange.listen((_) => applyFilters());

  prevPage.onClick.listen((_) {
    if (currentPage > 1) {
      currentPage--;
      renderPage();
      window.scrollTo(0.toJS, 0);
    }
  });

  prevPageBottom.onClick.listen((_) {
    if (currentPage > 1) {
      currentPage--;
      renderPage();
      window.scrollTo(0.toJS, 0);
    }
  });

  nextPage.onClick.listen((_) {
    currentPage++;
    renderPage();
    window.scrollTo(0.toJS, 0);
  });

  nextPageBottom.onClick.listen((_) {
    currentPage++;
    renderPage();
    window.scrollTo(0.toJS, 0);
  });

  // Download and parse default bibliography on startup
  loadFromUrl(bibSource.value);
}
