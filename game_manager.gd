extends Node2D

var current_level = null
var current_level_path = ""
var current_level_finished_function = Callable()

# permanent desktop
var desktop_background
var desktop_overlay
var taskbar
var start_button
var clock_label
var start_menu
var start_menu_title
var menu_game_button
var menu_level_select_button
var menu_continue_button
var menu_shutdown_button

# fake XP / Win7 window
var window_shadow
var game_window
var title_bar
var title_bar_glow
var title_label
var content_panel
var content_root

# popup
var popup_button = null
var popup_label = null
var popup_title = null

# system monitor window
var monitor_shadow
var monitor_window
var monitor_title_bar
var monitor_title_glow
var monitor_title_label
var monitor_content
var monitor_label
var monitor_bar_background
var monitor_bar_fill
var monitor_percent_label

var clock_timer = 0.0


func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	randomize()

	if not GameState.system_control_maxed.is_connected(_on_system_control_maxed):
		GameState.system_control_maxed.connect(_on_system_control_maxed)

	if GameState.has_signal("system_control_changed"):
		if not GameState.system_control_changed.is_connected(_on_system_control_changed):
			GameState.system_control_changed.connect(_on_system_control_changed)

	build_desktop()
	layout_desktop()
	hide_game_window()
	update_clock()
	update_start_menu_buttons()


func _process(delta):
	clock_timer += delta

	if clock_timer >= 1.0:
		clock_timer = 0.0
		update_clock()

	layout_desktop()


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if start_menu and start_menu.visible:
			var click_pos = event.position

			var over_menu = Rect2(start_menu.position, start_menu.size).has_point(click_pos)
			var over_start = Rect2(start_button.position, start_button.size).has_point(click_pos)

			if not over_menu and not over_start:
				start_menu.visible = false


# =========================================================
# DESKTOP
# =========================================================

func build_desktop():
	var screen = get_viewport_rect().size

	desktop_background = TextureRect.new()
	desktop_background.name = "DesktopBackground"
	desktop_background.texture = load("res://assets/xp_background.jpg")
	desktop_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desktop_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	desktop_background.position = Vector2.ZERO
	desktop_background.size = screen
	desktop_background.z_index = -50
	add_child(desktop_background)

	desktop_overlay = ColorRect.new()
	desktop_overlay.name = "DesktopOverlay"
	desktop_overlay.color = Color(1, 1, 1, 0.02)
	desktop_overlay.position = Vector2.ZERO
	desktop_overlay.size = screen
	desktop_overlay.z_index = -49
	add_child(desktop_overlay)

	taskbar = Panel.new()
	taskbar.name = "Taskbar"
	taskbar.z_index = 50
	taskbar.add_theme_stylebox_override("panel", make_taskbar_style())
	add_child(taskbar)

	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "Start"
	start_button.z_index = 51
	style_start_button(start_button)
	start_button.pressed.connect(_on_start_pressed)
	add_child(start_button)

	clock_label = Label.new()
	clock_label.name = "ClockLabel"
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clock_label.add_theme_font_size_override("font_size", 13)
	clock_label.modulate = Color(1, 1, 1)
	clock_label.z_index = 51
	add_child(clock_label)

	start_menu = Panel.new()
	start_menu.name = "StartMenu"
	start_menu.visible = false
	start_menu.z_index = 60
	start_menu.add_theme_stylebox_override("panel", make_start_menu_style())
	add_child(start_menu)

	start_menu_title = Label.new()
	start_menu_title.name = "StartMenuTitle"
	start_menu_title.text = "I Agree?"
	start_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	start_menu_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_menu_title.add_theme_font_size_override("font_size", 16)
	start_menu_title.modulate = Color(1, 1, 1)
	start_menu.add_child(start_menu_title)

	menu_game_button = Button.new()
	menu_game_button.name = "MenuGameButton"
	menu_game_button.text = "Spustit hru"
	style_menu_button(menu_game_button)
	menu_game_button.pressed.connect(start_new_game)
	start_menu.add_child(menu_game_button)

	menu_level_select_button = Button.new()
	menu_level_select_button.name = "MenuLevelSelectButton"
	menu_level_select_button.text = "Vybrat level"
	style_menu_button(menu_level_select_button)
	menu_level_select_button.pressed.connect(show_level_select_menu)
	start_menu.add_child(menu_level_select_button)

	menu_continue_button = Button.new()
	menu_continue_button.name = "MenuContinueButton"
	menu_continue_button.text = "Pokračovat"
	style_menu_button(menu_continue_button)
	menu_continue_button.pressed.connect(resume_game)
	start_menu.add_child(menu_continue_button)

	menu_shutdown_button = Button.new()
	menu_shutdown_button.name = "MenuShutdownButton"
	menu_shutdown_button.text = "Vypnout"
	style_menu_button(menu_shutdown_button)
	menu_shutdown_button.pressed.connect(fake_shutdown)
	start_menu.add_child(menu_shutdown_button)

	build_game_window()
	build_system_monitor()


