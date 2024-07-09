extends RigidBody3D

@export var curve: NodePath

const SPEED := 10.0

var time := 0.0

func update_rotation(up: Vector3, state):
	var forward := self.position + up.cross(Vector3.RIGHT)
	state.transform = state.transform.looking_at(forward, up)

func _ready():
	var path: Path3D = get_node(self.curve)
	var curve := path.curve
	var curve_global_position = Vector3(0, self.position.y, self.position.z)
	var curve_local_position = path.transform.affine_inverse() * curve_global_position
	time = curve.get_closest_offset(curve_local_position) - 3.0

	var target := path.transform * curve.sample_baked(time)
	var up_vector = path.transform * -curve.sample_baked_up_vector(time, true) - path.position

	self.position.y = target.y
	self.position.z = target.z
	update_rotation(up_vector, self)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	time -= SPEED * get_parent().direction * state.step
	var path: Path3D = get_node(self.curve)
	var curve := path.curve
	var offset = fposmod(time, curve.get_baked_length())

	var target := path.transform * curve.sample_baked(offset)
	var up_vector = path.transform * -curve.sample_baked_up_vector(offset, true) - path.position
	var translated_target = Vector3(self.position.x, target.y, target.z)
	state.linear_velocity = (translated_target - self.position) / state.step
	update_rotation(up_vector, state)
