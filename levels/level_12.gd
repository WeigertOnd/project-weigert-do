extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var target_panel = $TargetPanel
@onready var preview_panel = $PreviewPanel
@onready var r_slider = $RSlider
@onready var g_slider = $GSlider
@onready var b_slider = $BSlider
@onready var r_label = $RLabel
@onready var g_label = $GLabel
@onready var b_label = $BLabel
@onready var result_label = $ResultLabel
@onready var check_button = $CheckButton
@onready var no_button = $NoButton

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO
var target_r = 0
var target_g = 0
var target_b = 0
var unlocked = false

var required_similarity = 84.0


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	unlocked = false
	target_r = randi_range(0, 255)
	target_g = randi_range(0, 255)
	target_b = randi_range(0, 255)

	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	target_panel.color = rgb_color(target_r, target_g, target_b)
	r_slider.value = 128
	g_slider.value = 128
	b_slider.value = 128
	no_button.disabled = true
	check_button.disabled = false
	result_label.modulate = Color(0.18, 0.18, 0.18)
	result_label.text = "Tref barvu alespoň na " + str(int(required_similarity)) + " %."
	update_preview()


func setup_ui():
	background.z_index = 0
	target_panel.z_index = 3
	preview_panel.z_index = 3
	r_slider.z_index = 4
	g_slider.z_index = 4
	b_slider.z_index = 4
	r_label.z_index = 4
	g_label.z_index = 4
	b_label.z_index = 4
	result_label.z_index = 4
	check_button.z_index = 4
	no_button.z_index = 4

	style_button_soft_xp(check_button)
	style_button_soft_xp(no_button)

	if not r_slider.value_changed.is_connected(_on_slider_changed):
		r_slider.value_changed.connect(_on_slider_changed)
	if not g_slider.value_changed.is_connected(_on_slider_changed):
		g_slider.value_changed.connect(_on_slider_changed)
	if not b_slider.value_changed.is_connected(_on_slider_changed):
		b_slider.value_changed.connect(_on_slider_changed)
	if not check_button.pressed.is_connected(_on_check_pressed):
		check_button.pressed.connect(_on_check_pressed)
	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	target_panel.position = Vector2(window_size.x / 2 - 210, 72)
	target_panel.size = Vector2(170, 118)
	preview_panel.position = Vector2(window_size.x / 2 + 40, 72)
	preview_panel.size = Vector2(170, 118)

	var label_x = window_size.x / 2 - 205
	var slider_x = window_size.x / 2 - 140
	var slider_width = 280
	layout_slider_row(r_label, r_slider, "R", label_x, slider_x, 232, slider_width)
	layout_slider_row(g_label, g_slider, "G", label_x, slider_x, 282, slider_width)
	layout_slider_row(b_label, b_slider, "B", label_x, slider_x, 332, slider_width)

	result_label.position = Vector2(window_size.x / 2 - 250, 382)
	result_label.size = Vector2(500, 32)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 16)

	check_button.size = Vector2(160, 42)
	no_button.size = Vector2(160, 42)
	check_button.position = Vector2(window_size.x / 2 - 177, 438)
	no_button.position = Vector2(window_size.x / 2 + 17, 438)


func layout_slider_row(label: Label, slider: HSlider, prefix: String, label_x: float, slider_x: float, y: float, slider_width: float):
	label.position = Vector2(label_x, y - 2)
	label.size = Vector2(48, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = Color(0.12, 0.12, 0.12)
	label.text = prefix + ":"

	slider.position = Vector2(slider_x, y)
	slider.size = Vector2(slider_width, 24)
	slider.min_value = 0
	slider.max_value = 255
	slider.step = 1


func _on_slider_changed(_value):
	update_preview()


func update_preview():
	var r = int(r_slider.value)
	var g = int(g_slider.value)
	var b = int(b_slider.value)
	preview_panel.color = rgb_color(r, g, b)
	r_label.text = "R:"
	g_label.text = "G:"
	b_label.text = "B:"


func _on_check_pressed():
	if unlocked:
		return

	var similarity = get_similarity()
	if similarity >= required_similarity:
		unlocked = true
		no_button.disabled = false
		check_button.disabled = true
		result_label.modulate = Color(0.0, 0.50, 0.0)
		result_label.text = "Dost blízko: " + str(int(similarity)) + " %. NESOUHLASÍM odemčeno."
		GameState.reduce_system_control(4)
	else:
		result_label.modulate = Color(0.62, 0.0, 0.0)
		result_label.text = "Mimo toleranci: " + str(int(similarity)) + " %. Zkus to blíž."
		GameState.add_system_control(5)


func _on_no_pressed():
	if not unlocked:
		return

	no_button.disabled = true
	await get_tree().create_timer(0.45).timeout
	level_finished.emit()


func get_similarity() -> float:
	var dr = float(int(r_slider.value) - target_r)
	var dg = float(int(g_slider.value) - target_g)
	var db = float(int(b_slider.value) - target_b)
	var distance = sqrt(dr * dr + dg * dg + db * db)
	var max_distance = sqrt(3.0 * 255.0 * 255.0)
	return clamp(100.0 - distance / max_distance * 100.0, 0.0, 100.0)


func rgb_color(r: int, g: int, b: int) -> Color:
	return Color(float(r) / 255.0, float(g) / 255.0, float(b) / 255.0)


func style_button_soft_xp(button):
	var normal = make_button_style(Color(0.94, 0.94, 0.91), Color(0.43, 0.48, 0.58), 5)
	var hover = make_button_style(Color(0.98, 0.99, 1.0), Color(0.22, 0.47, 0.88), 5)
	var pressed = make_button_style(Color(0.76, 0.86, 0.98), Color(0.16, 0.33, 0.70), 5)
	var disabled = make_button_style(Color(0.84, 0.84, 0.82), Color(0.64, 0.64, 0.64), 5)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.04, 0.04, 0.04))
	button.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.43, 0.43))
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
