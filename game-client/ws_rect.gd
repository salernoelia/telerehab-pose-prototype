extends Node2D

# The URL we will connect to.
@export var websocket_url: String = "ws://127.0.0.1:8000/ws"  # Replace with your FastAPI server URL

# Our WebSocketPeer instance.
var socket: WebSocketPeer = WebSocketPeer.new()

# Rectangle properties
var rect_position: Vector2 = Vector2(200, 200)
const RECT_SIZE: Vector2 = Vector2(50, 50)
const RECT_COLOR: Color = Color(1, 0, 0)  # Red

# Timer for sending periodic pings
var ping_timer: Timer

func _ready():
	# Initiate connection to the given URL.
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect to WebSocket server: ", err)
		set_process(false)
	else:
		print("WebSocket connection initiated to ", websocket_url)
	
	# Setup a Timer to send "ping" every 5 seconds
	ping_timer = Timer.new()
	ping_timer.wait_time = 5.0  # Ping interval in seconds
	ping_timer.autostart = false
	ping_timer.one_shot = false
	ping_timer.connect("timeout", Callable(self, "_on_ping_timer_timeout"))
	add_child(ping_timer)
	
	# Enable processing to handle polling
	set_process(true)

func _process(delta):
	if socket == null:
		return
	
	# Poll the WebSocket to process incoming and outgoing data
	socket.poll()
	
	# Get the current state of the WebSocket connection
	var state = socket.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_CONNECTING:
			print("Connecting to server...")
		
		WebSocketPeer.STATE_OPEN:
			# Start the ping timer if it's not already active
			if ping_timer.is_stopped():
				ping_timer.start()
			
			# Process incoming messages
			while socket.get_available_packet_count() > 0:
				var packet = socket.get_packet()
				if socket.was_string_packet():
					handle_text_packet(packet.get_string_from_utf8())
				else:
					print("Received binary packet of size: ", packet.size())
		
		WebSocketPeer.STATE_CLOSING:
			print("Connection is closing...")
		
		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
			set_process(false)

	# Request to redraw the rectangle if its position has changed
	queue_redraw()

func handle_text_packet(message: String):
	print("Received message: ", message)
	
	var json = JSON.new()
	var error = json.parse(message)
	
	if error == OK:
		var data = json.get_data()
		if data.has("landmarks") and typeof(data["landmarks"]) == TYPE_ARRAY and data["landmarks"].size() > 0:
			var landmarks = data["landmarks"]
			
			# Use the first landmark to update the rectangle position
			var first_landmark = landmarks[0]
			if first_landmark.has("visibility") and first_landmark["visibility"] > 0.5:
				rect_position.x = first_landmark["x"] * get_viewport_rect().size.x
				rect_position.y = first_landmark["y"] * get_viewport_rect().size.y
			else:
				print("Landmark visibility too low, skipping update.")
	else:
		print("JSON Parse Error: ", error)
		print("Error line: ", json.get_error_line())
		print("Error message: ", json.get_error_message())


func _draw():
	draw_rect(Rect2(rect_position, RECT_SIZE), RECT_COLOR)

func send_message(message: String):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var err = socket.send_text(message)
		if err != OK:
			print("Error sending message: ", err)
		else:
			print("Sent message: ", message)
	else:
		print("WebSocket is not open. Cannot send message.")

func _on_ping_timer_timeout():
	send_message("ping")

func _exit_tree():
	if socket.get_ready_state() in [WebSocketPeer.STATE_OPEN, WebSocketPeer.STATE_CONNECTING]:
		socket.close(1000, "Client disconnecting")
