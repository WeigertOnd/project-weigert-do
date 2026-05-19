extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect
@onready var arena = get_node_or_null("Arena")
@onready var line = get_node_or_null("Line")
@onready var target_label = get_node_or_null("TargetLabel")
@onready var game_button = get_node_or_null("NoButton")
@onready var score_label = get_node_or_null("ScoreLabel")
@onready var error_label = get_node_or_null("ErrorLabel")

var article_label: Label
var article_agree_button: Button
var article_no_button: Button

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var decoy_nodes = []
var decoy_velocities = []

var score = 0
var target_score = 3
var error_time = 0.0
var completed = false
var failed = false


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
	screen_state = "article"
	score = 0
	error_time = 0.0
	completed = false
	failed = false

	clear_decoys()
	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	show_article_screen()
	layout_ui()
	update_score_label()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if screen_state != "game":
		return

	if completed or failed:
		return

	if error_time > 0:
		error_time -= delta

		if error_time <= 0:
			error_label.visible = false
			background.color = Color(0.96, 0.96, 0.92)
			game_button.disabled = false

		return

	move_decoys(delta)


func setup_ui():
	ensure_game_nodes()

	background.z_index = -10

	arena.z_index = 1
	line.z_index = 2
	target_label.z_index = 4
	score_label.z_index = 4
	error_label.z_index = 6
	game_button.z_index = 5

	style_panel(arena)
	LevelUtils.style_green_button(game_button)
	style_green_pill(target_label)

	target_label.focus_mode = Control.FOCUS_NONE
	target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not game_button.pressed.is_connected(_on_game_button_pressed):
		game_button.pressed.connect(_on_game_button_pressed)

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 18)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 10
		add_child(article_label)

	if not LevelUtils.is_valid_node(article_agree_button):
		article_agree_button = Button.new()
		article_agree_button.name = "ArticleAgreeButton"
		article_agree_button.text = "Souhlasím"
		article_agree_button.z_index = 10
		article_agree_button.focus_mode = Control.FOCUS_NONE
		article_agree_button.pressed.connect(_on_article_agree_pressed)
		add_child(article_agree_button)

	if not LevelUtils.is_valid_node(article_no_button):
		article_no_button = Button.new()
		article_no_button.name = "ArticleNoButton"
		article_no_button.text = "Nesouhlasím"
		article_no_button.z_index = 10
		article_no_button.focus_mode = Control.FOCUS_NONE
		article_no_button.pressed.connect(_on_article_no_pressed)
		add_child(article_no_button)

	LevelUtils.style_green_button(article_agree_button)
	LevelUtils.style_red_button(article_no_button)

	layout_ui()
	last_window_size = window_size


func ensure_game_nodes():
	if not LevelUtils.is_valid_node(arena):
		arena = Panel.new()
		arena.name = "Arena"
		add_child(arena)

	if not LevelUtils.is_valid_node(line):
		line = ColorRect.new()
		line.name = "Line"
		add_child(line)

	if not LevelUtils.is_valid_node(target_label):
		target_label = Button.new()
		target_label.name = "TargetLabel"
		target_label.focus_mode = Control.FOCUS_NONE
		target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(target_label)

	if not LevelUtils.is_valid_node(game_button):
		game_button = Button.new()
		game_button.name = "NoButton"
		add_child(game_button)

	if not LevelUtils.is_valid_node(score_label):
		score_label = Label.new()
		score_label.name = "ScoreLabel"
		add_child(score_label)

	if not LevelUtils.is_valid_node(error_label):
		error_label = Label.new()
		error_label.name = "ErrorLabel"
		add_child(error_label)


func show_article_screen():
	screen_state = "article"

	clear_decoys()

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = LevelUtils.get_article_text(article_number)

	article_agree_button.visible = true
	article_agree_button.disabled = false
	article_agree_button.text = "Souhlasím"
	LevelUtils.style_green_button(article_agree_button)

	article_no_button.visible = true
	article_no_button.disabled = false
	article_no_button.text = "Nesouhlasím"
	LevelUtils.style_red_button(article_no_button)

	arena.visible = false
	line.visible = false
	target_label.visible = false
	score_label.visible = false
	error_label.visible = false
	game_button.visible = false


