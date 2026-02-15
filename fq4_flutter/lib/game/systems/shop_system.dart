// Shop system for buying and selling items
// Port from Godot GDScript shop_system.gd

class ShopData {
  final String shopId;
  final String shopName;
  final List<String> itemsForSale;
  final double buyPriceMultiplier;
  final double sellPriceMultiplier;

  ShopData({
    required this.shopId,
    required this.shopName,
    required this.itemsForSale,
    this.buyPriceMultiplier = 1.0,
    this.sellPriceMultiplier = 0.5,
  });
}

class ShopSystem {
  ShopData? currentShop;
  final Map<String, int> _stock = {};

  // Callbacks
  Function(String itemId, int price)? onItemPurchased;
  Function(String itemId, int price)? onItemSold;
  Function(String itemId, String reason)? onPurchaseFailed;
  Function(ShopData)? onShopOpened;
  Function()? onShopClosed;

  // Gold check callbacks (from InventorySystem)
  bool Function(int amount)? canAfford;
  bool Function(int amount)? spendGold;
  void Function(int amount)? addGold;

  void openShop(ShopData shop) {
    currentShop = shop;
    _initStock(shop);
    onShopOpened?.call(shop);
  }

  void closeShop() {
    currentShop = null;
    _stock.clear();
    onShopClosed?.call();
  }

  ({bool success, String? reason}) buyItem(String itemId, int buyPrice) {
    if (currentShop == null) {
      return (success: false, reason: 'No shop opened');
    }
    if (!hasStock(itemId)) {
      return (success: false, reason: 'Out of stock');
    }
    if (canAfford == null || !canAfford!(buyPrice)) {
      onPurchaseFailed?.call(itemId, 'Not enough gold');
      return (success: false, reason: 'Not enough gold');
    }
    spendGold?.call(buyPrice);
    _decreaseStock(itemId);
    onItemPurchased?.call(itemId, buyPrice);
    return (success: true, reason: null);
  }

  ({bool success, String? reason}) sellItem(String itemId, int sellPrice) {
    if (currentShop == null) {
      return (success: false, reason: 'No shop opened');
    }
    addGold?.call(sellPrice);
    onItemSold?.call(itemId, sellPrice);
    return (success: true, reason: null);
  }

  int getBuyPrice(int basePrice) => currentShop != null
      ? (basePrice * currentShop!.buyPriceMultiplier).round()
      : basePrice;

  int getSellPrice(int basePrice) => currentShop != null
      ? (basePrice * currentShop!.sellPriceMultiplier).round()
      : (basePrice * 0.5).round();

  bool hasStock(String itemId) {
    final s = _stock[itemId];
    return s != null && (s == -1 || s > 0);
  }

  int getStock(String itemId) => _stock[itemId] ?? 0;

  void setStockLimit(String itemId, int quantity) {
    _stock[itemId] = quantity;
  }

  void _initStock(ShopData shop) {
    _stock.clear();
    for (final id in shop.itemsForSale) {
      _stock[id] = -1;
    }
  }

  void _decreaseStock(String itemId) {
    final s = _stock[itemId];
    if (s != null && s > 0) {
      _stock[itemId] = s - 1;
    }
  }
}
