extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var no_button = $NoButton

var control_label
var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var claw_hand: Node2D
var claw_arm: ColorRect
var claw_position = Vector2(428, 84)
var claw_width = 170.0
var claw_height = 96.0
var claw_top_y = 84.0
var claw_min_x = 50.0
var claw_max_x = 806.0
var claw_move_step = 34.0
var claw_move_speed = 260.0

var claw_open = true
var claw_descending = false
var grab_down_duration = 0.34
var grab_up_duration = 0.42
var moving_left = false
var moving_right = false
var waiting_for_lifted_click = false
var drop_start_x = 0.0
var drop_sway_phase = 0.0
var drop_sway_strength = 24.0

var instruction_label: Label
var result_label: Label
var left_button: Button
var down_button: Button
var right_button: Button

var target_buttons = []
var agree_buttons = []
var lifted_button: Button
var lifted_button_index = -1
var round_count = 0
var max_rounds = 3
var can_interact = true
var level_completed = false


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	round_count = 0
	claw_position = Vector2(window_size.x / 2, claw_top_y)
	claw_open = true
	claw_descending = false
	moving_left = false
	moving_right = false
	waiting_for_lifted_click = false
	drop_start_x = claw_position.x
	drop_sway_phase = 0.0
	lifted_button = null
	lifted_button_index = -1
	can_interact = true
	level_completed = false

	setup_ui()
	set_control_buttons_disabled(false)
	background.color = Color(0.96, 0.96, 0.92)

	no_button.visible = true
	no_button.disabled = false
	no_button.text = "Nesouhlasím"

	style_button_soft_xp(no_button)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	update_system_control_label()
	create_claw()
	create_target_buttons()
	move_claw_to_x(window_size.x / 2)
	update_instruction_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if can_interact and not claw_descending:
		if moving_left:
			move_claw_by(-claw_move_speed * delta)
		if moving_right:
			move_claw_by(claw_move_speed * delta)


func setup_ui():
	background.z_index = 0
	no_button.z_index = 5

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

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.add_theme_font_size_override("font_size", 14)
		instruction_label.modulate = Color(0.2, 0.2, 0.2)
		instruction_label.z_index = 10
		add_child(instruction_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 16)
		result_label.modulate = Color(0.2, 0.2, 0.2)
		result_label.z_index = 10
		result_label.visible = false
		add_child(result_label)

	if left_button == null or not is_instance_valid(left_button):
		left_button = Button.new()
		left_button.name = "LeftButton"
		left_button.text = "←"
		left_button.z_index = 50
		style_arrow_button(left_button)
		left_button.button_down.connect(_on_left_button_down)
		left_button.button_up.connect(_on_left_button_up)
		left_button.pressed.connect(_on_left_pressed)
		add_child(left_button)

	if down_button == null or not is_instance_valid(down_button):
		down_button = Button.new()
		down_button.name = "DownButton"
		down_button.text = "↓"
		down_button.z_index = 50
		style_arrow_button(down_button)
		down_button.pressed.connect(_on_down_pressed)
		add_child(down_button)

	if right_button == null or not is_instance_valid(right_button):
		right_button = Button.new()
		right_button.name = "RightButton"
		right_button.text = "→"
		right_button.z_index = 50
		style_arrow_button(right_button)
		right_button.button_down.connect(_on_right_button_down)
		right_button.button_up.connect(_on_right_button_up)
		right_button.pressed.connect(_on_right_pressed)
		add_child(right_button)

	layout_ui()
	last_window_size = window_size
	update_system_control_label_position()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	if left_button:
		left_button.size = Vector2(76, 46)
		left_button.position = Vector2(window_size.x / 2 - 128, window_size.y - 72)

	if down_button:
		down_button.size = Vector2(76, 46)
		down_button.position = Vector2(window_size.x / 2 - 38, window_size.y - 72)

	if right_button:
		right_button.size = Vector2(76, 46)
		right_button.position = Vector2(window_size.x / 2 + 52, window_size.y - 72)

	if instruction_label:
		instruction_label.size = Vector2(window_size.x - 100, 40)
		instruction_label.position = Vector2(50, 30)

	if result_label:
		result_label.size = Vector2(window_size.x - 100, 50)
		result_label.position = Vector2(50, window_size.y / 2 - 100)

	layout_target_buttons()
	update_claw_bounds()
	move_claw_to_x(claw_position.x)


