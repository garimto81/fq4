extends Control
class_name PauseMenu

## Pause Menu System
## Opens with ESC key, pauses game, provides navigation buttons

@onready var resume_button: Button = $Container/ResumeButton
@onready var inventory_button: Button = $Container/InventoryButton
@onready var options_button: Button = $Container/OptionsButton
@onready var save_button: Button = $Container/SaveButton
@onready var load_button: Button = $Container/LoadButton
@onready var title_button: Button = $Container/TitleButton

signal resume_requested()
signal inventory_requested()
signal save_requested()
signal load_requested()
signal title_requested()

func _ready() -> void:
	# Connect button signals
	resume_button.pressed.connect(_on_resume)
	inventory_button.pressed.connect(_on_inventory)
	options_button.pressed.connect(_on_options)
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	title_button.pressed.connect(_on_title)

	# Initialize hidden
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # Process even when paused

func _input(event: InputEvent) -> void:
	# Toggle pause menu with ESC
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume()
		else:
			open()

func open() -> void:
	"""Open pause menu and pause game."""
	get_tree().paused = true
	show()
	resume_button.grab_focus()
	print("[PauseMenu] Opened")

func close() -> void:
	"""Close pause menu and resume game."""
	hide()
	get_tree().paused = false
	resume_requested.emit()
	print("[PauseMenu] Closed")

func _on_resume() -> void:
	close()

func _on_inventory() -> void:
	inventory_requested.emit()
	print("[PauseMenu] Inventory requested")

func _on_options() -> void:
	# Show GraphicsSettings panel
	var settings_scene = preload("res://scenes/ui/graphics_settings.tscn")
	var settings_instance = settings_scene.instantiate()
	settings_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(settings_instance)
	settings_instance.show()
	print("[PauseMenu] Options opened")

func _on_save() -> void:
	save_requested.emit()
	print("[PauseMenu] Save requested")

func _on_load() -> void:
	load_requested.emit()
	print("[PauseMenu] Load requested")

func _on_title() -> void:
	# Confirm and return to title screen
	get_tree().paused = false
	title_requested.emit()
	print("[PauseMenu] Return to title requested")
