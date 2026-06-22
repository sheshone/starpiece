extends Node

const MAX_SIMULTANEOUS_SFX: int = 12
var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var _music_player: AudioStreamPlayer
var _current_music_key: String = ""
var _music_positions: Dictionary = {}
var music_enabled: bool = true
var music_volume_percent: float = 0.65
var last_sfx_msec: int = -1000


func _ready() -> void:
	music_enabled = bool(ProgressManager.settings.get("music_enabled", true))
	music_volume_percent = float(ProgressManager.settings.get("music_volume", 0.65))
	for _i in range(MAX_SIMULTANEOUS_SFX):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)
	_create_music_player()
	GameManager.game_started.connect(_on_game_started)
	TurnManager.phase_changed.connect(_on_phase_changed)


func _create_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	_music_player.volume_db = -8.0
	add_child(_music_player)


func play_sfx(key: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := AssetCatalog.audio(key)
	if not stream or _players.is_empty():
		return
	var player := _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	last_sfx_msec = Time.get_ticks_msec()


func play_sfx_first(keys: Array[String], volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	for key in keys:
		if AssetCatalog.audio(key):
			play_sfx(key, volume_db, pitch_scale)
			return


func play_button_fallback() -> void:
	if Time.get_ticks_msec() - last_sfx_msec <= 24:
		return
	play_sfx_first(["button_help", "refresh"], -7.0)


func play_music(key: String, volume_db: float = -8.0) -> void:
	if not music_enabled:
		return
	if key == _current_music_key and _music_player.playing and _music_player.stream == AssetCatalog.audio(key):
		_music_player.volume_db = _scaled_music_db(volume_db)
		return
	var stream := AssetCatalog.audio(key)
	if not stream:
		return
	_store_current_music_position()
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	if is_instance_valid(_music_player):
		_music_player.stop()
		remove_child(_music_player)
		_music_player.queue_free()
	_create_music_player()
	_music_player.stream = stream
	_music_player.volume_db = _scaled_music_db(volume_db)
	_current_music_key = key
	var resume_position := float(_music_positions.get(key, 0.0))
	var stream_length := stream.get_length()
	if stream_length > 0.0:
		resume_position = fmod(resume_position, stream_length)
	_music_player.play(resume_position)


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	ProgressManager.settings.music_enabled = enabled
	if enabled:
		_sync_game_music()
	else:
		stop_music()
	ProgressManager.save_current_run()


func set_music_volume(percent: float) -> void:
	music_volume_percent = clampf(percent, 0.0, 1.0)
	ProgressManager.settings.music_volume = music_volume_percent
	if is_instance_valid(_music_player):
		_music_player.volume_db = _scaled_music_db(-8.0)
	ProgressManager.save_current_run()


func _scaled_music_db(base_db: float) -> float:
	if music_volume_percent <= 0.001:
		return -80.0
	return base_db + linear_to_db(music_volume_percent)


func stop_music() -> void:
	_store_current_music_position()
	_current_music_key = ""
	if is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null


func _store_current_music_position() -> void:
	if (
		_current_music_key.is_empty()
		or not is_instance_valid(_music_player)
		or not _music_player.playing
	):
		return
	_music_positions[_current_music_key] = _music_player.get_playback_position()


func _on_game_started() -> void:
	# 开始按钮的信号与开始界面销毁发生在同一帧，延后一帧可确保菜单音乐不会再次覆盖。
	call_deferred("_sync_game_music")


func _on_phase_changed(phase: TurnManager.Phase) -> void:
	if not GameManager.is_game_running:
		return
	match phase:
		TurnManager.Phase.BUILD:
			play_music("music_build", -9.0)
		TurnManager.Phase.COMBAT:
			play_music("music_combat", -8.0)
		TurnManager.Phase.GAME_OVER:
			stop_music()


func _sync_game_music() -> void:
	if not GameManager.is_game_running:
		return
	_on_phase_changed(TurnManager.current_phase)