func create_claw():
	if claw_arm == null or not is_instance_valid(claw_arm):
		claw_arm = ColorRect.new()
		claw_arm.name = "ClawArm"
		claw_arm.color = Color(0.12, 0.12, 0.12)
		claw_arm.z_index = 14
		add_child(claw_arm)

	if claw_hand == null or not is_instance_valid(claw_hand):
		claw_hand = Node2D.new()
		claw_hand.name = "ClawHand"
		claw_hand.z_index = 32
		add_child(claw_hand)

		var wrist = ColorRect.new()
		wrist.name = "Wrist"
		wrist.size = Vector2(30, 38)
		wrist.color = Color(0.10, 0.10, 0.10)
		wrist.position = Vector2(-15, -30)
		claw_hand.add_child(wrist)

		var palm = ColorRect.new()
		palm.name = "Palm"
		palm.size = Vector2(86, 44)
		palm.color = Color(0.15, 0.15, 0.15)
		palm.position = Vector2(-43, 0)
		claw_hand.add_child(palm)

		var palm_highlight = ColorRect.new()
		palm_highlight.name = "PalmHighlight"
		palm_highlight.size = Vector2(78, 8)
		palm_highlight.color = Color(0.23, 0.23, 0.23)
		palm_highlight.position = Vector2(-39, 4)
		claw_hand.add_child(palm_highlight)

		for i in range(3):
			var knuckle = ColorRect.new()
			knuckle.name = "Knuckle" + str(i)
			knuckle.size = Vector2(14, 10)
			knuckle.color = Color(0.08, 0.08, 0.08)
			knuckle.position = Vector2(-28 + i * 21, 30)
			claw_hand.add_child(knuckle)

		var left_finger = ColorRect.new()
		left_finger.name = "LeftFinger"
		left_finger.size = Vector2(28, 58)
		left_finger.color = Color(0.18, 0.18, 0.18)
		left_finger.position = Vector2(-68, 34)
		claw_hand.add_child(left_finger)

		var right_finger = ColorRect.new()
		right_finger.name = "RightFinger"
		right_finger.size = Vector2(28, 58)
		right_finger.color = Color(0.18, 0.18, 0.18)
		right_finger.position = Vector2(40, 34)
		claw_hand.add_child(right_finger)

		var left_tip = ColorRect.new()
		left_tip.name = "LeftTip"
		left_tip.size = Vector2(34, 12)
		left_tip.color = Color(0.08, 0.08, 0.08)
		left_tip.position = Vector2(-72, 88)
		claw_hand.add_child(left_tip)

		var right_tip = ColorRect.new()
		right_tip.name = "RightTip"
		right_tip.size = Vector2(34, 12)
		right_tip.color = Color(0.08, 0.08, 0.08)
		right_tip.position = Vector2(38, 88)
		claw_hand.add_child(right_tip)

	update_claw_position()
	draw_claw_state()


func create_target_buttons():
	for btn in agree_buttons:
		if btn and is_instance_valid(btn):
			btn.queue_free()
	agree_buttons.clear()
	target_buttons.clear()

	for i in range(3):
		var btn = Button.new()
		btn.name = "AgreeButton" + str(i)
		btn.text = "Souhlasím"
		btn.z_index = 5
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		style_button_soft_xp(btn)
		btn.pressed.connect(_on_target_button_pressed.bind(btn))
		add_child(btn)

		agree_buttons.append(btn)
		target_buttons.append(btn)

	no_button.z_index = 5
	no_button.focus_mode = Control.FOCUS_NONE
	no_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_buttons.append(no_button)

	shuffle_target_buttons()
	layout_target_buttons()
	reset_target_button_modulates()


