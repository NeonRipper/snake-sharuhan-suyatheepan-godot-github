extends CanvasLayer

@export var snake: Snake

var button_container: HBoxContainer
@onready var label: Label = $GameOverLabel
@onready var restart_button: Button = $%Restart
@onready var quit_button: Button = $%Quit
@onready var points_label:Label = $PointsLabel
@onready var stamina_label: Label = $StaminaLabel
@onready var start_label: Label = $StartLabel
@onready var pause_label: Label = $PauseLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	snake.on_game_over.connect(on_game_over)
	snake.on_point_scored.connect(on_point_scored)
	snake.on_stamina_changed.connect(on_stamina_changed)
	snake.on_game_started.connect(on_game_started)
	snake.on_pause_toggled.connect(on_pause_toggled)
	button_container = get_node("ButtonContainer")
	restart_button.pressed.connect(on_restart_button_pressed)
	quit_button.pressed.connect(on_quit_button_pressed)
	pause_label.visible = false
	
func on_game_started():
	start_label.visible = false

	
func on_pause_toggled(paused):
	pause_label.visible = paused

func on_game_over():
	button_container.visible = true
	label.visible = true
	print("GAME OVER UI")

func on_restart_button_pressed():
	get_tree().reload_current_scene()

func on_point_scored(points):
	points_label.text = "Points: %d" % points
	
func on_stamina_changed(stamina):
	stamina_label.text = "Stamina: %d" % stamina

func on_quit_button_pressed():
		get_tree().quit()
