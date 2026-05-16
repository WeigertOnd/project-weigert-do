extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var instruction_label: Label
var result_label: Label
var control_label: Label
var no_button: Button
var completed = false
var reveal_time = 0.0
var reveal_duration = 24.0
var hidden_position = Vector2.ZERO


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
	reveal_time = 0.0
	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	place_hidden_button()
	update_button_visibility()
	update_system_control_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if not completed:
		reveal_time = min(reveal_duration, reveal_time + delta)
		update_button_visibility()


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = -100

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 20
		add_child(instruction_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 20
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 25
		add_child(control_label)

	if no_button == null or not is_instance_valid(no_button):
		no_button = Button.new()
		no_button.name = "InvisibleNoButton"
		no_button.text = "Nesouhlasím"
		no_button.size = Vector2(150, 46)
		no_button.z_index = 10
		no_button.focus_mode = Control.FOCUS_NONE
		no_button.pressed.connect(_on_no_pressed)
		add_child(no_button)
		style_button(no_button)

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	instruction_label.position = Vector2(60, 64)
	instruction_label.size = Vector2(window_size.x - 120, 50)
	instruction_label.text = "Nesouhlasím je někde tady. Nejdřív je úplně průhledné."

	result_label.position = Vector2(70, window_size.y - 108)
	result_label.size = Vector2(window_size.x - 140, 34)


func _draw():
	var sky_height = window_size.y * 0.56
	draw_rect(Rect2(Vector2.ZERO, Vector2(window_size.x, sky_height)), Color(0.38, 0.70, 1.0), true)
	draw_rect(Rect2(Vector2(0, sky_height), Vector2(window_size.x, window_size.y - sky_height)), Color(0.38, 0.74, 0.16), true)
	for i in range(8):
		var y = sky_height + i * 18.0
		draw_line(Vector2(0, y), Vector2(window_size.x, y + 40), Color(0.54, 0.86, 0.20, 0.45), 6.0)
	draw_circle(Vector2(window_size.x * 0.18, 84), 44, Color(1, 1, 1, 0.55))
	draw_circle(Vector2(window_size.x * 0.24, 76), 52, Color(1, 1, 1, 0.45))
	draw_circle(Vector2(window_size.x * 0.31, 88), 38, Color(1, 1, 1, 0.40))


func place_hidden_button():
	var margin = 20.0
	var min_x = -80.0
	var max_x = window_size.x - 70.0
	var min_y = 124.0
	var max_y = window_size.y - 140.0
	hidden_position = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))

	if randf() < 0.35:
		hidden_position.x = [-78.0, window_size.x - 68.0].pick_random()
		hidden_position.y = randf_range(min_y, max_y)
	elif randf() < 0.55:
		hidden_position.x = randf_range(margin, window_size.x - 170.0)
		hidden_position.y = [-16.0, window_size.y - 58.0].pick_random()

	no_button.position = hidden_position


func update_button_visibility():
	var alpha = clamp(reveal_time / reveal_duration, 0.0, 1.0)
	no_button.modulate = Color(1, 1, 1, alpha)


func _on_no_pressed():
	if completed:
		return
	complete_level()


func complete_level():
	completed = true
	no_button.modulate = Color(1, 1, 1, 1)
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Našel jsi neviditelné NESOUHLASÍM."
	result_label.visible = true
	GameState.reduce_system_control(5)
	update_system_control_label()
	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return
	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_button(button: Button):
	var normal = make_button_style(Color(0.65, 0.90, 0.66), Color(0.10, 0.45, 0.22))
	var hover = make_button_style(Color(0.72, 0.96, 0.74), Color(0.10, 0.45, 0.22))
	var pressed = make_button_style(Color(0.54, 0.80, 0.56), Color(0.10, 0.45, 0.22))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 14)


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
