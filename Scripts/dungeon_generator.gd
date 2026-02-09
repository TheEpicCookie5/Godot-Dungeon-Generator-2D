extends Node

@export var tile_map_layer: TileMapLayer
@export var tile_size: int = 16

var floor_tile: Vector2i = Vector2i(1, 1)

var right_wall_tile: Vector2i = Vector2i(2, 1)
var left_wall_tile: Vector2i = Vector2i(0, 1)
var top_wall_tile: Vector2i = Vector2i(1, 0)
var bottom_wall_tile: Vector2i = Vector2i(1, 2)

var top_right_corner_tile: Vector2i = Vector2i(2, 0)
var top_left_corner_tile: Vector2i = Vector2i(0, 0)
var bottom_right_corner_tile: Vector2i = Vector2i(2, 2)
var bottom_left_corner_tile: Vector2i = Vector2i(0, 2)

var right_top_corridor_wall_tile: Vector2i = Vector2i(0, 4)
var left_top_corridor_wall_tile: Vector2i = Vector2i(1, 4)
var right_bottom_corridor_wall_tile: Vector2i = Vector2i(0, 3)
var left_bottom_left_corridor_wall_tile: Vector2i = Vector2i(1, 3)

var rooms: Array[Room]
var corridors: Array[Corridor]

var starting_position: Vector2i = Vector2i(16, 16)

@export var min_room_size: int = 8
@export var max_room_size: int = 12

@export var min_corridor_length: int = 1
@export var max_corridor_length: int = 3

#min_corridor_width must be: min_room_size - (min_room_size - 2)
#max_corridor_width must be: max_room_size - (max_room_size - 2)
@export var min_corridor_width: int = 2
@export var max_corridor_width: int = 3

@export_range(3, 100) var max_room_count: int = 100

@export var player: CharacterBody2D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var generated_rooms_count: int = 0

var pos_to_atlas_coords: Dictionary[Vector2i, Vector2i]

func _ready() -> void:
	rng.seed = randi()
	
	var starting_room: Room = random_room(starting_position, Corridor.new())
	rooms.append(starting_room)
	
	var tile_size_float: float = float(tile_size)
	var room_w_float: float = float(starting_room.w)
	var room_h_float: float = float(starting_room.h)
	
	#spawns the player in the middle of the starting room
	player.position = Vector2(tile_size_float + (tile_size_float * room_w_float / 2.0), tile_size_float + (tile_size_float * room_h_float / 2.0)) - Vector2(tile_size, tile_size)
	
	#adds the data to the pos_to_atlas_coords dictionary
	add_room_tile_data(starting_room)
	
	#creates 1/3 of the rooms using the max room count
	layout_branch(starting_room)
	
	#creates the rest of the rooms and connects them to existing rooms so that there are dead-ends
	add_rooms_to_existing_rooms()
	
	place_all_tiles()

func place_all_tiles():
	for i: Vector2i in pos_to_atlas_coords.keys():
		change_tile(i, pos_to_atlas_coords[i])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reload_scene"):
		get_tree().reload_current_scene()

func random_room(corridor_end: Vector2i, corridor: Corridor) -> Room:
	var room: Room = Room.new()
	var room_size: Vector2 = random_room_size()
	
	room.w = int(room_size.x)
	room.h = int(room_size.y)
	
	if corridor_end != starting_position:
		if corridor.dir == 0:
			room.x = int(rng.randi_range(corridor_end.x - (room.w + tile_size), corridor_end.x - (room.w * tile_size) + (corridor.width + 2) * tile_size))
			room.y = corridor_end.y - (room.h * tile_size)
		elif corridor.dir == 1:
			room.x = corridor_end.x
			room.y = int(rng.randi_range(corridor_end.y - (room.h + tile_size), corridor_end.y - (room.h - 2 - corridor.width) * tile_size))
		elif corridor.dir == 2:
			room.x = int(rng.randi_range(corridor_end.x - (room.w + tile_size), corridor_end.x - (room.w * tile_size) + (corridor.width + 2) * tile_size))
			room.y = corridor_end.y
		elif corridor.dir == 3:
			room.x = corridor_end.x - (room.w * tile_size) + tile_size
			room.y = int(rng.randi_range(corridor_end.y - (room.h + tile_size), corridor_end.y - (room.h - 2 - corridor.width) * tile_size))
	else:
		room.x = corridor.x
		room.y = corridor.y
	
	var first_tile_position: Vector2i = to_tile_position(room.x, room.y)
	
	room.tile_x = first_tile_position.x
	room.tile_y = first_tile_position.y
	
	return room