func layout_target_buttons():
	if target_buttons.is_empty():
		return

	var button_width = 140.0
	var button_height = 42.0
	var spacing = 14.0
	var total_width = button_width * 4.0 + spacing * 3.0
	var start_x = window_size.x / 2 - total_width / 2
	var target_y = window_size.y - 150.0

	for i in range(target_buttons.size()):
		var btn = target_buttons[i]
		if btn and is_instance_valid(btn):
			if btn == lifted_button and (waiting_for_lifted_click or claw_descending):
				continue

			btn.size = Vector2(button_width, button_height)
			btn.position = Vector2(start_x + i * (button_width + spacing), target_y)


func update_claw_position():
	if claw_hand and is_instance_valid(claw_hand):
		claw_hand.position = claw_position

	if claw_arm and is_instance_valid(claw_arm):
		claw_arm.position = Vector2(claw_position.x - 7.0, 58.0)
		claw_arm.size = Vector2(14.0, max(0.0, claw_position.y - 58.0))

	update_lifted_button_position()


func draw_claw_state():
	if not claw_hand or not is_instance_valid(claw_hand):
		return

	var left_finger = claw_hand.get_node_or_null("LeftFinger")
	var right_finger = claw_hand.get_node_or_null("RightFinger")
	var left_tip = claw_hand.get_node_or_null("LeftTip")
	var right_tip = claw_hand.get_node_or_null("RightTip")

	if claw_open:
		if left_finger:
			left_finger.position.x = -68
			left_finger.rotation_degrees = -8
		if right_finger:
			right_finger.position.x = 40
			right_finger.rotation_degrees = 8
		if left_tip:
			left_tip.position.x = -72
			left_tip.rotation_degrees = -8
		if right_tip:
			right_tip.position.x = 38
			right_tip.rotation_degrees = 8
	else:
		if left_finger:
			left_finger.position.x = -48
			left_finger.rotation_degrees = 0
		if right_finger:
			right_finger.position.x = 20
			right_finger.rotation_degrees = 0
		if left_tip:
			left_tip.position.x = -50
			left_tip.rotation_degrees = 0
		if right_tip:
			right_tip.position.x = 16
			right_tip.rotation_degrees = 0


func _on_left_pressed():
	if can_interact and not claw_descending:
		move_claw_by(-claw_move_step)


func _on_left_button_down():
	moving_left = true


func _on_left_button_up():
	moving_left = false


func _on_down_pressed():
	if can_interact and not claw_descending:
		grab_attempt()


func _on_right_pressed():
	if can_interact and not claw_descending:
		move_claw_by(claw_move_step)


func _on_right_button_down():
	moving_right = true


func _on_right_button_up():
	moving_right = false


func grab_attempt():
	if target_buttons.is_empty():
		return

	can_interact = false
	claw_descending = true
	moving_left = false
	moving_right = false
	set_control_buttons_disabled(true)
	claw_open = false
	draw_claw_state()

	drop_start_x = claw_position.x
	drop_sway_phase = randf_range(0.0, PI * 2.0)
	var target_y = get_target_drop_y()

	var down_tween = create_tween()
	down_tween.set_ease(Tween.EASE_IN)
	down_tween.set_trans(Tween.TRANS_QUAD)
	down_tween.tween_method(Callable(self, "set_claw_drop_y"), claw_position.y, target_y, grab_down_duration)
	await down_tween.finished

	var caught_index = get_caught_target_index()
	if caught_index >= 0:
		await lift_caught_button(caught_index)
		return

	missed_button()

	var up_tween = create_tween()
	up_tween.set_ease(Tween.EASE_OUT)
	up_tween.set_trans(Tween.TRANS_QUAD)
	up_tween.tween_method(Callable(self, "set_claw_y"), claw_position.y, claw_top_y, grab_up_duration)
	await up_tween.finished

	claw_open = true
	claw_descending = false
	draw_claw_state()

	if not level_completed and round_count < max_rounds and result_label.visible:
		await get_tree().create_timer(0.65).timeout
		result_label.visible = false
		background.color = Color(0.96, 0.96, 0.92)
		can_interact = true
		set_control_buttons_disabled(false)


func set_claw_y(new_y: float):
	claw_position.y = new_y
	update_claw_position()


