extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var instruction_label: Label
var result_label: Label
var control_label: Label
var no_button: Button
var yes_button: Button
var completed = false
var swap_cooldown = false
var no_positions = [
	Vector2(176, 178),
	Vector2(482, 150),
	Vector2(246, 312),
	Vector2(596, 292),
	Vector2(92, 270)
]
var yes_positions = [
	Vector2(500, 238),
	Vector2(168, 270),
	Vector2(565, 168),
	Vector2(326, 220),
	Vector2(416, 332)
]
var move_index = 0


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
	swap_cooldown = false
	move_index = 0
	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	no_button.disabled = false
	yes_button.disabled = false
	no_button.position = no_positions[0]
	yes_button.position = yes_positions[0]
	update_system_control_label()


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = 0

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 20
		add_child(instruction_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 20
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 25
		add_child(control_label)

	if no_button == null or not is_instance_valid(no_button):
		no_button = Button.new()
		no_button.name = "RunawayNoButton"
		no_button.text = "Nesouhlasím"
		no_button.size = Vector2(154, 48)
		no_button.z_index = 10
		no_button.focus_mode = Control.FOCUS_NONE
		no_button.mouse_entered.connect(_on_no_hovered)
		no_button.pressed.connect(_on_no_pressed)
		add_child(no_button)
		style_button(no_button, false)

	if yes_button == null or not is_instance_valid(yes_button):
		yes_button = Button.new()
		yes_button.name = "SwappingYesButton"
		yes_button.text = "Souhlasím"
		yes_button.size = Vector2(154, 48)
		yes_button.z_index = 10
		yes_button.focus_mode = Control.FOCUS_NONE
		yes_button.pressed.connect(_on_yes_pressed)
		add_child(yes_button)
		style_button(yes_button, true)

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	instruction_label.position = Vector2(60, 68)
	instruction_label.size = Vector2(window_size.x - 120, 50)
	instruction_label.text = "Najeď opatrně. NESOUHLASÍM utíká a SOUHLASÍM mu bere místo."

	result_label.position = Vector2(70, window_size.y - 108)
	result_label.size = Vector2(window_size.x - 140, 34)


func _on_no_hovered():
	if completed or swap_cooldown:
		return

	swap_cooldown = true
	move_index = (move_index + 1) % no_positions.size()
	var old_no_position = no_button.position
	var new_no_position = clamp_button_position(no_positions[move_index] + Vector2(randf_range(-24, 24), randf_range(-18, 18)))

	var no_tween = create_tween()
	no_tween.set_ease(Tween.EASE_OUT)
	no_tween.set_trans(Tween.TRANS_BACK)
	no_tween.tween_property(no_button, "position", new_no_position, 0.28)

	var yes_tween = create_tween()
	yes_tween.set_ease(Tween.EASE_OUT)
	yes_tween.set_trans(Tween.TRANS_SINE)
	yes_tween.tween_property(yes_button, "position", old_no_position, 0.20)

	await get_tree().create_timer(0.34).timeout
	swap_cooldown = false


func _on_no_pressed():
	if completed:
		return
	complete_level()


func _on_yes_pressed():
	if completed:
		return

	GameState.add_system_control(8)
	update_system_control_label()
	background.color = Color(0.95, 0.82, 0.82)
	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = "SOUHLASÍM se sem dostalo moc rychle."
	result_label.visible = true
	await get_tree().create_timer(0.45).timeout
	if not completed:
		background.color = Color(0.96, 0.96, 0.92)


func complete_level():
	completed = true
	no_button.disabled = true
	yes_button.disabled = true
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Chytil jsi utíkající NESOUHLASÍM."
	result_label.visible = true
	GameState.reduce_system_control(5)
	update_system_control_label()
	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func clamp_button_position(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, 34.0, window_size.x - 188.0),
		clamp(pos.y, 126.0, window_size.y - 132.0)
	)


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return
	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_button(button: Button, agree: bool):
	var bg = Color(0.82, 0.50, 0.56) if agree else Color(0.65, 0.90, 0.66)
	var border = Color(0.55, 0.16, 0.28) if agree else Color(0.10, 0.45, 0.22)
	button.add_theme_stylebox_override("normal", make_button_style(bg, border))
	button.add_theme_stylebox_override("hover", make_button_style(bg.lerp(Color(1, 1, 1), 0.08), border))
	button.add_theme_stylebox_override("pressed", make_button_style(bg.lerp(Color(0, 0, 0), 0.08), border))
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 14)


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
