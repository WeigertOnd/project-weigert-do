extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

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

var target_center = Vector2(428, 250)
var target_radius = 140.0
var rotation_angle = 0.0
var rotation_speed = 9.2
var green_fraction = 0.13
var cursor_pos = Vector2.ZERO
var cursor_time = 0.0
var completed = false
var failed = false
var attempts_left = 2


func _ready():
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
	attempts_left = 2
	rotation_angle = randf() * TAU
	cursor_time = 0.0
	cursor_pos = target_center

	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	show_article_screen()
	update_system_control_label()
	layout_ui()
	queue_redraw()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()
	update_system_control_label_position()

	if screen_state != "game" or completed or failed:
		return

	rotation_angle = fposmod(rotation_angle + rotation_speed * delta, TAU)
	update_cursor(delta)
	queue_redraw()


func _input(event):
	if screen_state != "game" or completed or failed:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		check_click()


func _draw():
	if screen_state != "game":
		return

	draw_circle(target_center, target_radius + 8, Color(0.08, 0.22, 0.32))
	draw_circle(target_center, target_radius, Color(0.82, 0.50, 0.56))
	draw_sector(target_center, target_radius, rotation_angle, rotation_angle + TAU * green_fraction, Color(0.18, 0.62, 0.22))
	draw_circle(target_center, 38, Color(0.96, 0.96, 0.92))
	draw_arc(target_center, target_radius, 0, TAU, 96, Color(0.08, 0.22, 0.32), 4.0)
	draw_string(ThemeDB.fallback_font, target_center + Vector2(-52, 8), "SOUHLASÍM", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.06, 0.22, 0.10))

	draw_line(cursor_pos + Vector2(-16, 0), cursor_pos + Vector2(16, 0), Color(0.08, 0.18, 0.32), 3.0)
	draw_line(cursor_pos + Vector2(0, -16), cursor_pos + Vector2(0, 16), Color(0.08, 0.18, 0.32), 3.0)
	draw_circle(cursor_pos, 5, Color(0.95, 0.95, 0.95))
	draw_arc(cursor_pos, 10, 0, TAU, 24, Color(0.08, 0.18, 0.32), 2.0)


func draw_sector(center: Vector2, radius: float, from_angle: float, to_angle: float, color: Color):
	var points = PackedVector2Array()
	points.append(center)
	var steps = 24
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var angle = lerp(from_angle, to_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)


func setup_ui():
	LevelUtils.layout_background(background, window_size)
	background.z_index = -100

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 10
		add_child(article_label)

	if not LevelUtils.is_valid_node(article_agree_button):
		article_agree_button = Button.new()
		article_agree_button.name = "ArticleAgreeButton"
		article_agree_button.text = "Souhlasím"
		article_agree_button.focus_mode = Control.FOCUS_NONE
		article_agree_button.z_index = 12
		article_agree_button.pressed.connect(_on_article_agree_pressed)
		add_child(article_agree_button)

	if not LevelUtils.is_valid_node(article_no_button):
		article_no_button = Button.new()
		article_no_button.name = "ArticleNoButton"
		article_no_button.text = "Nesouhlasím"
		article_no_button.focus_mode = Control.FOCUS_NONE
		article_no_button.z_index = 12
		article_no_button.pressed.connect(_on_article_no_pressed)
		add_child(article_no_button)

	if not LevelUtils.is_valid_node(instruction_label):
		instruction_label = Label.new()
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 20
		add_child(instruction_label)

	if not LevelUtils.is_valid_node(attempts_label):
		attempts_label = Label.new()
		attempts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		attempts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		attempts_label.add_theme_font_size_override("font_size", 16)
		attempts_label.modulate = Color(0.15, 0.15, 0.15)
		attempts_label.z_index = 20
		add_child(attempts_label)

	if not LevelUtils.is_valid_node(result_label):
		result_label = Label.new()
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 20
		add_child(result_label)

	if not LevelUtils.is_valid_node(control_label):
		control_label = Label.new()
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 25
		add_child(control_label)

	LevelUtils.style_green_button(article_agree_button)
	LevelUtils.style_red_button(article_no_button)

	layout_ui()


func show_article_screen():
	screen_state = "article"
	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = LevelUtils.get_article_text(article_number)
	article_no_button.visible = true
	article_no_button.disabled = false
	article_agree_button.visible = true
	article_agree_button.disabled = false

	set_game_visible(false)
	queue_redraw()


func show_game_screen():
	screen_state = "game"
	completed = false
	failed = false
	attempts_left = 2
	rotation_angle = randf() * TAU
	cursor_time = 0.0
	cursor_pos = target_center
	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = false
	article_no_button.visible = false
	article_agree_button.visible = false

	set_game_visible(true)
	result_label.visible = false
	layout_ui()
	cursor_pos = target_center
	update_attempts_label()
	update_cursor(0.0)
	queue_redraw()


