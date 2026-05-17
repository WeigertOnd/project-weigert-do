extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var score_label: Label
var target_label: Label
var result_label: Label
var control_label: Label
var shot_button: Button
var no_button: Button

var board_rect = Rect2(236, 46, 430, 394)
var ball_pos = Vector2.ZERO
var ball_vel = Vector2.ZERO
var ball_active = false
var completed = false
var score = 0
var target_score = 120
var pegs = []
var bars = []
var bar_motion_time = 0.0


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
	score = 0
	bar_motion_time = 0.0
	ball_active = false
	setup_ui()
	create_board()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	no_button.disabled = true
	no_button.modulate = Color(1, 1, 1, 0.45)
	update_score_ui()
	update_system_control_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()
	update_system_control_label_position()
	if ball_active and not completed:
		simulate_ball(delta)
	move_modifiers(delta)
	queue_redraw()


func _draw():
	draw_rect(board_rect, Color(0.985, 0.985, 0.965), true)
	draw_rect(board_rect, Color(0.08, 0.22, 0.32), false, 4.0)
	for peg in pegs:
		draw_circle(peg, 6.0, Color(0.52, 0.58, 0.62))
	for bar in bars:
		var rect = bar["rect"]
		if not is_rect_fully_inside_board(rect):
			continue
		var value = int(bar["value"])
		var color = Color(0.45, 0.82, 0.54) if value > 0 else Color(0.82, 0.50, 0.56)
		draw_rect(rect, color, true)
		draw_rect(rect, Color(0.52, 0.58, 0.62), false, 3.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(22, 28), get_modifier_text(value), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.12, 0.12, 0.12))
	if ball_active:
		draw_circle(ball_pos, 9.0, Color(0.12, 0.22, 0.34))


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = -100

	if score_label == null or not is_instance_valid(score_label):
		score_label = Label.new()
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		score_label.add_theme_font_size_override("font_size", 26)
		score_label.modulate = Color(0.12, 0.12, 0.12)
		score_label.z_index = 10
		add_child(score_label)

	if target_label == null or not is_instance_valid(target_label):
		target_label = Label.new()
		target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		target_label.add_theme_font_size_override("font_size", 16)
		target_label.modulate = Color(0.15, 0.15, 0.15)
		target_label.z_index = 10
		add_child(target_label)

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

	if shot_button == null or not is_instance_valid(shot_button):
		shot_button = Button.new()
		shot_button.text = "Výstřel"
		shot_button.z_index = 12
		shot_button.pressed.connect(_on_shot_pressed)
		style_button(shot_button, true)
		add_child(shot_button)

	if no_button == null or not is_instance_valid(no_button):
		no_button = Button.new()
		no_button.text = "Nesouhlasím"
		no_button.z_index = 12
		no_button.pressed.connect(_on_no_pressed)
		style_button(no_button, false)
		add_child(no_button)

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	board_rect = Rect2(window_size.x / 2.0 - 215.0, 48.0, 430.0, 386.0)
	score_label.position = Vector2(board_rect.position.x, 68)
	score_label.size = Vector2(board_rect.size.x, 42)
	target_label.position = Vector2(26, 86)
	target_label.size = Vector2(174, 80)
	result_label.position = Vector2(70, window_size.y - 78)
	result_label.size = Vector2(window_size.x - 140, 32)
	no_button.position = Vector2(34, 244)
	no_button.size = Vector2(154, 50)
	shot_button.position = Vector2(window_size.x - 174, window_size.y - 98)
	shot_button.size = Vector2(142, 54)


func create_board():
	pegs.clear()
	bars.clear()
	for row in range(7):
		var count = 5 if row % 2 == 0 else 6
		for col in range(count):
			var x = board_rect.position.x + 70 + col * 66 + (33 if row % 2 == 0 else 0)
			var y = board_rect.position.y + 94 + row * 50
			pegs.append(Vector2(x, y))

	var bar_specs = [
		[132.0, 30, 0, 0.0], [132.0, 60, 0, 170.0], [132.0, -25, 0, 340.0],
		[194.0, -10, 1, 0.0], [194.0, 75, 1, 170.0], [194.0, -50, 1, 340.0],
		[250.0, -20, 2, 0.0], [250.0, 75, 2, 170.0], [250.0, -10, 2, 340.0],
		[306.0, -2, 3, 0.0], [306.0, -2, 3, 170.0], [306.0, 45, 3, 340.0]
	]
	for spec in bar_specs:
		bars.append({
			"rect": Rect2(board_rect.position + Vector2(float(spec[3]), float(spec[0])), Vector2(94, 24)),
			"value": spec[1],
			"hit": false,
			"row": spec[2],
			"offset": spec[3]
		})


