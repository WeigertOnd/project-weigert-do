extends Node2D

signal level_finished

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var instruction_label: Label
var result_label: Label
var control_label: Label
var agree_button: Button
var blank_button: Button
var search_panel: Panel
var close_button: Button
var cells = []
var completed = false
var search_open = false

var rows = 9
var cols = 18
var target_word = "NESOUHLASÍM"
var target_row = 4
var target_col = 3


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
	search_open = false
	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false
	search_panel.visible = false
	close_button.visible = false
	agree_button.visible = true
	blank_button.visible = true
	agree_button.disabled = false
	blank_button.disabled = false
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
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 17)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 40
		add_child(instruction_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 70
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 80
		add_child(control_label)

	if agree_button == null or not is_instance_valid(agree_button):
		agree_button = Button.new()
		agree_button.text = "Souhlasím"
		agree_button.z_index = 20
		agree_button.pressed.connect(_on_agree_pressed)
		style_button(agree_button, true)
		add_child(agree_button)

	if blank_button == null or not is_instance_valid(blank_button):
		blank_button = Button.new()
		blank_button.text = ""
		blank_button.z_index = 20
		blank_button.pressed.connect(_on_blank_pressed)
		style_button(blank_button, false)
		add_child(blank_button)

	if search_panel == null or not is_instance_valid(search_panel):
		search_panel = Panel.new()
		search_panel.z_index = 55
		search_panel.add_theme_stylebox_override("panel", make_panel_style())
		add_child(search_panel)
		create_grid()

	if close_button == null or not is_instance_valid(close_button):
		close_button = Button.new()
		close_button.text = "X"
		close_button.z_index = 65
		close_button.pressed.connect(_on_close_pressed)
		style_close_button(close_button)
		add_child(close_button)

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	instruction_label.position = Vector2(60, 70)
	instruction_label.size = Vector2(window_size.x - 120, 42)
	instruction_label.text = "Vyber správné tlačítko. Jedno z nich prý nic nedělá."

	agree_button.position = Vector2(window_size.x / 2.0 - 190, 225)
	agree_button.size = Vector2(160, 54)
	blank_button.position = Vector2(window_size.x / 2.0 + 30, 225)
	blank_button.size = Vector2(160, 54)

	result_label.position = Vector2(70, window_size.y - 96)
	result_label.size = Vector2(window_size.x - 140, 34)

	search_panel.position = Vector2(48, 76)
	search_panel.size = Vector2(window_size.x - 96, 362)
	close_button.position = Vector2(search_panel.position.x + search_panel.size.x - 50, search_panel.position.y + 10)
	close_button.size = Vector2(38, 38)

	layout_grid()


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
		if cell and is_instance_valid(cell):
			cell.queue_free()
	cells.clear()


func layout_grid():
	if cells.is_empty():
		return
	var start = Vector2(28, 62)
	var gap = Vector2(38, 30)
	for r in range(rows):
		for c in range(cols):
			var index = r * cols + c
			cells[index].position = start + Vector2(c * gap.x, r * gap.y)
			cells[index].size = Vector2(30, 26)


func make_letter_grid() -> Array:
	var letters = ["N", "E", "S", "O", "U", "H", "L", "A", "S", "Í", "M"]
	var grid = []
	var attempts = 0
	while attempts < 80:
		grid.clear()
		for r in range(rows):
			var row = []
			for c in range(cols):
				row.append(letters.pick_random())
			grid.append(row)

		for i in range(target_word.length()):
			grid[target_row][target_col + i] = target_word[i]

		if count_target_words(grid) == 1:
			return grid
		attempts += 1

	return grid


func count_target_words(grid: Array) -> int:
	var directions = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 1)
	]
	var total = 0
	for r in range(rows):
		for c in range(cols):
			for dir in directions:
				if word_at(grid, r, c, dir):
					total += 1
	return total


func word_at(grid: Array, row: int, col: int, dir: Vector2i) -> bool:
	for i in range(target_word.length()):
		var r = row + dir.y * i
		var c = col + dir.x * i
		if r < 0 or r >= rows or c < 0 or c >= cols:
			return false
		if grid[r][c] != target_word[i]:
			return false
	return true


func _on_agree_pressed():
	if completed:
		return
	GameState.add_system_control(8)
	update_system_control_label()
	background.color = Color(0.95, 0.82, 0.82)
	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = "Tohle bylo moc viditelné."
	result_label.visible = true
	await get_tree().create_timer(0.45).timeout
	if not completed:
		background.color = Color(0.96, 0.96, 0.92)


func _on_blank_pressed():
	if completed:
		return
	search_open = true
	agree_button.visible = false
	blank_button.visible = false
	search_panel.visible = true
	close_button.visible = true
	instruction_label.text = "Najdi jediné NESOUHLASÍM."


func _on_close_pressed():
	if completed:
		return
	search_open = false
	search_panel.visible = false
	close_button.visible = false
	agree_button.visible = true
	blank_button.visible = true
	instruction_label.text = "Vyber správné tlačítko. Jedno z nich prý nic nedělá."


func _on_cell_pressed(row: int, col: int):
	if completed or not search_open:
		return

	if row == target_row and col >= target_col and col < target_col + target_word.length():
		highlight_word()
		complete_level()
	else:
		GameState.add_system_control(3)
		update_system_control_label()
		result_label.modulate = Color(0.58, 0.0, 0.0)
		result_label.text = "Tady NESOUHLASÍM není."
		result_label.visible = true


func highlight_word():
	for i in range(target_word.length()):
		var index = target_row * cols + target_col + i
		cells[index].add_theme_stylebox_override("normal", make_button_style(Color(0.65, 0.90, 0.66), Color(0.10, 0.45, 0.22)))


func complete_level():
	completed = true
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Jedno jediné NESOUHLASÍM nalezeno."
	result_label.visible = true
	GameState.reduce_system_control(5)
	update_system_control_label()
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


func style_button(button: Button, agree: bool):
	var bg = Color(0.82, 0.50, 0.56) if agree else Color(0.94, 0.94, 0.91)
	var border = Color(0.55, 0.16, 0.28) if agree else Color(0.20, 0.40, 0.72)
	button.add_theme_stylebox_override("normal", make_button_style(bg, border))
	button.add_theme_stylebox_override("hover", make_button_style(bg.lerp(Color(1, 1, 1), 0.08), border))
	button.add_theme_stylebox_override("pressed", make_button_style(bg.lerp(Color(0, 0, 0), 0.08), border))
	button.add_theme_color_override("font_color", Color(1, 1, 1) if agree else Color(0.08, 0.18, 0.32))
	button.add_theme_font_size_override("font_size", 15)


func style_cell(button: Button):
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.98, 0.98, 0.96), Color(0.42, 0.50, 0.70)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.90, 0.95, 1.0), Color(0.20, 0.40, 0.72)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(0.78, 0.88, 1.0), Color(0.20, 0.40, 0.72)))
	button.add_theme_color_override("font_color", Color(0.18, 0.25, 0.50))
	button.add_theme_font_size_override("font_size", 16)


func style_close_button(button: Button):
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.95, 0.28, 0.22), Color(0.75, 0.18, 0.15)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(1.0, 0.36, 0.30), Color(0.75, 0.18, 0.15)))
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 20)


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
