extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var article_label: Label
var article_agree_button: Button
var article_no_button: Button

var instruction_label: Label
var timer_label: Label
var result_label: Label
var control_label: Label
var search_panel: Panel
var cells = []

var rows = 9
var cols = 18
var target_letters = ["S", "O", "U", "H", "L", "A", "S", "Í", "M"]
var allowed_letters = ["S", "O", "U", "H", "L", "A", "Í", "M"]
var target_cells = []

var max_time = 60.0
var time_left = 60.0

var max_attempts = 5
var attempts_left = 5

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
	completed = false
	failed = false
	time_left = max_time
	attempts_left = max_attempts

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	show_article_screen()
	update_system_control_label()
	layout_ui()
	queue_redraw()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if screen_state != "game" or completed or failed:
		return

	time_left -= delta

	if time_left <= 0.0:
		time_left = 0.0
		update_timer_label()
		fail_level("Čas vypršel.")
		return

	update_timer_label()


func setup_ui():
	LevelUtils.layout_background(background, window_size)
	background.z_index = -100

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 10
		add_child(article_label)

	if not LevelUtils.is_valid_node(article_agree_button):
		article_agree_button = Button.new()
		article_agree_button.name = "ArticleAgreeButton"
		article_agree_button.text = "Souhlasím"
		article_agree_button.focus_mode = Control.FOCUS_NONE
		article_agree_button.z_index = 12
		article_agree_button.pressed.connect(_on_article_agree_pressed)
		add_child(article_agree_button)

	if not LevelUtils.is_valid_node(article_no_button):
		article_no_button = Button.new()
		article_no_button.name = "ArticleNoButton"
		article_no_button.text = "Nesouhlasím"
		article_no_button.focus_mode = Control.FOCUS_NONE
		article_no_button.z_index = 12
		article_no_button.pressed.connect(_on_article_no_pressed)
		add_child(article_no_button)

	if not LevelUtils.is_valid_node(instruction_label):
		instruction_label = Label.new()
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 17)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 40
		add_child(instruction_label)

	if not LevelUtils.is_valid_node(timer_label):
		timer_label = Label.new()
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		timer_label.add_theme_font_size_override("font_size", 18)
		timer_label.modulate = Color(0.50, 0.0, 0.0)
		timer_label.z_index = 45
		add_child(timer_label)

	if not LevelUtils.is_valid_node(result_label):
		result_label = Label.new()
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 70
		add_child(result_label)

	if not LevelUtils.is_valid_node(control_label):
		control_label = Label.new()
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 80
		add_child(control_label)

	if not LevelUtils.is_valid_node(search_panel):
		search_panel = Panel.new()
		search_panel.z_index = 55
		search_panel.add_theme_stylebox_override("panel", make_panel_style())
		add_child(search_panel)

	LevelUtils.style_green_button(article_agree_button)
	LevelUtils.style_red_button(article_no_button)

	layout_ui()


func show_article_screen():
	screen_state = "article"

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = LevelUtils.get_article_text(article_number)

	article_no_button.visible = true
	article_no_button.disabled = false

	article_agree_button.visible = true
	article_agree_button.disabled = false

	set_game_visible(false)
	layout_ui()


func show_game_screen():
	screen_state = "game"
	completed = false
	failed = false
	time_left = max_time
	attempts_left = max_attempts

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = false
	article_no_button.visible = false
	article_agree_button.visible = false

	set_game_visible(true)

	result_label.visible = false
	result_label.text = ""

	create_grid()
	layout_ui()
	update_timer_label()
	update_instruction_label()


func set_game_visible(visible: bool):
	instruction_label.visible = visible
	timer_label.visible = visible
	search_panel.visible = visible
	result_label.visible = visible and result_label.visible


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if screen_state == "article":
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, window_size.y - 145)

		var article_button_size = Vector2(180, 44)
		var spacing = 80
		var total_width = article_button_size.x * 2 + spacing
		var start_x = window_size.x / 2.0 - total_width / 2.0
		var button_y = window_size.y - 68

		article_no_button.size = article_button_size
		article_agree_button.size = article_button_size

		article_no_button.position = Vector2(start_x, button_y)
		article_agree_button.position = Vector2(start_x + article_button_size.x + spacing, button_y)

		update_system_control_label_position()
		return

	instruction_label.position = Vector2(60, 24)
	instruction_label.size = Vector2(window_size.x - 120, 36)
	update_instruction_label()

	timer_label.position = Vector2(60, 60)
	timer_label.size = Vector2(window_size.x - 120, 28)

	search_panel.position = Vector2(48, 94)
	search_panel.size = Vector2(window_size.x - 96, min(350.0, window_size.y - 154.0))

	result_label.position = Vector2(70, window_size.y - 56)
	result_label.size = Vector2(window_size.x - 140, 34)

	layout_grid()
	update_system_control_label_position()


func update_instruction_label():
	if instruction_label:
		instruction_label.text = "Najdi slovo SOUHLASÍM. Pokusy: " + str(attempts_left) + "/" + str(max_attempts)


func create_grid():
	clear_grid()

	var grid = make_letter_grid()

	for r in range(rows):
		for c in range(cols):
			var cell = Button.new()
			cell.text = grid[r][c]
			cell.focus_mode = Control.FOCUS_NONE
			cell.z_index = 60
			cell.pressed.connect(_on_cell_pressed.bind(r, c))
			style_cell(cell)
			search_panel.add_child(cell)
			cells.append(cell)


func clear_grid():
	for cell in cells:
		if LevelUtils.is_valid_node(cell):
			cell.queue_free()

	cells.clear()