func set_game_visible(visible: bool):
	instruction_label.visible = visible
	attempts_label.visible = visible
	result_label.visible = visible and result_label.visible


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if screen_state == "article":
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, window_size.y - 145)

		var article_button_size = Vector2(180, 44)
		var spacing = 80
		var total_width = article_button_size.x * 2 + spacing
		var start_x = window_size.x / 2.0 - total_width / 2.0
		var button_y = window_size.y - 68
		article_no_button.size = article_button_size
		article_agree_button.size = article_button_size
		article_no_button.position = Vector2(start_x, button_y)
		article_agree_button.position = Vector2(start_x + article_button_size.x + spacing, button_y)
		update_system_control_label_position()
		return

	target_radius = min(142.0, max(104.0, min(window_size.x, window_size.y) * 0.25))
	target_center = Vector2(window_size.x / 2.0, window_size.y / 2.0 + 2)
	instruction_label.position = Vector2(60, 34)
	instruction_label.size = Vector2(window_size.x - 120, 42)
	instruction_label.text = "Klikni ve chvíli, kdy se pohyblivé mířítko trefí do zelené části SOUHLASÍM."

	attempts_label.position = Vector2(60, 78)
	attempts_label.size = Vector2(window_size.x - 120, 26)

	result_label.position = Vector2(70, window_size.y - 64)
	result_label.size = Vector2(window_size.x - 140, 34)

	update_system_control_label_position()


func update_cursor(delta):
	cursor_time += delta

	var radius = target_radius * (
		0.58
		+ 0.24 * sin(cursor_time * 2.6)
		+ 0.12 * sin(cursor_time * 6.4)
		+ 0.05 * sin(cursor_time * 10.2)
	)
	var angle = (
		cursor_time * 3.55
		+ sin(cursor_time * 4.0) * 0.95
		+ cos(cursor_time * 7.8) * 0.42
		+ sin(cursor_time * 11.6) * 0.16
	)
	var wobble = Vector2(
		sin(cursor_time * 8.8) * 26.0 + sin(cursor_time * 14.0) * 8.0,
		cos(cursor_time * 7.3) * 23.0 + cos(cursor_time * 11.8) * 7.0
	)
	cursor_pos = target_center + Vector2(cos(angle), sin(angle)) * radius + wobble

	var delta_from_center = cursor_pos - target_center
	var max_distance = target_radius - 12.0
	if delta_from_center.length() > max_distance:
		cursor_pos = target_center + delta_from_center.normalized() * max_distance


func _on_article_agree_pressed():
	if completed or failed:
		return
	show_game_screen()


func _on_article_no_pressed():
	if completed or failed:
		return
	fail_level("Souhlas nebyl dokončen.")


func check_click():
	var delta = cursor_pos - target_center
	var distance = delta.length()
	if distance > target_radius or distance < 42.0:
		fail_click()
		return

	var angle = fposmod(atan2(delta.y, delta.x), TAU)
	var local_angle = fposmod(angle - rotation_angle, TAU)
	if local_angle <= TAU * green_fraction:
		complete_level()
	else:
		fail_click()


func fail_click():
	attempts_left -= 1
	update_attempts_label()
	update_system_control_label()

	background.color = Color(0.95, 0.82, 0.82)
	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.visible = true

	if attempts_left <= 0:
		result_label.text = GameState.result_fail_text
		fail_level("Druhý pokus minul zelenou část.")
		return

	result_label.text = "Mimo. Zbývá 1 pokus."

	await get_tree().create_timer(0.35).timeout

	if not completed and not failed:
		background.color = Color(0.96, 0.96, 0.92)


func fail_level(message: String):
	if failed:
		return

	failed = true
	background.color = Color(0.95, 0.82, 0.82)

	if screen_state == "article":
		article_no_button.disabled = true
		article_agree_button.disabled = true

		article_label.modulate = Color(0.58, 0.0, 0.0)
		article_label.text = GameState.result_fail_text

		result_label.visible = false

		update_system_control_label()

		await get_tree().create_timer(GameState.result_freeze_time).timeout
		level_failed.emit()
		return

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = GameState.result_fail_text
	result_label.visible = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func complete_level():
	completed = true
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = GameState.result_success_text
	result_label.visible = true
	update_system_control_label()
	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func update_attempts_label():
	if attempts_label:
		attempts_label.text = "Pokusy: " + str(attempts_left) + "/2"


func update_system_control_label_position():
	LevelUtils.update_system_control_label(control_label, Vector2(window_size.x - 340, 8))


func update_system_control_label():
	LevelUtils.refresh_system_control_label(control_label)
