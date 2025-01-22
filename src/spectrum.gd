extends PanelContainer

const BAR_COUNT: int = 16 # 8 is the lowest
const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60

var spectrum: AudioEffectSpectrumAnalyzerInstance

var max_heights: PackedFloat64Array = []
var min_heights: PackedFloat64Array = []
var heights: PackedFloat64Array = []

var bar_width: float = 0.0



func _ready() -> void:
	_on_interface_is_audio_playing(false)

	for l_arr: PackedFloat64Array in [max_heights, min_heights, heights]:
		@warning_ignore("return_value_discarded")
		l_arr.resize(BAR_COUNT)
		l_arr.fill(0.0)


func _process(_delta: float) -> void:
	var l_previous_hz: float = 0.0

	for i: int in BAR_COUNT:
		# Get the actual height
		var l_hz: float = (i + 1) * FREQ_MAX / BAR_COUNT
		var l_magnitude: float = spectrum.get_magnitude_for_frequency_range(
				l_previous_hz, l_hz).length()
		var l_energy: float = clampf(
				(MIN_DB + linear_to_db(l_magnitude)) / MIN_DB, 0, 1)
		var l_height: float = l_energy * size.y * 10.0

		if l_height > max_heights[i]:
			max_heights[i] = l_height
		else:
			max_heights[i] = lerp(max_heights[i], l_height, 0.1)

		if l_height <= 0.0:
			min_heights[i] = lerp(min_heights[i], l_height, 0.1)

		heights[i] = lerp(min_heights[i], max_heights[i], 0.1) + 4
		l_previous_hz = l_hz

	queue_redraw()


func _draw() -> void:
	for i: int in BAR_COUNT:
		var l_color: Color = Color.from_hsv(
				(BAR_COUNT * 0.6 + i * 0.5) / BAR_COUNT, 0.5, 0.6)
		var l_rect: Rect2 = Rect2(
			i * bar_width,			# Position X
			size.y - heights[i],	# Position Y
			bar_width - 2,	# Width
			heights[i])		# Height

		draw_rect(l_rect, l_color)


func _on_interface_is_audio_playing(a_value:bool) -> void:
	if a_value: # Audio is playing
		spectrum = AudioServer.get_bus_effect_instance(0, 0)
	else:
		spectrum = AudioServer.get_bus_effect_instance(1, 1)


func _on_resized() -> void:
	bar_width = size.x / BAR_COUNT

