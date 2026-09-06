extends Node2D

@onready var label: Label = $Label
const some_cell_scene = preload("res://some_cell.tscn")
enum Direction {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	NONE
}

var height: int = 5
var width: int = 6
var field_init_data: Array[bool] = [
	true,	true,	true,	true,	true,	true,
	true,	true,	true,	true,	true,	true,
	true,	true,	false,	true,	true,	true,
	true,	true,	true,	true,	true,	true,
	true,	true,	true,	true,	true,	true
]

var cell_size: int = 64
var current_row: int = 0
var current_col: int = 0
var final_row: int = 2
var filan_col: int = 3
var prev_mouse_pos: Vector2

class Cell:
	var enabled: bool
	var some_cell: SomeCell
	func _init(sc: SomeCell) -> void:
		some_cell = sc
var field: Array[Cell] = []

var started: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_field()

func _physics_process(delta: float) -> void:
	if(started):
		if(check_mouse_movement()):
			started = false
		
	if(Input.is_key_pressed(KEY_R)):
		lets_get_it_restarted()
	if(Input.is_key_pressed(KEY_ESCAPE)):
		lets_get_it_stopped()

func init_field():
	field.resize(height * width)
	for i in range(height):
		for j in range(width):
			field[i * width + j] = Cell.new(some_cell_scene.instantiate())
			add_child(field[i * width + j].some_cell)
			field[i * width + j].some_cell.position = Vector2(j * cell_size, i * cell_size)
	label.position = Vector2(50, height * cell_size + 50)
	label.text = "Press R to start/restart\nPress Esc to stop\n"


func lets_get_it_restarted():
	for i in range(height):
		for j in range(width):
			field[i * width + j].enabled = field_init_data[i * width + j]
			field[i * width + j].some_cell.set_active(field[i * width + j].enabled)
	field[final_row * width + filan_col].some_cell.set_final()
	field[0].some_cell.set_current()
	current_row = 0
	current_col = 0
	prev_mouse_pos = Vector2(cell_size * .5, cell_size * .5)
	DisplayServer.warp_mouse(prev_mouse_pos)
	started = true

func lets_get_it_stopped():
	for i in range(height):
		for j in range(width):
			field[i * width + j].enabled = true
			field[i * width + j].some_cell.set_active(field[i * width + j].enabled)
	started = false

# Возвращает true, если игра завершена
func check_mouse_movement() -> bool:
	var top_limit: int = current_row * cell_size
	var bottom_limit: int = current_row * cell_size + cell_size
	var left_limit: int = current_col * cell_size
	var right_limit: int = current_col * cell_size + cell_size
	var new_mouse_pos: Vector2 = get_global_mouse_position()
	var mouse_vector: Vector2 = new_mouse_pos - prev_mouse_pos
	
	# Проверяем выходы за пределы текущей клетки
	if(new_mouse_pos.y < top_limit || new_mouse_pos.y > bottom_limit || new_mouse_pos.x < left_limit || new_mouse_pos.x > right_limit):
		# Проверяем направление выхода по порядку: верх, лево, низ, право
		# Векторы от предыдущего положения до углов клетки
		var v_to_top_right: Vector2 = Vector2(right_limit - prev_mouse_pos.x, top_limit - prev_mouse_pos.y)
		var v_to_top_left: Vector2 = Vector2(left_limit - prev_mouse_pos.x, top_limit - prev_mouse_pos.y)
		var v_to_bottom_right: Vector2 = Vector2(right_limit - prev_mouse_pos.x, bottom_limit - prev_mouse_pos.y)
		var v_to_bottom_left: Vector2 = Vector2(left_limit - prev_mouse_pos.x, bottom_limit - prev_mouse_pos.y)
		var direction: Direction = Direction.NONE
		# Проверка на выход вверх
		if(new_mouse_pos.y < top_limit && v_to_top_right.orthogonal().dot(mouse_vector) > 0 && v_to_top_left.orthogonal().dot(mouse_vector) < 0):
			direction = Direction.TOP
		# Проверка на выход влево
		elif(new_mouse_pos.x < left_limit && v_to_top_left.orthogonal().dot(mouse_vector) > 0 && v_to_bottom_left.orthogonal().dot(mouse_vector) < 0):
			direction = Direction.LEFT
		# Проверка на выход вниз
		elif(new_mouse_pos.y > bottom_limit && v_to_bottom_left.orthogonal().dot(mouse_vector) > 0 && v_to_bottom_right.orthogonal().dot(mouse_vector) < 0):
			direction = Direction.BOTTOM
		# Проверка на выход вправо
		elif(new_mouse_pos.x > right_limit && v_to_bottom_right.orthogonal().dot(mouse_vector) > 0 && v_to_top_right.orthogonal().dot(mouse_vector) < 0):
			direction = Direction.RIGHT
		
		# Индексы новой клетки
		var new_row = current_row - (1 if direction == Direction.TOP else 0) + (1 if direction == Direction.BOTTOM else 0)
		var new_col = current_col - (1 if direction == Direction.LEFT else 0) + (1 if direction == Direction.RIGHT else 0)
		# Проверка доступности новой клетки
		var is_ok: bool = false
		if(new_row > -1 && new_row < height && new_col > -1 && new_col < width && field[new_row * width + new_col].enabled):
			is_ok = true
		
		# Перемещаем курсор на границы клетки
		var bound_position: Vector2
		if(direction == Direction.TOP || direction == Direction.BOTTOM):
			bound_position.y = top_limit if direction == Direction.TOP else bottom_limit
			bound_position.x = prev_mouse_pos.x + mouse_vector.x * (bound_position.y - prev_mouse_pos.y) / mouse_vector.y
		if(direction == Direction.LEFT || direction == Direction.RIGHT):
			bound_position.x = left_limit if direction == Direction.LEFT else right_limit
			bound_position.y = prev_mouse_pos.y + mouse_vector.y * (bound_position.x - prev_mouse_pos.x) / mouse_vector.x
		
		# Если выход недоступен, то отодвигаем курсор от границ текущей клетки на пару пикселе, обновляем значения и заканчиваем проверку
		if(!is_ok):
			bound_position.x = clamp(bound_position.x, left_limit + 2, right_limit - 2)
			bound_position.y = clamp(bound_position.y, top_limit + 2, bottom_limit - 2)
			prev_mouse_pos = bound_position
			DisplayServer.warp_mouse(prev_mouse_pos)
			return false
		# Если выход доступен, то отодвигаем курсор на пару пикселей от границ новой клетки, обновляем значения и делаем новую проверку
		else:
			bound_position.x = clamp(bound_position.x, left_limit + 2, right_limit - 2)
			bound_position.y = clamp(bound_position.y, top_limit + 2, bottom_limit - 2)
			prev_mouse_pos = bound_position
			# Блокируем текущую клетку
			field[current_row * width + current_col].enabled = false
			field[current_row * width + current_col].some_cell.set_active(false)
			# Меняем индексы текущей клетки на новые
			current_row = new_row
			current_col = new_col
			field[current_row * width + current_col].some_cell.set_current()
			# Проверяем игру на завершение
			if (current_row == final_row && current_col == filan_col):
				field[current_row * width + current_col].some_cell.set_final_win()
				return true
			# Рекурсивно проверяем перемещение курсора дальше
			return check_mouse_movement()
	# Если выхода за пределы клетки не было, то игра не завершена
	else:
		return false
