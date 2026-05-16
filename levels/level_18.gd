extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var instruction_label: Label
var input_label: Label
var result_label: Label
var control_label: Label
var confirm_button: Button
var delete_button: Button
var digit_buttons = []
var balls = []
var answer = ""
var completed = false
var count_area = Rect2(34, 38, 788, 160)


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
	answer = ""
	setup_ui()
	create_balls()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	update_input_label()
	update_system_control_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()
	update_system_control_label_position()
	if completed:
		return
	move_balls(delta)
	queue_redraw()


func _draw():
	draw_rect(count_area, Color(0.90, 0.90, 0.90), true)
	for ball in balls:
		draw_circle(ball["pos"], ball["radius"], Color(0.76, 0.67, 0.56))
		draw_arc(ball["pos"], ball["radius"], 0, TAU, 24, Color(0.48, 0.43, 0.36), 4.0)


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = -100

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.add_theme_font_size_override("font_size", 19)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 10
		add_child(instruction_label)

	if input_label == null or not is_instance_valid(input_label):
		input_label = Label.new()
		input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		input_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		input_label.add_theme_font_size_override("font_size", 22)
		input_label.modulate = Color(0.10, 0.10, 0.10)
		input_label.z_index = 10
		add_child(input_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 17)
		result_label.z_index = 10
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 12
		add_child(control_label)

	if digit_buttons.is_empty():
		for i in range(10):
			var btn = Button.new()
			btn.text = str(i)
			btn.z_index = 12
			btn.pressed.connect(_on_digit_pressed.bind(str(i)))
			style_button(btn)
			add_child(btn)
			digit_buttons.append(btn)

	if confirm_button == null or not is_instance_valid(confirm_button):
		confirm_button = Button.new()
		confirm_button.text = "Potvrdit"
		confirm_button.z_index = 12
		confirm_button.pressed.connect(_on_confirm_pressed)
		style_button(confirm_button)
		add_child(confirm_button)

	if delete_button == null or not is_instance_valid(delete_button):
		delete_button = Button.new()
		delete_button.text = "Smazat"
		delete_button.z_index = 12
		delete_button.pressed.connect(_on_delete_pressed)
		style_button(delete_button)
		add_child(delete_button)

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	count_area = Rect2(34, 38, window_size.x - 68, 160)
	instruction_label.position = Vector2(80, 214)
	instruction_label.size = Vector2(window_size.x - 160, 46)
	instruction_label.text = "Kolik kuliček je nahoře?"
	input_label.position = Vector2(120, 268)
	input_label.size = Vector2(window_size.x - 240, 48)
	result_label.position = Vector2(70, window_size.y - 74)
	result_label.size = Vector2(window_size.x - 140, 30)

	var start_x = window_size.x / 2.0 - 294.0
	var y1 = 330.0
	var y2 = 396.0
	for i in range(5):
		digit_buttons[i].position = Vector2(start_x + i * 80.0, y1)
		digit_buttons[i].size = Vector2(66, 50)
	for i in range(5, 10):
		digit_buttons[i].position = Vector2(start_x + (i - 5) * 80.0, y2)
		digit_buttons[i].size = Vector2(66, 50)

	confirm_button.position = Vector2(start_x + 430, y1)
	confirm_button.size = Vector2(176, 50)
	delete_button.position = Vector2(start_x + 430, y2)
	delete_button.size = Vector2(176, 50)


func create_balls():
	balls.clear()
	var count = randi_range(15, 22)
	for _i in range(count):
		var radius = randf_range(12.0, 16.0)
		var pos = Vector2(
			randf_range(count_area.position.x + radius, count_area.end.x - radius),
			randf_range(count_area.position.y + radius, count_area.end.y - radius)
		)
		var vel = Vector2(randf_range(-135, 135), randf_range(-95, 95))
		balls.append({"pos": pos, "vel": vel, "radius": radius})


func move_balls(delta):
	for ball in balls:
		var pos = ball["pos"] + ball["vel"] * delta
		var vel = ball["vel"]
		var radius = ball["radius"]
		if pos.x - radius < count_area.position.x or pos.x + radius > count_area.end.x:
			vel.x *= -1.0
			pos.x = clamp(pos.x, count_area.position.x + radius, count_area.end.x - radius)
		if pos.y - radius < count_area.position.y or pos.y + radius > count_area.end.y:
			vel.y *= -1.0
			pos.y = clamp(pos.y, count_area.position.y + radius, count_area.end.y - radius)
		ball["pos"] = pos
		ball["vel"] = vel


func _on_digit_pressed(digit: String):
	if completed or answer.length() >= 2:
		return
	answer += digit
	update_input_label()


func _on_delete_pressed():
	if completed:
		return
	answer = answer.substr(0, max(0, answer.length() - 1))
	update_input_label()


func _on_confirm_pressed():
	if completed:
		return
	if answer == str(balls.size()):
		complete_level()
	else:
		GameState.add_system_control(7)
		update_system_control_label()
		result_label.modulate = Color(0.58, 0.0, 0.0)
		result_label.text = "Špatně. Kuličky se mezitím tváří nevinně."
		result_label.visible = true
		answer = ""
		update_input_label()


func update_input_label():
	input_label.text = answer if answer != "" else "?"


func complete_level():
	completed = true
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Správný počet."
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
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.94, 0.94, 0.91), Color(0.20, 0.40, 0.72)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.98, 0.99, 1.0), Color(0.24, 0.48, 0.92)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(0.76, 0.86, 0.98), Color(0.16, 0.33, 0.70)))
	button.add_theme_color_override("font_color", Color(0.08, 0.18, 0.32))
	button.add_theme_font_size_override("font_size", 15)


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
