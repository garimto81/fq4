import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../managers/game_manager.dart';
import '../../core/constants/ai_constants.dart';

/// 글로벌 게임 입력 핸들러
class GameInputHandler extends Component with KeyboardHandler, HasGameReference {
  GameManager? get _gm => parent is GameManager ? parent as GameManager : findParent<GameManager>();

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return false;

    final gm = _gm;
    if (gm == null) return false;

    switch (event.logicalKey) {
      // 부대 내 유닛 전환 (Q/E)
      case LogicalKeyboardKey.keyQ:
        gm.switchUnitInSquad(-1);
        return true;
      case LogicalKeyboardKey.keyE:
        gm.switchUnitInSquad(1);
        return true;

      // 부대 전환 (Tab)
      case LogicalKeyboardKey.tab:
        gm.switchSquad(1);
        return true;

      // 일시정지 (Escape)
      case LogicalKeyboardKey.escape:
        if (gm.state == GameState.playing) {
          gm.state = GameState.paused;
        } else if (gm.state == GameState.paused) {
          gm.state = GameState.playing;
        }
        return true;

      // 부대 명령 (1-5)
      case LogicalKeyboardKey.digit1:
        _issueCommand(SquadCommand.gather);
        return true;
      case LogicalKeyboardKey.digit2:
        _issueCommand(SquadCommand.scatter);
        return true;
      case LogicalKeyboardKey.digit3:
        _issueCommand(SquadCommand.attackAll);
        return true;
      case LogicalKeyboardKey.digit4:
        _issueCommand(SquadCommand.defendAll);
        return true;
      case LogicalKeyboardKey.digit5:
        _issueCommand(SquadCommand.retreatAll);
        return true;

      default:
        return false;
    }
  }

  void _issueCommand(SquadCommand command) {
    // 현재 부대의 모든 AI 유닛에게 명령 전달
    final gm = _gm;
    if (gm == null) return;
    final squad = gm.squads[gm.currentSquadId];
    if (squad == null) return;
    // AIUnitComponent의 aiBrain.currentCommand에 설정
    // 실제 연결은 Unit 컴포넌트 구현 후
  }
}