func build_game_window():
	window_shadow = Panel.new()
	window_shadow.name = "WindowShadow"
	window_shadow.visible = false
	window_shadow.z_index = 10
	window_shadow.add_theme_stylebox_override("panel", make_shadow_style())
	add_child(window_shadow)

	game_window = Panel.new()
	game_window.name = "GameWindow"
	game_window.visible = false
	game_window.z_index = 11
	game_window.add_theme_stylebox_override("panel", make_window_frame_style())
	add_child(game_window)

	title_bar = Panel.new()
	title_bar.name = "TitleBar"
	title_bar.visible = false
	title_bar.z_index = 12
	title_bar.add_theme_stylebox_override("panel", make_title_bar_style())
	add_child(title_bar)

	title_bar_glow = ColorRect.new()
	title_bar_glow.name = "TitleBarGlow"
	title_bar_glow.visible = false
	title_bar_glow.color = Color(1, 1, 1, 0.18)
	title_bar_glow.z_index = 13
	add_child(title_bar_glow)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.visible = false
	title_label.text = "I AGREE?"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.modulate = Color(1, 1, 1)
	title_label.z_index = 14
	add_child(title_label)

	content_panel = Panel.new()
	content_panel.name = "ContentPanel"
	content_panel.visible = false
	content_panel.z_index = 12
	content_panel.add_theme_stylebox_override("panel", make_content_style())
	add_child(content_panel)

	content_root = Node2D.new()
	content_root.name = "ContentRoot"
	content_root.visible = false
	content_root.z_index = 15
	add_child(content_root)


func layout_desktop():
	var screen = get_viewport_rect().size

	if desktop_background:
		desktop_background.position = Vector2.ZERO
		desktop_background.size = screen

	if desktop_overlay:
		desktop_overlay.position = Vector2.ZERO
		desktop_overlay.size = screen

	if taskbar:
		taskbar.position = Vector2(0, screen.y - 42)
		taskbar.size = Vector2(screen.x, 42)

	if start_button:
		start_button.position = Vector2(8, screen.y - 36)
		start_button.size = Vector2(100, 30)

	if clock_label:
		clock_label.position = Vector2(screen.x - 92, screen.y - 32)
		clock_label.size = Vector2(76, 22)

	if start_menu:
		start_menu.position = Vector2(8, screen.y - 326)
		start_menu.size = Vector2(250, 280)

		if start_menu_title:
			start_menu_title.position = Vector2(14, 10)
			start_menu_title.size = Vector2(210, 30)

		if menu_game_button:
			menu_game_button.position = Vector2(18, 56)
			menu_game_button.size = Vector2(214, 40)

		if menu_level_select_button:
			menu_level_select_button.position = Vector2(18, 104)
			menu_level_select_button.size = Vector2(214, 40)

		if menu_continue_button:
			menu_continue_button.position = Vector2(18, 152)
			menu_continue_button.size = Vector2(214, 40)

		if menu_shutdown_button:
			menu_shutdown_button.position = Vector2(18, 224)
			menu_shutdown_button.size = Vector2(214, 40)

	layout_game_window()
	layout_system_monitor()


func layout_game_window():
	var screen = get_viewport_rect().size
	var window_size = Vector2(880, 580)
	var window_pos = Vector2(
		(screen.x - window_size.x) / 2,
		(screen.y - window_size.y) / 2 - 22
	)

	if window_shadow:
		window_shadow.position = window_pos + Vector2(10, 12)
		window_shadow.size = window_size

	if game_window:
		game_window.position = window_pos
		game_window.size = window_size

	if title_bar:
		title_bar.position = window_pos + Vector2(5, 5)
		title_bar.size = Vector2(window_size.x - 10, 36)

	if title_bar_glow:
		title_bar_glow.position = window_pos + Vector2(7, 7)
		title_bar_glow.size = Vector2(window_size.x - 14, 14)

	if title_label:
		title_label.position = window_pos + Vector2(18, 11)
		title_label.size = Vector2(680, 22)

	if content_panel:
		content_panel.position = window_pos + Vector2(12, 48)
		content_panel.size = Vector2(window_size.x - 24, window_size.y - 60)

	if content_root:
		content_root.position = get_window_content_origin()

		if current_level and is_instance_valid(current_level):
			if current_level.has_method("set_window_size"):
				current_level.set_window_size(get_window_content_size())
			elif current_level.has_method("set_window_rect"):
				current_level.set_window_rect(Rect2(Vector2.ZERO, get_window_content_size()))


func get_window_content_origin() -> Vector2:
	return content_panel.position


func get_window_content_size() -> Vector2:
	return content_panel.size


func show_game_window():
	window_shadow.visible = true
	game_window.visible = true
	title_bar.visible = true
	title_bar_glow.visible = true
	title_label.visible = true
	content_panel.visible = true
	content_root.visible = true
	show_system_monitor()