func set_claw_drop_y(new_y: float):
	var target_y = get_target_drop_y()
	var distance = max(1.0, target_y - claw_top_y)
	var progress = clamp((new_y - claw_top_y) / distance, 0.0, 1.0)
	var sway = sin(drop_sway_phase + progress * PI * 2.4) * drop_sway_strength * progress

	claw_position.x = clamp(drop_start_x + sway, claw_min_x, claw_max_x)
	claw_position.y = new_y
	update_claw_position()


func set_claw_y_with_lifted_button(new_y: float):
	claw_position.y = new_y
	update_claw_position()
	update_lifted_button_position()


func get_caught_target_index() -> int:
	if claw_hand == null or not is_instance_valid(claw_hand):
		return -1

	var claw_rect = Rect2(claw_position - Vector2(claw_width / 2, 0), Vector2(claw_width, claw_height))

	for i in range(target_buttons.size()):
		var btn = target_buttons[i]
		if btn and is_instance_valid(btn):
			var button_rect = Rect2(btn.position, btn.size)
			if claw_rect.intersects(button_rect):
				return i

	return -1


func lift_caught_button(index: int):
	lifted_button_index = index
	lifted_button = target_buttons[index]

	lifted_button.z_index = 30
	lifted_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lifted_button.disabled = false
	update_lifted_button_position()

	var up_tween = create_tween()
	up_tween.set_ease(Tween.EASE_OUT)
	up_tween.set_trans(Tween.TRANS_QUAD)
	up_tween.tween_method(Callable(self, "set_claw_y_with_lifted_button"), claw_position.y, claw_top_y, grab_up_duration)
	await up_tween.finished

	claw_open = true
	claw_descending = false
	waiting_for_lifted_click = true
	draw_claw_state()

	lifted_button.z_index = 35
	lifted_button.mouse_filter = Control.MOUSE_FILTER_STOP
	result_label.modulate = Color(0.10, 0.10, 0.10)
	result_label.text = "Tlačítko vytaženo.\nTeď na něj klikni."
	result_label.visible = true
	update_instruction_label()


func handle_lifted_button_click():
	if not waiting_for_lifted_click or lifted_button == null or not is_instance_valid(lifted_button):
		return

	lifted_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if lifted_button == no_button:
		caught_correct_button()
	else:
		caught_wrong_button()

		if round_count < max_rounds:
			await get_tree().create_timer(1.1).timeout
			reset_after_wrong_lifted_click()


func missed_button():
	if not can_interact and not claw_descending:
		return

	result_label.modulate = Color(0.45, 0.32, 0.0)
	result_label.text = "Vedle.\nZkus ruku posunout přesněji."
	result_label.visible = true
	background.color = Color(0.96, 0.91, 0.75)


func caught_correct_button():
	if not can_interact and not claw_descending and not waiting_for_lifted_click:
		return

	can_interact = false
	waiting_for_lifted_click = false
	level_completed = true
	result_label.modulate = Color(0.0, 0.6, 0.0)
	result_label.text = "Správně!\nNesouhlasím vybráno."
	result_label.visible = true

	GameState.reduce_system_control(5)
	update_system_control_label()

	await get_tree().create_timer(1.5).timeout
	level_finished.emit()


func caught_wrong_button():
	if not can_interact and not claw_descending and not waiting_for_lifted_click:
		return

	can_interact = false
	waiting_for_lifted_click = false
	round_count += 1
	GameState.add_system_control(10)
	update_system_control_label()

	result_label.modulate = Color(0.6, 0.0, 0.0)
	result_label.text = "Špatně.\nKlikl jsi na SOUHLASÍM."
	result_label.visible = true

	background.color = Color(0.95, 0.82, 0.82)

	if round_count >= max_rounds:
		await get_tree().create_timer(1.2).timeout
		trigger_game_over()
		return

	update_instruction_label()


