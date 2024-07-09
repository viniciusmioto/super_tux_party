@tool
extends Marker3D

# Hack to ensure a nice editing experience, see _ready function for more details
@export var nodes: Array[Node]:
	set(x):
		nodes = x
		update()

var material := StandardMaterial3D.new()

func _ready():
	if Engine.is_editor_hint():
		set_process(true)
		update()
	else:
		$EditorLines.queue_free()

func update():
	if not is_inside_tree():
		return
	if Engine.is_editor_hint():
		if len(nodes) == 0:
			return
		var mesh: ImmediateMesh = $EditorLines.mesh
		mesh.clear_surfaces()
		mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
		for node in nodes:
			if node == null:
				continue
			
			mesh.surface_set_color(Color(0.0, 1.0, 1.0, 1.0))
			var dir = node.position - self.position
			if dir.length() == 0:
				continue
			
			var offset = Vector3()
			mesh.surface_add_vertex(offset)
			mesh.surface_add_vertex(dir + offset)
			mesh.surface_add_vertex(dir + offset)
			mesh.surface_add_vertex(dir + offset + (-0.25 * dir.normalized()).rotated(Vector3(0, 1, 0), 0.2617994))
			mesh.surface_add_vertex(dir + offset)
			mesh.surface_add_vertex(dir + offset + (-0.25 * dir.normalized()).rotated(Vector3(0, 1, 0), -0.2617994))
		mesh.surface_end()
