extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect
@onready var no_button = $NoButton

var article_label: Label
var agree_button: Button

var control_label: Label
var title_label: Label
var score_label: Label
var status_label: Label
var target_label: Label
var launch_button: Button

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var score = 0
var target_score = 500
var balls_left = 3
var unlocked = false
var ball_launched = false
var ball_position = Vector2.ZERO
var ball_velocity = Vector2.ZERO
var ball_radius = 7.5

var left_flipper_active = false
var right_flipper_active = false
var left_flipper_held = false
var right_flipper_held = false
var left_flipper_lift = 0.0
var right_flipper_lift = 0.0
var left_flipper_swing_speed = 0.0
var right_flipper_swing_speed = 0.0
var flipper_timer_left = 0.0
var flipper_timer_right = 0.0
var flipper_duration = 0.18
var flipper_animation_speed = 12.0
var flipper_length = 100.0
var flipper_pivot_offset = 106.0
var flipper_hit_radius = 6.5
var center_drain_half_width = 36.0
var launcher_lane_width = 48.0
var launcher_lane_gap_height = 72.0
var launcher_stuck_time = 0.0
var ball_stuck_time = 0.0
var last_ball_position = Vector2.ZERO

var bumpers = []
var posts = []
var bumper_flash = {}
var gravity = 780.0
var max_ball_speed = 900.0
var launch_power = Vector2(-16.0, -960.0)
var physics_step = 1.0 / 120.0
var ball_damping_per_second = 0.72
var wall_restitution = 0.88
var rubber_restitution = 0.90
var bumper_kick = 185.0
var flipper_kick = 700.0


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
	setup_bumpers()
	last_window_size = window_size


func start_level():
	screen_state = "article"

	score = 0
	balls_left = 3
	unlocked = false
	ball_launched = false

	left_flipper_active = false
	right_flipper_active = false
	left_flipper_held = false
	right_flipper_held = false
	left_flipper_lift = 0.0
	right_flipper_lift = 0.0
	left_flipper_swing_speed = 0.0
	right_flipper_swing_speed = 0.0
	flipper_timer_left = 0.0
	flipper_timer_right = 0.0
	ball_stuck_time = 0.0
	last_ball_position = Vector2.ZERO
	launcher_stuck_time = 0.0

	setup_ui()
	setup_bumpers()
	reset_ball()
	update_labels()
	show_article_screen()
	queue_redraw()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if screen_state != "pinball":
		queue_redraw()
		return

	update_system_control_label_position()
	update_flippers(delta)

	if ball_launched and not unlocked:
		update_ball(delta)

	update_bumper_flash(delta)
	queue_redraw()


func _input(event):
	if screen_state != "pinball":
		return

	if not (event is InputEventKey) or event.echo:
		return

	if event.keycode == KEY_LEFT:
		if event.pressed:
			left_flipper_held = true
			activate_left_flipper()
		else:
			left_flipper_held = false
			left_flipper_active = false

	elif event.keycode == KEY_RIGHT:
		if event.pressed:
			right_flipper_held = true
			activate_right_flipper()
		else:
			right_flipper_held = false
			right_flipper_active = false

	elif event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_on_launch_pressed()


