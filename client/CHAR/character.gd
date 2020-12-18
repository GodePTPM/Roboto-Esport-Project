extends Node

var playback
var animation_Tree
var kinematicBody
var cameraSpatial
var mouseSensibility = 0.25
var charSpeed = 3.0
var currentSpeed = 0.0
var accelerateInterpolation = 0.0
var decelerateInterpolation = 0.0
var currentAnimation = "IDLE"

func _ready():
	animation_Tree = get_node("AnimationTree")
	kinematicBody = get_node("KinematicBody")
	cameraSpatial = get_node("CameraSpatial")
	playback = animation_Tree.get("parameters/playback")
	playback.start("IDLE")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	accelerateInterpolation = clamp(accelerateInterpolation+delta, 0, 1)
	decelerateInterpolation = clamp(decelerateInterpolation+delta, 0, 1)
	var moveVector = Vector3(0,-5,0)
	var jogging = false
	if Input.is_action_pressed("walk_left"):
		jogging = true;
	if Input.is_action_pressed("walk_right"):
		jogging = true;
	if Input.is_action_pressed("walk_forward"):
		jogging = true;
	if Input.is_action_pressed("walk_backward"):
		jogging = true;
	
	if !jogging:
		playback.travel("IDLE")
		currentAnimation = "IDLE"
		accelerateInterpolation = 0
		currentSpeed = lerp(currentSpeed, 0, decelerateInterpolation)
	else:
		decelerateInterpolation = 0
		if Input.is_action_pressed("sprint"):
			playback.travel("RUN")
			currentAnimation = "RUN"
			currentSpeed = lerp(currentSpeed, charSpeed*2, accelerateInterpolation)
		else:
			playback.travel("JOG")
			currentAnimation = "JOG"
			currentSpeed = lerp(currentSpeed, charSpeed, accelerateInterpolation)
		
		var newRotation = lerp_angle(kinematicBody.get_rotation().y, cameraSpatial.get_rotation().y, accelerateInterpolation)
		
		kinematicBody.set_rotation(Vector3(0, newRotation, 0))
		
	
	moveVector += -kinematicBody.get_global_transform().basis.z*(currentSpeed)
	
	kinematicBody.move_and_slide(moveVector, Vector3.UP)
	
	cameraSpatial.translation = kinematicBody.translation

func _input(event):
	if event is InputEventMouseMotion:
		cameraSpatial.rotation_degrees.x += -event.relative.y*mouseSensibility
		cameraSpatial.rotation_degrees.x = clamp(cameraSpatial.rotation_degrees.x, -80, 60)
		cameraSpatial.rotation_degrees.y += -event.relative.x*mouseSensibility
