extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var progress = 0.0
var progress_max = 100.0

# Obtížnost
var click_power = 5.0
var decay_speed = 11.0
var hit_penalty = 25.0

# Panáček
var runner_radius = 14.0
var runner_bob_time = 0.0

# Progress bar
var bar_position = Vector2.ZERO
var bar_size = Vector2.ZERO

# Překážky
var obstacles = []
var obstacle_spawn_timer = 0.0
var obstacle_spawn_delay = 0.36
var obstacle_speed = 230.0
var obstacle_size = Vector2(34, 34)

var game_finished = false


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
	screen_state = "runner"
	progress = 0.0
	obstacles.clear()
	obstacle_spawn_timer = 0.0
	runner_bob_time = 0.0
	game_finished = false

	setup_ui()
	show_runner_game()


func setup_ui():
	background.z_index = -10
	text_label.z_index = 5
	agree_button.z_index = 10
	no_button.z_index = 10

	background.color = Color(0.96, 0.96, 0.92)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func show_article_screen():
	screen_state = "article"
	game_finished = false

	progress = 0.0
	obstacles.clear()
	obstacle_spawn_timer = 0.0

	background.color = Color(0.96, 0.96, 0.92)

	text_label.visible = true
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = LevelUtils.get_article_text(article_number)

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	LevelUtils.style_green_button(agree_button)
	LevelUtils.style_red_button(no_button)

	layout_ui()
	queue_redraw()


func show_runner_game():
	screen_state = "runner"
	game_finished = false

	progress = 0.0
	obstacles.clear()
	obstacle_spawn_timer = 0.0
	runner_bob_time = 0.0

	background.color = Color(0.96, 0.96, 0.92)

	text_label.visible = true
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = LevelUtils.get_article_text(article_number)

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	LevelUtils.style_green_button(agree_button)
	LevelUtils.style_red_button(no_button)

	layout_ui()
	queue_redraw()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if screen_state == "runner" and not game_finished:
		update_runner_game(delta)

	queue_redraw()


func update_runner_game(delta):
	if game_finished:
		return

	runner_bob_time += delta * 8.0

	progress -= decay_speed * delta
	progress = clamp(progress, 0.0, progress_max)

	obstacle_spawn_timer -= delta

	if obstacle_spawn_timer <= 0.0:
		spawn_obstacle()
		obstacle_spawn_timer = obstacle_spawn_delay

	update_obstacles(delta)

	if progress >= progress_max:
		finish_success()


func spawn_obstacle():
	var spawn_x = randf_range(bar_position.x + 20, bar_position.x + bar_size.x - 20)
	var spawn_y = bar_position.y - 170

	var obstacle = {
		"pos": Vector2(spawn_x, spawn_y),
		"rotation": randf_range(-0.6, 0.6)
	}

	obstacles.append(obstacle)


func update_obstacles(delta):
	var runner_pos = get_runner_position()

	for i in range(obstacles.size() - 1, -1, -1):
		var obstacle = obstacles[i]
		var pos = obstacle["pos"]

		pos.y += obstacle_speed * delta
		obstacle["pos"] = pos
		obstacles[i] = obstacle

		var obstacle_rect = Rect2(
			pos - obstacle_size / 2.0,
			obstacle_size
		)

		if obstacle_rect.has_point(runner_pos):
			progress -= hit_penalty
			progress = clamp(progress, 0.0, progress_max)
			obstacles.remove_at(i)
			start_hit_feedback()
			continue

		if pos.y > bar_position.y + 85:
			obstacles.remove_at(i)


func get_runner_position() -> Vector2:
	var ratio = progress / progress_max
	var x = bar_position.x + ratio * bar_size.x
	var y = bar_position.y + bar_size.y / 2.0

	y += sin(runner_bob_time) * 4.0

	return Vector2(x, y)


func start_hit_feedback():
	background.color = Color(0.95, 0.82, 0.82)

	await get_tree().create_timer(0.08).timeout

	if screen_state == "runner":
		background.color = Color(0.96, 0.96, 0.92)


func finish_success():
	if game_finished:
		return

	game_finished = true
	progress = progress_max

	agree_button.disabled = true
	no_button.disabled = true
	agree_button.visible = false
	no_button.visible = false
	obstacles.clear()

	text_label.modulate = Color(0.05, 0.38, 0.10)
	text_label.text = GameState.result_success_text

	queue_redraw()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if screen_state == "article":
		text_label.position = Vector2(70, 40)
		text_label.size = Vector2(window_size.x - 140, window_size.y - 145)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 20)

	elif screen_state == "runner":
		text_label.position = Vector2(70, 32)
		text_label.size = Vector2(window_size.x - 140, 215)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 15)

	bar_position = Vector2(80, 305)
	bar_size = Vector2(window_size.x - 160, 28)

	no_button.size = Vector2(180, 44)
	agree_button.size = Vector2(180, 44)

	var button_y = window_size.y - 68

	no_button.position = Vector2(window_size.x / 2.0 - 220, button_y)
	agree_button.position = Vector2(window_size.x / 2.0 + 40, button_y)


