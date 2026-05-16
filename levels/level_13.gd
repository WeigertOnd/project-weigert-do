extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var result_label: Label
var control_label: Label
var windows = []
var drag_window = null
var drag_offset = Vector2.ZERO
var completed = false
var mistake_count = 0


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
	mistake_count = 0
	drag_window = null
	drag_offset = Vector2.ZERO

	setup_ui()
	clear_windows()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	create_stacked_windows()
	update_system_control_label()


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if drag_window != null and is_instance_valid(drag_window):
		drag_window.position = clamp_window_position(to_local(get_global_mouse_position()) - drag_offset)


func _input(event):
	if completed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			drag_window = null


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = 0

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 20)
		result_label.z_index = 80
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 90
		add_child(control_label)

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	if result_label:
		result_label.position = Vector2(90, window_size.y - 74)
		result_label.size = Vector2(window_size.x - 180, 36)


func create_stacked_windows():
	var base_pos = Vector2(28, 24)
	create_overlay_window(base_pos, true, 1)
	create_overlay_window(base_pos, false, 2)
	create_overlay_window(base_pos, false, 3)
	create_overlay_window(base_pos, false, 4)


func create_overlay_window(pos: Vector2, correct: bool, z: int):
	var panel = Panel.new()
	panel.name = "CorrectOverlayWindow" if correct else "FakeOverlayWindow"
	panel.position = pos
	panel.size = get_overlay_window_size()
	panel.z_index = z * 5
	panel.set_meta("correct", correct)
	panel.add_theme_stylebox_override("panel", make_window_style(correct))
	add_child(panel)
	windows.append(panel)

	var title_bar = Panel.new()
	title_bar.name = "TitleBar"
	title_bar.position = Vector2(5, 5)
	title_bar.size = Vector2(panel.size.x - 10, 34)
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.add_theme_stylebox_override("panel", make_title_style())
	title_bar.gui_input.connect(_on_title_bar_input.bind(panel))
	panel.add_child(title_bar)

	var title = Label.new()
	title.name = "Title"
	title.text = "Překrytá okna"
	title.position = Vector2(14, 7)
	title.size = Vector2(panel.size.x - 28, 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1, 1, 1)
	title_bar.add_child(title)

	var instruction = Label.new()
	instruction.name = "Instruction"
	instruction.text = "Odtáhni falešná okna a najdi jediné okno s NESOUHLASÍM."
	instruction.position = Vector2(42, 74)
	instruction.size = Vector2(panel.size.x - 84, 42)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_font_size_override("font_size", 16)
	instruction.modulate = Color(0.14, 0.14, 0.14)
	panel.add_child(instruction)

	var button_size = Vector2(150, 46)
	var gap = 28.0
	var total_width = button_size.x * 2.0 + gap
	var button_y = panel.size.y * 0.52
	var left_x = panel.size.x / 2.0 - total_width / 2.0
	var right_x = left_x + button_size.x + gap

	var left_button = Button.new()
	left_button.position = Vector2(left_x, button_y)
	left_button.size = button_size
	left_button.text = "Nesouhlasím" if correct else "Souhlasím"
	style_button(left_button)
	left_button.pressed.connect(_on_window_button_pressed.bind(panel, correct))
	panel.add_child(left_button)

	var right_button = Button.new()
	right_button.position = Vector2(right_x, button_y)
	right_button.size = button_size
	right_button.text = "Souhlasím"
	style_button(right_button)
	right_button.pressed.connect(_on_window_button_pressed.bind(panel, false))
	panel.add_child(right_button)


func _on_title_bar_input(event, panel: Panel):
	if completed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		bring_window_to_front(panel)
		drag_window = panel
		drag_offset = to_local(get_global_mouse_position()) - panel.position


func bring_window_to_front(panel: Panel):
	var max_z = panel.z_index
	for window in windows:
		if window and is_instance_valid(window):
			max_z = max(max_z, window.z_index)
	panel.z_index = max_z + 5


func _on_window_button_pressed(panel: Panel, is_correct_button: bool):
	if completed:
		return

	bring_window_to_front(panel)

	if is_correct_button and bool(panel.get_meta("correct")):
		complete_level()
	else:
		mistake_count += 1
		GameState.add_system_control(8)
		update_system_control_label()
		background.color = Color(0.95, 0.82, 0.82)
		result_label.modulate = Color(0.58, 0.0, 0.0)
		result_label.text = "Špatné okno. Chyby: " + str(mistake_count)
		result_label.visible = true
		await get_tree().create_timer(0.55).timeout
		if not completed:
			background.color = Color(0.96, 0.96, 0.92)


func complete_level():
	completed = true
	drag_window = null
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Správné okno nalezeno."
	result_label.visible = true
	GameState.reduce_system_control(5)
	update_system_control_label()

	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func clear_windows():
	for window in windows:
		if window and is_instance_valid(window):
			window.queue_free()
	windows.clear()


func get_overlay_window_size() -> Vector2:
	return Vector2(max(420.0, window_size.x - 56.0), max(300.0, window_size.y - 88.0))


func clamp_window_position(pos: Vector2) -> Vector2:
	var overlay_size = get_overlay_window_size()
	var visible_edge = 145.0
	return Vector2(
		clamp(pos.x, -overlay_size.x + visible_edge, window_size.x - visible_edge),
		clamp(pos.y, 14.0, window_size.y - 92.0)
	)


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return

	control_label.position = Vector2(window_size.x - 340, window_size.y - 34)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func make_window_style(correct: bool) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.96, 0.92)
	sb.border_color = Color(0.05, 0.28, 0.72) if correct else Color(0.12, 0.24, 0.42)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 8
	return sb


func make_title_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.38, 0.86)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.65, 0.82, 1.0)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	return sb


func style_button(button: Button):
	var normal = make_button_style(Color(0.94, 0.94, 0.91), Color(0.43, 0.48, 0.58), 5)
	var hover = make_button_style(Color(0.98, 0.99, 1.0), Color(0.22, 0.47, 0.88), 5)
	var pressed = make_button_style(Color(0.76, 0.86, 0.98), Color(0.16, 0.33, 0.70), 5)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.04, 0.04, 0.04))
	button.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	button.add_theme_font_size_override("font_size", 14)


func make_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.shadow_color = Color(1, 1, 1, 0.20)
	sb.shadow_size = 1
	return sb