func hide_game_window():
	window_shadow.visible = false
	game_window.visible = false
	title_bar.visible = false
	title_bar_glow.visible = false
	title_label.visible = false
	content_panel.visible = false
	content_root.visible = false
	hide_system_monitor()


func set_window_title(new_title: String):
	if title_label:
		title_label.text = new_title


func update_clock():
	if clock_label:
		var time_text = Time.get_time_string_from_system()

		if time_text.length() >= 5:
			clock_label.text = time_text.substr(0, 5)
		else:
			clock_label.text = time_text


func update_start_menu_buttons():
	if menu_continue_button:
		menu_continue_button.disabled = current_level == null


# =========================================================
# SYSTEM MONITOR WINDOW
# =========================================================

func build_system_monitor():
	monitor_shadow = Panel.new()
	monitor_shadow.name = "SystemMonitorShadow"
	monitor_shadow.visible = false
	monitor_shadow.z_index = 20
	monitor_shadow.add_theme_stylebox_override("panel", make_monitor_shadow_style())
	add_child(monitor_shadow)

	monitor_window = Panel.new()
	monitor_window.name = "SystemMonitorWindow"
	monitor_window.visible = false
	monitor_window.z_index = 21
	monitor_window.add_theme_stylebox_override("panel", make_monitor_window_style())
	add_child(monitor_window)

	monitor_title_bar = Panel.new()
	monitor_title_bar.name = "SystemMonitorTitleBar"
	monitor_title_bar.visible = false
	monitor_title_bar.z_index = 22
	monitor_title_bar.add_theme_stylebox_override("panel", make_monitor_title_bar_style())
	add_child(monitor_title_bar)

	monitor_title_glow = ColorRect.new()
	monitor_title_glow.name = "SystemMonitorTitleGlow"
	monitor_title_glow.visible = false
	monitor_title_glow.color = Color(1, 1, 1, 0.18)
	monitor_title_glow.z_index = 23
	add_child(monitor_title_glow)

	monitor_title_label = Label.new()
	monitor_title_label.name = "SystemMonitorTitleLabel"
	monitor_title_label.visible = false
	monitor_title_label.text = "System Monitor"
	monitor_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	monitor_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	monitor_title_label.add_theme_font_size_override("font_size", 13)
	monitor_title_label.modulate = Color(1, 1, 1)
	monitor_title_label.z_index = 24
	add_child(monitor_title_label)

	monitor_content = Panel.new()
	monitor_content.name = "SystemMonitorContent"
	monitor_content.visible = false
	monitor_content.z_index = 22
	monitor_content.add_theme_stylebox_override("panel", make_monitor_content_style())
	add_child(monitor_content)

	monitor_label = Label.new()
	monitor_label.name = "SystemMonitorLabel"
	monitor_label.visible = false
	monitor_label.text = "KONTROLA SYSTÉMU"
	monitor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monitor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	monitor_label.add_theme_font_size_override("font_size", 13)
	monitor_label.modulate = Color(0.10, 0.10, 0.10)
	monitor_label.z_index = 24
	add_child(monitor_label)

	monitor_bar_background = Panel.new()
	monitor_bar_background.name = "SystemMonitorBarBackground"
	monitor_bar_background.visible = false
	monitor_bar_background.z_index = 24
	monitor_bar_background.add_theme_stylebox_override("panel", make_monitor_bar_background_style())
	add_child(monitor_bar_background)

	monitor_bar_fill = ColorRect.new()
	monitor_bar_fill.name = "SystemMonitorBarFill"
	monitor_bar_fill.visible = false
	monitor_bar_fill.color = Color(0.05, 0.35, 0.85)
	monitor_bar_fill.z_index = 25
	add_child(monitor_bar_fill)

	monitor_percent_label = Label.new()
	monitor_percent_label.name = "SystemMonitorPercentLabel"
	monitor_percent_label.visible = false
	monitor_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monitor_percent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	monitor_percent_label.add_theme_font_size_override("font_size", 13)
	monitor_percent_label.modulate = Color(0.06, 0.06, 0.06)
	monitor_percent_label.z_index = 26
	add_child(monitor_percent_label)

	update_system_monitor()


