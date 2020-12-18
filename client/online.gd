extends Node

func get_random_number():
	randomize()
	return randi()%10000

const rollingBall = preload("res://RollingBall.tscn")
const pedChar = preload("res://CHAR/MODELS/SWAT/online-swat.tscn")
var socketUDP = PacketPeerUDP.new()
var player
var serialGeneration = get_random_number()
var interpolation = 0


func _ready():
	socketUDP.connect_to_host("176.152.202.128", 3000)
	var sendData = ["connect"]
	socketUDP.put_packet(JSON.print(sendData).to_ascii())
	player = get_node("swatSpatial")
	print("Your serial: " + str(serialGeneration))

var clients = []
var clientsPositions = []

func _process(_delta):
	interpolation = clamp(interpolation+_delta, 0, 1)
	var playerPosition = player.get_node("KinematicBody").translation
	var sendData = ["playersPosition", serialGeneration, playerPosition.x, playerPosition.y, playerPosition.z, player.get_node("KinematicBody").get_rotation().y, get_node("swatSpatial").get("currentAnimation")]
	socketUDP.put_packet(JSON.print(sendData).to_ascii())
	if socketUDP.get_available_packet_count() > 0:
		var array_bytes = JSON.parse(socketUDP.get_packet().get_string_from_ascii()).result
		if array_bytes[0] == "SetPosition":
			if clients.find("player_" + str(array_bytes[1]), 0) == -1:
				print("created new player")
				var newPed = pedChar.instance()
				newPed.set_name("player_" + str(array_bytes[1]))
				self.add_child(newPed)
				clients.append("player_" + str(array_bytes[1]))
			var thePed = get_node("player_" + str(array_bytes[1]))
			
			clientsPositions.append([thePed, array_bytes[2],array_bytes[3],array_bytes[4],array_bytes[5]])
			
			if thePed:
				if thePed.get_node("AnimationTree").get("parameters/playback").get_current_node() == "":
					thePed.get_node("AnimationTree").get("parameters/playback").start(array_bytes[6])
				else:
					thePed.get_node("AnimationTree").get("parameters/playback").travel(array_bytes[6])
		if array_bytes[0] == "Reset":
			interpolation = 0
			clientsPositions = []
	
	for x in clientsPositions:
		x[0].get_node("KinematicBody").set_rotation(Vector3(0, lerp_angle(x[0].get_node("KinematicBody").get_rotation().y,x[4],interpolation), 0))
		x[0].get_node("KinematicBody").translation = x[0].get_node("KinematicBody").translation.linear_interpolate(Vector3(x[1],x[2],x[3]), interpolation)



func _exit_tree():
	var sendData = ["disconnect"]
	socketUDP.put_packet(JSON.print(sendData).to_ascii())
	socketUDP.close()

func _input(ev):
	if ev is InputEventKey and ev.scancode == KEY_K and ev.pressed:
		var theRolling = rollingBall.instance()
		self.add_child(theRolling)
