extends Node

## AudioManager: Audio management singleton
## Handles BGM and SFX playback with volume control

# Audio players
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 8

# Volume settings
var master_volume: float = 1.0
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0
var current_bgm: String = ""

# Signals
signal bgm_changed(track_name: String)
signal sfx_played(sfx_name: String)
signal volume_changed(bus_name: String, value: float)

func _ready() -> void:
	# Create BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"  # Use Master bus until BGM bus created
	add_child(bgm_player)

	# Create SFX player pool
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

	print("[AudioManager] Initialized with %d SFX channels" % MAX_SFX_PLAYERS)

## Play background music
func play_bgm(track_name: String, fade_duration: float = 1.0) -> void:
	if current_bgm == track_name and bgm_player.playing:
		return

	current_bgm = track_name

	# Try to load the track
	var track_path = "res://assets/audio/bgm/%s.ogg" % track_name
	if ResourceLoader.exists(track_path):
		var stream = load(track_path)
		bgm_player.stream = stream
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
		bgm_player.play()
		print("[AudioManager] Playing BGM: ", track_name)
	else:
		print("[AudioManager] BGM not found: ", track_path, " (placeholder)")

	bgm_changed.emit(track_name)

## Stop BGM
func stop_bgm(fade_duration: float = 1.0) -> void:
	if bgm_player.playing:
		bgm_player.stop()
	current_bgm = ""
	print("[AudioManager] BGM stopped")

## Play sound effect
func play_sfx(sfx_name: String) -> void:
	# Find available player
	var player = _get_available_sfx_player()
	if player == null:
		print("[AudioManager] No available SFX channel")
		return

	# Try to load the SFX
	var sfx_path = "res://assets/audio/sfx/%s.ogg" % sfx_name
	if ResourceLoader.exists(sfx_path):
		var stream = load(sfx_path)
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		player.play()
		print("[AudioManager] Playing SFX: ", sfx_name)
	else:
		print("[AudioManager] SFX not found: ", sfx_path, " (placeholder)")

	sfx_played.emit(sfx_name)

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]  # Reuse first if all busy

## Volume controls
func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_update_volumes()
	volume_changed.emit("Master", master_volume)

func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	_update_volumes()
	volume_changed.emit("BGM", bgm_volume)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	volume_changed.emit("SFX", sfx_volume)

func _update_volumes() -> void:
	if bgm_player:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

func get_current_bgm() -> String:
	return current_bgm

func is_bgm_playing() -> bool:
	return bgm_player != null and bgm_player.playing
