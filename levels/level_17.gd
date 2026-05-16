extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var instruction_label: Label
var result_label: Label
var control_label: Label
var reels = []
var reel_labels = []
var stop_buttons = []
var stopped = [false, false, false]
var reel_offsets = [0.0, 31.0, 62.0]
var reel_speeds = [520.0, 640.0, 760.0]
var completed = false

var reel_sequences = [
	["Souhlasím", "Souhlasím", "Souhlasím", "Nesouhlasím", "Souhlasím", "Souhlasím"],
	["Souhlasím", "Nesouhlasím", "Souhlasím", "Souhlasím", "Souhlasím", "Souhlasím"],
	["Souhlasím", "Souhlasím", "Souhlasím", "Souhlasím", "Nesouhlasím", "Souhlasím"]
]


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return
	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	completed = false
	stopped = [false, false, false]
	reel_offsets = [0.0, 31.0, 62.0]
	setup_ui()
	clear_reels()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	create_reels()
	update_system_control_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()
	update_system_control_label_position()
	if completed:
		return

	for i in range(3):
		if not stopped[i]:
			reel_offsets[i] = fposmod(reel_offsets[i] + reel_speeds[i] * delta, 288.0)
			update_reel_labels(i)


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = 0

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 50
		add_child(instruction_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 50
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 60
		add_child(control_label)

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	instruction_label.position = Vector2(50, 42)
	instruction_label.size = Vector2(window_size.x - 100, 34)
	instruction_label.text = "Zastav automat tak, aby NESOUHLASÍM leželo na prostřední čáře."
	result_label.position = Vector2(70, window_size.y - 98)
	result_label.size = Vector2(window_size.x - 140, 34)


func create_reels():
	var start_x = window_size.x / 2.0 - 292.0
	for i in range(3):
		var panel = Panel.new()
		panel.position = Vector2(start_x + i * 210.0, 102)
		panel.size = Vector2(182, 258)
		panel.z_index = 4
		panel.add_theme_stylebox_override("panel", make_panel_style())
		add_child(panel)
		reels.append(panel)

		var labels = []
		for row in range(6):
			var label = Button.new()
			label.focus_mode = Control.FOCUS_NONE
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.size = Vector2(150, 46)
			label.position = Vector2(16, 6 + row * 48)
			label.add_theme_font_size_override("font_size", 14)
			panel.add_child(label)
			labels.append(label)
		reel_labels.append(labels)

		var marker = ColorRect.new()
		marker.position = Vector2(8, 126)
		marker.size = Vector2(panel.size.x - 16, 5)
		marker.color = Color(0.08, 0.22, 0.32, 0.92)
		marker.z_index = 20
		panel.add_child(marker)

		var stop = Button.new()
		stop.text = "Stop"
		stop.position = Vector2(panel.position.x + 4, 398)
		stop.size = Vector2(174, 54)
		stop.z_index = 8
		stop.pressed.connect(_on_stop_pressed.bind(i))
		style_control_button(stop)
		add_child(stop)
		stop_buttons.append(stop)
		update_reel_labels(i)


func update_reel_labels(reel_index: int):
	var labels = reel_labels[reel_index]
	var sequence = reel_sequences[reel_index]
	var offset_steps = int(floor(reel_offsets[reel_index] / 48.0))
	for row in range(labels.size()):
		var text = sequence[(row + offset_steps) % sequence.size()]
		var label = labels[row]
		label.text = text
		label.add_theme_stylebox_override("normal", make_button_style(
			Color(0.65, 0.90, 0.66) if text == "Nesouhlasím" else Color(0.82, 0.50, 0.56),
			Color(0.10, 0.45, 0.22) if text == "Nesouhlasím" else Color(0.55, 0.16, 0.28)
		))


func get_middle_text(reel_index: int) -> String:
	var sequence = reel_sequences[reel_index]
	var offset_steps = int(floor(reel_offsets[reel_index] / 48.0))
	return sequence[(2 + offset_steps) % sequence.size()]


func _on_stop_pressed(index: int):
	if completed or stopped[index]:
		return
	stopped[index] = true
	stop_buttons[index].disabled = true
	if stopped[0] and stopped[1] and stopped[2]:
		check_result()


func check_result():
	for i in range(3):
		if get_middle_text(i) != "Nesouhlasím":
			GameState.add_system_control(9)
			update_system_control_label()
			result_label.modulate = Color(0.58, 0.0, 0.0)
			result_label.text = "Vedle čáry. Automat jede znovu."
			result_label.visible = true
			await get_tree().create_timer(0.75).timeout
			start_level()
			return
	complete_level()


func complete_level():
	completed = true
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Tři nesouhlasy na čáře."
	result_label.visible = true
	GameState.reduce_system_control(5)
	update_system_control_label()
	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func clear_reels():
	for panel in reels:
		if panel and is_instance_valid(panel):
			panel.queue_free()
	for stop in stop_buttons:
		if stop and is_instance_valid(stop):
			stop.queue_free()
	reels.clear()
	reel_labels.clear()
	stop_buttons.clear()


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return
	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_control_button(button: Button):
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.94, 0.94, 0.91), Color(0.20, 0.40, 0.72)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.98, 0.99, 1.0), Color(0.24, 0.48, 0.92)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(0.76, 0.86, 0.98), Color(0.16, 0.33, 0.70)))
	button.add_theme_stylebox_override("disabled", make_button_style(Color(0.64, 0.70, 0.76), Color(0.32, 0.42, 0.52)))
	button.add_theme_color_override("font_color", Color(0.08, 0.18, 0.32))
	button.add_theme_font_size_override("font_size", 16)


func make_panel_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.98, 0.96)
	sb.border_color = Color(0.08, 0.22, 0.32)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb


func make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	return sb
