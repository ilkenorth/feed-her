extends Node2D

@export var width: int = 8
@export var height: int = 10
@export var offset: int = 64
@export var piece_scene: PackedScene

var possible_colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.PURPLE, Color.ORANGE]

var grid: Array = []
var walls: Array = []
var busy: bool = false
var game_over: bool = false
var info_label: Label
var character_box: ColorRect
var character_label: Label

func _ready():
	var screen_size = Vector2(720, 1280)
	var board_width_px = width * offset
	var board_height_px = height * offset
	position = Vector2(
		(screen_size.x - board_width_px) / 2 + offset / 2,
		(screen_size.y - board_height_px) / 2 + offset / 2 + 150
	)
	make_2d_array()
	spawn_pieces()
	if not has_possible_move():
		shuffle_board()
	setup_ui()

func make_2d_array():
	for column in width:
		grid.append([])
		walls.append([])
		for row in height:
			grid[column].append(null)
			walls[column].append(0)

func spawn_pieces():
	for column in width:
		for row in height:
			var random_color = possible_colors.pick_random()
			while match_at(column, row, random_color):
				random_color = possible_colors.pick_random()
			var random_type = "healthy" if random_color in [Color.GREEN, Color.BLUE] else "unhealthy"
			var piece = piece_scene.instantiate()
			add_child(piece)
			piece.position = Vector2(column * offset, row * offset)
			piece.get_node("Sprite2D").modulate = random_color
			piece.piece_type = random_type
			piece.special_type = "normal"
			if randf() < 0.02:
				piece.mark_as_line_clear(randf() < 0.5)
			elif randf() < 0.002:
				piece.mark_as_fate(randf() < 0.5)
			piece.column = column
			piece.row = row
			grid[column][row] = piece

func match_at(column, row, color) -> bool:
	if column > 1:
		if grid[column - 1][row] != null and grid[column - 2][row] != null:
			if grid[column - 1][row].get_node("Sprite2D").modulate == color and grid[column - 2][row].get_node("Sprite2D").modulate == color:
				return true
	if row > 1:
		if grid[column][row - 1] != null and grid[column][row - 2] != null:
			if grid[column][row - 1].get_node("Sprite2D").modulate == color and grid[column][row - 2].get_node("Sprite2D").modulate == color:
				return true
	return false

func would_match_at(c1, r1, c2, r2) -> bool:
	var color1 = grid[c1][r1].get_node("Sprite2D").modulate
	var color2 = grid[c2][r2].get_node("Sprite2D").modulate
	grid[c1][r1].get_node("Sprite2D").modulate = color2
	grid[c2][r2].get_node("Sprite2D").modulate = color1
	var matches = find_matches()
	grid[c1][r1].get_node("Sprite2D").modulate = color1
	grid[c2][r2].get_node("Sprite2D").modulate = color2
	return matches.size() > 0

func has_possible_move() -> bool:
	for column in width:
		for row in height:
			if grid[column][row] == null or walls[column][row] > 0:
				continue
			if column < width - 1 and grid[column +1][row] != null and walls[column + 1][row] == 0:
				if would_match_at(column, row, column + 1, row):
					return true
			if row < height - 1 and grid[column][row + 1] != null and walls[column][row + 1] == 0:
				if would_match_at(column, row, column, row + 1):
					return true
	return false

func shuffle_board():
	var pieces = []
	for column in width:
		for row in height:
			if grid[column][row] != null and walls[column][row] == 0:
				pieces.append(grid[column][row])
	var colors = []
	for piece in pieces:
		colors.append(piece.get_node("Sprite2D").modulate)
	colors.shuffle()
	for i in range(pieces.size()):
		var piece = pieces[i]
		var color = colors[i]
		piece.get_node("Sprite2D").modulate = color
		piece.piece_type = "healthy" if color in [Color.GREEN, Color.BLUE] else "unhealthy"
	if not has_possible_move():
		shuffle_board()
		return
	if find_matches().size() > 0:
		await resolve_matches()

func find_matches() -> Array:
	var groups = []
	var h_checked = []
	var v_checked = []
	for column in width:
		for row in height:
			var piece = grid[column][row]
			if piece == null:
				continue
			var color = piece.get_node("Sprite2D").modulate
			if piece not in h_checked:
				var h_run = [piece]
				var c = column + 1
				while c < width and grid[c][row] != null and grid[c][row].get_node("Sprite2D").modulate == color:
					h_run.append(grid[c][row])
					c += 1
				if h_run.size() >= 3:
					groups.append(h_run)
					for p in h_run:
						h_checked.append(p)
			if piece not in v_checked:
				var v_run = [piece]
				var r = row + 1
				while r < height and grid[column][r] != null and grid[column][r].get_node("Sprite2D").modulate == color:
					v_run.append(grid[column][r])
					r += 1
				if v_run.size() >= 3:
					groups.append(v_run)
					for p in v_run:
						v_checked.append(p)
	return groups