func layout_system_monitor():
	var screen = get_viewport_rect().size
	var size = Vector2(260, 138)

	var main_window_size = Vector2(880, 580)
	var main_window_pos = Vector2(
		(screen.x - main_window_size.x) / 2,
		(screen.y - main_window_size.y) / 2 - 22
	)

	var pos = Vector2(
		main_window_pos.x + main_window_size.x + 18,
		main_window_pos.y + 28
	)

	if pos.x + size.x > screen.x - 18:
		pos.x = main_window_pos.x - size.x - 18

	if pos.x < 18:
		pos.x = screen.x - size.x - 18
		pos.y = main_window_pos.y + main_window_size.y + 16

	if pos.y + size.y > screen.y - 55:
		pos.y = screen.y - size.y - 58

	if monitor_shadow:
		monitor_shadow.position = pos + Vector2(7, 8)
		monitor_shadow.size = size

	if monitor_window:
		monitor_window.position = pos
		monitor_window.size = size

	if monitor_title_bar:
		monitor_title_bar.position = pos + Vector2(4, 4)
		monitor_title_bar.size = Vector2(size.x - 8, 30)

	if monitor_title_glow:
		monitor_title_glow.position = pos + Vector2(6, 6)
		monitor_title_glow.size = Vector2(size.x - 12, 11)

	if monitor_title_label:
		monitor_title_label.position = pos + Vector2(14, 7)
		monitor_title_label.size = Vector2(size.x - 28, 21)

	if monitor_content:
		monitor_content.position = pos + Vector2(8, 40)
		monitor_content.size = Vector2(size.x - 16, size.y - 50)

	if monitor_label:
		monitor_label.position = pos + Vector2(16, 51)
		monitor_label.size = Vector2(size.x - 32, 22)

	if monitor_bar_background:
		monitor_bar_background.position = pos + Vector2(22, 84)
		monitor_bar_background.size = Vector2(size.x - 44, 24)

	update_system_monitor()


func show_system_monitor():
	set_system_monitor_visible(true)
	update_system_monitor()


func hide_system_monitor():
	set_system_monitor_visible(false)


func set_system_monitor_visible(value):
	if monitor_shadow:
		monitor_shadow.visible = value
	if monitor_window:
		monitor_window.visible = value
	if monitor_title_bar:
		monitor_title_bar.visible = value
	if monitor_title_glow:
		monitor_title_glow.visible = value
	if monitor_title_label:
		monitor_title_label.visible = value
	if monitor_content:
		monitor_content.visible = value
	if monitor_label:
		monitor_label.visible = value
	if monitor_bar_background:
		monitor_bar_background.visible = value
	if monitor_bar_fill:
		monitor_bar_fill.visible = value
	if monitor_percent_label:
		monitor_percent_label.visible = value


func update_system_monitor():
	if monitor_bar_background == null or not is_instance_valid(monitor_bar_background):
		return

	var percent = GameState.system_control
	var ratio = clamp(float(percent) / float(GameState.max_system_control), 0.0, 1.0)

	var bar_pos = monitor_bar_background.position
	var bar_size = monitor_bar_background.size

	if monitor_bar_fill:
		monitor_bar_fill.position = bar_pos + Vector2(3, 3)
		monitor_bar_fill.size = Vector2((bar_size.x - 6) * ratio, bar_size.y - 6)

		if percent < 50:
			monitor_bar_fill.color = Color(0.05, 0.35, 0.85)
		elif percent < 80:
			monitor_bar_fill.color = Color(0.95, 0.55, 0.05)
		else:
			monitor_bar_fill.color = Color(0.85, 0.05, 0.05)

	if monitor_percent_label:
		monitor_percent_label.position = bar_pos
		monitor_percent_label.size = bar_size
		monitor_percent_label.text = str(percent) + " %"


func _on_system_control_changed(_new_value):
	update_system_monitor()


# =========================================================
# START MENU
# =========================================================

func _on_start_pressed():
	start_menu.visible = not start_menu.visible
	update_start_menu_buttons()


func start_new_game():
	start_menu.visible = false
	GameState.reset_system_control()
	start_level_1()


