import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/poc/poc_manifest.dart';

void main() {
  group('PocManifest', () {
    test('all contains exactly 11 POC definitions', () {
      expect(PocManifest.all.length, 11);
    });

    test('all IDs are unique', () {
      final ids = PocManifest.all.map((d) => d.id).toSet();
      expect(ids.length, PocManifest.all.length);
    });

    test('all routes start with /', () {
      for (final def in PocManifest.all) {
        expect(def.route, startsWith('/'), reason: '${def.id} route should start with /');
      }
    });

    test('all definitions have non-empty name and description', () {
      for (final def in PocManifest.all) {
        expect(def.name.isNotEmpty, true, reason: '${def.id} should have a name');
        expect(def.description.isNotEmpty, true, reason: '${def.id} should have a description');
      }
    });

    test('all definitions have at least one criterion', () {
      for (final def in PocManifest.all) {
        expect(def.criteria.isNotEmpty, true,
            reason: '${def.id} should have at least one criterion');
      }
    });

    test('byId returns correct definition', () {
      final s1 = PocManifest.byId('poc-s1');
      expect(s1, isNotNull);
      expect(s1!.name, 'POC-07: Direction-Based Damage');
      expect(s1.route, '/poc-s1');
    });

    test('byId returns correct definition for poc-s5', () {
      final s5 = PocManifest.byId('poc-s5');
      expect(s5, isNotNull);
      expect(s5!.name, 'POC-11: AI Flanking Behavior');
      expect(s5.route, '/poc-s5');
      expect(s5.requiresInput, false);
      expect(s5.criteria.length, 4);
    });

    test('byId returns null for unknown id', () {
      expect(PocManifest.byId('unknown'), isNull);
    });

    test('categories returns 4 categories in order', () {
      final cats = PocManifest.categories;
      expect(cats.length, 4);
      expect(cats[0], 'Core Systems');
      expect(cats[1], 'Integration');
      expect(cats[2], 'Gocha-Kyara');
      expect(cats[3], 'Strategic Combat');
    });

    test('byCategory returns correct POCs', () {
      final core = PocManifest.byCategory('Core Systems');
      expect(core.length, 4); // poc-1, poc-2, poc-3, poc-4
      expect(core.map((d) => d.id).toList(),
          ['poc-1', 'poc-2', 'poc-3', 'poc-4']);

      final strategic = PocManifest.byCategory('Strategic Combat');
      expect(strategic.length, 5); // poc-s1, poc-s2, poc-s3, poc-s4, poc-s5
    });

    test('autoRunnable returns only POCs without requiresInput', () {
      final auto = PocManifest.autoRunnable;
      for (final def in auto) {
        expect(def.requiresInput, false,
            reason: '${def.id} should not require input');
      }
      // poc-2, poc-4, poc-5, poc-s1, poc-s2, poc-s3, poc-s5 = 7
      expect(auto.length, 7);
    });

    test('isAutoRunnable is inverse of requiresInput', () {
      for (final def in PocManifest.all) {
        expect(def.isAutoRunnable, !def.requiresInput,
            reason: '${def.id} isAutoRunnable should be !requiresInput');
      }
    });

    test('expected POC IDs exist', () {
      final expectedIds = [
        'poc-1', 'poc-2', 'poc-3', 'poc-4', 'poc-5',
        'poc-t0', 'poc-s1', 'poc-s2', 'poc-s3', 'poc-s4', 'poc-s5',
      ];
      for (final id in expectedIds) {
        expect(PocManifest.byId(id), isNotNull, reason: '$id should exist');
      }
    });

    test('criterion IDs are unique within each POC', () {
      for (final def in PocManifest.all) {
        final criterionIds = def.criteria.map((c) => c.id).toSet();
        expect(criterionIds.length, def.criteria.length,
            reason: '${def.id} should have unique criterion IDs');
      }
    });

    test('criteria evaluate functions handle empty metrics', () {
      for (final def in PocManifest.all) {
        for (final criterion in def.criteria) {
          // Should not throw with empty metrics
          final result = criterion.evaluate({});
          expect(result, isA<bool>(),
              reason: '${def.id}/${criterion.id} should return bool for empty metrics');
        }
      }
    });
  });
}