func layout_grid():
	if cells.is_empty():
		return

	var start = Vector2(24, 24)
	var gap = Vector2(
		(search_panel.size.x - 48.0) / float(cols),
		(search_panel.size.y - 48.0) / float(rows)
	)
	var cell_size = Vector2(
		min(32.0, gap.x - 4.0),
		min(28.0, gap.y - 4.0)
	)

	for r in range(rows):
		for c in range(cols):
			var index = r * cols + c
			cells[index].position = start + Vector2(c * gap.x, r * gap.y)
			cells[index].size = cell_size


func make_letter_grid() -> Array:
	for attempts in range(160):
		var grid = []

		for r in range(rows):
			var row = []

			for c in range(cols):
				row.append(allowed_letters.pick_random())

			grid.append(row)

		place_target_word(grid)

		if count_target_words(grid) == 1:
			return grid

	return make_simple_grid()


func make_simple_grid() -> Array:
	var grid = []

	for r in range(rows):
		var row = []

		for c in range(cols):
			row.append(allowed_letters.pick_random())

		grid.append(row)

	target_cells.clear()

	for i in range(target_letters.size()):
		grid[i][2] = target_letters[i]
		target_cells.append(Vector2i(2, i))

	return grid


func place_target_word(grid: Array):
	var directions = [Vector2i(1, 0), Vector2i(0, 1)]
	var dir = directions.pick_random()

	var start_col_min = 0 if dir.x >= 0 else target_letters.size() - 1
	var start_col_max = cols - target_letters.size() if dir.x >= 0 else cols - 1
	var start_row_min = 0
	var start_row_max = rows - target_letters.size() if dir.y > 0 else rows - 1

	var start_col = randi_range(start_col_min, start_col_max)
	var start_row = randi_range(start_row_min, start_row_max)

	target_cells.clear()

	for i in range(target_letters.size()):
		var c = start_col + dir.x * i
		var r = start_row + dir.y * i

		grid[r][c] = target_letters[i]
		target_cells.append(Vector2i(c, r))


func count_target_words(grid: Array) -> int:
	var directions = [Vector2i(1, 0), Vector2i(0, 1)]
	var total = 0

	for r in range(rows):
		for c in range(cols):
			for dir in directions:
				if word_at(grid, r, c, dir):
					total += 1

	return total


func word_at(grid: Array, row: int, col: int, dir: Vector2i) -> bool:
	for i in range(target_letters.size()):
		var r = row + dir.y * i
		var c = col + dir.x * i

		if r < 0 or r >= rows or c < 0 or c >= cols:
			return false

		if grid[r][c] != target_letters[i]:
			return false

	return true


func _on_article_agree_pressed():
	if completed or failed:
		return

	show_game_screen()


func _on_article_no_pressed():
	if completed or failed:
		return

	fail_level("Souhlas nebyl dokončen.")


func _on_cell_pressed(row: int, col: int):
	if completed or failed or screen_state != "game":
		return

	if target_cells.has(Vector2i(col, row)):
		highlight_word()
		complete_level()
		return

	attempts_left -= 1
	update_instruction_label()
	update_system_control_label()

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.visible = true

	if attempts_left <= 0:
		attempts_left = 0
		update_instruction_label()
		result_label.text = GameState.result_fail_text
		fail_level("Došly pokusy.")
		return

	result_label.text = "Tady SOUHLASÍM není. Zbývá pokusů: " + str(attempts_left)


func highlight_word():
	for pos in target_cells:
		var index = pos.y * cols + pos.x
		cells[index].add_theme_stylebox_override(
			"normal",
			LevelUtils.make_grid_button_style(Color(0.65, 0.90, 0.66), Color(0.10, 0.45, 0.22))
		)


func complete_level():
	completed = true
	background.color = Color(0.84, 0.94, 0.84)

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = GameState.result_success_text
	result_label.visible = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func fail_level(message: String):
	if failed:
		return

	failed = true
	background.color = Color(0.95, 0.82, 0.82)

	if screen_state == "article":
		article_no_button.disabled = true
		article_agree_button.disabled = true

		article_label.modulate = Color(0.58, 0.0, 0.0)
		article_label.text = GameState.result_fail_text

		result_label.visible = false

		update_system_control_label()

		await get_tree().create_timer(GameState.result_freeze_time).timeout
		level_failed.emit()
		return

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = GameState.result_fail_text
	result_label.visible = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func update_timer_label():
	timer_label.text = "Čas: " + str(max(0, ceili(time_left))) + " s"


func update_system_control_label_position():
	LevelUtils.update_system_control_label(control_label, Vector2(window_size.x - 340, 8))


func update_system_control_label():
	LevelUtils.refresh_system_control_label(control_label)


func style_cell(button: Button):
	button.add_theme_stylebox_override("normal", LevelUtils.make_grid_button_style(Color(0.98, 0.98, 0.96), Color(0.42, 0.50, 0.70)))
	button.add_theme_stylebox_override("hover", LevelUtils.make_grid_button_style(Color(0.90, 0.95, 1.0), Color(0.20, 0.40, 0.72)))
	button.add_theme_stylebox_override("pressed", LevelUtils.make_grid_button_style(Color(0.78, 0.88, 1.0), Color(0.20, 0.40, 0.72)))
	button.add_theme_color_override("font_color", Color(0.18, 0.25, 0.50))
	button.add_theme_font_size_override("font_size", 16)


func make_panel_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.94, 0.88)
	sb.border_color = Color(0.08, 0.22, 0.32)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	return sb