func show_level_select_menu():
	start_menu.visible = false
	show_popup_window(
		"Vybrat level",
		"",
		"Zrušit",
		Callable(self, "go_to_desktop")
	)

	var size = get_window_content_size()

	if popup_label:
		popup_label.visible = false
	if popup_title:
		popup_title.position = Vector2(40, 18)
		popup_title.size = Vector2(size.x - 80, 34)
	if popup_button:
		popup_button.position = Vector2(size.x / 2 - 105, 462)

	var level_names = ["Level 1: Souhlas s podmínkami", "Level 2: Nastavení soukromí", "Level 3: Ověření identity", "Level 4: Žádost o smazání dat", "Level 5: Finální test", "Level 6: Tahací automat", "Level 7: Pinball nesouhlasu", "Level 8: Prohozený souhlas", "Level 9: Pumpa nesouhlasu", "Level 10: Reakce", "Level 11: Odhad času", "Level 12: Odhad barvy", "Level 13: Překrytá okna", "Level 14: Fronta souhlasů", "Level 15: Neviditelný nesouhlas", "Level 16: Utíkající nesouhlas", "Level 17: Automat", "Level 18: Počet kuliček", "Level 19: Bodovací kulička", "Level 20: Terč nesouhlasu", "Level 21: Hledání slova", "Bonus Level"]
	var start_y = 66
	var button_width = 300
	var button_height = 30
	var button_spacing = 5
	var column_spacing = 22
	var columns = 2

	for i in range(1, 23):
		var column = (i - 1) % columns
		var row = floori(float(i - 1) / float(columns))
		var total_width = button_width * columns + column_spacing
		var level_button = Button.new()
		level_button.name = "LevelButton" + str(i)
		level_button.text = level_names[i - 1]
		level_button.position = Vector2(size.x / 2 - total_width / 2 + column * (button_width + column_spacing), start_y + row * (button_height + button_spacing))
		level_button.size = Vector2(button_width, button_height)
		style_window_button(level_button)

		match i:
			1:
				level_button.pressed.connect(start_level_1_direct)
			2:
				level_button.pressed.connect(start_level_2_direct)
			3:
				level_button.pressed.connect(start_level_3_direct)
			4:
				level_button.pressed.connect(start_level_4_direct)
			5:
				level_button.pressed.connect(start_level_5_direct)
			6:
				level_button.pressed.connect(start_level_6_direct)
			7:
				level_button.pressed.connect(start_level_7_direct)
			8:
				level_button.pressed.connect(start_level_8_direct)
			9:
				level_button.pressed.connect(start_level_9_direct)
			10:
				level_button.pressed.connect(start_level_10_direct)
			11:
				level_button.pressed.connect(start_level_11_direct)
			12:
				level_button.pressed.connect(start_level_12_direct)
			13:
				level_button.pressed.connect(start_level_13_direct)
			14:
				level_button.pressed.connect(start_level_14_direct)
			15:
				level_button.pressed.connect(start_level_15_direct)
			16:
				level_button.pressed.connect(start_level_16_direct)
			17:
				level_button.pressed.connect(start_level_17_direct)
			18:
				level_button.pressed.connect(start_level_18_direct)
			19:
				level_button.pressed.connect(start_level_19_direct)
			20:
				level_button.pressed.connect(start_level_20_direct)
			21:
				level_button.pressed.connect(start_level_21_direct)
			22:
				level_button.pressed.connect(start_bonus_level_direct)

		content_root.add_child(level_button)


func resume_game():
	start_menu.visible = false

	if current_level == null:
		start_new_game()
	else:
		show_game_window()


func fake_shutdown():
	start_menu.visible = false
	show_popup_window(
		"Vypnout systém",
		"Opravdu chcete vypnout aplikaci?",
		"Vypnout",
		Callable(self, "_really_quit")
	)


func _really_quit():
	get_tree().quit()


# =========================================================
# LEVEL LOADING
# =========================================================

func clear_window_content():
	if content_root:
		for child in content_root.get_children():
			child.queue_free()

	current_level = null
	current_level_path = ""
	current_level_finished_function = Callable()
	popup_button = null
	popup_label = null
	popup_title = null

	update_start_menu_buttons()


func load_level(level_path: String, title: String, finished_function: Callable):
	clear_window_content()
	show_game_window()
	set_window_title(title)

	current_level_path = level_path
	current_level_finished_function = finished_function

	if not ResourceLoader.exists(level_path):
		show_popup_window(
			"Chyba",
			"Soubor levelu nebyl nalezen:\n" + level_path,
			"Zpět na plochu",
			Callable(self, "go_to_desktop")
		)
		return

	var level_scene = load(level_path)
	current_level = level_scene.instantiate()
	content_root.add_child(current_level)

	if current_level.has_signal("level_finished"):
		current_level.level_finished.connect(finished_function)

	if current_level.has_method("set_window_size"):
		current_level.set_window_size(get_window_content_size())
	elif current_level.has_method("set_window_rect"):
		current_level.set_window_rect(Rect2(Vector2.ZERO, get_window_content_size()))

	update_start_menu_buttons()


func go_to_desktop():
	clear_window_content()
	hide_game_window()
	start_menu.visible = false


# =========================================================
# POPUP WINDOWS
# =========================================================

func show_popup_window(window_title_text: String, body_text: String, button_text: String, next_action: Callable):
	clear_window_content()
	show_game_window()
	set_window_title(window_title_text)

	var size = get_window_content_size()

	popup_title = Label.new()
	popup_title.name = "PopupTitle"
	popup_title.text = window_title_text
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_title.position = Vector2(40, 72)
	popup_title.size = Vector2(size.x - 80, 44)
	popup_title.add_theme_font_size_override("font_size", 28)
	popup_title.modulate = Color(0.1, 0.1, 0.1)
	content_root.add_child(popup_title)

	popup_label = Label.new()
	popup_label.name = "PopupLabel"
	popup_label.text = body_text
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.position = Vector2(70, 166)
	popup_label.size = Vector2(size.x - 140, 170)
	popup_label.add_theme_font_size_override("font_size", 20)
	popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_label.modulate = Color(0.15, 0.15, 0.15)
	content_root.add_child(popup_label)

	popup_button = Button.new()
	popup_button.name = "PopupButton"
	popup_button.text = button_text
	popup_button.position = Vector2(size.x / 2 - 105, 382)
	popup_button.size = Vector2(210, 42)
	style_window_button(popup_button)
	content_root.add_child(popup_button)

	if next_action.is_valid():
		popup_button.pressed.connect(next_action)

	update_start_menu_buttons()