func add_connected_room_tile_data(room: Room, corridor: Corridor, corridor_end: Vector2i):
	if corridor.dir == 0:
		pos_to_atlas_coords[to_tile_position(corridor_end.x - tile_size, room.y + (room.h * tile_size) - tile_size)] = left_bottom_left_corridor_wall_tile
		pos_to_atlas_coords[to_tile_position(corridor_end.x + (tile_size * corridor.width), room.y + (room.h * tile_size) - tile_size)] = right_bottom_corridor_wall_tile
		
		pos_to_atlas_coords[to_tile_position(corridor_end.x, room.y + (room.h * tile_size) - tile_size)] = floor_tile
		
		for w: int in range(1, corridor.width):
			pos_to_atlas_coords[to_tile_position(corridor_end.x + (tile_size * w), room.y + (room.h * tile_size) - tile_size)] = floor_tile
			
	elif corridor.dir == 1:
		for w: int in range(1, corridor.width + 1):
			pos_to_atlas_coords[to_tile_position(corridor_end.x, corridor_end.y + (tile_size * w) - tile_size)] = floor_tile
			
		pos_to_atlas_coords[to_tile_position(corridor_end.x, corridor_end.y - tile_size)] = left_top_corridor_wall_tile
		pos_to_atlas_coords[to_tile_position(corridor_end.x, corridor_end.y + (tile_size * corridor.width))] = left_bottom_left_corridor_wall_tile
	
	elif corridor.dir == 2:
		for w: int in range(1, corridor.width + 1):
			pos_to_atlas_coords[to_tile_position(corridor_end.x + (tile_size * w) - tile_size, corridor_end.y)] = floor_tile
			
		pos_to_atlas_coords[to_tile_position(corridor_end.x - tile_size, corridor_end.y)] = left_top_corridor_wall_tile
		pos_to_atlas_coords[to_tile_position(corridor_end.x + (tile_size * corridor.width), corridor_end.y)] = right_top_corridor_wall_tile
	
	elif corridor.dir == 3:
		for w: int in range(1, corridor.width + 1):
			pos_to_atlas_coords[to_tile_position(corridor_end.x, corridor_end.y + (tile_size * w) - tile_size)] = floor_tile
			
		pos_to_atlas_coords[to_tile_position(corridor_end.x, corridor_end.y - tile_size)] = right_top_corridor_wall_tile
		pos_to_atlas_coords[to_tile_position(corridor_end.x, corridor_end.y + (tile_size * corridor.width))] = right_bottom_corridor_wall_tile

func random_room_size() -> Vector2:
	return Vector2(rng.randi_range(min_room_size, max_room_size), rng.randi_range(min_room_size, max_room_size))

func random_corridor(room: Room, dir: int) -> Corridor:
	var corridor: Corridor = Corridor.new()
	
	corridor.length = rng.randi_range(min_corridor_length, max_corridor_length)
	corridor.width = rng.randi_range(min_corridor_width, max_corridor_width)
	
	if dir == 0:
		corridor.x = int((rng.randi_range(room.tile_x + 2, room.tile_x + (room.w - corridor.width - 2) )) * tile_size)
		corridor.y = room.y
	elif dir == 1:
		corridor.x = room.x + room.w * tile_size
		corridor.y = int((rng.randi_range(room.tile_y + 2, room.tile_y + (room.h - corridor.width - 2) )) * tile_size)
	elif dir == 2:
		corridor.x = int((rng.randi_range(room.tile_x + 2, room.tile_x + (room.w - corridor.width - 2) )) * tile_size)
		corridor.y = room.y + room.h * tile_size
	elif dir == 3:
		corridor.x = room.x - tile_size
		corridor.y = int((rng.randi_range(room.tile_y + 2, room.tile_y + (room.h - corridor.width - 2))) * tile_size)
	
	corridor.dir = dir
	
	return corridor

