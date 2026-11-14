extends Control
## The main menu and the lobby, built in code so the scene needs no widgets.
##
## Menu: pick a name, then Play solo, Host a game, or Join a game at an
## address. Lobby: the list of players who joined; the host presses Start.

var _menu_box: VBoxContainer
var _lobby_box: VBoxContainer
var _name_edit: LineEdit
var _address_edit: LineEdit
var _status: Label
var _player_list: Label
var _start_button: Button
var _menu_buttons: Array[Button] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	Net.players_changed.connect(_on_players_changed)
	Net.join_failed.connect(_on_join_failed)
	_status.text = Net.notice
	Net.notice = ""
	_show_lobby(false)


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.02, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(Config.tuning.menu_width, 0.0)
	column.add_theme_constant_override("separation", Config.tuning.menu_spacing)
	center.add_child(column)
	var title := Label.new()
	title.text = "CRYO BREACH"
	title.add_theme_font_size_override("font_size", Config.tuning.menu_title_size)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	_build_menu(column)
	_build_lobby(column)


func _build_menu(column: VBoxContainer) -> void:
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", Config.tuning.menu_spacing)
	column.add_child(_menu_box)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Your name"
	_name_edit.text = Net.local_name
	_name_edit.max_length = Config.tuning.max_name_length
	_menu_box.add_child(_name_edit)
	_menu_buttons.append(_add_button(_menu_box, "Play solo", _on_solo_pressed))
	_menu_buttons.append(_add_button(_menu_box, "Host a game", _on_host_pressed))
	_address_edit = LineEdit.new()
	_address_edit.placeholder_text = "Host address"
	_address_edit.text = "127.0.0.1"
	_menu_box.add_child(_address_edit)
	_menu_buttons.append(_add_button(_menu_box, "Join a game", _on_join_pressed))
	_add_button(_menu_box, "Quit", get_tree().quit)


func _build_lobby(column: VBoxContainer) -> void:
	_lobby_box = VBoxContainer.new()
	_lobby_box.add_theme_constant_override("separation", Config.tuning.menu_spacing)
	column.add_child(_lobby_box)
	var heading := Label.new()
	heading.text = "Lobby"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_box.add_child(heading)
	_player_list = Label.new()
	_lobby_box.add_child(_player_list)
	_start_button = _add_button(_lobby_box, "Start match", _on_start_pressed)
	_add_button(_lobby_box, "Leave", Net.leave)


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button


## Shows the lobby (after hosting or joining) or the menu.
func _show_lobby(show_it: bool) -> void:
	_menu_box.visible = not show_it
	_lobby_box.visible = show_it
	_start_button.visible = show_it and multiplayer.is_server()
	if show_it:
		_refresh_player_list()


func _refresh_player_list() -> void:
	var lines := PackedStringArray()
	var ids := Net.players.keys()
	ids.sort()
	for peer_id: int in ids:
		var line: String = Net.players[peer_id].name
		if peer_id == 1:
			line += "  (host)"
		if peer_id == multiplayer.get_unique_id():
			line += "  (you)"
		lines.append(line)
	_player_list.text = "\n".join(lines)
	if multiplayer.is_server():
		_status.text = "Others can join at your address, port %d." % Config.tuning.default_port
	else:
		_status.text = "Waiting for the host to start the match."


func _read_name() -> void:
	var typed := _name_edit.text.strip_edges()
	if not typed.is_empty():
		Net.local_name = typed


func _set_menu_enabled(enabled: bool) -> void:
	for button in _menu_buttons:
		button.disabled = not enabled


func _on_solo_pressed() -> void:
	_read_name()
	Net.play_offline()
	Net.host_start_match(RoomAssignment.make_phase2())


func _on_host_pressed() -> void:
	_read_name()
	var error := Net.host_game(Config.tuning.default_port)
	if error != OK:
		_status.text = "Could not host a game (error %d). Is the port in use?" % error
		return
	_show_lobby(true)


func _on_join_pressed() -> void:
	_read_name()
	var address := _address_edit.text.strip_edges()
	var error := Net.join_game(address, Config.tuning.default_port)
	if error != OK:
		_status.text = "Could not start joining (error %d)." % error
		return
	_status.text = "Connecting to %s..." % address
	_set_menu_enabled(false)


func _on_start_pressed() -> void:
	Net.host_start_match(RoomAssignment.make_phase2())


func _on_players_changed() -> void:
	var in_lobby := multiplayer.is_server() or Net.players.has(multiplayer.get_unique_id())
	if in_lobby and Net.is_networked():
		_show_lobby(true)
	elif _lobby_box.visible:
		_refresh_player_list()


func _on_join_failed() -> void:
	_status.text = "Could not connect to the host."
	_set_menu_enabled(true)
