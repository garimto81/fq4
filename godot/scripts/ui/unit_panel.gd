extends Control
class_name UnitPanel

@onready var portrait: TextureRect = $Portrait
@onready var name_label: Label = $InfoContainer/NameLabel
@onready var hp_bar: ProgressBar = $InfoContainer/HPBar
@onready var hp_label: Label = $InfoContainer/HPBar/HPLabel
@onready var mp_bar: ProgressBar = $InfoContainer/MPBar
@onready var mp_label: Label = $InfoContainer/MPBar/MPLabel
@onready var fatigue_bar: ProgressBar = $InfoContainer/FatigueBar
@onready var fatigue_label: Label = $InfoContainer/FatigueBar/FTLabel
@onready var state_label: Label = $StateLabel
@onready var squad_grid: GridContainer = $SquadGrid

signal unit_clicked(unit: Node)

var current_unit: Node = null
var squad_member_icons: Array[TextureButton] = []

func _ready() -> void:
	# Connect to GameManager signals if available
	if GameManager:
		GameManager.controlled_unit_changed.connect(_on_active_unit_changed)

	# Initialize squad grid slots
	_initialize_squad_grid()

func _initialize_squad_grid() -> void:
	# Create 18 slots for squad members (3 rows x 6 columns)
	for i in range(18):
		var icon_button = TextureButton.new()
		icon_button.custom_minimum_size = Vector2(32, 32)
		icon_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		icon_button.modulate = Color(1, 1, 1, 0.3)  # Dim empty slots
		icon_button.pressed.connect(_on_squad_icon_pressed.bind(i))
		squad_grid.add_child(icon_button)
		squad_member_icons.append(icon_button)

func set_unit(unit: Node) -> void:
	current_unit = unit
	_update_display()

func _update_display() -> void:
	if current_unit == null:
		visible = false
		return

	visible = true

	# Update name
	name_label.text = current_unit.unit_name if current_unit.unit_name else current_unit.name

	# Update HP bar
	hp_bar.max_value = current_unit.max_hp
	hp_bar.value = current_unit.current_hp
	hp_label.text = "%d/%d" % [current_unit.current_hp, current_unit.max_hp]

	# MP bar
	mp_bar.max_value = current_unit.max_mp
	mp_bar.value = current_unit.current_mp
	mp_label.text = "%d/%d" % [current_unit.current_mp, current_unit.max_mp]

	# Update fatigue
	var fatigue_percent = int(float(current_unit.current_fatigue) / current_unit.max_fatigue * 100)
	fatigue_bar.max_value = 100.0
	fatigue_bar.value = fatigue_percent
	fatigue_label.text = "%d%%" % fatigue_percent

	# Color code fatigue bar
	if fatigue_percent < 30:
		fatigue_bar.modulate = Color.GREEN
	elif fatigue_percent < 60:
		fatigue_bar.modulate = Color.YELLOW
	elif fatigue_percent < 80:
		fatigue_bar.modulate = Color.ORANGE
	else:
		fatigue_bar.modulate = Color.RED

	# Update AI state for AI units
	if "ai_state" in current_unit:
		var state_text = ""
		var ai_state = current_unit.ai_state
		# Use numeric comparison instead of enum
		if ai_state == 1:  # FOLLOW
			state_text = "FOLLOW"
			state_label.modulate = Color.CYAN
		elif ai_state == 3:  # CHASE
			state_text = "CHASE"
			state_label.modulate = Color.YELLOW
		elif ai_state == 4:  # ATTACK
			state_text = "ATTACK"
			state_label.modulate = Color.RED
		elif ai_state == 5:  # RETREAT
			state_text = "RETREAT"
			state_label.modulate = Color.ORANGE
		elif ai_state == 8:  # REST
			state_text = "REST"
			state_label.modulate = Color.GREEN
		else:
			state_text = "IDLE"
			state_label.modulate = Color.WHITE
		state_label.text = "State: " + state_text
		state_label.visible = true
	else:
		state_label.visible = false

	# Update portrait
	_update_portrait()

func _update_portrait() -> void:
	if current_unit == null:
		portrait.texture = null
		return

	# Try to load portrait by unit name or portrait_id
	var portrait_id = ""
	if "portrait_id" in current_unit and current_unit.portrait_id != null:
		portrait_id = current_unit.portrait_id
	if portrait_id.is_empty():
		portrait_id = current_unit.unit_name.to_lower().replace(" ", "_")

	var portrait_path = "res://assets/portraits/%s.png" % portrait_id
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	else:
		# Use default portrait
		var default_path = "res://assets/portraits/default.png"
		if ResourceLoader.exists(default_path):
			portrait.texture = load(default_path)
		else:
			portrait.texture = null

func set_squad_members(units: Array) -> void:
	# Clear all icons first
	for i in range(squad_member_icons.size()):
		var icon = squad_member_icons[i]
		icon.texture_normal = null
		icon.modulate = Color(1, 1, 1, 0.3)
		icon.disabled = true

	# Update with actual squad members
	for i in range(min(units.size(), squad_member_icons.size())):
		var unit = units[i]
		var icon = squad_member_icons[i]

		# Load unit portrait texture
		var unit_portrait_id = ""
		if "portrait_id" in unit and unit.portrait_id != null:
			unit_portrait_id = unit.portrait_id
		if unit_portrait_id.is_empty():
			unit_portrait_id = unit.unit_name.to_lower().replace(" ", "_")
		var unit_portrait_path = "res://assets/portraits/%s.png" % unit_portrait_id
		if ResourceLoader.exists(unit_portrait_path):
			icon.texture_normal = load(unit_portrait_path)

		# Highlight if this is the current unit
		if unit == current_unit:
			icon.modulate = Color(1, 1, 0, 1)  # Yellow highlight
		else:
			icon.modulate = Color(1, 1, 1, 1)  # Full opacity

		icon.disabled = false

func _on_active_unit_changed(unit: Node) -> void:
	set_unit(unit)

	# Update squad members if GameManager has squad info
	if GameManager and GameManager.has_method("get_current_squad"):
		var squad = GameManager.get_current_squad()
		set_squad_members(squad)

func _on_squad_icon_pressed(index: int) -> void:
	# Emit signal to switch to this squad member
	if GameManager and GameManager.has_method("get_current_squad"):
		var squad = GameManager.get_current_squad()
		if index < squad.size():
			unit_clicked.emit(squad[index])

func _process(_delta: float) -> void:
	# Update display each frame for smooth bar animations
	if current_unit != null:
		_update_display()