func show_game_screen():
	screen_state = "game"

	score = 0
	error_time = 0.0
	completed = false
	failed = false

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = false
	article_agree_button.visible = false
	article_no_button.visible = false

	arena.visible = true
	line.visible = true
	target_label.visible = true
	score_label.visible = true
	error_label.visible = false
	game_button.visible = true

	game_button.disabled = false
	game_button.text = "Souhlasím"
	LevelUtils.style_green_button(game_button)

	target_label.text = "Souhlasím"
	style_green_pill(target_label)

	layout_ui()
	clear_decoys()
	create_decoys()
	update_score_label()


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if screen_state == "article":
		if article_label:
			article_label.position = Vector2(70, 40)
			article_label.size = Vector2(window_size.x - 140, window_size.y - 145)

		var button_size = Vector2(180, 44)
		var spacing = 80
		var total_width = button_size.x * 2 + spacing
		var start_x = window_size.x / 2.0 - total_width / 2.0
		var button_y = window_size.y - 68

		article_no_button.size = button_size
		article_agree_button.size = button_size

		article_no_button.position = Vector2(start_x, button_y)
		article_agree_button.position = Vector2(start_x + button_size.x + spacing, button_y)

		return

	arena.position = Vector2(34, 30)
	arena.size = Vector2(window_size.x - 68, 330)

	target_label.text = "Souhlasím"
	target_label.position = Vector2(window_size.x / 2 - 78, 60)
	target_label.size = Vector2(156, 38)
	target_label.add_theme_font_size_override("font_size", 15)

	game_button.size = Vector2(220, 64)
	game_button.position = Vector2(window_size.x / 2 - game_button.size.x / 2, window_size.y - 92)

	line.color = Color(0.42, 0.38, 0.32)
	line.position = Vector2(window_size.x / 2 - 2, target_label.position.y + target_label.size.y)
	line.size = Vector2(4, game_button.position.y - line.position.y - 16)

	score_label.position = Vector2(60, window_size.y - 86)
	score_label.size = Vector2(220, 30)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 15)
	score_label.modulate = Color(0.12, 0.12, 0.12)

	error_label.position = Vector2(window_size.x / 2 - 180, 378)
	error_label.size = Vector2(360, 34)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 22)
	error_label.modulate = Color(0.65, 0.0, 0.0)


func _on_article_agree_pressed():
	show_game_screen()


func _on_article_no_pressed():
	if failed or completed:
		return

	failed = true

	article_agree_button.disabled = true
	article_no_button.disabled = true

	background.color = Color(0.95, 0.82, 0.82)

	article_label.modulate = Color(0.55, 0.0, 0.0)
	article_label.text = GameState.result_fail_text


	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func create_decoys():
	var rect = get_arena_inner_rect()
	var placed_rects = []

	for i in range(11):
		var decoy = Button.new()
		decoy.text = "Nesouhlasím"
		decoy.size = Vector2(116, 34)
		var spawn_rect = Rect2(Vector2.ZERO, decoy.size)

		for attempt in range(40):
			spawn_rect.position = Vector2(
				randf_range(rect.position.x, rect.position.x + rect.size.x - decoy.size.x),
				randf_range(rect.position.y + 60, rect.position.y + rect.size.y - decoy.size.y - 20)
			)

			var overlaps = false

			for placed_rect in placed_rects:
				if spawn_rect.grow(8).intersects(placed_rect):
					overlaps = true
					break

			if not overlaps:
				break

		decoy.position = spawn_rect.position
		placed_rects.append(spawn_rect)

		decoy.focus_mode = Control.FOCUS_NONE
		decoy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decoy.z_index = 3

		style_red_pill(decoy)
		add_child(decoy)

		var velocity = Vector2(randf_range(-470, 470), randf_range(-230, 230))

		if abs(velocity.x) < 180:
			velocity.x = 260 if velocity.x >= 0 else -260

		if abs(velocity.y) < 70:
			velocity.y = 120 if velocity.y >= 0 else -120

		decoy_nodes.append(decoy)
		decoy_velocities.append(velocity)


