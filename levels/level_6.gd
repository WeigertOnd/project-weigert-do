extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var no_button = $NoButton

var control_label
var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var claw_hand: Sprite2D
var claw_position = Vector2.ZERO
var claw_moving = false
var claw_direction = 1
var claw_speed = 120.0
var claw_min_x = 100.0
var claw_max_x = 700.0
var claw_descend_start_y = 80.0
var claw_descend_target_y = 350.0
var claw_is_descending = false
var claw_descend_speed = 200.0

var cycle_timer = 0.0
var cycle_duration = 4.0
var descend_delay = 2.0
var descend_delay_timer = 0.0

var caught_count = 0
var escaped_count = 0
var max_attempts = 3


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	caught_count = 0
	escaped_count = 0
	cycle_timer = 0.0
	claw_position = Vector2(claw_min_x, claw_descend_start_y)
	claw_moving = true
	claw_direction = 1
	claw_is_descending = false
	descend_delay_timer = 0.0

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	no_button.visible = true
	no_button.disabled = false
	no_button.text = "Nesouhlasím"
	style_button_soft_xp(no_button)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	update_system_control_label()
	create_claw()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	update_claw(delta)
	check_claw_collision()


func setup_ui():
	background.z_index = 0
	no_button.z_index = 5

	layout_ui()
	last_window_size = window_size

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 10
		add_child(control_label)

	update_system_control_label_position()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	no_button.size = Vector2(160, 40)
	no_button.position = Vector2(window_size.x / 2 - 80, window_size.y - 80)


func create_claw():
	if claw_hand != null:
		return

	claw_hand = Sprite2D.new()
	claw_hand.name = "Claw"
	claw_hand.z_index = 15

	var claw_visual = ColorRect.new()
	claw_visual.size = Vector2(40, 35)
	claw_visual.color = Color(0.2, 0.2, 0.2)
	claw_hand.add_child(claw_visual)

	add_child(claw_hand)
	claw_hand.position = claw_position


func update_claw(delta):
	if not claw_moving:
		return

	if not claw_is_descending:
		cycle_timer += delta

		claw_position.x += claw_direction * claw_speed * delta

		if claw_position.x <= claw_min_x:
			claw_position.x = claw_min_x
			claw_direction = 1
			cycle_timer = 0.0
			descend_delay_timer = descend_delay
		elif claw_position.x >= claw_max_x:
			claw_position.x = claw_max_x
			claw_direction = -1
			cycle_timer = 0.0
			descend_delay_timer = descend_delay

		descend_delay_timer -= delta
		if descend_delay_timer <= 0 and cycle_timer >= 0.5:
			claw_is_descending = true
	else:
		claw_position.y += claw_descend_speed * delta

		if claw_position.y >= claw_descend_target_y:
			claw_position.y = claw_descend_target_y
			claw_is_descending = false
			cycle_timer = 0.0
			descend_delay_timer = 0.5

	if claw_hand:
		claw_hand.position = claw_position


func check_claw_collision():
	if claw_is_descending and claw_hand and no_button:
		var claw_rect = Rect2(claw_position - Vector2(20, 17), Vector2(40, 35))
		var button_rect = Rect2(no_button.position, no_button.size)

		if claw_rect.intersects(button_rect):
			caught_by_claw()


func caught_by_claw():
	caught_count += 1
	claw_moving = false
	no_button.disabled = true

	if caught_count >= max_attempts:
		trigger_game_over()
	else:
		reset_claw_cycle()


func reset_claw_cycle():
	await get_tree().create_timer(0.8).timeout

	claw_position = Vector2(claw_min_x, claw_descend_start_y)
	claw_is_descending = false
	cycle_timer = 0.0
	descend_delay_timer = 0.0
	claw_moving = true
	claw_direction = 1

	no_button.disabled = false


func trigger_game_over():
	no_button.visible = false
	background.color = Color(0.95, 0.82, 0.82)

	await get_tree().create_timer(1.5).timeout

	start_level()


func _on_no_pressed():
	if not claw_moving or no_button.disabled:
		return

	escaped_count += 1
	GameState.reduce_system_control(5)
	update_system_control_label()

	no_button.visible = false
	claw_moving = false
	background.color = Color(0.82, 0.95, 0.82)

	await get_tree().create_timer(1.2).timeout

	level_finished.emit()


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return

	control_label.position = Vector2(window_size.x - 340, window_size.y - 34)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_button_soft_xp(button):
	var normal = make_button_style(
		Color(0.94, 0.94, 0.91),
		Color(0.43, 0.48, 0.58),
		5
	)

	var hover = make_button_style(
		Color(0.98, 0.99, 1.0),
		Color(0.22, 0.47, 0.88),
		5
	)

	var pressed = make_button_style(
		Color(0.76, 0.86, 0.98),
		Color(0.16, 0.33, 0.70),
		5
	)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

	button.add_theme_color_override("font_color", Color(0.04, 0.04, 0.04))
	button.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
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