func move_modifiers(delta):
	bar_motion_time += delta
	for bar in bars:
		var rect = bar["rect"]
		var row = int(bar["row"])
		var direction = 1.0 if row % 2 == 0 else -1.0
		var span = board_rect.size.x + rect.size.x + 72.0
		var progress = fposmod(float(bar["offset"]) + bar_motion_time * 112.0, span)
		var x = board_rect.position.x - rect.size.x - 36.0 + progress
		if direction < 0.0:
			x = board_rect.end.x + 36.0 - progress
		rect.position = Vector2(x, rect.position.y)
		bar["rect"] = rect


func _on_shot_pressed():
	if completed or ball_active:
		return
	ball_pos = Vector2(board_rect.position.x + board_rect.size.x / 2.0, board_rect.position.y + 18)
	ball_vel = Vector2(randf_range(-85.0, 85.0), 155.0)
	ball_active = true
	shot_button.disabled = true


func simulate_ball(delta):
	ball_vel.y += 860.0 * delta
	ball_pos += ball_vel * delta

	if ball_pos.x < board_rect.position.x + 9:
		ball_pos.x = board_rect.position.x + 9
		ball_vel.x = abs(ball_vel.x)
	elif ball_pos.x > board_rect.end.x - 9:
		ball_pos.x = board_rect.end.x - 9
		ball_vel.x = -abs(ball_vel.x)

	for peg in pegs:
		var delta_pos = ball_pos - peg
		var distance = delta_pos.length()
		if distance < 15.0 and distance > 0.01:
			var normal = delta_pos / distance
			ball_pos = peg + normal * 15.0
			ball_vel = ball_vel.bounce(normal) * 0.84
			ball_vel.x += randf_range(-24.0, 24.0)

	for bar in bars:
		if bool(bar["hit"]):
			continue
		var rect = bar["rect"]
		if is_rect_fully_inside_board(rect) and circle_intersects_rect(ball_pos, 9.0, rect):
			bar["hit"] = true
			apply_modifier(int(bar["value"]))
			ball_vel.y *= -0.65
			ball_vel.x += randf_range(-42.0, 42.0)
			update_score_ui()

	if ball_pos.y > board_rect.end.y + 24:
		ball_active = false
		shot_button.disabled = false
		if score >= target_score:
			unlock_no_button()
		else:
			GameState.add_system_control(3)
			update_system_control_label()
			result_label.modulate = Color(0.45, 0.32, 0.0)
			result_label.text = "Ještě málo bodů. Střílej znovu."
			result_label.visible = true


func update_score_ui():
	score_label.text = "%04d" % max(0, score)
	target_label.text = "Cíl:\n%d bodů" % target_score


func apply_modifier(value: int):
	if value == -2:
		score = int(floor(float(score) / 2.0))
	else:
		score += value
	score = max(0, score)


func get_modifier_text(value: int) -> String:
	if value == -2:
		return "/2"
	return "%+d" % value


func is_rect_fully_inside_board(rect: Rect2) -> bool:
	return rect.position.x >= board_rect.position.x + 6.0 and rect.end.x <= board_rect.end.x - 6.0 and rect.position.y >= board_rect.position.y + 6.0 and rect.end.y <= board_rect.end.y - 6.0


func circle_intersects_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest = Vector2(
		clamp(center.x, rect.position.x, rect.end.x),
		clamp(center.y, rect.position.y, rect.end.y)
	)
	return center.distance_squared_to(closest) <= radius * radius


func unlock_no_button():
	no_button.disabled = false
	no_button.modulate = Color(1, 1, 1, 1)
	result_label.modulate = Color(0.0, 0.45, 0.0)
	result_label.text = "Tlačítko NESOUHLASÍM je odemčené."
	result_label.visible = true
	GameState.reduce_system_control(5)
	update_system_control_label()


func _on_no_pressed():
	if completed or no_button.disabled:
		return
	completed = true
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Nesouhlas doručen přes skóre."
	result_label.visible = true
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


func style_button(button: Button, primary: bool):
	var bg = Color(0.65, 0.90, 0.66) if not primary else Color(0.94, 0.94, 0.91)
	var border = Color(0.10, 0.45, 0.22) if not primary else Color(0.20, 0.40, 0.72)
	button.add_theme_stylebox_override("normal", make_button_style(bg, border))
	button.add_theme_stylebox_override("hover", make_button_style(bg.lerp(Color(1, 1, 1), 0.08), border))
	button.add_theme_stylebox_override("pressed", make_button_style(bg.lerp(Color(0, 0, 0), 0.08), border))
	button.add_theme_stylebox_override("disabled", make_button_style(Color(0.68, 0.70, 0.70), Color(0.36, 0.40, 0.44)))
	button.add_theme_color_override("font_color", Color(0.08, 0.18, 0.32) if primary else Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.32, 0.36, 0.38))
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
