extends Node
class_name EquipmentDatabase
## EquipmentDatabase: 장비 데이터베이스
##
## 게임 내 모든 장비(무기, 방어구, 액세서리)의 데이터를 생성하고 관리합니다.

## 장비 ID로 EquipmentData 생성
static func create_equipment(equip_id: String) -> EquipmentData:
	var data := EquipmentData.new()

	match equip_id:
		# ========== 무기 (6개) ==========
		"iron_sword":
			data.id = "iron_sword"
			data.display_name = "철검"
			data.description = "가장 기본적인 철제 검"
			data.slot = EquipmentData.EquipmentSlot.WEAPON
			data.weapon_type = EquipmentData.WeaponType.SWORD
			data.bonus_atk = 10
			data.required_level = 1
			data.buy_price = 200
			data.sell_price = 100

		"steel_sword":
			data.id = "steel_sword"
			data.display_name = "강철검"
			data.description = "단단한 강철로 제작된 검"
			data.slot = EquipmentData.EquipmentSlot.WEAPON
			data.weapon_type = EquipmentData.WeaponType.SWORD
			data.bonus_atk = 18
			data.required_level = 5
			data.buy_price = 500
			data.sell_price = 250

		"silver_sword":
			data.id = "silver_sword"
			data.display_name = "은검"
			data.description = "마력이 깃든 은으로 제작된 검"
			data.slot = EquipmentData.EquipmentSlot.WEAPON
			data.weapon_type = EquipmentData.WeaponType.SWORD
			data.bonus_atk = 28
			data.required_level = 10
			data.buy_price = 1200
			data.sell_price = 600

		"wooden_bow":
			data.id = "wooden_bow"
			data.display_name = "나무 활"
			data.description = "간단한 나무 활"
			data.slot = EquipmentData.EquipmentSlot.WEAPON
			data.weapon_type = EquipmentData.WeaponType.BOW
			data.bonus_atk = 8
			data.attack_range_bonus = 50.0
			data.required_level = 1
			data.buy_price = 180
			data.sell_price = 90

		"longbow":
			data.id = "longbow"
			data.display_name = "장궁"
			data.description = "사거리가 긴 강력한 활"
			data.slot = EquipmentData.EquipmentSlot.WEAPON
			data.weapon_type = EquipmentData.WeaponType.BOW
			data.bonus_atk = 15
			data.attack_range_bonus = 80.0
			data.required_level = 5
			data.buy_price = 600
			data.sell_price = 300

		"magic_staff":
			data.id = "magic_staff"
			data.display_name = "마법 지팡이"
			data.description = "마력을 증폭시키는 지팡이"
			data.slot = EquipmentData.EquipmentSlot.WEAPON
			data.weapon_type = EquipmentData.WeaponType.STAFF
			data.bonus_atk = 5
			data.bonus_mp = 20
			data.required_level = 3
			data.buy_price = 400
			data.sell_price = 200

		# ========== 방어구 (4개) ==========
		"leather_armor":
			data.id = "leather_armor"
			data.display_name = "가죽 갑옷"
			data.description = "가벼운 가죽 갑옷"
			data.slot = EquipmentData.EquipmentSlot.ARMOR
			data.weapon_type = EquipmentData.WeaponType.NONE
			data.bonus_def = 5
			data.required_level = 1
			data.buy_price = 150
			data.sell_price = 75

		"chainmail":
			data.id = "chainmail"
			data.display_name = "사슬 갑옷"
			data.description = "튼튼하지만 무거운 사슬 갑옷"
			data.slot = EquipmentData.EquipmentSlot.ARMOR
			data.weapon_type = EquipmentData.WeaponType.NONE
			data.bonus_def = 12
			data.bonus_spd = -5
			data.required_level = 5
			data.buy_price = 400
			data.sell_price = 200

		"plate_armor":
			data.id = "plate_armor"
			data.display_name = "판금 갑옷"
			data.description = "최고 수준의 방어력을 자랑하는 판금 갑옷"
			data.slot = EquipmentData.EquipmentSlot.ARMOR
			data.weapon_type = EquipmentData.WeaponType.NONE
			data.bonus_def = 25
			data.bonus_spd = -10
			data.required_level = 10
			data.buy_price = 1000
			data.sell_price = 500

		"mage_robe":
			data.id = "mage_robe"
			data.display_name = "마법사 로브"
			data.description = "마력을 증폭시키는 로브"
			data.slot = EquipmentData.EquipmentSlot.ARMOR
			data.weapon_type = EquipmentData.WeaponType.NONE
			data.bonus_def = 3
			data.bonus_mp = 30
			data.required_level = 3
			data.buy_price = 350
			data.sell_price = 175

		# ========== 액세서리 (4개) ==========
		"lucky_charm":
			data.id = "lucky_charm"
			data.display_name = "행운의 부적"
			data.description = "행운을 가져다주는 신비한 부적"
			data.slot = EquipmentData.EquipmentSlot.ACCESSORY
			data.weapon_type = EquipmentData.WeaponType.NONE
			data.bonus_lck = 5
			data.critical_chance_bonus = 0.05
			data.required_level = 1
			data.buy_price = 300
			data.sell_price = 150

		"speed_boots":
			data.id = "speed_boots"
			data.display_name = "신속의 부츠"
			data.description = "착용자의 속도를 향상시키는 부츠"
			data.slot = EquipmentData.EquipmentSlot.ACCESSORY
			data.weapon_type = EquipmentData.WeaponType.NONE
			data.bonus_spd = 10
			data.required_level = 1
			data.buy_price = 400
			data.sell_price = 200

		"guardian_ring":
			data.id = "guardian_ring"
			data.display_name = "수호의 반지"
			data.description = "착용자를 보호하는 마법의 반지"
			data.slot = EquipmentData.EquipmentSlot.ACCESSORY
			data.weapon_type = EquipmentData.WeaponType.NONE
			data.bonus_def = 3
			data.evasion_bonus = 0.05
			data.required_level = 1
			data.buy_price = 350
			data.sell_price = 175

		"mana_crystal":
			data.id = "mana_crystal"
			data.display_name = "마나 크리스탈"
			data.description = "순수한 마력이 응축된 크리스탈"
			data.slot = EquipmentData.EquipmentSlot.ACCESSORY
			data.weapon_type = EquipmentData.WeaponType.NONE
			data.bonus_mp = 50
			data.required_level = 1
			data.buy_price = 500
			data.sell_price = 250

		_:
			push_error("Unknown equipment ID: " + equip_id)
			return null

	return data