func setup_ui():
	background.color = Color(0.96, 0.96, 0.92)
	background.z_index = -10
	no_button.z_index = 30

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 18)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 40
		add_child(article_label)

	if not LevelUtils.is_valid_node(agree_button):
		agree_button = Button.new()
		agree_button.name = "AgreeButton"
		agree_button.text = "Souhlasím"
		agree_button.z_index = 40
		agree_button.pressed.connect(_on_article_agree_pressed)
		add_child(agree_button)

	if not LevelUtils.is_valid_node(title_label):
		title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 20)
		title_label.modulate = Color(0.12, 0.12, 0.12)
		title_label.z_index = 20
		add_child(title_label)

	if not LevelUtils.is_valid_node(score_label):
		score_label = Label.new()
		score_label.name = "ScoreLabel"
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		score_label.add_theme_font_size_override("font_size", 16)
		score_label.modulate = Color(0.12, 0.12, 0.12)
		score_label.z_index = 20
		add_child(score_label)

	if not LevelUtils.is_valid_node(target_label):
		target_label = Label.new()
		target_label.name = "TargetLabel"
		target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		target_label.add_theme_font_size_override("font_size", 14)
		target_label.modulate = Color(0.42, 0.0, 0.0)
		target_label.z_index = 20
		add_child(target_label)

	if not LevelUtils.is_valid_node(status_label):
		status_label = Label.new()
		status_label.name = "StatusLabel"
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 15)
		status_label.modulate = Color(0.14, 0.14, 0.14)
		status_label.z_index = 20
		add_child(status_label)

	if not LevelUtils.is_valid_node(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 25
		add_child(control_label)

	if not LevelUtils.is_valid_node(launch_button):
		launch_button = Button.new()
		launch_button.name = "LaunchButton"
		launch_button.text = "Výstřel"
		launch_button.z_index = 30
		LevelUtils.style_blue_button(launch_button)
		launch_button.pressed.connect(_on_launch_pressed)
		add_child(launch_button)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	update_system_control_label()


func show_article_screen():
	screen_state = "article"

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.text = LevelUtils.get_article_text(article_number)

	agree_button.visible = true
	agree_button.disabled = false
	agree_button.text = "Souhlasím"
	LevelUtils.style_green_button(agree_button)

	no_button.visible = true
	no_button.disabled = false
	no_button.text = "Nesouhlasím"
	LevelUtils.style_red_button(no_button)

	title_label.visible = false
	score_label.visible = false
	target_label.visible = false
	status_label.visible = false
	control_label.visible = false

	if launch_button:
		launch_button.visible = false

	layout_ui()
	queue_redraw()


func show_pinball_screen():
	screen_state = "pinball"

	article_label.visible = false
	agree_button.visible = false

	title_label.visible = true
	score_label.visible = true
	target_label.visible = true
	status_label.visible = true
	control_label.visible = true

	if launch_button:
		launch_button.visible = true
		launch_button.disabled = false
		launch_button.text = "Výstřel"
		LevelUtils.style_blue_button(launch_button)

	no_button.visible = true
	no_button.disabled = true
	no_button.text = "Souhlasím"
	LevelUtils.style_soft_xp_button(no_button)

	score = 0
	balls_left = 3
	unlocked = false
	ball_launched = false

	reset_ball()
	update_labels()
	layout_ui()
	queue_redraw()


func _on_article_agree_pressed():
	show_pinball_screen()


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if screen_state == "article":
		if article_label:
			article_label.position = Vector2(70, 40)
			article_label.size = Vector2(window_size.x - 140, window_size.y - 145)

		if agree_button:
			agree_button.size = Vector2(180, 44)
			agree_button.position = Vector2(window_size.x / 2.0 + 40, window_size.y - 68)

		no_button.size = Vector2(180, 44)
		no_button.position = Vector2(window_size.x / 2.0 - 220, window_size.y - 68)
		return

	title_label.position = Vector2(230, 18)
	title_label.size = Vector2(396, 28)
	title_label.text = "PINBALL SOUHLASU"

	score_label.position = Vector2(44, 50)
	score_label.size = Vector2(240, 30)

	target_label.position = Vector2(window_size.x / 2 - 170, 48)
	target_label.size = Vector2(340, 34)

	status_label.position = Vector2(window_size.x / 2 - 260, 76)
	status_label.size = Vector2(520, 42)

	if launch_button:
		launch_button.size = Vector2(130, 42)
		launch_button.position = Vector2(window_size.x / 2.0 - 65, window_size.y - 64)

	no_button.size = Vector2(180, 42)
	no_button.position = Vector2(window_size.x - 220, window_size.y - 64)

	update_system_control_label_position()


func setup_bumpers():
	var playfield = get_playfield_rect()

	bumpers = [
		{"position": playfield.position + Vector2(playfield.size.x * 0.30, 92), "radius": 11.0, "score": 20, "label": "+20"},
		{"position": playfield.position + Vector2(playfield.size.x * 0.68, 104), "radius": 12.0, "score": 20, "label": "+20"},
		{"position": playfield.position + Vector2(playfield.size.x * 0.50, 184), "radius": 16.0, "score": 35, "label": "+35"},
		{"position": playfield.position + Vector2(playfield.size.x * 0.24, 214), "radius": 10.0, "score": 12, "label": "+12"},
		{"position": playfield.position + Vector2(playfield.size.x * 0.76, 214), "radius": 10.0, "score": 12, "label": "+12"},
		{"position": playfield.position + Vector2(playfield.size.x * 0.32, 286), "radius": 11.0, "score": 16, "label": "+16"},
		{"position": playfield.position + Vector2(playfield.size.x * 0.68, 286), "radius": 11.0, "score": 16, "label": "+16"},
	]

	posts = [
		{"position": playfield.position + Vector2(playfield.size.x * 0.20, 130), "radius": 4.0},
		{"position": playfield.position + Vector2(playfield.size.x * 0.82, 142), "radius": 4.0},
		{"position": playfield.position + Vector2(playfield.size.x * 0.43, 132), "radius": 4.0},
		{"position": playfield.position + Vector2(playfield.size.x * 0.58, 138), "radius": 4.0},
		{"position": playfield.position + Vector2(playfield.size.x * 0.28, 168), "radius": 4.0},
		{"position": playfield.position + Vector2(playfield.size.x * 0.72, 168), "radius": 4.0},
		{"position": playfield.position + Vector2(playfield.size.x * 0.40, 236), "radius": 4.5},
		{"position": playfield.position + Vector2(playfield.size.x * 0.60, 236), "radius": 4.5},
		{"position": playfield.position + Vector2(playfield.size.x * 0.50, 260), "radius": 4.0},
		{"position": playfield.position + Vector2(playfield.size.x * 0.20, 274), "radius": 4.5},
		{"position": playfield.position + Vector2(playfield.size.x * 0.80, 274), "radius": 4.5},
		{"position": playfield.position + Vector2(playfield.size.x * 0.34, 304), "radius": 4.0},
		{"position": playfield.position + Vector2(playfield.size.x * 0.66, 304), "radius": 4.0},
	]

	bumper_flash.clear()


func reset_ball():
	ball_position = get_launch_position()
	ball_velocity = Vector2.ZERO
	ball_launched = false
	launcher_stuck_time = 0.0
	ball_stuck_time = 0.0
	last_ball_position = ball_position

	if launch_button:
		launch_button.disabled = unlocked


func update_flippers(delta):
	var previous_left_lift = left_flipper_lift
	var previous_right_lift = right_flipper_lift

	if flipper_timer_left > 0:
		flipper_timer_left -= delta

		if flipper_timer_left <= 0 and not left_flipper_held:
			left_flipper_active = false

	if flipper_timer_right > 0:
		flipper_timer_right -= delta

		if flipper_timer_right <= 0 and not right_flipper_held:
			right_flipper_active = false

	var left_target = 1.0 if left_flipper_active else 0.0
	var right_target = 1.0 if right_flipper_active else 0.0

	left_flipper_lift = move_toward(left_flipper_lift, left_target, flipper_animation_speed * delta)
	right_flipper_lift = move_toward(right_flipper_lift, right_target, flipper_animation_speed * delta)

	var safe_delta = max(delta, 0.0001)
	left_flipper_swing_speed = (left_flipper_lift - previous_left_lift) / safe_delta
	right_flipper_swing_speed = (right_flipper_lift - previous_right_lift) / safe_delta


func update_ball(delta):
	var remaining = min(delta, 0.05)

	while remaining > 0.0 and ball_launched and not unlocked:
		var step = min(physics_step, remaining)
		remaining -= step
		integrate_ball(step)

		if ball_velocity.length() > max_ball_speed:
			ball_velocity = ball_velocity.normalized() * max_ball_speed

		handle_bottom_drain()

	if ball_launched and not unlocked:
		update_stuck_detector(delta)


func integrate_ball(delta):
	ball_velocity.y += gravity * delta
	ball_velocity *= pow(ball_damping_per_second, delta)
	ball_position += ball_velocity * delta

	handle_wall_collisions()

	if handle_launcher_lane_recovery(delta):
		return

	handle_lower_side_guard_collisions()
	handle_bumper_collisions()
	handle_post_collisions()
	handle_flipper_collisions()


func handle_wall_collisions():
	var playfield = get_playfield_rect()
	var play_left = playfield.position.x
	var play_right = playfield.position.x + playfield.size.x
	var play_top = playfield.position.y
	var lane_x = play_right - launcher_lane_width
	var lane_gate_y = play_top + launcher_lane_gap_height

	if ball_position.x - ball_radius < play_left:
		ball_position.x = play_left + ball_radius
		ball_velocity.x = abs(ball_velocity.x) * wall_restitution
		ball_velocity.y *= 0.985

	if ball_position.x + ball_radius > play_right:
		ball_position.x = play_right - ball_radius
		ball_velocity.x = -abs(ball_velocity.x) * wall_restitution
		ball_velocity.y *= 0.985

	if ball_position.y - ball_radius < play_top:
		ball_position.y = play_top + ball_radius
		ball_velocity.y = abs(ball_velocity.y) * 0.78
		ball_velocity.x *= 0.96

	if ball_position.x > lane_x + ball_radius and ball_position.y <= lane_gate_y + ball_radius * 2.0:
		release_ball_from_launcher(lane_x, lane_gate_y)
		return

	if ball_position.y - ball_radius > lane_gate_y:
		if ball_position.x >= lane_x and ball_position.x - ball_radius < lane_x:
			ball_position.x = lane_x + ball_radius
			ball_velocity.x = abs(ball_velocity.x) * wall_restitution
			ball_velocity.y *= 0.99
		elif ball_position.x < lane_x and ball_position.x + ball_radius > lane_x:
			ball_position.x = lane_x - ball_radius
			ball_velocity.x = -abs(ball_velocity.x) * wall_restitution
			ball_velocity.y *= 0.99


func handle_lower_side_guard_collisions():
	for guard in get_lower_side_guard_segments():
		var start: Vector2 = guard[0]
		var end: Vector2 = guard[1]
		var push_x: float = guard[2]
		var min_x = min(start.x, end.x)
		var max_x = max(start.x, end.x)

		if ball_position.x < min_x or ball_position.x > max_x:
			continue

		var t = clamp((ball_position.x - start.x) / (end.x - start.x), 0.0, 1.0)
		var guard_y = lerp(start.y, end.y, t)

		if ball_position.y + ball_radius <= guard_y:
			continue

		ball_position.y = guard_y - ball_radius
		ball_velocity.y = -abs(ball_velocity.y) * 0.46 - 35.0
		ball_velocity.x += push_x


func update_stuck_detector(delta):
	var playfield = get_playfield_rect()
	var moved_far_enough = ball_position.distance_to(last_ball_position) > 4.0
	var slow_enough = ball_velocity.length() < 115.0
	var in_upper_trap_zone = ball_position.y < playfield.position.y + 112.0

	if slow_enough and (not moved_far_enough or in_upper_trap_zone):
		ball_stuck_time += delta
	else:
		ball_stuck_time = 0.0
		last_ball_position = ball_position

	if ball_stuck_time > 0.42:
		nudge_stuck_ball()


func nudge_stuck_ball():
	var playfield = get_playfield_rect()
	var lane_x = playfield.position.x + playfield.size.x - launcher_lane_width
	var center_x = playfield.position.x + playfield.size.x / 2.0

	if ball_position.x > lane_x + ball_radius:
		reset_launcher_after_weak_shot()
		return

	var direction = 1.0 if ball_position.x < center_x else -1.0
	var vertical_push = 260.0 if ball_position.y < playfield.position.y + 112.0 else -280.0
	ball_position += Vector2(direction * 10.0, 8.0 if vertical_push > 0.0 else -8.0)
	ball_velocity = Vector2(direction * 210.0, vertical_push)
	ball_stuck_time = 0.0
	last_ball_position = ball_position


func handle_bottom_drain():
	var playfield = get_playfield_rect()
	var bottom_y = playfield.position.y + playfield.size.y
	var lane_x = playfield.position.x + playfield.size.x - launcher_lane_width
	var drain_gap = get_flipper_drain_gap()
	var over_bottom = ball_position.y + ball_radius > bottom_y

	if not over_bottom:
		return

	if ball_position.x > lane_x + ball_radius:
		reset_launcher_after_weak_shot()
		return

	if ball_position.x >= drain_gap.x and ball_position.x <= drain_gap.y:
		drain_ball()
		return

	ball_position.y = bottom_y - ball_radius
	ball_velocity.y = -abs(ball_velocity.y) * 0.34

	if ball_position.x < playfield.position.x + playfield.size.x / 2.0:
		ball_velocity.x += 95.0
	else:
		ball_velocity.x -= 95.0


func reset_launcher_after_weak_shot():
	ball_position = get_launch_position()
	ball_velocity = Vector2.ZERO
	ball_launched = false
	launcher_stuck_time = 0.0
	ball_stuck_time = 0.0
	last_ball_position = ball_position
	status_label.text = "Výstřel byl slabý. Zkus Výstřel / SPACE znovu."

	if launch_button:
		launch_button.disabled = unlocked


func release_ball_from_launcher(lane_x: float, lane_gate_y: float):
	ball_position = Vector2(lane_x - ball_radius - 10.0, lane_gate_y + ball_radius + 18.0)
	ball_velocity = Vector2(-235.0, 180.0)
	launcher_stuck_time = 0.0
	ball_stuck_time = 0.0
	last_ball_position = ball_position


func handle_launcher_lane_recovery(delta) -> bool:
	var playfield = get_playfield_rect()
	var lane_x = playfield.position.x + playfield.size.x - launcher_lane_width
	var bottom_y = playfield.position.y + playfield.size.y
	var ball_in_lane = ball_position.x > lane_x + ball_radius

	if not ball_in_lane:
		launcher_stuck_time = 0.0
		return false

	if ball_position.y < bottom_y - 44.0 and ball_velocity.length() < 120.0:
		launcher_stuck_time += delta
	else:
		launcher_stuck_time = 0.0

	if launcher_stuck_time > 0.55:
		reset_launcher_after_weak_shot()
		return true

	return false


func handle_bumper_collisions():
	for bumper in bumpers:
		var center: Vector2 = bumper["position"]
		var radius: float = bumper["radius"]
		var to_ball = ball_position - center
		var distance = to_ball.length()

		if distance > 0 and distance < radius + ball_radius:
			var normal = to_ball.normalized()
			ball_position = center + normal * (radius + ball_radius + 1.0)
			ball_velocity = ball_velocity.bounce(normal) * rubber_restitution + normal * bumper_kick
			add_score(bumper["score"])
			bumper_flash[center] = 0.18


func handle_post_collisions():
	for post in posts:
		var center: Vector2 = post["position"]
		var radius: float = post["radius"]
		var to_ball = ball_position - center
		var distance = to_ball.length()

		if distance > 0 and distance < radius + ball_radius:
			var normal = to_ball.normalized()
			ball_position = center + normal * (radius + ball_radius + 0.5)
			ball_velocity = ball_velocity.bounce(normal) * 0.86 + normal * 70.0


func handle_flipper_collisions():
	handle_single_flipper_collision(get_left_flipper_points(), left_flipper_active, left_flipper_swing_speed, 210.0)
	handle_single_flipper_collision(get_right_flipper_points(), right_flipper_active, right_flipper_swing_speed, -210.0)


func handle_single_flipper_collision(points: Array, active: bool, swing_speed: float, impulse_x: float):
	var closest = get_closest_point_on_segment(ball_position, points[0], points[1])
	var to_ball = ball_position - closest
	var distance = to_ball.length()
	var hit_distance = ball_radius + flipper_hit_radius

	if distance > hit_distance:
		return

	var normal = to_ball.normalized()

	if normal == Vector2.ZERO:
		normal = Vector2.UP

	ball_position = closest + normal * (hit_distance + 0.5)

	var hit_t = get_segment_hit_ratio(closest, points[0], points[1])
	var tip_boost = lerp(0.72, 1.12, hit_t)
	var swing_strength = clamp(swing_speed / flipper_animation_speed, 0.0, 1.0)

	if active and swing_strength > 0.05:
		ball_velocity = ball_velocity.bounce(normal) * 0.24
		ball_velocity.x += impulse_x * tip_boost
		ball_velocity.y = min(ball_velocity.y, -flipper_kick * tip_boost)
		ball_velocity.y -= 160.0 * swing_strength
	elif active:
		ball_velocity = ball_velocity.bounce(normal) * 0.64
		ball_velocity.y = min(ball_velocity.y, -250.0)
		ball_velocity.x += impulse_x * 0.22
	else:
		ball_velocity = ball_velocity.bounce(normal) * 0.72
		ball_velocity.y = min(ball_velocity.y, -150.0)


func get_closest_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> Vector2:
	var segment = segment_end - segment_start
	var segment_length_squared = segment.length_squared()

	if segment_length_squared == 0:
		return segment_start

	var t = clamp((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return segment_start + segment * t


func get_segment_hit_ratio(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment = segment_end - segment_start
	var segment_length_squared = segment.length_squared()

	if segment_length_squared == 0:
		return 0.0

	return clamp((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)


func drain_ball():
	balls_left -= 1
	GameState.add_system_control(5)
	update_system_control_label()

	if balls_left <= 0 and not unlocked:
		ball_launched = false

		if launch_button:
			launch_button.disabled = true

		status_label.text = "Kuličky došly. Nepodařilo se získat 500 skóre."
		score_label.text = "Skóre: %d\nKuličky: 0" % score

		await get_tree().create_timer(1.4).timeout
		level_failed.emit()
		return

	reset_ball()
	update_labels()


func add_score(amount):
	if unlocked:
		return

	score += amount
	update_labels()

	if score >= target_score:
		unlock_no_button()


func unlock_no_button():
	unlocked = true
	ball_launched = false

	no_button.text = "Souhlasím"
	no_button.disabled = false
	LevelUtils.style_green_button(no_button)

	if launch_button:
		launch_button.disabled = true

	GameState.reduce_system_control(5)
	update_system_control_label()
	update_labels()


func update_bumper_flash(delta):
	var expired = []

	for key in bumper_flash.keys():
		bumper_flash[key] -= delta

		if bumper_flash[key] <= 0:
			expired.append(key)

	for key in expired:
		bumper_flash.erase(key)


func update_labels():
	score_label.text = "Skóre: %d\nKuličky: %d" % [score, balls_left]
	target_label.text = "Cíl: %d bodů pro odemčení SOUHLASÍM" % target_score

func get_playfield_rect() -> Rect2:
	var width = min(500.0, window_size.x - 300.0)
	var height = min(328.0, window_size.y - 192.0)
	var x = window_size.x / 2.0 - width / 2.0
	var y = 112.0
	return Rect2(Vector2(x, y), Vector2(width, height))


func get_flipper_drain_gap() -> Vector2:
	var playfield = get_playfield_rect()
	var left_pivot_x = playfield.position.x + flipper_pivot_offset
	var right_pivot_x = playfield.position.x + playfield.size.x - flipper_pivot_offset
	var left_tip_x = left_pivot_x + cos(deg_to_rad(-9.0)) * flipper_length
	var right_tip_x = right_pivot_x + cos(deg_to_rad(189.0)) * flipper_length
	return Vector2(left_tip_x + 2.0, right_tip_x - 2.0)


func get_lower_side_guard_segments() -> Array:
	var playfield = get_playfield_rect()
	var lane_x = playfield.position.x + playfield.size.x - launcher_lane_width
	var left_flipper = get_left_flipper_points()
	var right_flipper = get_right_flipper_points()
	var left_pivot: Vector2 = left_flipper[0]
	var right_pivot: Vector2 = right_flipper[0]

	return [
		[
			Vector2(playfield.position.x + 2.0, left_pivot.y - 16.0),
			Vector2(left_pivot.x - 12.0, left_pivot.y - 4.0),
			95.0
		],
		[
			Vector2(right_pivot.x + 12.0, right_pivot.y - 4.0),
			Vector2(lane_x - 4.0, right_pivot.y - 16.0),
			-95.0
		],
	]


func get_launch_position() -> Vector2:
	var playfield = get_playfield_rect()
	return Vector2(
		playfield.position.x + playfield.size.x - launcher_lane_width / 2.0,
		playfield.position.y + playfield.size.y - 70.0
	)


func get_left_flipper_points() -> Array:
	var playfield = get_playfield_rect()
	var pivot = Vector2(
		playfield.position.x + flipper_pivot_offset,
		playfield.position.y + playfield.size.y - 48.0
	)
	var angle = lerp(deg_to_rad(-9.0), deg_to_rad(-38.0), left_flipper_lift)
	var tip = pivot + Vector2(cos(angle), sin(angle)) * flipper_length
	return [pivot, tip]


func get_right_flipper_points() -> Array:
	var playfield = get_playfield_rect()
	var pivot = Vector2(
		playfield.position.x + playfield.size.x - flipper_pivot_offset,
		playfield.position.y + playfield.size.y - 48.0
	)
	var angle = lerp(deg_to_rad(189.0), deg_to_rad(218.0), right_flipper_lift)
	var tip = pivot + Vector2(cos(angle), sin(angle)) * flipper_length
	return [pivot, tip]


func _on_launch_pressed():
	if screen_state != "pinball":
		return

	if unlocked or ball_launched:
		return

	ball_launched = true
	ball_position = get_launch_position()
	ball_velocity = launch_power + Vector2(randf_range(-14, 16), randf_range(-35, 8))
	launcher_stuck_time = 0.0
	ball_stuck_time = 0.0
	last_ball_position = ball_position

	if launch_button:
		launch_button.disabled = true


func activate_left_flipper():
	left_flipper_active = true
	flipper_timer_left = flipper_duration


func activate_right_flipper():
	right_flipper_active = true
	flipper_timer_right = flipper_duration


func _on_no_pressed():
	if screen_state == "article":
		level_failed.emit()
		return

	if screen_state != "pinball":
		return

	if not unlocked:
		return

	level_finished.emit()


func update_system_control_label_position():
	LevelUtils.update_system_control_label(control_label, Vector2(window_size.x - 340, 8))


func update_system_control_label():
	LevelUtils.refresh_system_control_label(control_label)


func _draw():
	if screen_state != "pinball":
		return

	draw_playfield()
	draw_bumpers()
	draw_posts()
	draw_flippers()
	draw_ball()


func draw_playfield():
	var panel = get_playfield_rect()
	var lane_x = panel.position.x + panel.size.x - launcher_lane_width
	var launcher = get_launch_position()
	var bottom_y = panel.position.y + panel.size.y
	var drain_gap = get_flipper_drain_gap()
	var guard_segments = get_lower_side_guard_segments()
	var outer = Rect2(panel.position - Vector2(12, 10), panel.size + Vector2(24, 20))

	var xp_blue = Color(0.18, 0.48, 0.92)
	var xp_blue_light = Color(0.58, 0.78, 1.0)
	var field_light = Color(0.86, 0.94, 1.0)
	var field_mid = Color(0.70, 0.84, 1.0)
	var field_deep = Color(0.44, 0.64, 0.94)

	draw_rect(Rect2(outer.position + Vector2(8, 10), outer.size), Color(0, 0, 0, 0.22), true)
	draw_rect(outer, xp_blue, true)
	draw_rect(Rect2(outer.position + Vector2(3, 3), outer.size - Vector2(6, 6)), xp_blue_light, false, 2.0)
	draw_rect(outer, Color(0.05, 0.20, 0.52), false, 2.0)
	draw_rect(panel, field_light, true)

	draw_poly([
		panel.position + Vector2(panel.size.x * 0.50, panel.size.y - 8.0),
		panel.position + Vector2(18.0, 14.0),
		panel.position + Vector2(panel.size.x * 0.34, 14.0),
		panel.position + Vector2(panel.size.x * 0.43, panel.size.y - 8.0),
	], Color(0.76, 0.88, 1.0))

	draw_poly([
		panel.position + Vector2(panel.size.x * 0.50, panel.size.y - 8.0),
		panel.position + Vector2(panel.size.x * 0.66, 14.0),
		panel.position + Vector2(panel.size.x - 18.0, 14.0),
		panel.position + Vector2(panel.size.x * 0.57, panel.size.y - 8.0),
	], Color(0.64, 0.80, 1.0))

	draw_poly([
		panel.position + Vector2(panel.size.x * 0.43, 0.0),
		panel.position + Vector2(panel.size.x * 0.57, 0.0),
		panel.position + Vector2(panel.size.x * 0.54, panel.size.y),
		panel.position + Vector2(panel.size.x * 0.46, panel.size.y),
	], Color(0.55, 0.75, 1.0, 0.52))

	draw_poly([
		panel.position + Vector2(8.0, 14.0),
		panel.position + Vector2(70.0, 14.0),
		panel.position + Vector2(44.0, 76.0),
		panel.position + Vector2(28.0, 166.0),
		panel.position + Vector2(44.0, 238.0),
		panel.position + Vector2(18.0, panel.size.y - 24.0),
		panel.position + Vector2(8.0, panel.size.y - 24.0),
	], Color(0.16, 0.38, 0.82))

	draw_poly([
		panel.position + Vector2(panel.size.x - 8.0, 14.0),
		panel.position + Vector2(panel.size.x - 70.0, 14.0),
		panel.position + Vector2(panel.size.x - 44.0, 76.0),
		panel.position + Vector2(panel.size.x - 28.0, 166.0),
		panel.position + Vector2(panel.size.x - 44.0, 238.0),
		panel.position + Vector2(panel.size.x - 18.0, panel.size.y - 24.0),
		panel.position + Vector2(panel.size.x - 8.0, panel.size.y - 24.0),
	], Color(0.16, 0.38, 0.82))

	draw_poly([
		panel.position + Vector2(20.0, 72.0),
		panel.position + Vector2(48.0, 96.0),
		panel.position + Vector2(45.0, 168.0),
		panel.position + Vector2(28.0, 184.0),
	], field_deep)

	draw_poly([
		panel.position + Vector2(panel.size.x - 20.0, 72.0),
		panel.position + Vector2(panel.size.x - 48.0, 96.0),
		panel.position + Vector2(panel.size.x - 45.0, 168.0),
		panel.position + Vector2(panel.size.x - 28.0, 184.0),
	], field_mid)

	draw_line(Vector2(panel.position.x, bottom_y), Vector2(drain_gap.x, bottom_y), Color(0.70, 0.72, 0.76), 2.0)
	draw_line(Vector2(drain_gap.y, bottom_y), Vector2(panel.position.x + panel.size.x, bottom_y), Color(0.70, 0.72, 0.76), 2.0)

	draw_rect(
		Rect2(Vector2(drain_gap.x, bottom_y - 7), Vector2(drain_gap.y - drain_gap.x, 14)),
		Color(0.12, 0.13, 0.14, 0.22),
		true
	)

	for guard in guard_segments:
		draw_line(guard[0], guard[1], Color(0.88, 0.88, 0.92), 5.0)
		draw_line(guard[0], guard[1], Color(0.52, 0.50, 0.72), 2.0)

	draw_target_lane(panel.position + Vector2(panel.size.x * 0.36, 34.0))
	draw_target_lane(panel.position + Vector2(panel.size.x * 0.50, 26.0))
	draw_target_lane(panel.position + Vector2(panel.size.x * 0.64, 34.0))
	draw_bonus_light(panel.position + Vector2(34.0, 120.0), Color(1.0, 0.84, 0.26))
	draw_bonus_light(panel.position + Vector2(panel.size.x - 34.0, 120.0), Color(1.0, 0.84, 0.26))
	draw_bonus_light(panel.position + Vector2(48.0, 246.0), Color(0.50, 0.85, 1.0))
	draw_bonus_light(panel.position + Vector2(panel.size.x - 48.0, 246.0), Color(0.50, 0.85, 1.0))
	draw_center_badge(panel.position + Vector2(panel.size.x / 2.0, panel.size.y * 0.58))
	draw_arrow_stack(panel.position + Vector2(panel.size.x / 2.0, panel.size.y - 98.0))
	draw_mini_flipper(panel.position + Vector2(68.0, 56.0), deg_to_rad(58.0))
	draw_mini_flipper(panel.position + Vector2(panel.size.x - 58.0, 72.0), deg_to_rad(-28.0))

	draw_line(
		Vector2(lane_x, panel.position.y + launcher_lane_gap_height),
		Vector2(lane_x, panel.position.y + panel.size.y - 14),
		Color(0.10, 0.11, 0.14),
		6.0
	)
	draw_line(
		Vector2(lane_x + 4.0, panel.position.y + launcher_lane_gap_height),
		Vector2(lane_x + 4.0, panel.position.y + panel.size.y - 18),
		Color(0.48, 0.50, 0.58),
		2.0
	)

	draw_arc(Vector2(lane_x + 15, panel.position.y + launcher_lane_gap_height), 15, PI, PI * 1.5, 16, Color(0.70, 0.72, 0.78), 2.0)
	draw_plunger_meter(panel, lane_x)
	draw_circle(launcher, 13, Color(0.82, 0.86, 0.92))
	draw_arc(launcher, 20, -PI * 0.7, PI * 0.7, 28, Color(0.77, 0.79, 0.86), 2.0)


func draw_poly(points: Array, color: Color):
	draw_colored_polygon(PackedVector2Array(points), color)


func draw_target_lane(center: Vector2):
	draw_circle(center + Vector2(0, -15), 6.0, Color(0.10, 0.58, 0.30))
	draw_circle(center + Vector2(0, -15), 3.8, Color(0.42, 0.95, 0.58))
	draw_rect(Rect2(center + Vector2(-5, -3), Vector2(10, 31)), Color(0.82, 0.82, 0.86), true)
	draw_rect(Rect2(center + Vector2(-2, 1), Vector2(4, 22)), Color(0.18, 0.17, 0.24), true)


func draw_bonus_light(center: Vector2, color: Color):
	draw_circle(center + Vector2(2, 2), 7.0, Color(0, 0, 0, 0.22))
	draw_circle(center, 7.0, Color(0.95, 0.72, 0.18))
	draw_circle(center, 4.3, color)
	draw_circle(center + Vector2(-2, -2), 2.0, Color(1, 1, 1, 0.75))


func draw_center_badge(center: Vector2):
	draw_poly([
		center + Vector2(-58.0, -18.0),
		center + Vector2(58.0, -18.0),
		center + Vector2(45.0, 18.0),
		center + Vector2(-45.0, 18.0),
	], Color(0.24, 0.72, 0.52))

	draw_poly([
		center + Vector2(-50.0, -10.0),
		center + Vector2(50.0, -10.0),
		center + Vector2(39.0, 10.0),
		center + Vector2(-39.0, 10.0),
	], Color(0.80, 0.94, 0.84))

	draw_line(center + Vector2(-38.0, 0.0), center + Vector2(38.0, 0.0), Color(0.92, 0.25, 0.40), 4.0)


func draw_arrow_stack(center: Vector2):
	for i in range(3):
		var y = center.y + i * 25.0

		draw_poly([
			Vector2(center.x - 24.0, y + 10.0),
			Vector2(center.x, y - 8.0),
			Vector2(center.x + 24.0, y + 10.0),
			Vector2(center.x + 17.0, y + 20.0),
			Vector2(center.x, y + 8.0),
			Vector2(center.x - 17.0, y + 20.0),
		], Color(0.28, 0.82, 0.56))

		draw_line(Vector2(center.x - 18.0, y + 11.0), Vector2(center.x, y - 2.0), Color(0.86, 1.0, 0.90), 2.0)
		draw_line(Vector2(center.x, y - 2.0), Vector2(center.x + 18.0, y + 11.0), Color(0.86, 1.0, 0.90), 2.0)


func draw_mini_flipper(center: Vector2, angle: float):
	var direction = Vector2(cos(angle), sin(angle))
	var start = center - direction * 15.0
	var end = center + direction * 15.0

	draw_line(start, end, Color(0.70, 0.90, 1.0), 10.0)
	draw_line(start, end, Color(0.16, 0.62, 0.82), 6.0)
	draw_circle(start, 4.0, Color(0.82, 0.88, 0.94))
	draw_circle(end, 4.0, Color(0.82, 0.88, 0.94))


func draw_plunger_meter(panel: Rect2, lane_x: float):
	var meter = Rect2(Vector2(lane_x + 27.0, panel.position.y + panel.size.y - 86.0), Vector2(10.0, 74.0))

	draw_rect(meter.grow(2.0), Color(0.88, 0.88, 0.84), true)
	draw_rect(meter, Color(0.07, 0.08, 0.10), true)

	for i in range(8):
		var y = meter.position.y + 6.0 + i * 8.0
		draw_line(Vector2(meter.position.x + 1.0, y), Vector2(meter.position.x + meter.size.x - 1.0, y), Color(0.70, 0.78, 0.88), 1.0)

	draw_circle(Vector2(meter.position.x + meter.size.x / 2.0, meter.position.y + meter.size.y + 13.0), 8.0, Color(0.92, 0.12, 0.25))


func draw_bumpers():
	var accent_colors = [
		Color(0.98, 0.85, 0.20),
		Color(0.30, 0.82, 0.55),
		Color(0.98, 0.28, 0.58),
		Color(0.24, 0.75, 0.96),
	]

	var index = 0

	for bumper in bumpers:
		var center: Vector2 = bumper["position"]
		var radius: float = bumper["radius"]
		var flashed = bumper_flash.has(center)
		var accent = accent_colors[index % accent_colors.size()]
		var outer = Color(1.0, 0.92, 0.20) if flashed else Color(0.94, 0.82, 0.24)

		draw_star(center, radius + 7.0, radius + 2.0, 12, outer)
		draw_circle(center + Vector2(3, 4), radius + 2.0, Color(0, 0, 0, 0.20))
		draw_circle(center, radius + 2.0, Color(0.92, 0.92, 0.86))
		draw_circle(center, radius - 2.0, accent)
		draw_circle(center + Vector2(-4, -5), radius * 0.28, Color(1, 1, 1, 0.70))
		draw_arc(center, radius + 2.0, 0, PI * 2, 40, Color(0.20, 0.12, 0.18), 2.0)

		index += 1


func draw_posts():
	var index = 0

	for post in posts:
		var center: Vector2 = post["position"]
		var radius: float = post["radius"]
		var body = Color(0.28, 0.78, 0.94) if index % 2 == 0 else Color(0.98, 0.78, 0.22)

		draw_circle(center + Vector2(2, 2), radius, Color(0, 0, 0, 0.16))
		draw_circle(center, radius, Color(0.92, 0.93, 0.95))
		draw_circle(center, radius * 0.66, body)
		draw_circle(center + Vector2(-2, -2), radius * 0.35, Color(1.0, 1.0, 1.0, 0.78))

		index += 1


func draw_star(center: Vector2, outer_radius: float, inner_radius: float, points: int, color: Color):
	var vertices = PackedVector2Array()

	for i in range(points * 2):
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var angle = -PI / 2.0 + i * PI / points
		vertices.append(center + Vector2(cos(angle), sin(angle)) * radius)

	draw_colored_polygon(vertices, color)


func draw_flippers():
	var active_color = Color(1.0, 0.28, 0.34)
	var idle_color = Color(0.88, 0.18, 0.22)

	var left_color = active_color if left_flipper_active else idle_color
	var right_color = active_color if right_flipper_active else idle_color

	var left_points = get_left_flipper_points()
	var right_points = get_right_flipper_points()

	var left_pivot = left_points[0]
	var left_tip = left_points[1]
	var right_pivot = right_points[0]
	var right_tip = right_points[1]

	draw_line(left_pivot, left_tip, Color(0.92, 0.92, 0.90), 15.0)
	draw_line(right_pivot, right_tip, Color(0.92, 0.92, 0.90), 15.0)
	draw_line(left_pivot, left_tip, left_color, 8.0)
	draw_line(right_pivot, right_tip, right_color, 8.0)

	draw_circle(left_pivot, 9, Color(0.96, 0.96, 0.94))
	draw_circle(right_pivot, 9, Color(0.96, 0.96, 0.94))
	draw_circle(left_pivot, 4, Color(0.70, 0.73, 0.80))
	draw_circle(right_pivot, 4, Color(0.70, 0.73, 0.80))
	draw_circle(left_tip, 5, Color(0.96, 0.96, 0.94))
	draw_circle(right_tip, 5, Color(0.96, 0.96, 0.94))


func draw_ball():
	draw_circle(ball_position + Vector2(3, 4), ball_radius, Color(0, 0, 0, 0.18))
	draw_circle(ball_position, ball_radius, Color(0.86, 0.88, 0.92))
	draw_circle(ball_position + Vector2(-4, -4), 4, Color(1.0, 1.0, 1.0, 0.75))