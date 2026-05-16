extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var instruction_label: Label
var result_label: Label
var control_label: Label

var target_center = Vector2(428, 250)
var target_radius = 150.0
var rotation_angle = 0.0
var rotation_speed = 5.8
var green_fraction = 0.15
var cursor_pos = Vector2.ZERO
var cursor_time = 0.0
var completed = false


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
	rotation_angle = randf() * TAU
	cursor_time = 0.0
	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	update_cursor(0.0)
	update_system_control_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()
	update_system_control_label_position()
	if completed:
		return
	rotation_angle = fposmod(rotation_angle + rotation_speed * delta, TAU)
	update_cursor(delta)
	queue_redraw()


func _input(event):
	if completed:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		check_click()


func _draw():
	draw_circle(target_center, target_radius + 8, Color(0.08, 0.22, 0.32))
	draw_circle(target_center, target_radius, Color(0.82, 0.50, 0.56))
	draw_sector(target_center, target_radius, rotation_angle, rotation_angle + TAU * green_fraction, Color(0.45, 0.82, 0.54))
	draw_circle(target_center, 38, Color(0.96, 0.96, 0.92))
	draw_arc(target_center, target_radius, 0, TAU, 96, Color(0.08, 0.22, 0.32), 4.0)
	draw_string(ThemeDB.fallback_font, target_center + Vector2(-64, 8), "NESOUHLASÍM", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.06, 0.22, 0.10))

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
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = -100

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 20
		add_child(instruction_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 20
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 25
		add_child(control_label)

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	target_center = Vector2(window_size.x / 2.0, window_size.y / 2.0 + 10)
	instruction_label.position = Vector2(60, 58)
	instruction_label.size = Vector2(window_size.x - 120, 44)
	instruction_label.text = "Klikni, kdyĹľ nekontrolovanĂ˝ kurzor trefĂ­ zelenĂ˝ vĂ˝sek NESOUHLASĂŤM."
	result_label.position = Vector2(70, window_size.y - 88)
	result_label.size = Vector2(window_size.x - 140, 34)


func update_cursor(delta):
	cursor_time += delta
	cursor_pos = target_center + Vector2(
		sin(cursor_time * 2.4) * 190.0 + sin(cursor_time * 7.1) * 22.0,
		cos(cursor_time * 1.9) * 118.0 + sin(cursor_time * 5.4) * 26.0
	)


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
	GameState.add_system_control(8)
	update_system_control_label()
	background.color = Color(0.95, 0.82, 0.82)
	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = "Mimo zelenĂ˝ nesouhlas."
	result_label.visible = true
	await get_tree().create_timer(0.35).timeout
	if not completed:
		background.color = Color(0.96, 0.96, 0.92)


func complete_level():
	completed = true
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "PĹ™Ă­mĂ˝ zĂˇsah do NESOUHLASĂŤM."
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