func show_final_screen():
	show_popup_window(
		"NESOUHLAS PŘIJAT",
		"Gratuluji.\nDostal ses ke skutečnému NESOUHLASÍM.\n\nKontrola systému: " + str(GameState.system_control) + " %",
		"Zpět na plochu",
		Callable(self, "go_to_desktop")
	)


# =========================================================
# LEVEL FLOW
# =========================================================

func start_level_1():
	load_level("res://levels/Level1.tscn", "Souhlas s podmínkami", Callable(self, "_on_level_1_finished"))


func start_level_2():
	load_level("res://levels/Level2.tscn", "Nastavení soukromí", Callable(self, "_on_level_2_finished"))


func start_level_3():
	load_level("res://levels/Level3.tscn", "Ověření identity", Callable(self, "_on_level_3_finished"))


func start_level_4():
	load_level("res://levels/Level4.tscn", "Žádost o smazání dat", Callable(self, "_on_level_4_finished"))


func start_level_5():
	load_level("res://levels/Level5.tscn", "Finální test", Callable(self, "_on_level_5_finished"))


func start_level_6():
	load_level("res://levels/Level6.tscn", "Tahací automat", Callable(self, "_on_level_6_finished"))


func start_level_7():
	load_level("res://levels/Level7.tscn", "Pinball nesouhlasu", Callable(self, "_on_level_7_finished"))


func start_level_8():
	load_level("res://levels/Level8.tscn", "Prohozený souhlas", Callable(self, "_on_level_8_finished"))


func start_level_9():
	load_level("res://levels/Level9.tscn", "Pumpa nesouhlasu", Callable(self, "_on_level_9_finished"))


func start_level_10():
	load_level("res://levels/Level10.tscn", "Reakce", Callable(self, "_on_level_10_finished"))


func start_level_11():
	load_level("res://levels/Level11.tscn", "Odhad času", Callable(self, "_on_level_11_finished"))


func start_level_12():
	load_level("res://levels/Level12.tscn", "Odhad barvy", Callable(self, "_on_level_12_finished"))


func start_level_13():
	load_level("res://levels/Level13.tscn", "Překrytá okna", Callable(self, "_on_level_13_finished"))


func start_level_14():
	load_level("res://levels/Level14.tscn", "Fronta souhlasů", Callable(self, "_on_level_14_finished"))


func start_level_15():
	load_level("res://levels/Level15.tscn", "Neviditelný nesouhlas", Callable(self, "_on_level_15_finished"))


func start_level_16():
	load_level("res://levels/Level16.tscn", "Utíkající nesouhlas", Callable(self, "_on_level_16_finished"))


func start_level_17():
	load_level("res://levels/Level17.tscn", "Automat", Callable(self, "_on_level_17_finished"))


func start_level_18():
	load_level("res://levels/Level18.tscn", "Počet kuliček", Callable(self, "_on_level_18_finished"))


func start_level_19():
	load_level("res://levels/Level19.tscn", "Bodovací kulička", Callable(self, "_on_level_19_finished"))


func start_level_20():
	load_level("res://levels/Level20.tscn", "Terč nesouhlasu", Callable(self, "_on_level_20_finished"))


func start_level_21():
	load_level("res://levels/Level21.tscn", "Hledání slova", Callable(self, "_on_level_21_finished"))


func _on_level_1_finished():
	start_level_2()


func _on_level_2_finished():
	show_popup_window(
		"Ověření vyžadováno",
		"Systém tvrdí, že před skutečným nesouhlasem musíte projít kontrolou identity.",
		"Pokračovat",
		Callable(self, "start_level_3")
	)


func _on_level_3_finished():
	show_popup_window(
		"Přístup udělen",
		"Identita byla ověřena.\nNyní údajně můžete požádat o smazání dat.",
		"Otevřít správu dat",
		Callable(self, "start_level_4")
	)


func _on_level_4_finished():
	show_popup_window(
		"Poslední krok",
		"Systém našel finální test.\nPrý už v něm bude skutečné NESOUHLASÍM.",
		"Spustit finální test",
		Callable(self, "start_level_5")
	)


func _on_level_5_finished():
	show_popup_window(
		"Level zvládnut",
		"Záhadný systém aktivuje poslední zkoušku.",
		"Pokračovat",
		Callable(self, "start_level_6")
	)


func _on_level_6_finished():
	show_popup_window(
		"Poslední zámek",
		"Systém schoval NESOUHLASÍM za skóre v pinballu.",
		"Spustit pinball",
		Callable(self, "start_level_7")
	)


func _on_level_7_finished():
	show_popup_window(
		"Ještě jeden souhlas",
		"Systém tvrdí, že poslední volba je konečně jednoduchá.",
		"Pokračovat",
		Callable(self, "start_level_8")
	)


