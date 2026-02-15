import 'package:flame/components.dart';

/// 이벤트 타입
enum EventType {
  dialogue,
  battle,
  mapTransition,
  itemPickup,
  flagSet,
  spawnEnemy,
  healParty,
  custom,
}

/// 트리거 조건
enum TriggerCondition {
  onEnter,
  onInteract,
  onFlag,
  onBattleEnd,
  auto,
}

/// 이벤트 데이터
class EventData {
  final EventType type;
  final Map<String, dynamic> data;

  EventData({
    required this.type,
    required this.data,
  });
}

/// 트리거 데이터
class TriggerData {
  final String id;
  final TriggerCondition condition;
  final List<EventData> events;
  final List<String> requiredFlags;
  final List<String> blockedFlags;
  final bool oneShot;

  TriggerData({
    required this.id,
    required this.condition,
    required this.events,
    this.requiredFlags = const [],
    this.blockedFlags = const [],
    this.oneShot = true,
  });
}

/// EventSystem: 이벤트 시스템 컴포넌트
///
/// 트리거 기반 이벤트, 대화/전투/씬 전환 이벤트를 관리합니다.
class EventSystem extends Component {
  // 이벤트 큐
  final List<EventData> eventQueue = [];
  bool isProcessing = false;
  EventData? currentEvent;

  // 등록된 트리거
  final List<TriggerData> registeredTriggers = [];

  // 콜백 (외부에서 설정)
  Function(EventData)? onEventStarted;
  Function(EventData)? onEventCompleted;
  Function(String)? onTriggerActivated;

  // 이벤트 실행 콜백
  Function(EventData)? onDialogueEvent;
  Function(EventData)? onBattleEvent;
  Function(EventData)? onMapTransitionEvent;
  Function(EventData)? onItemPickupEvent;
  Function(EventData)? onFlagSetEvent;
  Function(EventData)? onSpawnEnemyEvent;
  Function(EventData)? onHealPartyEvent;
  Function(EventData)? onCustomEvent;

  // 플래그 시스템 콜백
  Function(String)? hasFlag;
  Function(String, bool)? setFlag;

  EventSystem();

  @override
  void update(double dt) {
    super.update(dt);
    // 큐 처리 (비동기 대신 폴링 방식)
    if (!isProcessing && eventQueue.isNotEmpty) {
      _processNextEvent();
    }
  }

  /// 이벤트 큐에 추가
  void queueEvent(EventData event) {
    eventQueue.add(event);
  }

  /// 이벤트 즉시 실행
  void executeEvent(EventData event) {
    currentEvent = event;
    isProcessing = true;

    onEventStarted?.call(event);

    switch (event.type) {
      case EventType.dialogue:
        _executeDialogueEvent(event);
        break;
      case EventType.battle:
        _executeBattleEvent(event);
        break;
      case EventType.mapTransition:
        _executeMapTransitionEvent(event);
        break;
      case EventType.itemPickup:
        _executeItemPickupEvent(event);
        break;
      case EventType.flagSet:
        _executeFlagSetEvent(event);
        break;
      case EventType.spawnEnemy:
        _executeSpawnEnemyEvent(event);
        break;
      case EventType.healParty:
        _executeHealPartyEvent(event);
        break;
      case EventType.custom:
        _executeCustomEvent(event);
        break;
    }

    onEventCompleted?.call(event);
    isProcessing = false;

    // 다음 이벤트 처리
    _processNextEvent();
  }

  /// 다음 이벤트 처리
  void _processNextEvent() {
    if (eventQueue.isEmpty) {
      return;
    }

    final nextEvent = eventQueue.removeAt(0);
    executeEvent(nextEvent);
  }

  /// 대화 이벤트 실행
  void _executeDialogueEvent(EventData event) {
    onDialogueEvent?.call(event);
  }

  /// 전투 이벤트 실행
  void _executeBattleEvent(EventData event) {
    onBattleEvent?.call(event);
  }

  /// 맵 전환 이벤트 실행
  void _executeMapTransitionEvent(EventData event) {
    onMapTransitionEvent?.call(event);
  }

  /// 아이템 획득 이벤트 실행
  void _executeItemPickupEvent(EventData event) {
    onItemPickupEvent?.call(event);
  }

  /// 플래그 설정 이벤트 실행
  void _executeFlagSetEvent(EventData event) {
    final flag = event.data['flag'] as String?;
    final value = event.data['value'] as bool? ?? true;

    if (flag != null && setFlag != null) {
      setFlag!(flag, value);
    }

    onFlagSetEvent?.call(event);
  }

  /// 적 스폰 이벤트 실행
  void _executeSpawnEnemyEvent(EventData event) {
    onSpawnEnemyEvent?.call(event);
  }

  /// 파티 회복 이벤트 실행
  void _executeHealPartyEvent(EventData event) {
    onHealPartyEvent?.call(event);
  }

  /// 커스텀 이벤트 실행
  void _executeCustomEvent(EventData event) {
    onCustomEvent?.call(event);
  }

  /// 트리거 등록
  void registerTrigger(TriggerData trigger) {
    registeredTriggers.add(trigger);
  }

  /// 트리거 체크 (특정 조건에서 호출)
  void checkTriggers(TriggerCondition condition,
      [Map<String, dynamic> context = const {}]) {
    for (final trigger in registeredTriggers) {
      if (trigger.condition != condition) {
        continue;
      }

      // 추가 조건 체크
      if (!_checkTriggerRequirements(trigger, context)) {
        continue;
      }

      // 이미 실행된 일회성 트리거인지 확인
      if (trigger.oneShot && hasFlag != null) {
        if (hasFlag!('trigger_${trigger.id}')) {
          continue;
        }
      }

      // 트리거 활성화
      onTriggerActivated?.call(trigger.id);

      // 일회성 트리거 표시
      if (trigger.oneShot && setFlag != null) {
        setFlag!('trigger_${trigger.id}', true);
      }

      // 이벤트 실행
      for (final event in trigger.events) {
        queueEvent(event);
      }
    }
  }

  /// 트리거 요구사항 체크
  bool _checkTriggerRequirements(
      TriggerData trigger, Map<String, dynamic> context) {
    if (hasFlag == null) {
      return true;
    }

    // 필수 플래그 체크
    for (final flag in trigger.requiredFlags) {
      if (!hasFlag!(flag)) {
        return false;
      }
    }

    // 차단 플래그 체크
    for (final flag in trigger.blockedFlags) {
      if (hasFlag!(flag)) {
        return false;
      }
    }

    return true;
  }

  /// 영역 진입 트리거 체크
  void checkAreaTriggers(String areaName) {
    checkTriggers(TriggerCondition.onEnter, {'area': areaName});
  }

  /// 상호작용 트리거 체크
  void checkInteractTriggers(String objectName) {
    checkTriggers(TriggerCondition.onInteract, {'object': objectName});
  }

  /// 자동 트리거 체크 (맵 로드 시)
  void checkAutoTriggers() {
    checkTriggers(TriggerCondition.auto, {});
  }

  /// 전투 종료 트리거 체크
  void checkBattleEndTriggers(bool victory) {
    checkTriggers(TriggerCondition.onBattleEnd, {'victory': victory});
  }

  /// 플래그 트리거 체크
  void checkFlagTriggers(String flag) {
    checkTriggers(TriggerCondition.onFlag, {'flag': flag});
  }
}
