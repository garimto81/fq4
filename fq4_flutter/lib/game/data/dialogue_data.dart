// DialogueData: 대화 데이터 클래스
//
// 대화 노드들과 선택지를 포함합니다.

class DialogueChoice {
  final String text;
  final String nextId;
  final String? event;

  DialogueChoice({
    required this.text,
    required this.nextId,
    this.event,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'next': nextId,
        if (event != null) 'event': event,
      };

  factory DialogueChoice.fromJson(Map<String, dynamic> json) {
    return DialogueChoice(
      text: json['text'] as String,
      nextId: json['next'] as String,
      event: json['event'] as String?,
    );
  }
}

class DialogueNode {
  final String id;
  final String speaker;
  final String text;
  final String? portraitPath;
  final List<DialogueChoice> choices;
  final String? nextId;
  final String? event;

  DialogueNode({
    required this.id,
    required this.speaker,
    required this.text,
    this.portraitPath,
    this.choices = const [],
    this.nextId,
    this.event,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'speaker': speaker,
        'text': text,
        if (portraitPath != null) 'portrait': portraitPath,
        if (choices.isNotEmpty)
          'choices': choices.map((c) => c.toJson()).toList(),
        if (nextId != null) 'next': nextId,
        if (event != null) 'event': event,
      };

  factory DialogueNode.fromJson(Map<String, dynamic> json) {
    final choicesJson = json['choices'] as List<dynamic>?;
    return DialogueNode(
      id: json['id'] as String,
      speaker: json['speaker'] as String,
      text: json['text'] as String,
      portraitPath: json['portrait'] as String?,
      choices: choicesJson
              ?.map((c) => DialogueChoice.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      nextId: json['next'] as String?,
      event: json['event'] as String?,
    );
  }
}

class DialogueData {
  final String dialogueId;
  final String title;
  final List<DialogueNode> nodes;
  final String startNodeId;

  DialogueData({
    required this.dialogueId,
    required this.title,
    required this.nodes,
    this.startNodeId = 'start',
  });

  /// 노드 ID로 노드 찾기
  DialogueNode? getNodeById(String nodeId) {
    try {
      return nodes.firstWhere((node) => node.id == nodeId);
    } catch (e) {
      return null;
    }
  }

  /// 시작 노드 가져오기
  DialogueNode? getStartNode() {
    return getNodeById(startNodeId);
  }

  /// 다음 노드 가져오기
  DialogueNode? getNextNode(DialogueNode currentNode, [int choiceIndex = -1]) {
    // 선택지가 있고 유효한 인덱스인 경우
    if (currentNode.choices.isNotEmpty &&
        choiceIndex >= 0 &&
        choiceIndex < currentNode.choices.length) {
      final nextId = currentNode.choices[choiceIndex].nextId;
      return getNodeById(nextId);
    }

    // 일반 다음 노드
    if (currentNode.nextId != null && currentNode.nextId!.isNotEmpty) {
      return getNodeById(currentNode.nextId!);
    }

    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': dialogueId,
        'title': title,
        'start_node': startNodeId,
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };

  factory DialogueData.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as List<dynamic>;
    return DialogueData(
      dialogueId: json['id'] as String,
      title: json['title'] as String,
      startNodeId: json['start_node'] as String? ?? 'start',
      nodes: nodesJson
          .map((n) => DialogueNode.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }

  // ========== 정적 팩토리 메서드 (샘플 대화 데이터) ==========

  /// Chapter 1 인트로 대화
  static DialogueData chapter1Intro() {
    return DialogueData(
      dialogueId: 'chapter1_intro',
      title: 'Chapter 1 - 여정의 시작',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '전란의 시대... 아레스는 운명에 이끌려 여정을 시작한다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '아레스',
          text: '이곳이 숲의 입구인가... 위험한 기운이 느껴진다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '타로',
          text: '아레스님, 조심하세요. 고블린들이 출몰한다고 합니다.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '아레스',
          text: '알았다. 부대를 이끌고 신중하게 전진하겠다.',
          event: 'set_flag:chapter1_intro_complete',
        ),
      ],
    );
  }

  /// Chapter 1 보스 조우
  static DialogueData chapter1BossEncounter() {
    return DialogueData(
      dialogueId: 'chapter1_boss_encounter',
      title: 'Chapter 1 - 고블린 킹 조우',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '고블린 킹',
          text: '크크크... 인간들이 여기까지 왔군.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '아레스',
          text: '고블린 킹... 너의 악행을 여기서 끝낸다!',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '고블린 킹',
          text: '흥, 큰소리는... 내 부하들을 모두 쓰러뜨린 실력은 인정하지.',
          nextId: 'choice',
        ),
        DialogueNode(
          id: 'choice',
          speaker: '아레스',
          text: '어떻게 하겠는가?',
          choices: [
            DialogueChoice(
              text: '당장 항복하라!',
              nextId: 'battle_aggressive',
            ),
            DialogueChoice(
              text: '평화적으로 해결할 방법은 없는가?',
              nextId: 'battle_diplomatic',
            ),
          ],
        ),
        DialogueNode(
          id: 'battle_aggressive',
          speaker: '고블린 킹',
          text: '항복? 크하하! 전사답게 싸우다 죽어라!',
          event: 'set_flag:aggressive_approach',
        ),
        DialogueNode(
          id: 'battle_diplomatic',
          speaker: '고블린 킹',
          text: '평화? 이미 늦었다. 전쟁뿐이다!',
          event: 'set_flag:diplomatic_approach',
        ),
      ],
    );
  }