func destroy_matches(groups: Array):
	for group in groups:
		var original_size = group.size()
		if original_size >= 5:
			trigger_gather(group)
		elif original_size == 4:
			trigger_random_special(group)
		for piece in group.duplicate():
			if piece.special_type == "line_clear":
				trigger_line_clear(piece, group)
			elif piece.special_type == "fate":
				trigger_fate(piece)
	var matches = []
	for group in groups:
		for piece in group:
			matches.append(piece)
	var unique_matches = []
	for piece in matches:
		if piece not in unique_matches:
			unique_matches.append(piece)
	for piece in unique_matches:
		GameState.add_score(piece.piece_type)
		grid[piece.column][piece.row] = null
		piece.pop()
	GameState.register_clears(unique_matches.size())
	update_ui()

func apply_gravity():
	for column in width:
		var empty_row = height - 1
		for row in range(height - 1, -1, -1):
			if grid[column][row] == null:
				continue
			if walls[column][row] > 0:
				if empty_row > row:
					empty_row = row
				empty_row -= 1
				continue
			if row != empty_row:
				var piece = grid[column][row]
				grid[column][empty_row] = piece
				grid[column][row] = null
				piece.row = empty_row
				piece.move(Vector2(piece.column * offset, piece.row * offset))
			empty_row -= 1
		for row in range(empty_row, -1, -1):
			if walls[column][row] > 0:
				continue
			var random_color = possible_colors.pick_random()
			var random_type = "healthy" if random_color in [Color.GREEN, Color.BLUE] else "unhealthy"
			var piece = piece_scene.instantiate()
			add_child(piece)
			piece.position = Vector2(column * offset, (row - (empty_row + 1)) * offset)
			piece.get_node("Sprite2D").modulate = random_color
			piece.piece_type = random_type
			piece.special_type = "normal"
			if randf() < 0.02:
				piece.mark_as_line_clear(randf() < 0.5)
			elif randf() < 0.002:
				piece.mark_as_fate(randf() < 0.5)
			piece.column = column
			piece.row = row
			grid[column][row] = piece
			piece.move(Vector2(column * offset, row * offset))

func swap_pieces(column, row, direction):
	if busy:
		return
	busy = true
	var new_col = column + direction.x
	var new_row = row + direction.y
	if new_col >= 0 and new_col < width and new_row >= 0 and new_row < height and walls[column][row] == 0 and walls[new_col][new_row] == 0:
		var first_piece = grid[column][row]
		var other_piece = grid[new_col][new_row]
		if first_piece != null and other_piece != null:
			grid[column][row] = other_piece
			grid[new_col][new_row] = first_piece
			first_piece.column = new_col
			first_piece.row = new_row
			other_piece.column = column
			other_piece.row = row
			first_piece.move(Vector2(first_piece.column * offset, first_piece.row * offset))
			other_piece.move(Vector2(other_piece.column * offset, other_piece.row * offset))
			await get_tree().create_timer(0.3).timeout
			var matches = find_matches()
			if matches.size() > 0:
				await resolve_matches()
			else:
				grid[column][row] = first_piece
				grid[new_col][new_row] = other_piece
				first_piece.column = column
				first_piece.row = row
				other_piece.column = new_col
				other_piece.row = new_row
				first_piece.move(Vector2(first_piece.column * offset, first_piece.row * offset))
				other_piece.move(Vector2(other_piece.column * offset, other_piece.row * offset))
	if not GameState.is_game_finished() and not game_over:
		busy = false


func resolve_matches():
	for column in width:
		for row in height:
			if walls[column][row] > 0:
				walls[column][row] -= 1
				if walls[column][row] == 0 and grid[column][row] != null:
					grid[column][row].get_node("Sprite2D").modulate *= 2.0
	var matches = find_matches()
	while matches.size() > 0:
		destroy_matches(matches)
		await get_tree().create_timer(0.2).timeout
		apply_gravity()
		await get_tree().create_timer(0.3).timeout
		matches = find_matches()
	if game_over:
		return
	if GameState.is_level_complete():
		await complete_level()
	elif not has_possible_move():
		await shuffle_board()

