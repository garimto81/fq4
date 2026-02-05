extends Resource
class_name ShopData
## ShopData: 상점 데이터 리소스
##
## NPC 상점의 인벤토리와 설정을 정의합니다.

@export var shop_id: String = "default_shop"
@export var shop_name: String = "상점"
@export var description: String = ""

# 판매 아이템 목록 (ItemData 리소스 배열)
@export var items_for_sale: Array = []

# 구매/판매 배율
@export var buy_price_multiplier: float = 1.0   # 구매가 배율
@export var sell_price_multiplier: float = 0.5  # 판매가 배율 (기본 50%)

# 상점 유형
enum ShopType {
	GENERAL,     # 일반 상점
	WEAPON,      # 무기점
	ARMOR,       # 방어구점
	MAGIC,       # 마법 상점
	INN          # 여관 (HP/피로도 회복)
}

@export var shop_type: ShopType = ShopType.GENERAL

# 영업 조건 (챕터, 이벤트 등)
@export var available_from_chapter: int = 1
@export var required_event_flag: String = ""