  /// Chapter 1 클리어
  static DialogueData chapter1Clear() {
    return DialogueData(
      dialogueId: 'chapter1_clear',
      title: 'Chapter 1 - 클리어',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '고블린 킹을 쓰러뜨린 아레스 일행...',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '타로',
          text: '해냈습니다! 마을이 안전해졌어요!',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '아레스',
          text: '하지만 이것은 시작일 뿐이다. 앞으로 더 큰 시련이 기다리고 있을 것이다.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '나레이션',
          text: 'Chapter 1 클리어!',
          event: 'set_flag:chapter1_complete',
        ),
      ],
    );
  }

  /// Chapter 2 시작
  static DialogueData chapter2Start() {
    return DialogueData(
      dialogueId: 'chapter2_start',
      title: 'Chapter 2 - 사막의 시련',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '아레스 일행은 사막 지대로 향한다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '아레스',
          text: '뜨거운 모래바람... 여기가 소문으로만 듣던 사막인가.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '타로',
          text: '물 보급을 신중히 해야 합니다. 사막은 무자비합니다.',
          event: 'set_flag:chapter2_intro_complete',
        ),
      ],
    );
  }

  /// Chapter 3 인트로
  static DialogueData chapter3Intro() {
    return DialogueData(
      dialogueId: 'chapter3_intro',
      title: 'Chapter 3 - 어둠의 숲',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '어둠이 짙게 드리운 숲... 불길한 기운이 감돈다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '알레인',
          text: '이곳의 마력이 심상치 않습니다. 강력한 무언가가 있어요.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '아레스',
          text: '타락한 기사에 대한 소문이 사실이었나... 조심해야겠다.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '나레이션',
          text: '숲 깊은 곳에서 비명소리가 들려온다.',
          event: 'set_flag:chapter3_intro_complete',
        ),
      ],
    );
  }

  /// Chapter 4 인트로
  static DialogueData chapter4Intro() {
    return DialogueData(
      dialogueId: 'chapter4_intro',
      title: 'Chapter 4 - 얼어붙은 성채',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '눈보라가 몰아치는 북방의 성채...',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '가렌',
          text: '이 추위... 보통이 아니군. 언데드의 기운이 느껴진다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '아레스',
          text: '리치가 이곳을 지배하고 있다는 정보가 맞는 것 같다.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '타로',
          text: '조심하세요. 언데드들은 통상적인 전술이 통하지 않습니다.',
          event: 'set_flag:chapter4_intro_complete',
        ),
      ],
    );
  }

  /// Chapter 5 인트로
  static DialogueData chapter5Intro() {
    return DialogueData(
      dialogueId: 'chapter5_intro',
      title: 'Chapter 5 - 독의 늪',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '독기가 피어오르는 늪지대... 생명의 기운이 느껴지지 않는다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '알레인',
          text: '해독 마법을 준비해야겠어요. 여기 독은 치명적입니다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '가렌',
          text: '타락한 귀족이 이곳을 이렇게 만들었다니... 용서할 수 없어.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '아레스',
          text: '빠르게 처리하고 이곳을 정화하자. 더 이상의 희생은 없어야 한다.',
          event: 'set_flag:chapter5_intro_complete',
        ),
      ],
    );
  }

  /// Chapter 6 인트로
  static DialogueData chapter6Intro() {
    return DialogueData(
      dialogueId: 'chapter6_intro',
      title: 'Chapter 6 - 불의 산',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '용암이 흐르는 화산... 공기마저 타들어간다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '타로',
          text: '데몬 제너럴이 이곳에 은신처를 만들었다는 정보가 확실해 보입니다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '아레스',
          text: '여기서 저들을 막지 못하면 전선이 무너진다. 각오하라.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '가렌',
          text: '드디어 제대로 된 싸움이군! 내 검이 불타오른다!',
          event: 'set_flag:chapter6_intro_complete',
        ),
      ],
    );
  }

  /// Chapter 7 인트로
  static DialogueData chapter7Intro() {
    return DialogueData(
      dialogueId: 'chapter7_intro',
      title: 'Chapter 7 - 어둠의 탑',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '하늘을 찌르는 검은 탑... 모든 것의 종착점.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '미라',
          text: '여러분, 제가 치유 마법으로 최선을 다해 돕겠습니다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '알레인',
          text: '타락한 영웅... 한때는 우리와 같은 편이었던 자가 적이 되다니.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '아레스',
          text: '여기서 끝낸다. 이것이 마지막 전투다... 모두 각오하라!',
          event: 'set_flag:chapter7_intro_complete',
        ),
      ],
    );
  }

  /// 튜토리얼 대화
  static DialogueData tutorial() {
    return DialogueData(
      dialogueId: 'tutorial',
      title: '튜토리얼',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '가이드',
          text: '환영합니다! First Queen 4에 오신 것을 환영합니다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '가이드',
          text: '이 게임은 실시간 전술 RPG입니다. 부대를 이끌고 전투를 승리로 이끄세요.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '가이드',
          text: '화살표 키로 유닛을 전환하고, 공격/방어 명령을 내릴 수 있습니다.',
          choices: [
            DialogueChoice(
              text: '알겠습니다',
              nextId: 'node_3',
            ),
            DialogueChoice(
              text: '좀 더 자세히 설명해주세요',
              nextId: 'detail',
            ),
          ],
        ),
        DialogueNode(
          id: 'detail',
          speaker: '가이드',
          text: '좌우 화살표: 부대원 전환\n상하 화살표: 부대 전환\nA: 공격 명령\nD: 방어 명령',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '가이드',
          text: '행운을 빕니다!',
          event: 'set_flag:tutorial_complete',
        ),
      ],
    );
  }

  /// Chapter 8 인트로 대화
  static DialogueData chapter8Intro() {
    return DialogueData(
      dialogueId: 'chapter8_intro',
      title: 'Chapter 8 - 마왕의 영역',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '아레스 일행은 마침내 마왕의 영역에 도달했다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '아레스',
          text: '드디어 여기까지 왔군... 이 어둠의 기운, 마왕이 가까이 있다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '타로',
          text: '조심하세요. 여기서부터는 진짜 지옥입니다.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '알레인',
          text: '우리가 함께라면 두렵지 않습니다. 끝까지 함께 해요!',
          event: 'set_flag:chapter8_intro_complete',
        ),
      ],
    );
  }

  /// Chapter 9 인트로 대화
  static DialogueData chapter9Intro() {
    return DialogueData(
      dialogueId: 'chapter9_intro',
      title: 'Chapter 9 - 최후의 결전',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '마왕의 최강 부하, 데몬 장군이 앞을 가로막는다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: 'Demon General',
          text: '여기까지 온 것은 대단하지만... 이것이 네 무덤이 될 것이다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '아레스',
          text: '너를 넘어야 마왕에게 다가갈 수 있다. 각오해라!',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: 'Demon General',
          text: '후후... 그 자신감, 꺾어주마!',
          event: 'set_flag:chapter9_intro_complete',
        ),
      ],
    );
  }

  /// Chapter 10 인트로 대화
  static DialogueData chapter10Intro() {
    return DialogueData(
      dialogueId: 'chapter10_intro',
      title: 'Chapter 10 - 마왕과의 대결',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '마침내 마왕의 옥좌 앞에 섰다. 모든 것을 끝낼 시간이다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: 'Demon King',
          text: '잘도 여기까지 왔구나, 인간들아. 하지만 이것이 끝이다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '아레스',
          text: '오랜 여정이었다. 하지만 이제 너를 쓰러뜨리고 평화를 되찾겠다!',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: 'Demon King',
          text: '크하하하! 그 말, 후회하게 해주마. 내 진정한 힘을 보여주겠다!',
          event: 'set_flag:chapter10_intro_complete',
        ),
      ],
    );
  }

  /// Good Ending 대화
  static DialogueData goodEnding() {
    return DialogueData(
      dialogueId: 'good_ending',
      title: 'TRUE ENDING - 진정한 영웅',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '마왕이 쓰러졌다. 아레스와 모든 동료들이 함께 승리를 맞이했다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '아레스',
          text: '해냈다... 우리가 해냈어!',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '타로',
          text: '아레스님, 우리 모두가 함께였기에 가능했습니다.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '알레인',
          text: '이제 왕국에 진정한 평화가 찾아올 거예요.',
          nextId: 'node_4',
        ),
        DialogueNode(
          id: 'node_4',
          speaker: '나레이션',
          text: '아레스 일행은 영웅으로 왕국에 돌아가 평화로운 시대를 열었다.\n\nTRUE ENDING - 모든 동료와 함께한 승리',
          event: 'set_flag:good_ending_complete',
        ),
      ],
    );
  }

  /// Normal Ending 대화
  static DialogueData normalEnding() {
    return DialogueData(
      dialogueId: 'normal_ending',
      title: 'NORMAL ENDING - 희생의 대가',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '마왕은 쓰러졌지만... 큰 희생이 따랐다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '아레스',
          text: '이겼지만... 우리가 잃은 것도 너무 많다.',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '타로',
          text: '그들의 희생은 헛되지 않을 것입니다. 우리가 기억할 테니까요.',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '나레이션',
          text: '평화는 찾아왔지만, 아레스의 마음에는 영원히 슬픔이 남았다.\n\nNORMAL ENDING - 희생 끝에 얻은 승리',
          event: 'set_flag:normal_ending_complete',
        ),
      ],
    );
  }

  /// Bad Ending 대화
  static DialogueData badEnding() {
    return DialogueData(
      dialogueId: 'bad_ending',
      title: 'BAD ENDING - 외로운 승리',
      nodes: [
        DialogueNode(
          id: 'start',
          speaker: '나레이션',
          text: '마왕은 쓰러졌다. 하지만 아레스는 홀로 남았다.',
          nextId: 'node_1',
        ),
        DialogueNode(
          id: 'node_1',
          speaker: '아레스',
          text: '모두... 모두 떠나갔다. 나 혼자만 남았어...',
          nextId: 'node_2',
        ),
        DialogueNode(
          id: 'node_2',
          speaker: '아레스',
          text: '이런 승리가 무슨 의미가 있단 말인가...',
          nextId: 'node_3',
        ),
        DialogueNode(
          id: 'node_3',
          speaker: '나레이션',
          text: '아레스는 왕국을 구했지만, 그 대가는 너무나 컸다.\n\nBAD ENDING - 모든 것을 잃은 영웅',
          event: 'set_flag:bad_ending_complete',
        ),
      ],
    );
  }
}