func trigger_game_over():
	moving_left = false
	moving_right = false

	for btn in agree_buttons:
		if btn and is_instance_valid(btn):
			btn.visible = false
	no_button.visible = false
	left_button.visible = false
	down_button.visible = false
	right_button.visible = false
	result_label.text = "Příliš mnoho chyb.\nLevel se restartuje."
	background.color = Color(0.95, 0.82, 0.82)

	await get_tree().create_timer(2.0).timeout
	left_button.visible = true
	down_button.visible = true
	right_button.visible = true
	start_level()


func update_instruction_label():
	if instruction_label:
		if waiting_for_lifted_click:
			instruction_label.text = "Klikni na vytažené tlačítko. Chyby: %d/%d" % [round_count, max_rounds]
		else:
			instruction_label.text = "Vytáhni NESOUHLASÍM a klikni na něj. Chyby: %d/%d" % [round_count, max_rounds]


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return

	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func _on_agree_pressed():
	if waiting_for_lifted_click and lifted_button != null and lifted_button != no_button:
		handle_lifted_button_click()


func _on_no_pressed():
	if waiting_for_lifted_click and lifted_button == no_button:
		handle_lifted_button_click()


func _on_target_button_pressed(button: Button):
	if waiting_for_lifted_click and button == lifted_button:
		handle_lifted_button_click()


func move_claw_by(amount: float):
	move_claw_to_x(claw_position.x + amount)


func move_claw_to_x(new_x: float):
	claw_position.x = clamp(new_x, claw_min_x, claw_max_x)
	claw_position.y = claw_top_y
	update_claw_position()


func update_claw_bounds():
	claw_min_x = 40.0 + claw_width / 2.0
	claw_max_x = max(claw_min_x, window_size.x - 40.0 - claw_width / 2.0)


func get_target_drop_y() -> float:
	if target_buttons.is_empty():
		return window_size.y - 160.0

	var first_button = target_buttons[0]
	if first_button and is_instance_valid(first_button):
		return first_button.position.y - claw_height + 16.0

	return window_size.y - 160.0


func update_lifted_button_position():
	if lifted_button == null or not is_instance_valid(lifted_button):
		return

	lifted_button.position = Vector2(
		claw_position.x - lifted_button.size.x / 2.0,
		claw_position.y + claw_height - 18.0
	)


func set_control_buttons_disabled(disabled: bool):
	if left_button and is_instance_valid(left_button):
		left_button.disabled = disabled
	if down_button and is_instance_valid(down_button):
		down_button.disabled = disabled
	if right_button and is_instance_valid(right_button):
		right_button.disabled = disabled


func reset_after_wrong_lifted_click():
	if level_completed or round_count >= max_rounds:
		return

	if lifted_button and is_instance_valid(lifted_button):
		lifted_button.z_index = 5
		lifted_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	lifted_button = null
	lifted_button_index = -1
	waiting_for_lifted_click = false
	claw_descending = false
	claw_open = true
	draw_claw_state()
	shuffle_target_buttons()
	layout_target_buttons()
	reset_target_button_modulates()
	result_label.visible = false
	background.color = Color(0.96, 0.96, 0.92)
	can_interact = true
	set_control_buttons_disabled(false)
	update_instruction_label()


func shuffle_target_buttons():
	if target_buttons.size() > 1:
		target_buttons.shuffle()


func reset_target_button_modulates():
	for btn in target_buttons:
		if btn and is_instance_valid(btn):
			btn.modulate = Color(1.0, 1.0, 1.0)


func _on_button_pressed(button_type: String):
	match button_type:
		"MOVE_LEFT":
			_on_left_pressed()
		"MOVE_RIGHT":
			_on_right_pressed()
		"MOVE_DOWN":
			_on_down_pressed()
		"AGREE_1":
			pass
		"AGREE_2":
			pass
		"AGREE_3":
			pass
		"DISAGREE":
			pass


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


func style_arrow_button(button):
	var normal = make_button_style(
		Color(0.20, 0.50, 0.85),
		Color(0.10, 0.30, 0.70),
		8
	)

	var hover = make_button_style(
		Color(0.30, 0.65, 1.0),
		Color(0.15, 0.40, 0.80),
		8
	)

	var pressed = make_button_style(
		Color(0.15, 0.35, 0.70),
		Color(0.08, 0.20, 0.55),
		8
	)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
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