func get_corridor_end(corridor: Corridor) -> Vector2i:
	match corridor.dir:
		0:
			return Vector2i(corridor.x, corridor.y - (tile_size * corridor.length))
		1:
			return Vector2i(corridor.x + (tile_size * corridor.length), corridor.y)
		2:
			return Vector2i(corridor.x, corridor.y + (tile_size * corridor.length))
		_:
			return Vector2i(corridor.x - (tile_size * corridor.length), corridor.y)

func add_corridor_tile_data(corridor: Corridor, dir: int):
	if dir == 0:
		pos_to_atlas_coords[to_tile_position(corridor.x, corridor.y)] = floor_tile
		
		for l in range(1, corridor.length + 1):
			for w in range(1, corridor.width + 1):
				pos_to_atlas_coords[to_tile_position(corridor.x, corridor.y - (tile_size * l))] = floor_tile
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * w), corridor.y)] = floor_tile
				
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * w), corridor.y - (tile_size * l))] = floor_tile
				
				pos_to_atlas_coords[to_tile_position(corridor.x - 1, corridor.y - (tile_size * l))] = left_wall_tile
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * corridor.width), corridor.y - (tile_size * l))] = right_wall_tile
			
		pos_to_atlas_coords[to_tile_position(corridor.x - 1, corridor.y)] = left_top_corridor_wall_tile
		pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * corridor.width), corridor.y)] = right_top_corridor_wall_tile
		
	elif dir == 1:
		for l in range(1, corridor.length + 1):
			for w in range(1, corridor.width + 1):
				pos_to_atlas_coords[to_tile_position(corridor.x - tile_size, corridor.y + (tile_size * w - 1))] = floor_tile
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * l) - tile_size, corridor.y + (tile_size * w - 1))] = floor_tile
				
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * l) - tile_size, corridor.y - 1)] = top_wall_tile
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * l) - tile_size, corridor.y + (tile_size * w))] = bottom_wall_tile
		
		pos_to_atlas_coords[to_tile_position(corridor.x - tile_size, corridor.y - 1)] = right_top_corridor_wall_tile
		pos_to_atlas_coords[to_tile_position(corridor.x - tile_size, corridor.y + (tile_size * corridor.width))] = right_bottom_corridor_wall_tile
	
	elif dir == 2:
		for l in range(1, corridor.length + 1):
			for w in range(1, corridor.width + 1):
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * w) - tile_size, corridor.y - tile_size)] = floor_tile
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * w) - tile_size, corridor.y + (tile_size * l) - tile_size)] = floor_tile
				
				pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * w), corridor.y + (tile_size * l) - tile_size)] = right_wall_tile
				pos_to_atlas_coords[to_tile_position(corridor.x - tile_size, corridor.y + (tile_size * l) - tile_size)] = left_wall_tile
		
		pos_to_atlas_coords[to_tile_position(corridor.x - 1, corridor.y - tile_size)] = left_bottom_left_corridor_wall_tile
		pos_to_atlas_coords[to_tile_position(corridor.x + (tile_size * corridor.width), corridor.y - tile_size)] = right_bottom_corridor_wall_tile
	
	elif dir == 3:
		for l in range(1, corridor.length + 1):
			for w in range(1, corridor.width + 1):
				pos_to_atlas_coords[to_tile_position(corridor.x + tile_size, corridor.y + (tile_size * w) - tile_size)] = floor_tile
				pos_to_atlas_coords[to_tile_position(corridor.x - (tile_size * l) + tile_size, corridor.y + (tile_size * w) - tile_size)] = floor_tile
				
				pos_to_atlas_coords[to_tile_position(corridor.x - (tile_size * l) + tile_size, corridor.y + (tile_size * w))] = bottom_wall_tile
				pos_to_atlas_coords[to_tile_position(corridor.x - (tile_size * l) + tile_size, corridor.y - 1)] = top_wall_tile
		
		pos_to_atlas_coords[to_tile_position(corridor.x + tile_size, corridor.y - 1)] = left_top_corridor_wall_tile
		pos_to_atlas_coords[to_tile_position(corridor.x + tile_size, corridor.y + (tile_size * corridor.width))] = left_bottom_left_corridor_wall_tile

