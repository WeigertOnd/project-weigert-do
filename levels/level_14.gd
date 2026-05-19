extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1

var article_label: Label
var instruction_label: Label
var result_label: Label
var track_panel: Panel

var buttons = []

var completed = false
var failed = false

var button_count = 100
var correct_index = 0

var button_size = Vector2(148, 44)
var item_spacing = 158.0

var scroll_offset = 0.0
var max_scroll = 0.0

var dragging = false
var drag_start_mouse_x = 0.0
var drag_start_scroll = 0.0
var drag_moved = false


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
	completed = false
	failed = false
	dragging = false
	drag_moved = false
	scroll_offset = 0.0

	clear_buttons()
	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = LevelUtils.get_article_text(article_number)

	instruction_label.visible = true
	result_label.visible = false

	correct_index = randi_range(0, button_count - 1)

	create_button_row()
	update_button_positions()
	layout_ui()


func setup_ui():
	LevelUtils.layout_background(background, window_size)
	background.z_index = -10

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)
		article_label.z_index = 5
		add_child(article_label)

	if not LevelUtils.is_valid_node(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.12, 0.12, 0.12)
		instruction_label.z_index = 10
		add_child(instruction_label)

	if not LevelUtils.is_valid_node(track_panel):
		track_panel = Panel.new()
		track_panel.name = "TrackPanel"
		track_panel.z_index = 1
		track_panel.clip_contents = true
		track_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		track_panel.gui_input.connect(_on_track_gui_input)
		add_child(track_panel)
		style_track(track_panel)

	if not LevelUtils.is_valid_node(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.add_theme_font_size_override("font_size", 20)
		result_label.z_index = 80
		add_child(result_label)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if article_label:
		article_label.position = Vector2(70, 28)
		article_label.size = Vector2(window_size.x - 140, 255)

	if instruction_label:
		instruction_label.position = Vector2(70, 286)
		instruction_label.size = Vector2(window_size.x - 140, 42)

	if track_panel:
		track_panel.position = Vector2(38, 340)
		track_panel.size = Vector2(window_size.x - 76, 78)

	if result_label:
		result_label.position = Vector2(70, window_size.y - 74)
		result_label.size = Vector2(window_size.x - 140, 42)

	update_button_positions()


func create_button_row():
	for i in range(button_count):
		var btn = Button.new()
		btn.name = "AgreeButton" if i == correct_index else "DisagreeButton"
		btn.text = "Souhlasím" if i == correct_index else "Nesouhlasím"
		btn.size = button_size
		btn.focus_mode = Control.FOCUS_NONE
		btn.z_index = 10
		btn.set_meta("correct", i == correct_index)
		btn.set_meta("index", i)

		LevelUtils.style_red_button(btn)

		btn.pressed.connect(_on_button_pressed.bind(btn))

		track_panel.add_child(btn)
		buttons.append(btn)

	var total_width = button_count * item_spacing
	var visible_width = track_panel.size.x
	max_scroll = max(0.0, total_width - visible_width + 40.0)


func update_button_positions():
	if not LevelUtils.is_valid_node(track_panel):
		return

	var start_x = 20.0 - scroll_offset
	var y = track_panel.size.y / 2.0 - button_size.y / 2.0

	for i in range(buttons.size()):
		var btn = buttons[i]

		if not LevelUtils.is_valid_node(btn):
			continue

		btn.position = Vector2(start_x + i * item_spacing, y)

		var visible_left = -button_size.x - 30
		var visible_right = track_panel.size.x + 30
		btn.visible = btn.position.x >= visible_left and btn.position.x <= visible_right


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()


func _input(event):
	if completed or failed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			dragging = false


func _on_track_gui_input(event: InputEvent):
	if completed or failed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_start_mouse_x = event.position.x
			drag_start_scroll = scroll_offset
			drag_moved = false
		else:
			dragging = false

	if event is InputEventMouseMotion and dragging:
		var delta_x = event.position.x - drag_start_mouse_x

		if abs(delta_x) > 4.0:
			drag_moved = true

		scroll_offset = clamp(drag_start_scroll - delta_x, 0.0, max_scroll)
		update_button_positions()


func _on_button_pressed(button: Button):
	if completed or failed:
		return

	if drag_moved:
		drag_moved = false
		return

	var is_correct = bool(button.get_meta("correct"))

	if is_correct:
		complete_level()
	else:
		fail_level()


func complete_level():
	if completed:
		return

	completed = true
	dragging = false

	background.color = Color(0.84, 0.94, 0.84)

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = GameState.result_success_text
	result_label.visible = true

	for btn in buttons:
		if LevelUtils.is_valid_node(btn):
			btn.disabled = true

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func fail_level():
	if failed:
		return

	failed = true
	dragging = false

	background.color = Color(0.95, 0.82, 0.82)

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = GameState.result_fail_text
	result_label.visible = true

	for btn in buttons:
		if LevelUtils.is_valid_node(btn):
			btn.disabled = true

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func clear_buttons():
	for btn in buttons:
		if LevelUtils.is_valid_node(btn):
			btn.queue_free()

	buttons.clear()


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
