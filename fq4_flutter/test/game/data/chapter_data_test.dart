import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/game/data/chapter_data.dart';

void main() {
  group('ChapterData', () {
    test('chapter1() returns correct data', () {
      final chapter1 = ChapterData.chapter1();

      expect(chapter1.chapterId, 1);
      expect(chapter1.maps.length, 3);
      expect(chapter1.hasBoss(), true);
    });

    test('chapter2() returns correct data', () {
      final chapter2 = ChapterData.chapter2();

      expect(chapter2.chapterId, 2);
      expect(chapter2.chapterName, isNotEmpty);
      expect(chapter2.maps, isNotEmpty);
    });

    test('chapter3() returns correct data', () {
      final chapter3 = ChapterData.chapter3();

      expect(chapter3.chapterId, 3);
      expect(chapter3.chapterName, isNotEmpty);
      expect(chapter3.maps, isNotEmpty);
    });

    test('getFirstMap() returns first map id', () {
      final chapter1 = ChapterData.chapter1();
      final firstMap = chapter1.getFirstMap();

      expect(firstMap, isNotEmpty);
      expect(chapter1.maps, contains(firstMap));
    });

    test('getNextMap() returns next map id', () {
      final chapter1 = ChapterData.chapter1();
      final firstMap = chapter1.getFirstMap();
      final secondMap = chapter1.getNextMap(firstMap);

      if (chapter1.maps.length > 1) {
        expect(secondMap, isNotNull);
        expect(chapter1.maps, contains(secondMap!));
        expect(chapter1.getMapIndex(secondMap), 1);
      }
    });

    test('getNextMap() returns null for last map', () {
      final chapter1 = ChapterData.chapter1();
      final lastMap = chapter1.maps.last;
      final nextMap = chapter1.getNextMap(lastMap);

      expect(nextMap, isNull);
    });

    test('getMapIndex() returns correct index', () {
      final chapter1 = ChapterData.chapter1();
      final firstMap = chapter1.getFirstMap();

      expect(chapter1.getMapIndex(firstMap), 0);

      if (chapter1.maps.length > 1) {
        final secondMap = chapter1.maps[1];
        expect(chapter1.getMapIndex(secondMap), 1);
      }
    });

    test('getMapIndex() returns -1 for invalid map', () {
      final chapter1 = ChapterData.chapter1();
      expect(chapter1.getMapIndex('invalid_map_id'), -1);
    });
  });
}