func _on_level_8_finished():
	show_popup_window(
		"Dokončení čeká",
		"Souhlas je prý možné odmítnout, ale jen pokud vydržíte.",
		"Pokračovat",
		Callable(self, "start_level_9")
	)


func _on_level_9_finished():
	show_popup_window(
		"Reakční test",
		"Další obrazovka vyžaduje kliknout jen tehdy, když přes linku neprochází souhlas.",
		"Pokračovat",
		Callable(self, "start_level_10")
	)


func _on_level_10_finished():
	show_popup_window(
		"Časový odhad",
		"Systém změří váš cit pro patnáct sekund.",
		"Pokračovat",
		Callable(self, "start_level_11")
	)


func _on_level_11_finished():
	show_popup_window(
		"Barevné ověření",
		"Poslední kontrola chce trefit barvu dostatečně blízko.",
		"Pokračovat",
		Callable(self, "start_level_12")
	)


func _on_level_12_finished():
	show_popup_window(
		"Překrytá okna",
		"Správné okno je někde pod falešnými dialogy.",
		"Pokračovat",
		Callable(self, "start_level_13")
	)


func _on_level_13_finished():
	show_popup_window(
		"Fronta souhlasů",
		"Systém rozjel řadu voleb. NESOUHLASÍM se mezi nimi jen mihne.",
		"Pokračovat",
		Callable(self, "start_level_14")
	)


func _on_level_14_finished():
	show_popup_window(
		"Neviditelné tlačítko",
		"Systém tlačítko schoval mimo jistotu zraku. Časem se prozradí.",
		"Pokračovat",
		Callable(self, "start_level_15")
	)


func _on_level_15_finished():
	show_popup_window(
		"Utíkající volba",
		"Nesouhlas už nechce zůstat na místě.",
		"Pokračovat",
		Callable(self, "start_level_16")
	)


func _on_level_16_finished():
	show_popup_window(
		"Automat",
		"Systém schoval NESOUHLASÍM do válců automatu.",
		"Pokračovat",
		Callable(self, "start_level_17")
	)


func _on_level_17_finished():
	show_popup_window(
		"Počet kuliček",
		"Stačí jen spočítat pohyblivé kuličky. Velmi férové.",
		"Pokračovat",
		Callable(self, "start_level_18")
	)


func _on_level_18_finished():
	show_popup_window(
		"Bodovací kulička",
		"Tlačítko se odemkne až po nasbírání bodů.",
		"Pokračovat",
		Callable(self, "start_level_19")
	)


func _on_level_19_finished():
	show_popup_window(
		"Terč nesouhlasu",
		"Poslední cíl se otáčí a kurzor neposlouchá.",
		"Pokračovat",
		Callable(self, "start_level_20")
	)


func _on_level_20_finished():
	show_popup_window(
		"Hledání slova",
		"Poslední formulář schoval jedno jediné NESOUHLASÍM do textu.",
		"Pokračovat",
		Callable(self, "start_level_21")
	)


func _on_level_21_finished():
	show_final_screen()


# =========================================================
# DIRECT LEVEL START (for level select menu)
# =========================================================

func start_level_1_direct():
	GameState.reset_system_control()
	start_level_1()


func start_level_2_direct():
	start_level_2()


func start_level_3_direct():
	start_level_3()


func start_level_4_direct():
	start_level_4()


func start_level_5_direct():
	start_level_5()


func start_level_6_direct():
	start_level_6()


func start_level_7_direct():
	start_level_7()


func start_level_8_direct():
	start_level_8()


func start_level_9_direct():
	start_level_9()


func start_level_10_direct():
	start_level_10()


func start_level_11_direct():
	start_level_11()


func start_level_12_direct():
	start_level_12()


func start_level_13_direct():
	start_level_13()


func start_level_14_direct():
	start_level_14()


func start_level_15_direct():
	start_level_15()


func start_level_16_direct():
	start_level_16()


func start_level_17_direct():
	start_level_17()


func start_level_18_direct():
	start_level_18()


func start_level_19_direct():
	start_level_19()


func start_level_20_direct():
	start_level_20()


func start_level_21_direct():
	start_level_21()


func start_bonus_level_direct():
	if ResourceLoader.exists("res://levels/BonusLevel.tscn"):
		load_level("res://levels/BonusLevel.tscn", "Korekční protokol", Callable(self, "_on_bonus_level_finished"))
	else:
		show_popup_window(
			"CHYBA",
			"Soubor bonus levelu nebyl nalezen:\nres://levels/BonusLevel.tscn",
			"Zpět na plochu",
			Callable(self, "go_to_desktop")
		)


# =========================================================
# BONUS / SYSTEM CONTROL 100 %
# =========================================================

func _on_system_control_maxed():
	start_menu.visible = false

	if ResourceLoader.exists("res://levels/BonusLevel.tscn"):
		load_level("res://levels/BonusLevel.tscn", "Korekční protokol", Callable(self, "_on_bonus_level_finished"))
	else:
		show_popup_window(
			"KONTROLA SYSTÉMU 100 %",
			"Soubor bonus levelu nebyl nalezen:\nres://levels/BonusLevel.tscn\n\nVytvoř BonusLevel.tscn, jinak se bonus nespustí.",
			"Zpět na plochu",
			Callable(self, "go_to_desktop")
		)


