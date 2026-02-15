import 'package:flame/components.dart';
import 'package:fq4_flutter/game/data/chapter_data.dart';

class ChapterManager extends Component {
  final Map<int, ChapterData> chapters = {};
  ChapterData? currentChapter;
  String currentMapId = '';

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 챕터 1-3 미리 로드
    chapters[1] = ChapterData.chapter1();
    chapters[2] = ChapterData.chapter2();
    chapters[3] = ChapterData.chapter3();
  }

  void startChapter(int chapterId) {
    if (!chapters.containsKey(chapterId)) {
      return;
    }

    currentChapter = chapters[chapterId];
    if (currentChapter != null) {
      currentMapId = currentChapter!.getFirstMap();
    }
  }

  bool advanceToNextMap() {
    if (currentChapter == null || currentMapId.isEmpty) {
      return false;
    }

    final nextMap = currentChapter!.getNextMap(currentMapId);
    if (nextMap == null) {
      return false;
    }

    currentMapId = nextMap;
    return true;
  }

  void completeChapter(int chapterId) {
    if (!chapters.containsKey(chapterId)) {
      return;
    }

    // 챕터 클리어 플래그 처리는 SaveSystem에서 담당
    // 다음 챕터가 있으면 시작
    final nextChapterId = chapterId + 1;
    if (chapters.containsKey(nextChapterId)) {
      startChapter(nextChapterId);
    } else {
      // 모든 챕터 완료
      currentChapter = null;
      currentMapId = '';
    }
  }

  ChapterData? getCurrentChapter() {
    return currentChapter;
  }

  void startNewGame() {
    startChapter(1);
  }
}
