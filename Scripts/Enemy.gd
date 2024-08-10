extends CharacterBody3D

@export_group("Physics")
@export var speed = 5.0
@export var jump = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var level: Node3D
var points: Array[Node3D]
var index: int

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
	# Obtenemos el nivel o mundo
	level = get_tree().get_nodes_in_group("Level")[0] as Node3D

	# Obtenemos los puntos objetivos (targets)
	points = level.target_points

	# Generamos un número aleatorio entero entre 0 y el total de targets
	index = randi() % points.size()

	# Navegación: Establecemos la señal como computable
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))


func _process(_delta):
	# Generamos un número aleatorio en caso de haber finalizado la navegación anterior
	if we_have_arrived():
		index = randi() % points.size()
	
	set_target_agent(points[index].global_position)
	move_and_slide_agent()

	# Establecemos las animaciones
	# Animación correr
	animation_tree.set("parameters/conditions/run", true)
	# Animación de correr hacia adelante
	animation_tree.set("parameters/Run/blend_position", Vector2(0, 1))


# Métodos Auxiliares
func _on_velocity_computed(safe_velocity: Vector3):
	velocity = Vector3(safe_velocity.x, 0, safe_velocity.z)
	move_and_slide()

func we_have_arrived():
	return navigation_agent.is_navigation_finished() && navigation_agent.is_target_reached()

func set_target_agent(target: Vector3):
	navigation_agent.target_position = target

func move_and_slide_agent():
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = global_position.direction_to(next_path_position) * speed

	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

	look_at(Vector3(next_path_position.x + 0.001, 0, next_path_position.z + 0.001))