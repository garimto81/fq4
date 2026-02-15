import '../data/dialogue_data.dart';

/// DialogueSystem: 대화 시스템 (순수 로직)
///
/// 대화 로직 처리기. UI와 분리되어 있으며 콜백 기반으로 동작합니다.
class DialogueSystem {
  // 현재 대화 상태
  DialogueData? currentDialogue;
  DialogueNode? currentNode;
  bool isActive = false;
  bool isTyping = false;

  // 타이핑 효과 설정
  double typingSpeed = 30.0; // 초당 글자 수
  double visibleCharacters = 0.0;

  // 콜백 (외부에서 설정)
  Function(String dialogueId)? onDialogueStarted;
  Function(String dialogueId)? onDialogueEnded;
  Function(DialogueNode node)? onNodeDisplayed;
  Function(int choiceIndex, String choiceText)? onChoiceSelected;
  Function(String eventString)? onEventTriggered;

  DialogueSystem({
    this.typingSpeed = 30.0,
  });

  /// 대화 시작
  void startDialogue(DialogueData dialogue) {
    currentDialogue = dialogue;
    isActive = true;

    onDialogueStarted?.call(dialogue.dialogueId);

    // 시작 노드 표시
    final startNode = dialogue.getStartNode();
    if (startNode == null) {
      // Error: No start node found
      endDialogue();
      return;
    }

    displayNode(startNode);
  }

  /// 대화 종료
  void endDialogue() {
    final dialogueId = currentDialogue?.dialogueId ?? '';

    isActive = false;
    isTyping = false;
    currentDialogue = null;
    currentNode = null;
    visibleCharacters = 0.0;

    onDialogueEnded?.call(dialogueId);
  }

  /// 노드 표시
  void displayNode(DialogueNode node) {
    currentNode = node;

    // 타이핑 효과 시작
    visibleCharacters = 0.0;
    isTyping = true;

    // 이벤트 처리
    if (node.event != null && node.event!.isNotEmpty) {
      onEventTriggered?.call(node.event!);
    }

    onNodeDisplayed?.call(node);
  }

  /// 다음 노드로 진행
  void advanceToNext([int choiceIndex = -1]) {
    if (currentDialogue == null || currentNode == null) {
      return;
    }

    final nextNode = currentDialogue!.getNextNode(currentNode!, choiceIndex);

    if (nextNode == null) {
      // 대화 종료
      endDialogue();
    } else {
      displayNode(nextNode);
    }
  }

  /// Accept 입력 처리 (스페이스바, Enter 등)
  void handleAcceptInput() {
    if (!isActive) {
      return;
    }

    if (isTyping) {
      // 타이핑 스킵
      skipTyping();
    } else if (currentNode != null && currentNode!.choices.isEmpty) {
      // 선택지가 없으면 다음 노드로 진행
      advanceToNext();
    }
  }

  /// 타이핑 스킵
  void skipTyping() {
    if (currentNode == null) {
      return;
    }

    isTyping = false;
    visibleCharacters = currentNode!.text.length.toDouble();
  }

  /// 선택지 선택 처리
  void selectChoice(int choiceIndex) {
    if (currentNode == null || choiceIndex < 0 || choiceIndex >= currentNode!.choices.length) {
      return;
    }

    final choice = currentNode!.choices[choiceIndex];
    onChoiceSelected?.call(choiceIndex, choice.text);

    // 선택지에 이벤트가 있으면 처리
    if (choice.event != null && choice.event!.isNotEmpty) {
      onEventTriggered?.call(choice.event!);
    }

    // 다음 노드로 진행
    advanceToNext(choiceIndex);
  }

  /// 업데이트 (타이핑 효과)
  void update(double dt) {
    if (!isActive || !isTyping || currentNode == null) {
      return;
    }

    visibleCharacters += typingSpeed * dt;

    if (visibleCharacters >= currentNode!.text.length) {
      visibleCharacters = currentNode!.text.length.toDouble();
      isTyping = false;
    }
  }

  /// 현재 표시할 텍스트 (타이핑 효과 적용)
  String getVisibleText() {
    if (currentNode == null) {
      return '';
    }

    final charCount = visibleCharacters.floor();
    if (charCount >= currentNode!.text.length) {
      return currentNode!.text;
    }

    return currentNode!.text.substring(0, charCount);
  }

  /// 타이핑 완료 여부
  bool isTypingComplete() {
    return !isTyping;
  }
}