func _on_bonus_level_finished():
	GameState.reset_system_control()
	go_to_desktop()


# =========================================================
# XP / WINDOWS 7 INSPIRED STYLES
# =========================================================

func make_taskbar_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.24, 0.62)
	sb.border_width_top = 2
	sb.border_color = Color(0.47, 0.68, 1.0)
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	return sb


func make_start_menu_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.94, 0.97, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.10, 0.32, 0.78)
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_bottom_right = 5
	sb.shadow_color = Color(0, 0, 0, 0.38)
	sb.shadow_size = 10
	return sb


func make_shadow_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.18)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	return sb


func make_window_frame_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 0.75, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.05, 0.28, 0.72)
	sb.corner_radius_top_left = 11
	sb.corner_radius_top_right = 11
	sb.corner_radius_bottom_left = 9
	sb.corner_radius_bottom_right = 9
	sb.shadow_color = Color(1, 1, 1, 0.25)
	sb.shadow_size = 2
	return sb


func make_title_bar_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.38, 0.86)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.65, 0.82, 1.0)
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.shadow_color = Color(1, 1, 1, 0.16)
	sb.shadow_size = 3
	return sb


func make_content_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.96, 0.92)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.72, 0.75, 0.80)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb


func make_monitor_shadow_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.16)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.shadow_color = Color(0, 0, 0, 0.42)
	sb.shadow_size = 12
	return sb


func make_monitor_window_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.60, 0.78, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.05, 0.28, 0.72)
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.corner_radius_bottom_left = 7
	sb.corner_radius_bottom_right = 7
	return sb


func make_monitor_title_bar_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.38, 0.86)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.65, 0.82, 1.0)
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 7
	return sb


func make_monitor_content_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.96, 0.92)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.72, 0.75, 0.80)
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_bottom_right = 5
	return sb


func make_monitor_bar_background_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.86, 0.84)
	sb.border_color = Color(0.38, 0.43, 0.52)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb


func style_start_button(btn: Button):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.23, 0.62, 0.10)
	normal.border_color = Color(0.11, 0.38, 0.05)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.shadow_color = Color(1, 1, 1, 0.25)
	normal.shadow_size = 2

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.33, 0.76, 0.16)
	hover.border_color = Color(0.13, 0.45, 0.08)
	hover.border_width_left = 1
	hover.border_width_top = 1
	hover.border_width_right = 1
	hover.border_width_bottom = 1
	hover.corner_radius_top_left = 16
	hover.corner_radius_top_right = 16
	hover.corner_radius_bottom_left = 16
	hover.corner_radius_bottom_right = 16
	hover.shadow_color = Color(1, 1, 1, 0.30)
	hover.shadow_size = 2

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.17, 0.46, 0.07)
	pressed.border_color = Color(0.08, 0.26, 0.04)
	pressed.border_width_left = 1
	pressed.border_width_top = 1
	pressed.border_width_right = 1
	pressed.border_width_bottom = 1
	pressed.corner_radius_top_left = 16
	pressed.corner_radius_top_right = 16
	pressed.corner_radius_bottom_left = 16
	pressed.corner_radius_bottom_right = 16

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 15)


func style_menu_button(btn: Button):
	var normal = make_soft_button_style(Color(0.97, 0.98, 1.0), Color(0.56, 0.64, 0.78), 5)
	var hover = make_soft_button_style(Color(0.88, 0.93, 1.0), Color(0.20, 0.44, 0.88), 5)
	var pressed = make_soft_button_style(Color(0.76, 0.85, 0.98), Color(0.16, 0.34, 0.72), 5)
	var disabled = make_soft_button_style(Color(0.82, 0.82, 0.82), Color(0.65, 0.65, 0.65), 5)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color(0.07, 0.07, 0.07))
	btn.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	btn.add_theme_color_override("font_disabled_color", Color(0.42, 0.42, 0.42))
	btn.add_theme_font_size_override("font_size", 14)


func style_window_button(btn: Button):
	var normal = make_soft_button_style(Color(0.94, 0.94, 0.91), Color(0.46, 0.50, 0.58), 4)
	var hover = make_soft_button_style(Color(0.98, 0.99, 1.0), Color(0.20, 0.44, 0.86), 4)
	var pressed = make_soft_button_style(Color(0.78, 0.86, 0.98), Color(0.16, 0.33, 0.68), 4)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	btn.add_theme_color_override("font_hover_color", Color(0.03, 0.03, 0.03))
	btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	btn.add_theme_font_size_override("font_size", 14)


func make_soft_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
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
	sb.shadow_color = Color(1, 1, 1, 0.18)
	sb.shadow_size = 1
	return sb
