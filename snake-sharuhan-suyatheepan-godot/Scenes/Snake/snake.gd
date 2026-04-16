extends Node2D

class_name Snake

const BODY_SEGMENT_SIZE = 32
const SPEED = 0.2 #timer normal
const SPRINT_SPEED = 0.1#timer lower = faster
const MAX_STAMINA = 100
const STAMINA_USE = 10
const STAMINA_REGEND = 10

signal on_game_started
signal on_game_over
signal on_point_scored(points)
signal on_stamina_changed(stamina)
signal on_pause_toggled(paused)


var points = 0
var body_fragments = []
var move_direction = Vector2.ZERO
var obstacle_direction = 1
var stamina = MAX_STAMINA
var game_started= false	
var game_over = false
var paused_game = false

var body_texture = preload("res://Scenes/Snake/Snake.png")
@onready var snake_parts: Node = $SnakeParts
@onready var timer = $Timer
@export var walls: Walls
var walls_dict
var food_spawner: FoodSpawner
var obstacle: Sprite2D


func _ready():
	if game_over:
		return
	var head = Sprite2D.new()
	head.position = Vector2(0,0)
	head.scale = Vector2(1,1)
	head.texture = body_texture
	head.modulate = Color(0,0.95, 0)
	snake_parts.add_child(head)
	body_fragments.append(head)
	timer.timeout.connect(on_timeout)
	timer.stop()
	walls_dict = walls.walls_dict
	food_spawner = get_tree().get_first_node_in_group("food_spawner") as FoodSpawner
	obstacle = get_parent().get_node("Obstacle") as Sprite2D
	food_spawner.spawn_food(body_fragments)
	on_point_scored.emit(points)
	on_stamina_changed.emit(stamina)

func _input(event):
	if game_over:
		return
	if not game_started and event.is_action_pressed("Start"):
		game_started = true
		timer.start()
		on_game_started.emit()
		return
	if not game_started:
		return
	
	if event.is_action_pressed("pause"):
		if paused_game == false:
			paused_game = true
			timer.stop()
		else:
			paused_game= false
			timer.start()
		on_pause_toggled.emit(paused_game)
		return
	# Handle user input to change the move direction
	if (event.is_action_pressed("ui_right") || event.is_action_pressed("right")) and move_direction.x != -1:
		move_direction = Vector2.RIGHT
	elif (event.is_action_pressed("ui_left") or event.is_action_pressed("left")) and move_direction.x != 1:
		move_direction = Vector2.LEFT
	elif (event.is_action_pressed("ui_up") or event.is_action_pressed("up")) and move_direction.y != 1:
		move_direction = Vector2.UP
	elif (event.is_action_pressed("ui_down") or event.is_action_pressed("down")) and move_direction.y != -1:
		move_direction = Vector2.DOWN
		
		
func on_timeout():
	if game_over:
		return
	handle_stamina()
	
	var previous_head_position = body_fragments[0].position
	var new_head_position = previous_head_position + move_direction * BODY_SEGMENT_SIZE
	
	if check_wall_collision(new_head_position):
		end_game()
		return
	move_to_position(new_head_position)

	#check for snake colliding with itself
	var snake_collision = check_snake_collision()
	if(snake_collision):
		end_game()
		return
	# obstacle col d w alision	
	if new_head_position == obstacle.position: 
		end_game()
		return
	if check_obstacle_collision():
		end_game()
		return
	move_obstacle()
	#food collision
	if new_head_position == food_spawner.food_position:
		food_spawner.destroy_food()
		food_spawner.spawn_food(body_fragments)
		add_body_segment()
		points += 1
		on_point_scored.emit(points)
		
func handle_stamina():
	if Input.is_action_pressed("sprint") and stamina > 0:
		stamina -= STAMINA_USE
		if stamina < 0:
			stamina = 0
		timer.wait_time = SPRINT_SPEED 
	else:
		stamina += STAMINA_REGEND
		if stamina > MAX_STAMINA:
			stamina = MAX_STAMINA
		timer.wait_time = SPEED
		
	on_stamina_changed.emit(stamina)
	
func move_obstacle():
	var next_pos = obstacle.position + Vector2.RIGHT * BODY_SEGMENT_SIZE * obstacle_direction
	
	if next_pos.x >= walls_dict["right"].position.x - BODY_SEGMENT_SIZE:
		obstacle_direction = -1
	elif next_pos.x <= walls_dict["left"].position.x + BODY_SEGMENT_SIZE:
		obstacle_direction = 1
	obstacle.position += Vector2.RIGHT* BODY_SEGMENT_SIZE *obstacle_direction
	
func check_wall_collision(head_position):
	
	if head_position.x == walls_dict["left"].position.x && move_direction == Vector2.LEFT:
		return true
	if head_position.x == walls_dict["right"].position.x && move_direction == Vector2.RIGHT:
		return true
	if head_position.y == walls_dict["top"].position.y and move_direction == Vector2.UP:
		return true
	if head_position.y  == walls_dict["bottom"].position.y and move_direction == Vector2.DOWN:
		return true
		
	return false
func move_to_position(new_position):

	if body_fragments.size() > 1:
		var last_element = body_fragments.pop_back()
		last_element.position = body_fragments[0].position
		body_fragments.insert(1, last_element)
		
	body_fragments[0].position = new_position
	position = new_position
	
func add_body_segment():
	var new_segment = Sprite2D.new()
	new_segment.texture = body_texture
	new_segment.scale = Vector2(0.9, 0.9)
	snake_parts.add_child(new_segment)
	new_segment.position = body_fragments[-1].position - move_direction * BODY_SEGMENT_SIZE
	body_fragments.append(new_segment)

func check_snake_collision():
	var body_fragments_without_head = body_fragments.slice(1, body_fragments.size())
	if(body_fragments_without_head.filter(func (fragment): return fragment.position == position )):
		return true
	return false
	
func check_obstacle_collision():
	for fragment in body_fragments:
		if fragment.position == obstacle.position:
			return true 
	return false
	
func end_game():
	game_over = true
	timer.stop()
	on_game_over.emit()