func _draw():
	if screen_state != "runner":
		return

	draw_progress_bar()
	draw_obstacles()
	draw_runner()


func draw_progress_bar():
	var bg_rect = Rect2(bar_position, bar_size)
	var fill_width = bar_size.x * (progress / progress_max)
	var fill_rect = Rect2(bar_position, Vector2(fill_width, bar_size.y))

	draw_rect(bg_rect, Color(0.10, 0.25, 0.32), true)
	draw_rect(fill_rect, Color(0.40, 0.86, 0.52), true)
	draw_rect(bg_rect, Color(0.05, 0.18, 0.24), false, 3.0)

	var percent_text = str(roundi(progress)) + "%"

	draw_string(
		ThemeDB.fallback_font,
		bar_position + Vector2(bar_size.x / 2.0 - 18, -12),
		percent_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.10, 0.10, 0.10)
	)


func draw_runner():
	var runner_pos = get_runner_position()

	var dark = Color(0.05, 0.16, 0.24)
	var skin = Color(1.0, 0.86, 0.68)
	var shirt = Color(0.20, 0.55, 1.0)
	var pants = Color(0.12, 0.20, 0.36)
	var shoe = Color(0.04, 0.04, 0.05)

	var run = sin(runner_bob_time)
	var arm_swing = run * 8.0
	var leg_swing = run * 10.0

	var body_pos = runner_pos + Vector2(0, -16)
	var head_pos = runner_pos + Vector2(0, -42)

	# Stín pod panáčkem
	draw_circle(runner_pos + Vector2(0, 27), 18, Color(0, 0, 0, 0.13))

	# Tělo
	draw_circle(body_pos, 15, shirt)
	draw_circle(body_pos, 15, dark, false, 2.0)

	# Hlava
	draw_circle(head_pos, 11, skin)
	draw_circle(head_pos, 11, dark, false, 2.0)

	# Vlasy
	draw_arc(head_pos + Vector2(0, -3), 11, PI, TAU, 12, dark, 4.0)

	# Ruce
	var left_shoulder = body_pos + Vector2(-10, -3)
	var right_shoulder = body_pos + Vector2(10, -3)

	var left_hand = body_pos + Vector2(-23, 10 + arm_swing)
	var right_hand = body_pos + Vector2(23, 10 - arm_swing)

	draw_line(left_shoulder, left_hand, dark, 4.0)
	draw_line(right_shoulder, right_hand, dark, 4.0)
	draw_circle(left_hand, 4, skin)
	draw_circle(right_hand, 4, skin)

	# Nohy
	var hip_left = body_pos + Vector2(-6, 13)
	var hip_right = body_pos + Vector2(6, 13)

	var left_foot = runner_pos + Vector2(-16, 24 + leg_swing)
	var right_foot = runner_pos + Vector2(16, 24 - leg_swing)

	draw_line(hip_left, left_foot, pants, 5.0)
	draw_line(hip_right, right_foot, pants, 5.0)

	draw_circle(left_foot, 5, shoe)
	draw_circle(right_foot, 5, shoe)

	# Oči
	draw_circle(head_pos + Vector2(-4, -1), 1.5, dark)
	draw_circle(head_pos + Vector2(4, -1), 1.5, dark)

	# Úsměv
	draw_arc(head_pos + Vector2(0, 2), 5, 0.15, PI - 0.15, 8, dark, 1.5)


func draw_obstacles():
	for obstacle in obstacles:
		var pos = obstacle["pos"]

		var points = PackedVector2Array([
			pos + Vector2(0, -19),
			pos + Vector2(18, -5),
			pos + Vector2(12, 17),
			pos + Vector2(-12, 17),
			pos + Vector2(-18, -5)
		])

		draw_colored_polygon(points, Color(0.95, 0.34, 0.45))

		var outline = PackedVector2Array([
			points[0],
			points[1],
			points[2],
			points[3],
			points[4],
			points[0]
		])

		draw_polyline(outline, Color(0.08, 0.20, 0.30), 3.0)

		# Malý odlesk
		draw_circle(pos + Vector2(-5, -6), 4, Color(1.0, 0.70, 0.78))


func _on_agree_pressed():
	if screen_state == "runner" and not game_finished:
		progress += click_power
		progress = clamp(progress, 0.0, progress_max)
		runner_bob_time += 0.45

		if progress >= progress_max:
			finish_success()
			return

		queue_redraw()


func _on_no_pressed():
	agree_button.disabled = true
	no_button.disabled = true

	text_label.modulate = Color(0.58, 0.0, 0.0)
	text_label.text = GameState.result_fail_text

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()
