import 'package:currency_pro/core/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every locale has the same keys as English', () {
    final Map<String, String> english = L10n.tables['en']!;
    final List<String> problems = <String>[];

    for (final MapEntry<String, Map<String, String>> entry
        in L10n.tables.entries) {
      if (entry.key == 'en') continue;
      final Set<String> missing =
          english.keys.toSet().difference(entry.value.keys.toSet());
      final Set<String> extra =
          entry.value.keys.toSet().difference(english.keys.toSet());
      if (missing.isNotEmpty) {
        problems.add('${entry.key} missing: ${missing.join(', ')}');
      }
      if (extra.isNotEmpty) {
        problems.add('${entry.key} extra: ${extra.join(', ')}');
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
