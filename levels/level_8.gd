extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO
var completed = false
var flash_time = 0.0


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
	flash_time = 0.0

	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"
	agree_button.disabled = false
	no_button.disabled = false
	agree_button.visible = true
	no_button.visible = true


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if flash_time > 0:
		flash_time -= delta
		if flash_time <= 0:
			background.color = Color(0.96, 0.96, 0.92)


func setup_ui():
	background.z_index = 0
	agree_button.z_index = 5
	no_button.z_index = 5

	style_button_soft_xp(agree_button)
	style_button_soft_xp(no_button)

	agree_button.focus_mode = Control.FOCUS_NONE
	no_button.focus_mode = Control.FOCUS_NONE

	if not agree_button.mouse_entered.is_connected(_on_agree_mouse_entered):
		agree_button.mouse_entered.connect(_on_agree_mouse_entered)
	if not agree_button.mouse_exited.is_connected(_on_agree_mouse_exited):
		agree_button.mouse_exited.connect(_on_agree_mouse_exited)
	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.mouse_entered.is_connected(_on_no_mouse_entered):
		no_button.mouse_entered.connect(_on_no_mouse_entered)
	if not no_button.mouse_exited.is_connected(_on_no_mouse_exited):
		no_button.mouse_exited.connect(_on_no_mouse_exited)
	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	var button_size = Vector2(160, 42)
	var spacing = 34
	var total_width = button_size.x * 2 + spacing
	var start_x = window_size.x / 2 - total_width / 2

	agree_button.size = button_size
	no_button.size = button_size
	agree_button.position = Vector2(start_x, window_size.y / 2 - button_size.y / 2)
	no_button.position = Vector2(start_x + button_size.x + spacing, window_size.y / 2 - button_size.y / 2)


func _on_agree_mouse_entered():
	agree_button.text = "Nesouhlasím"


func _on_agree_mouse_exited():
	if not completed:
		agree_button.text = "Souhlasím"


func _on_no_mouse_entered():
	no_button.text = "Souhlasím"


func _on_no_mouse_exited():
	if not completed:
		no_button.text = "Nesouhlasím"


func _on_agree_pressed():
	if completed:
		return

	completed = true
	agree_button.disabled = true
	no_button.disabled = true
	agree_button.text = "Nesouhlasím"
	no_button.text = "Souhlasím"
	background.color = Color(0.84, 0.94, 0.84)
	GameState.reduce_system_control(5)

	await get_tree().create_timer(1.2).timeout
	level_finished.emit()


func _on_no_pressed():
	if completed:
		return

	GameState.add_system_control(8)
	start_flash()


func start_flash():
	background.color = Color(0.95, 0.82, 0.82)
	flash_time = 0.11


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
