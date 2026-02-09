extends CharacterBody2D

const SPEED: float = 100.0

@onready var camera: Camera2D = get_node("Camera2D")

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down") as Vector2
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom += Vector2(0.1, 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom -= Vector2(0.1, 0.1)