## 모든 장비 ID 목록 반환
static func get_all_equipment_ids() -> Array[String]:
	var ids: Array[String] = []

	# 무기
	ids.append_array([
		"iron_sword",
		"steel_sword",
		"silver_sword",
		"wooden_bow",
		"longbow",
		"magic_staff"
	])

	# 방어구
	ids.append_array([
		"leather_armor",
		"chainmail",
		"plate_armor",
		"mage_robe"
	])

	# 액세서리
	ids.append_array([
		"lucky_charm",
		"speed_boots",
		"guardian_ring",
		"mana_crystal"
	])

	return ids

## 특정 슬롯의 장비 ID 목록 반환
static func get_equipment_by_slot(slot: EquipmentData.EquipmentSlot) -> Array[String]:
	var ids: Array[String] = []

	match slot:
		EquipmentData.EquipmentSlot.WEAPON:
			ids.append_array([
				"iron_sword",
				"steel_sword",
				"silver_sword",
				"wooden_bow",
				"longbow",
				"magic_staff"
			])

		EquipmentData.EquipmentSlot.ARMOR:
			ids.append_array([
				"leather_armor",
				"chainmail",
				"plate_armor",
				"mage_robe"
			])

		EquipmentData.EquipmentSlot.ACCESSORY:
			ids.append_array([
				"lucky_charm",
				"speed_boots",
				"guardian_ring",
				"mana_crystal"
			])

	return ids