func setup_ui():
	var layer = CanvasLayer.new()
	add_child(layer)
	info_label = Label.new()
	info_label.position = Vector2(20, 20)
	info_label.add_theme_font_size_override("font_size", 24)
	layer.add_child(info_label)
	character_label = Label.new()
	character_label.position = Vector2(40, 70)
	character_label.add_theme_font_size_override("font_size", 20)
	layer.add_child(character_label)
	character_box = ColorRect.new()
	character_box.position = Vector2(40, 130)
	layer.add_child(character_box)
	update_ui()

func update_ui():
	if game_over:
		return
	info_label.text = "Level " + str(GameState.current_level) + "  |  Cleared: " + str(GameState.pieces_cleared) + " / " + str(GameState.get_goal())
	update_character()

func clear_board():
	for column in width:
		for row in height:
			if grid[column][row] != null:
				grid[column][row].queue_free()
				grid[column][row] = null
			walls[column][row] = 0

func complete_level():
	info_label.text = "Level " + str(GameState.current_level) + " completed!"
	await get_tree().create_timer(1.5).timeout
	GameState.next_level()
	if GameState.is_game_finished():
		show_final_scene()
		return
	clear_board()
	spawn_pieces()
	update_ui()

func show_final_scene():
	game_over = true
	busy = true
	character_label.visible = false
	character_box.visible = false
	clear_board()
	info_label.text = "10 yıl sonra...\n\n(buraya final metni gelecek - oyuncunun healthy/unhealthy oranına bakılmaksızın sabit, acı bir son)"
	show_return_button()

func update_character():
	var size_px = 60 + GameState.current_level * 15
	character_box.size = Vector2(size_px, size_px)
	var t = clampf((GameState.nutrition_score + 40) / 80.0, 0.0, 1.0)
	character_box.color = Color.RED.lerp(Color.GREEN, t)
	character_label.text = GameState.get_life_stage() + "\n" + GameState.get_health_state()

func trigger_gather(group: Array):
	print("gather çağrıldı, grup boyutu: ", group.size())
	var color = group[0].get_node("Sprite2D").modulate
	for column in width:
		for row in height:
			var piece = grid[column][row]
			if piece != null and piece.get_node("Sprite2D").modulate == color and piece not in group:
				group.append(piece)

func trigger_random_special(group: Array):
	var choice = ["flip_type", "wall"].pick_random()
	if choice == "flip_type":
		var healthy_colors = [Color.GREEN, Color.BLUE]
		var unhealthy_colors = [Color.RED, Color.YELLOW, Color.PURPLE, Color.ORANGE]
		for column in width:
			for row in height:
				var piece = grid[column][row]
				if piece != null and walls[column][row] == 0:
					if piece.piece_type == "healthy":
						piece.get_node("Sprite2D").modulate = unhealthy_colors.pick_random()
						piece.piece_type = "unhealthy"
					else:
						piece.get_node("Sprite2D").modulate = healthy_colors.pick_random()
						piece.piece_type = "healthy"
	elif choice == "wall":
		var valid_cells = []
		for column in width:
			for row in height:
				if grid[column][row] != null and walls[column][row] == 0:
					valid_cells.append(Vector2(column, row))
		if valid_cells.size() > 0:
			var cell = valid_cells.pick_random()
			walls[cell.x][cell.y] = 5
			grid[cell.x][cell.y].get_node("Sprite2D").modulate *= 0.5

func trigger_line_clear(piece, group: Array):
	print("line_clear tetiklendi! Satır mı: ", piece.is_line_clear_row)
	if piece.is_line_clear_row:
		for column in width:
			var p = grid[column][piece.row]
			if p != null and p not in group:
				group.append(p)
	else:
		for row in height:
			var p = grid[piece.column][row]
			if p != null and p not in group:
				group.append(p)

func trigger_fate(piece):
	game_over = true
	busy = true
	character_label.visible = false
	character_box.visible = false
	if piece.fate_is_good:
		info_label.text = "Something good happened... (Buraya hikaye metni gelecek)"
	else:
		info_label.text = "Something bad happened... (Buraya hikaye metni gelecek)"
	await get_tree().create_timer(2.0).timeout
	info_label.text += "\n\nOyun bitti."
	show_return_button()

func show_return_button():
		var button = Button.new()
		button.text = "Ana Menüye Dön"
		button.position = Vector2(40, 200)
		info_label.get_parent().add_child(button)
		button.pressed.connect(_on_return_pressed)

func _on_return_pressed():
	GameState.reset_game()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		await shuffle_board()
