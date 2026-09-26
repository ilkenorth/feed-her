extends Node2D

@export var width: int = 8
@export var height: int = 10
@export var offset: int = 64
@export var piece_scene: PackedScene

var possible_colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.PURPLE, Color.ORANGE]

var grid: Array = []

func _ready():
	make_2d_array()
	spawn_pieces()

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
			var piece = piece_scene.instantiate()
			add_child(piece)
			piece.position = Vector2(column * offset, row * offset)
			piece.get_node("Sprite2D").modulate = random_color
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
		grid[piece.column][piece.row] = null
		piece.queue_free()

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
			var piece = piece_scene.instantiate()
			add_child(piece)
			piece.position = Vector2(column * offset, (row - (empty_row + 1)) * offset)
			piece.get_node("Sprite2D").modulate = random_color
			piece.column = column
			piece.row = row
			grid[column][row] = piece
			piece.move(Vector2(column * offset, row * offset))

func swap_pieces(column, row, direction):
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
				destroy_matches(matches)
				if matches.size() > 0:
					destroy_matches(matches)
					apply_gravity()
			else:
				grid[column][row] = first_piece
				grid[new_col][new_row] = other_piece
				first_piece.column = column
				first_piece.row = row
				other_piece.column = new_col
				other_piece.row = new_row
				first_piece.move(Vector2(first_piece.column * offset, first_piece.row * offset))
				other_piece.move(Vector2(other_piece.column * offset, other_piece.row * offset))
