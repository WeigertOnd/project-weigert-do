extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var instruction_label: Label
var result_label: Label
var control_label: Label
var track_panel: Panel
var buttons = []
var offsets = []
var completed = false
var scroll_speed = 380.0
var item_spacing = 158.0
var track_y = 230.0


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
	setup_ui()
	clear_buttons()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	create_button_train()
	update_system_control_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if not completed:
		move_train(delta)


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = 0

	if track_panel == null or not is_instance_valid(track_panel):
		track_panel = Panel.new()
		track_panel.name = "TrackPanel"
		track_panel.z_index = 1
		add_child(track_panel)
		style_track(track_panel)

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	track_panel.position = Vector2(38, track_y - 36)
	track_panel.size = Vector2(window_size.x - 76, 118)

	instruction_label.position = Vector2(60, 84)
	instruction_label.size = Vector2(window_size.x - 120, 34)
	instruction_label.text = "Klikni na NESOUHLASÍM, až projede kolem."

	result_label.position = Vector2(70, window_size.y - 128)
	result_label.size = Vector2(window_size.x - 140, 34)


func create_button_train():
	var labels = ["Souhlasím", "Souhlasím", "Souhlasím", "Nesouhlasím", "Souhlasím", "Souhlasím", "Souhlasím"]
	for i in range(labels.size()):
		var btn = Button.new()
		btn.name = "TrainButton" + str(i)
		btn.text = labels[i]
		btn.size = Vector2(148, 44)
		btn.z_index = 10
		btn.focus_mode = Control.FOCUS_NONE
		style_button(btn, labels[i] == "Souhlasím")
		btn.pressed.connect(_on_train_button_pressed.bind(labels[i] == "Nesouhlasím"))
		add_child(btn)
		buttons.append(btn)
		offsets.append(float(i) * item_spacing)


func move_train(delta):
	var loop_width = item_spacing * buttons.size()
	var left_edge = track_panel.position.x + 20.0
	var right_edge = track_panel.position.x + track_panel.size.x - buttons[0].size.x - 20.0

	for i in range(buttons.size()):
		offsets[i] = fposmod(float(offsets[i]) - scroll_speed * delta, loop_width)
		var x = left_edge + float(offsets[i])
		buttons[i].visible = x >= left_edge and x <= right_edge

		buttons[i].position = Vector2(x, track_y)


func _on_train_button_pressed(is_correct: bool):
	if completed:
		return

	if is_correct:
		complete_level()
	else:
		GameState.add_system_control(6)
		update_system_control_label()
		background.color = Color(0.95, 0.82, 0.82)
		result_label.modulate = Color(0.58, 0.0, 0.0)
		result_label.text = "To byl SOUHLAS."
		result_label.visible = true
		await get_tree().create_timer(0.45).timeout
		if not completed:
			background.color = Color(0.96, 0.96, 0.92)


func complete_level():
	completed = true
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Správně zachyceno."
	result_label.visible = true
	GameState.reduce_system_control(5)
	update_system_control_label()
	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func clear_buttons():
	for btn in buttons:
		if btn and is_instance_valid(btn):
			btn.queue_free()
	buttons.clear()
	offsets.clear()


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return
	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_track(panel: Panel):
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.985, 0.985, 0.965)
	sb.border_color = Color(0.08, 0.22, 0.32)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", sb)


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
