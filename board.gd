extends Node2D

@export var width: int = 8
@export var height: int = 10
@export var offset: int = 64
@export var piece_scene: PackedScene

var possible_colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.PURPLE, Color.ORANGE]

var grid: Array = []
var busy: bool = false
var info_label: Label
var character_box: ColorRect
var character_label: Label

func _ready():
	make_2d_array()
	spawn_pieces()
	setup_ui()

func make_2d_array():
	for column in width:
		grid.append([])
		for row in height:
			grid[column].append(null)

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

func find_matches() -> Array:
	var matches = []
	for column in width:
		for row in height:
			var piece = grid[column][row]
			if piece == null:
				continue
			var color = piece.get_node("Sprite2D").modulate
			if column < width - 2:
				var p1 = grid[column + 1][row]
				var p2 = grid[column + 2][row]
				if p1 != null and p2 != null:
					if p1.get_node("Sprite2D").modulate == color and p2.get_node("Sprite2D").modulate == color:
						matches.append(piece)
						matches.append(p1)
						matches.append(p2)
			if row < height - 2:
				var p1 = grid[column][row + 1]
				var p2 = grid[column][row + 2]
				if p1 != null and p2 != null:
					if p1.get_node("Sprite2D").modulate == color and p2.get_node("Sprite2D").modulate == color:
						matches.append(piece)
						matches.append(p1)
						matches.append(p2)
	return matches

func destroy_matches(matches: Array):
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
			if grid[column][row] != null:
				if row != empty_row:
					var piece = grid[column][row]
					grid[column][empty_row] = piece
					grid[column][row] = null
					piece.row = empty_row
					piece.move(Vector2(piece.column * offset, piece.row * offset))
				empty_row -= 1
		for row in range(empty_row, -1, -1):
			var random_color = possible_colors.pick_random()
			var random_type = "healthy" if random_color in [Color.GREEN, Color.BLUE] else "unhealthy"
			var piece = piece_scene.instantiate()
			add_child(piece)
			piece.position = Vector2(column * offset, (row - (empty_row + 1)) * offset)
			piece.get_node("Sprite2D").modulate = random_color
			piece.piece_type = random_type
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
	if new_col >= 0 and new_col < width and new_row >= 0 and new_row < height:
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
	if not GameState.is_game_finished():
		busy = false


func resolve_matches():
	var matches = find_matches()
	while matches.size() > 0:
		destroy_matches(matches)
		await get_tree().create_timer(0.2).timeout
		apply_gravity()
		await get_tree().create_timer(0.3).timeout
		matches = find_matches()
	if GameState.is_level_complete():
		await complete_level()

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
	info_label.text = "Level " + str(GameState.current_level) + "  |  Cleared: " + str(GameState.pieces_cleared) + " / " + str(GameState.get_goal())
	update_character()

func clear_board():
	for column in width:
		for row in height:
			if grid[column][row] != null:
				grid[column][row].queue_free()
				grid[column][row] = null

func complete_level():
	info_label.text = "Level " + str(GameState.current_level) + " completed!"
	await get_tree().create_timer(1.5).timeout
	GameState.next_level()
	if GameState.is_game_finished():
		info_label.text = "Game over (final will be here)"
		return
	clear_board()
	spawn_pieces()
	update_ui()

func update_character():
	var size_px = 60 + GameState.current_level * 15
	character_box.size = Vector2(size_px, size_px)
	var t = clampf((GameState.nutrition_score + 40) / 80.0, 0.0, 1.0)
	character_box.color = Color.RED.lerp(Color.GREEN, t)
	character_label.text = GameState.get_life_stage() + "\n" + GameState.get_health_state()
