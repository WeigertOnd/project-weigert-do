extends Node2D

const ArticleData = preload("res://data/ArticleData.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var article_label: Label
var article_agree_button: Button
var article_no_button: Button

var instruction_label: Label
var attempts_label: Label
var result_label: Label
var control_label: Label

var reels = []
var reel_labels = []
var stop_buttons = []

var stopped = [false, false, false]
var reel_offsets = [0.0, 31.0, 62.0]

# 1. sloupec pomalu, 2. rychleji, 3. nejrychleji
var reel_speeds = [300.0, 520.0, 760.0]

var completed = false
var failed = false

var attempts = 0
var max_attempts = 5
var needed_agree_in_middle = 3
var fail_freeze_time = 0.9

# V každém sloupci je jen jedno Souhlasím
var reel_sequences = [
	["Nesouhlasím", "Nesouhlasím", "Souhlasím", "Nesouhlasím", "Nesouhlasím", "Nesouhlasím"],
	["Nesouhlasím", "Nesouhlasím", "Nesouhlasím", "Souhlasím", "Nesouhlasím", "Nesouhlasím"],
	["Nesouhlasím", "Souhlasím", "Nesouhlasím", "Nesouhlasím", "Nesouhlasím", "Nesouhlasím"]
]


func _ready():
	randomize()
	start_level()


func set_article_number(new_article_number: int):
	article_number = new_article_number

	if is_inside_tree():
		start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	screen_state = "article"
	completed = false
	failed = false
	attempts = 0

	stopped = [false, false, false]
	reel_offsets = [0.0, 31.0, 62.0]

	setup_ui()
	clear_reels()

	background.color = Color(0.96, 0.96, 0.92)

	show_article_screen()
	update_system_control_label()
	layout_ui()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if screen_state != "game":
		return

	if completed or failed:
		return

	for i in range(3):
		if not stopped[i]:
			reel_offsets[i] = fposmod(reel_offsets[i] + reel_speeds[i] * delta, 288.0)
			update_reel_labels(i)


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = -10

	if article_label == null or not is_instance_valid(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 5
		add_child(article_label)

	if article_agree_button == null or not is_instance_valid(article_agree_button):
		article_agree_button = Button.new()
		article_agree_button.name = "ArticleAgreeButton"
		article_agree_button.text = "Souhlasím"
		article_agree_button.focus_mode = Control.FOCUS_NONE
		article_agree_button.z_index = 10
		article_agree_button.pressed.connect(_on_article_agree_pressed)
		add_child(article_agree_button)

	if article_no_button == null or not is_instance_valid(article_no_button):
		article_no_button = Button.new()
		article_no_button.name = "ArticleNoButton"
		article_no_button.text = "Nesouhlasím"
		article_no_button.focus_mode = Control.FOCUS_NONE
		article_no_button.z_index = 10
		article_no_button.pressed.connect(_on_article_no_pressed)
		add_child(article_no_button)

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 50
		add_child(instruction_label)

	if attempts_label == null or not is_instance_valid(attempts_label):
		attempts_label = Label.new()
		attempts_label.name = "AttemptsLabel"
		attempts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		attempts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		attempts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		attempts_label.add_theme_font_size_override("font_size", 16)
		attempts_label.modulate = Color(0.12, 0.12, 0.12)
		attempts_label.z_index = 200
		add_child(attempts_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 50
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 60
		add_child(control_label)

	style_green_button(article_agree_button)
	style_red_button(article_no_button)

	layout_ui()
	last_window_size = window_size


func show_article_screen():
	screen_state = "article"

	clear_reels()

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)

	article_no_button.visible = true
	article_no_button.disabled = false
	article_no_button.text = "Nesouhlasím"
	style_red_button(article_no_button)

	article_agree_button.visible = true
	article_agree_button.disabled = false
	article_agree_button.text = "Souhlasím"
	style_green_button(article_agree_button)

	instruction_label.visible = false
	attempts_label.visible = false
	result_label.visible = false

	layout_ui()


func show_game_screen():
	screen_state = "game"

	completed = false
	failed = false

	stopped = [false, false, false]
	reel_offsets = [0.0, 31.0, 62.0]

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = false
	article_no_button.visible = false
	article_agree_button.visible = false

	instruction_label.visible = true
	instruction_label.text = (
		"Zastav automat tak, aby v prostřední řadě bylo "
		+ str(needed_agree_in_middle)
		+ "× Souhlasím."
	)

	instruction_label.visible = false
	attempts_label.visible = true
	update_attempts_label()

	result_label.visible = false

	clear_reels()
	create_reels()
	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	if screen_state == "article":
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, window_size.y - 145)

		var button_size = Vector2(180, 44)
		var spacing = 80
		var total_width = button_size.x * 2 + spacing
		var start_x = window_size.x / 2.0 - total_width / 2.0
		var button_y = window_size.y - 68

		article_no_button.size = button_size
		article_agree_button.size = button_size

		article_no_button.position = Vector2(start_x, button_y)
		article_agree_button.position = Vector2(start_x + button_size.x + spacing, button_y)

		update_system_control_label_position()
		return

	instruction_label.position = Vector2(50, 4)
	instruction_label.size = Vector2(window_size.x - 100, 26)

	attempts_label.position = Vector2(28, 8)
	attempts_label.size = Vector2(220, 24)
	attempts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	attempts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	result_label.position = Vector2(70, window_size.y - 86)
	result_label.size = Vector2(window_size.x - 140, 42)

	update_system_control_label_position()


func _on_article_agree_pressed():
	if completed or failed:
		return

	show_game_screen()


func _on_article_no_pressed():
	if completed or failed:
		return

	fail_from_article()


func create_reels():
	var start_x = window_size.x / 2.0 - 292.0

	for i in range(3):
		var panel = Panel.new()
		panel.position = Vector2(start_x + i * 210.0, 116)
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
		stop.position = Vector2(panel.position.x + 4, 412)
		stop.size = Vector2(174, 54)
		stop.z_index = 8
		stop.focus_mode = Control.FOCUS_NONE
		stop.pressed.connect(_on_stop_pressed.bind(i))
		style_blue_button(stop)
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

		if text == "Souhlasím":
			apply_green_style_to_display_button(label)
		else:
			apply_red_style_to_display_button(label)


func get_middle_text(reel_index: int) -> String:
	var sequence = reel_sequences[reel_index]
	var offset_steps = int(floor(reel_offsets[reel_index] / 48.0))

	# Řádek 2 je uprostřed markeru.
	return sequence[(2 + offset_steps) % sequence.size()]


func _on_stop_pressed(index: int):
	if completed or failed or stopped[index]:
		return

	stopped[index] = true
	stop_buttons[index].disabled = true

	if stopped[0] and stopped[1] and stopped[2]:
		check_result()


func check_result():
	var agree_count = 0

	for i in range(3):
		if get_middle_text(i) == "Souhlasím":
			agree_count += 1

	if agree_count >= needed_agree_in_middle:
		complete_level()
		return

	attempts += 1
	update_attempts_label()

	GameState.add_system_control(7)
	update_system_control_label()

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.visible = true

	if attempts >= max_attempts:
		await get_tree().create_timer(0.8).timeout
		fail_from_game()
		return

	await get_tree().create_timer(0.85).timeout
	restart_reels_only()


func restart_reels_only():
	if completed or failed:
		return

	stopped = [false, false, false]

	reel_offsets = [
		randf_range(0.0, 90.0),
		randf_range(30.0, 120.0),
		randf_range(60.0, 150.0)
	]

	for stop in stop_buttons:
		if stop and is_instance_valid(stop):
			stop.disabled = false

	result_label.visible = false

	instruction_label.text = (
		"Zastav automat tak, aby v prostřední řadě bylo "
		+ str(needed_agree_in_middle)
		+ "× Souhlasím."
	)

	update_attempts_label()


func complete_level():
	if completed:
		return

	completed = true

	for stop in stop_buttons:
		if stop and is_instance_valid(stop):
			stop.disabled = true

	background.color = Color(0.84, 0.94, 0.84)

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.visible = true

	GameState.reduce_system_control(5)
	update_system_control_label()

	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func fail_from_article():
	if failed:
		return

	failed = true

	article_no_button.disabled = true
	article_agree_button.disabled = true

	background.color = Color(0.95, 0.82, 0.82)

	article_label.modulate = Color(0.58, 0.0, 0.0)
	article_label.text = "Souhlas nebyl dokončen."

	GameState.add_system_control(8)
	update_system_control_label()

	await get_tree().create_timer(fail_freeze_time).timeout
	level_failed.emit()


func fail_from_game():
	if failed:
		return

	failed = true

	for stop in stop_buttons:
		if stop and is_instance_valid(stop):
			stop.disabled = true

	background.color = Color(0.95, 0.82, 0.82)

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.visible = true

	GameState.add_system_control(10)
	update_system_control_label()

	await get_tree().create_timer(fail_freeze_time).timeout
	level_failed.emit()


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


func update_attempts_label():
	if attempts_label == null or not is_instance_valid(attempts_label):
		return

	attempts_label.text = "Pokusy: " + str(attempts) + "/" + str(max_attempts)


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return

	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


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


func style_blue_button(button: Button):
	var normal = make_button_style(Color(0.20, 0.50, 0.85), Color(0.10, 0.30, 0.70), 7)
	var hover = make_button_style(Color(0.30, 0.65, 1.0), Color(0.15, 0.40, 0.80), 7)
	var pressed = make_button_style(Color(0.15, 0.35, 0.70), Color(0.08, 0.20, 0.55), 7)
	var disabled = make_button_style(Color(0.46, 0.52, 0.60), Color(0.28, 0.32, 0.40), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 16)


func style_green_button(button: Button):
	var normal = make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12), 7)
	var hover = make_button_style(Color(0.25, 0.75, 0.30), Color(0.10, 0.42, 0.15), 7)
	var pressed = make_button_style(Color(0.10, 0.45, 0.16), Color(0.05, 0.26, 0.08), 7)
	var disabled = make_button_style(Color(0.52, 0.62, 0.52), Color(0.32, 0.42, 0.32), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 16)


func style_red_button(button: Button):
	var normal = make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 7)
	var hover = make_button_style(Color(0.90, 0.18, 0.18), Color(0.50, 0.05, 0.05), 7)
	var pressed = make_button_style(Color(0.52, 0.07, 0.07), Color(0.28, 0.02, 0.02), 7)
	var disabled = make_button_style(Color(0.62, 0.48, 0.48), Color(0.42, 0.30, 0.30), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 16)


func apply_green_style_to_display_button(button: Button):
	var normal = make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 14)


func apply_red_style_to_display_button(button: Button):
	var normal = make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 14)


func make_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	return sb
