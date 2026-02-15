// Phase 2: 인벤토리 시스템

import '../data/item_data.dart';

class InventorySystem {
  final Map<String, ({ItemData data, int quantity})> items = {};
  final int maxSlots;
  int gold;

  // 콜백
  void Function(String itemId, int quantity)? onItemAdded;
  void Function(String itemId, int quantity)? onItemRemoved;
  void Function(String itemId)? onItemUsed;
  void Function(int newGold)? onGoldChanged;

  InventorySystem({
    this.maxSlots = 50,
    this.gold = 0,
  });

  ({bool success, String reason, int added}) addItem(ItemData item, int quantity) {
    if (quantity <= 0) {
      return (success: false, reason: '수량은 1 이상이어야 합니다', added: 0);
    }

    final existingItem = items[item.id];

    if (existingItem != null) {
      // 기존 아이템이 있는 경우 스택 추가
      final currentQuantity = existingItem.quantity;
      final availableSpace = item.maxStack - currentQuantity;

      if (availableSpace <= 0) {
        // 이미 최대 스택
        if (getFreeSlots() <= 0) {
          return (success: false, reason: '인벤토리가 가득 찼습니다', added: 0);
        }
        // 새 슬롯 사용
        final addedToNewSlot = quantity > item.maxStack ? item.maxStack : quantity;
        items[item.id] = (data: item, quantity: addedToNewSlot);
        onItemAdded?.call(item.id, addedToNewSlot);
        return (success: true, reason: '', added: addedToNewSlot);
      }

      // 스택에 추가 가능
      final canAdd = availableSpace >= quantity ? quantity : availableSpace;
      items[item.id] = (data: item, quantity: currentQuantity + canAdd);
      onItemAdded?.call(item.id, canAdd);
      return (success: true, reason: '', added: canAdd);
    } else {
      // 새 아이템
      if (getFreeSlots() <= 0) {
        return (success: false, reason: '인벤토리가 가득 찼습니다', added: 0);
      }

      final addedQuantity = quantity > item.maxStack ? item.maxStack : quantity;
      items[item.id] = (data: item, quantity: addedQuantity);
      onItemAdded?.call(item.id, addedQuantity);
      return (success: true, reason: '', added: addedQuantity);
    }
  }

  ({bool success, int remaining}) removeItem(String itemId, int quantity) {
    final item = items[itemId];
    if (item == null) {
      return (success: false, remaining: 0);
    }

    if (item.quantity < quantity) {
      return (success: false, remaining: item.quantity);
    }

    final newQuantity = item.quantity - quantity;
    if (newQuantity <= 0) {
      items.remove(itemId);
      onItemRemoved?.call(itemId, quantity);
      return (success: true, remaining: 0);
    }

    items[itemId] = (data: item.data, quantity: newQuantity);
    onItemRemoved?.call(itemId, quantity);
    return (success: true, remaining: newQuantity);
  }

  ({bool success, String reason}) useItem(String itemId) {
    final item = items[itemId];
    if (item == null) {
      return (success: false, reason: '아이템을 찾을 수 없습니다');
    }

    if (!item.data.canUse()) {
      return (success: false, reason: '사용할 수 없는 아이템입니다');
    }

    // 아이템 소모
    final removeResult = removeItem(itemId, 1);
    if (!removeResult.success) {
      return (success: false, reason: '아이템 제거 실패');
    }

    onItemUsed?.call(itemId);
    return (success: true, reason: '');
  }

  bool hasItem(String itemId, int quantity) {
    final item = items[itemId];
    return item != null && item.quantity >= quantity;
  }

  int getItemCount(String itemId) {
    final item = items[itemId];
    return item?.quantity ?? 0;
  }

  List<({String id, ItemData data, int quantity})> getAllItems() {
    return items.entries
        .map((e) => (id: e.key, data: e.value.data, quantity: e.value.quantity))
        .toList();
  }

  int getFreeSlots() {
    return maxSlots - items.length;
  }

  bool isFull() {
    return getFreeSlots() <= 0;
  }

  void addGold(int amount) {
    if (amount <= 0) return;
    gold += amount;
    onGoldChanged?.call(gold);
  }

  bool spendGold(int amount) {
    if (!canAfford(amount)) {
      return false;
    }
    gold -= amount;
    onGoldChanged?.call(gold);
    return true;
  }

  bool canAfford(int amount) {
    return gold >= amount;
  }
}
