extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton
@onready var progress_back = $ProgressBack
@onready var progress_fill = $ProgressBack/ProgressFill
@onready var progress_label = $ProgressLabel
@onready var error_label = $ErrorLabel

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO
var progress = 0.0
var completed = false
var error_time = 0.0
var buttons_swapped = false

var fill_per_click = 11.5
var drain_per_second = 18.0
var swap_chance = 0.28


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	progress = 0.0
	completed = false
	error_time = 0.0
	buttons_swapped = false

	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	error_label.visible = false
	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"
	agree_button.disabled = false
	no_button.disabled = false
	update_progress_bar()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if completed:
		return

	if error_time > 0:
		error_time -= delta
		if error_time <= 0:
			error_label.visible = false
			background.color = Color(0.96, 0.96, 0.92)
			agree_button.disabled = false
			no_button.disabled = false
		return

	if progress > 0:
		progress = max(0.0, progress - drain_per_second * delta)
		update_progress_bar()


func setup_ui():
	background.z_index = 0
	progress_back.z_index = 5
	progress_fill.z_index = 6
	progress_label.z_index = 7
	error_label.z_index = 8
	agree_button.z_index = 10
	no_button.z_index = 10

	style_button_soft_xp(agree_button)
	style_button_soft_xp(no_button)
	style_progress_back()

	agree_button.focus_mode = Control.FOCUS_NONE
	no_button.focus_mode = Control.FOCUS_NONE

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)
	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	progress_back.position = Vector2(window_size.x / 2 - 250, 166)
	progress_back.size = Vector2(500, 34)

	progress_fill.position = Vector2(3, 3)
	progress_fill.size = Vector2(0, progress_back.size.y - 6)

	progress_label.position = Vector2(window_size.x / 2 - 160, 216)
	progress_label.size = Vector2(320, 28)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 15)
	progress_label.modulate = Color(0.12, 0.12, 0.12)

	error_label.position = Vector2(window_size.x / 2 - 170, 262)
	error_label.size = Vector2(340, 42)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 22)
	error_label.modulate = Color(0.65, 0.0, 0.0)

	var button_size = Vector2(160, 42)
	var spacing = 34
	var total_width = button_size.x * 2 + spacing
	var left_pos = Vector2(window_size.x / 2 - total_width / 2, 340)
	var right_pos = Vector2(left_pos.x + button_size.x + spacing, 340)

	agree_button.size = button_size
	no_button.size = button_size

	if buttons_swapped:
		agree_button.position = right_pos
		no_button.position = left_pos
	else:
		agree_button.position = left_pos
		no_button.position = right_pos

	update_progress_bar()


func _on_no_pressed():
	if completed or error_time > 0:
		return

	progress = min(100.0, progress + fill_per_click)
	GameState.reduce_system_control(1)
	update_progress_bar()

	if progress >= 100.0:
		complete_level()
		return

	if randf() < swap_chance:
		swap_buttons()


func _on_agree_pressed():
	if completed or error_time > 0:
		return

	GameState.add_system_control(12)
	progress = 0.0
	update_progress_bar()
	show_error()


func complete_level():
	completed = true
	progress = 100.0
	update_progress_bar()
	background.color = Color(0.84, 0.94, 0.84)
	agree_button.disabled = true
	no_button.disabled = true

	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func show_error():
	error_time = 1.05
	background.color = Color(0.95, 0.82, 0.82)
	error_label.text = "CHYBA"
	error_label.visible = true
	agree_button.disabled = true
	no_button.disabled = true


func swap_buttons():
	buttons_swapped = not buttons_swapped
	layout_ui()


func update_progress_bar():
	if progress_fill == null or not is_instance_valid(progress_fill):
		return

	var ratio = clamp(progress / 100.0, 0.0, 1.0)
	progress_fill.size = Vector2(max(0.0, progress_back.size.x - 6) * ratio, max(0.0, progress_back.size.y - 6))
	progress_fill.color = Color(0.12, 0.52, 0.86) if ratio < 0.82 else Color(0.12, 0.64, 0.28)

	if progress_label:
		progress_label.text = "Dokončení: " + str(int(progress)) + " %"


func style_progress_back():
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.86, 0.86, 0.84)
	panel_style.border_color = Color(0.38, 0.43, 0.52)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	progress_back.add_theme_stylebox_override("panel", panel_style)


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