func layout_branch(connecting_room: Room):
	for i in range(1, int(floor(float(max_room_count) / 3.0))):
		var room: Room = make_more_rooms(connecting_room)
		
		connecting_room = room
	
	generated_rooms_count += int(floor(float(max_room_count) / 3.0))

func make_more_rooms(connecting_room: Room) -> Room:
	var room: Room = Room.new()
	var corridor: Corridor = Corridor.new()
	
	var retries: int = 0
	var valid: bool = false
	
	#0: up, 1: right, 2: down, 3: left
	var dir: int = rng.randi_range(0, 3)
	
	var failed_directions: Array[int]
	
	#tries to make a room that doesn't collide with anything
	while valid == false and retries < (max_room_count * 4) + 1:
		
		#gets a direction that hasn't been tried out
		dir = get_dir(failed_directions)
		
		if dir == -1 or connecting_room == null:
			return null
		
		corridor = random_corridor(connecting_room, dir)
		
		var corridor_end: Vector2i = get_corridor_end(corridor)
		
		room = random_room(corridor_end, corridor)
		
		if !is_layout_conflicting(room):
			valid = true
			
			add_corridor_tile_data(corridor, dir)
			
			add_room_tile_data(room)
			add_connected_room_tile_data(room, corridor, corridor_end)
		else:
			if !failed_directions.has(dir):
				failed_directions.append(dir)
		
		retries += 1
	
	corridors.append(corridor)
	rooms.append(room)
	return room

func get_dir(failed_directions: Array[int]) -> int:
	var directions: Array[int] = [ 0, 1, 2, 3 ]
	
	directions.shuffle()
	
	for dir: int in directions:
		if !failed_directions.has(dir):
			return dir
	
	return -1

func is_layout_conflicting(room: Room) -> bool:
	for r: Room in rooms:
		if rooms_colliding(r, room):
			return true
			
	return false

func rooms_colliding(r1: Room, r2: Room) -> bool:
	if(r1.tile_x < r2.tile_x + r2.w and
		r1.tile_x + r1.w > r2.tile_x and
		r1.tile_y < r2.tile_y + r2.h and
		r1.tile_y + r1.h > r2.tile_y):
			return true
			
	return false

func add_rooms_to_existing_rooms():
	var second_rooms_count: int = int(floor(float(max_room_count) / 3.0))
	var second_rooms_starting_index: int = rooms.size()
	
	add_existing_rooms_loop(second_rooms_count, 1)
	
	generated_rooms_count += second_rooms_count
	var last_rooms_count: int = max_room_count - generated_rooms_count
	
	add_existing_rooms_loop(last_rooms_count, second_rooms_starting_index)
	
	print("rooms generated: ", rooms.size())
	print("\n")

func add_existing_rooms_loop(looping_num: int, min_index: int):
	for i: int in looping_num:
		var random_index: int = rng.randi_range(min_index, rooms.size() - 1)
		var _room: Room = make_more_rooms(rooms[random_index])

func add_room_tile_data(room: Room):
	var tile: Vector2i = Vector2i.ZERO
	
	for w: int in room.w:
		for h: int in room.h:
			var tile_position: Vector2i = to_tile_position(room.x + w * tile_size, room.y + h * tile_size)
			
			tile = return_tile(room.w, room.h, w, h)
			pos_to_atlas_coords[tile_position] = tile

func return_tile(room_w: int, room_h: int, w: int, h: int) -> Vector2i:
	if w == 0:
		if h == 0: return top_left_corner_tile
		elif h == room_h - 1: return bottom_left_corner_tile
		
		return left_wall_tile
	elif w == room_w - 1:
		if h == 0: return top_right_corner_tile
		elif h == room_h - 1: return bottom_right_corner_tile
		
		return right_wall_tile
	elif w > 0 and w < room_w - 1 and h == 0 or h == room_h - 1:
		if h == 0: return top_wall_tile
		
		return bottom_wall_tile
	else:
		return floor_tile

func change_tile(tile_position: Vector2i, tile: Vector2i):
	tile_map_layer.set_cell(tile_position, 0, tile, 0)

func to_tile_position(x: int, y: int) -> Vector2i:
	return Vector2i(tile_map_layer.local_to_map(Vector2i(x, y)))
