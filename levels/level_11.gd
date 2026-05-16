extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var start_button = $StartButton
@onready var no_button = $NoButton
@onready var instruction_label = $InstructionLabel
@onready var timer_label = $TimerLabel
@onready var result_label = $ResultLabel

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO
var running = false
var completed = false
var elapsed = 0.0
var reset_time = 0.0

var target_time = 15.0
var tolerance = 0.5


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	running = false
	completed = false
	elapsed = 0.0
	reset_time = 0.0

	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	timer_label.visible = false
	result_label.visible = false
	instruction_label.visible = true
	instruction_label.text = "Stiskni Start. Až odhadneš, že uběhlo 15 sekund, klikni na Nesouhlasím. Tolerance je půl sekundy."
	start_button.disabled = false
	no_button.disabled = true
	no_button.text = "Nesouhlasím"
	start_button.text = "Start"


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if completed:
		return

	if reset_time > 0:
		reset_time -= delta
		if reset_time <= 0:
			start_level()
		return

	if running:
		elapsed += delta
		update_timer_label()


func setup_ui():
	background.z_index = 0
	timer_label.z_index = 5
	instruction_label.z_index = 5
	result_label.z_index = 6
	start_button.z_index = 5
	no_button.z_index = 5

	style_button_soft_xp(start_button)
	style_button_soft_xp(no_button)

	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	timer_label.position = Vector2(window_size.x / 2 - 120, 126)
	timer_label.size = Vector2(240, 54)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 34)
	timer_label.modulate = Color(0.10, 0.10, 0.10)

	instruction_label.position = Vector2(window_size.x / 2 - 290, 70)
	instruction_label.size = Vector2(580, 48)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.add_theme_font_size_override("font_size", 17)
	instruction_label.modulate = Color(0.12, 0.12, 0.12)

	result_label.position = Vector2(window_size.x / 2 - 230, 218)
	result_label.size = Vector2(460, 64)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 21)
	result_label.modulate = Color(0.56, 0.0, 0.0)

	var button_size = Vector2(160, 42)
	var spacing = 34
	var total_width = button_size.x * 2 + spacing
	var start_x = window_size.x / 2 - total_width / 2

	no_button.size = button_size
	start_button.size = button_size
	no_button.position = Vector2(start_x, 340)
	start_button.position = Vector2(start_x + button_size.x + spacing, 340)


func _on_start_pressed():
	if completed or running:
		return

	elapsed = 0.0
	running = true
	start_button.disabled = true
	no_button.disabled = false
	result_label.visible = false
	timer_label.visible = true
	timer_label.modulate.a = 1.0
	update_timer_label()


func _on_no_pressed():
	if completed or not running:
		return

	var difference = abs(elapsed - target_time)
	if difference <= tolerance:
		complete_level()
	else:
		show_error()


func update_timer_label():
	timer_label.text = "%.2f s" % elapsed

	if elapsed <= 5.0:
		timer_label.modulate.a = 1.0
	else:
		timer_label.modulate.a = max(0.0, 1.0 - (elapsed - 5.0) / 1.4)

	if elapsed > target_time + 2.5:
		show_error()


func show_error():
	running = false
	reset_time = 1.35
	background.color = Color(0.95, 0.82, 0.82)
	result_label.text = "CHYBA"
	result_label.visible = true
	start_button.disabled = true
	no_button.disabled = true
	GameState.add_system_control(10)


func complete_level():
	completed = true
	running = false
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Přijato"
	result_label.visible = true
	start_button.disabled = true
	no_button.disabled = true
	GameState.reduce_system_control(4)

	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


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
