extends PanelContainer

signal is_audio_playing(a_value: bool)

const ALPHA_DISABLED: float = 0.7
const PATH_ICONS: String = "res://assets/icons/%s"

const ICON_RECORDING: Texture2D = preload(PATH_ICONS % "recording.svg")
const ICON_NOT_RECORDING: Texture2D = preload(PATH_ICONS % "not_recording.svg")

const ICON_PAUSE: Texture2D = preload(PATH_ICONS % "pause.svg")
const ICON_PLAY: Texture2D = preload(PATH_ICONS % "play.svg")


@export var button_record: TextureButton
@export var button_play: TextureButton
@export var button_save: Button
@export var panel_spectrum: PanelContainer
@export var audio_playback: AudioStreamPlayer

var effect: AudioEffectRecord
var recording: AudioStreamWAV
var path_last_saved: String = ""

var is_dragging: bool = false
var mouse_offset: Vector2 = Vector2.ZERO



func _ready() -> void:
	effect = AudioServer.get_bus_effect(1, 0)
	panel_spectrum.modulate.a = ALPHA_DISABLED
	button_play.modulate.a = ALPHA_DISABLED
	button_play.disabled = true
	button_save.disabled = true


func _process(_delta: float) -> void:
	if is_dragging:
		get_window().position += Vector2i(get_global_mouse_position() - mouse_offset)


func _on_title_bar_gui_input(a_event: InputEvent) -> void:
	# check if dragging
	# Save the mouse position
	if a_event is InputEventMouseButton:
		if (a_event as InputEventMouseButton).button_index == 1:
			if !is_dragging and a_event.is_pressed():
				is_dragging = true
				mouse_offset = get_global_mouse_position()
			elif !a_event.is_pressed():
				is_dragging = false


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_save_button_pressed() -> void:
	var l_dialog: FileDialog = FileDialog.new()

	l_dialog.title = tr("TITLE_DIALOG_SAVE")
	l_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	l_dialog.access = FileDialog.ACCESS_FILESYSTEM
	l_dialog.use_native_dialog = true
	l_dialog.filters = ["*.wav"]

	if path_last_saved != "":
		l_dialog.current_path = path_last_saved

	@warning_ignore("return_value_discarded")
	l_dialog.file_selected.connect(_on_saved)

	add_child(l_dialog)
	l_dialog.popup_centered()


func _on_saved(a_file_path: String) -> void:
	@warning_ignore("return_value_discarded")
	recording.save_to_wav(a_file_path)
	path_last_saved = a_file_path


func _on_play_button_pressed() -> void:
	if audio_playback.stream_paused or !audio_playback.playing:
		print("Start audio playback")

		button_play.texture_normal = ICON_PAUSE
		audio_playback.stream_paused = false

		if !audio_playback.playing:
			audio_playback.play()

		is_audio_playing.emit(true)
	else:
		print("Pause audio playback")

		button_play.texture_normal = ICON_PLAY
		audio_playback.stream_paused = true
		is_audio_playing.emit(false)


func _on_recording_playback_finished() -> void:
	print("Audio playback finished")
	button_play.texture_normal = ICON_PLAY


func _on_record_button_pressed() -> void:
	if effect.is_recording_active():
		print("Recording stopped")

		# Recording stuff
		recording = effect.get_recording()
		effect.set_recording_active(false)
		button_record.texture_normal = ICON_NOT_RECORDING

		# Audio stuff
		audio_playback.stream = recording

		# Theming
		panel_spectrum.modulate.a = ALPHA_DISABLED
		button_play.modulate.a = 1.0
		button_play.disabled = false
		button_save.disabled = false
	else:
		print("Recording started")

		# Recording stuff
		effect.set_recording_active(true)
		button_record.texture_normal = ICON_RECORDING

		# Audio stuff
		audio_playback.stop()
		is_audio_playing.emit(false)

		# Theming
		panel_spectrum.modulate.a = 1.0
		button_play.modulate.a = ALPHA_DISABLED
		button_play.disabled = true
		button_save.disabled = true

