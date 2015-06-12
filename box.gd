extends RigidBody2D

const EVENT_START_DRAG = 0
const EVENT_END_DRAG = 1
const EVENT_DRAGGING = 2

const ALPHA = 0.1
const EPSILON = 0.0005
const SCALE_FACTOR = 25
const STATE_EXPIRATION_TIME = 1.0 / 20.0
const SNAP_DISTANCE = 50

var dragging = false
var host = true;

var state = null
var state_timer = 0

func _ready():
	set_process_input(true)
	set_can_sleep(false)
	
func _integrate_forces(s):
	if (not host and state != null and state_timer < STATE_EXPIRATION_TIME):
		var current_transform = s.get_transform()
		var current_pos = current_transform.get_origin()
		var transform = Matrix32(state[1], state[0])
		
		if (current_pos.distance_to(state[0]) > SNAP_DISTANCE):	
			s.set_transform(transform)
		else:
			s.set_transform(current_transform.interpolate_with(transform, ALPHA))
		
		s.set_linear_velocity(state[2])
		s.set_angular_velocity(state[3])
		
		state_timer += s.get_step()

func _input_event(viewport, event, shape_idx):
	if (event.type == InputEvent.MOUSE_BUTTON and event.pressed):
		dragging = true
		start_drag()
		broadcast(["event", "start_drag", get_name()])

func _input(event):
	if (event.type == InputEvent.MOUSE_MOTION and dragging):
		var rect = get_tree().get_root().get_rect()
		var pos = event.pos
		
		if (pos.x <= 0 or pos.y <= 0 or pos.x >= (rect.size.x - 1) or pos.y >= (rect.size.y - 1)):
			dragging = false
			stop_drag()
			broadcast(["event", "stop_drag", get_name()])
		else:
			drag(pos)
			broadcast(["event", "drag", get_name(), pos])
			
	elif (event.type == InputEvent.MOUSE_BUTTON and not event.pressed and dragging):
		dragging = false
		stop_drag()
		broadcast(["event", "stop_drag", get_name()])

func start_drag():
	set_gravity_scale(0)
	set_linear_velocity(Vector2(0,0))

func stop_drag():
	set_gravity_scale(1)
	set_applied_force(Vector2(0,0))

func drag(pos):
	set_applied_force((pos - get_pos()) * SCALE_FACTOR)

func broadcast(packet):
	var demo = get_node("/root/demo")
	
	if (host):
		demo.server.broadcast(packet)
	else:
		demo.client.send(packet)

func set_state(state):
	self.state = state
	self.state_timer = 0
	