func move_decoys(delta):
	var rect = get_arena_inner_rect()

	for i in range(decoy_nodes.size()):
		var decoy = decoy_nodes[i]
		var velocity = decoy_velocities[i]

		if not LevelUtils.is_valid_node(decoy):
			continue

		decoy.position += velocity * delta

		if decoy.position.x < rect.position.x:
			decoy.position.x = rect.position.x
			velocity.x = abs(velocity.x)

		elif decoy.position.x + decoy.size.x > rect.position.x + rect.size.x:
			decoy.position.x = rect.position.x + rect.size.x - decoy.size.x
			velocity.x = -abs(velocity.x)

		if decoy.position.y < rect.position.y:
			decoy.position.y = rect.position.y
			velocity.y = abs(velocity.y)

		elif decoy.position.y + decoy.size.y > rect.position.y + rect.size.y:
			decoy.position.y = rect.position.y + rect.size.y - decoy.size.y
			velocity.y = -abs(velocity.y)

		decoy_velocities[i] = velocity


func _on_game_button_pressed():
	if completed or failed or error_time > 0:
		return

	if is_disagree_on_line():
		fail_level()
		return

	score += 1
	update_score_label()

	if score >= target_score:
		complete_level()


func is_disagree_on_line() -> bool:
	var line_x = line.position.x + line.size.x / 2

	for decoy in decoy_nodes:
		if not LevelUtils.is_valid_node(decoy):
			continue

		if line_x >= decoy.position.x and line_x <= decoy.position.x + decoy.size.x:
			return true

	return false


func clear_decoys():
	for decoy in decoy_nodes:
		if LevelUtils.is_valid_node(decoy):
			decoy.queue_free()

	decoy_nodes.clear()
	decoy_velocities.clear()


func fail_level():
	if failed:
		return

	failed = true

	game_button.disabled = true
	clear_decoys()

	background.color = Color(0.95, 0.82, 0.82)

	error_label.text = GameState.result_fail_text
	error_label.visible = true

	target_label.text = "Nesouhlasím"
	style_red_pill(target_label)

	score_label.text = "Reakce: %d/%d" % [score, target_score]


	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func complete_level():
	if completed:
		return

	completed = true
	background.color = Color(0.84, 0.94, 0.84)

	game_button.disabled = true
	clear_decoys()

	target_label.text = "Souhlasím"
	score_label.text = "Reakce: %d/%d" % [target_score, target_score]

	error_label.modulate = Color(0.0, 0.50, 0.0)
	error_label.text = GameState.result_success_text
	error_label.visible = true

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func update_score_label():
	score_label.text = "Reakce: %d/%d" % [score, target_score]


func get_arena_inner_rect() -> Rect2:
	return Rect2(arena.position + Vector2(12, 12), arena.size - Vector2(24, 24))


func style_panel(panel: Panel):
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.98, 0.96)
	sb.border_color = Color(0.09, 0.22, 0.32)
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6

	panel.add_theme_stylebox_override("panel", sb)


func style_green_pill(control: Control):
	var sb = LevelUtils.make_bold_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12), 8)

	control.add_theme_stylebox_override("normal", sb)
	control.add_theme_stylebox_override("hover", sb)
	control.add_theme_stylebox_override("pressed", sb)
	control.add_theme_color_override("font_color", Color(1, 1, 1))
	control.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	control.add_theme_font_size_override("font_size", 14)


func style_red_pill(control: Control):
	var sb = LevelUtils.make_bold_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 8)

	control.add_theme_stylebox_override("normal", sb)
	control.add_theme_stylebox_override("hover", sb)
	control.add_theme_stylebox_override("pressed", sb)
	control.add_theme_color_override("font_color", Color(1, 1, 1))
	control.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	control.add_theme_font_size_override("font_size", 14)
