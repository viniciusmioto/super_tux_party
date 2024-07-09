extends Node

func get_nodes_in_group(root: Node, group: StringName) -> Array[Node]:
	var result: Array[Node] = []
	var stack: Array = [root]
	while stack:
		var current: Node = stack.pop_back()
		if current.is_in_group(group):
			result.append(current)
		# Preserve order
		# The first element that is processed is the last one on the stack
		var children = current.get_children()
		children.reverse()
		stack += children
	return result

func _nextpass_apply_mesh(material: Material, mesh: Mesh) -> void:
	for i in range(mesh.get_surface_count()):
		var mat: Material = mesh.surface_get_material(i)
		if not mat:
			continue
		while not mat.next_pass in [null, material]:
			mat = mat.next_pass
		mat.next_pass = material

func apply_nextpass_material(material: Material, node: Node) -> void:
	if node is MeshInstance3D:
		_nextpass_apply_mesh(material, node.mesh)
		for i in range(node.get_surface_override_material_count()):
			var mat: Material = node.get_surface_override_material(i)
			if not mat:
				continue
			while not mat.next_pass in [null, material]:
				mat = mat.next_pass
			mat.next_pass = material

	for child in node.get_children():
		apply_nextpass_material(material, child)

func _nextpass_remove_mesh(material: Material, mesh: Mesh) -> void:
	for i in range(mesh.get_surface_count()):
		var mat: Material = mesh.surface_get_material(i)
		if not mat:
			continue
		while not mat.next_pass in [null, material]:
			mat = mat.next_pass
		if mat.next_pass == material:
			mat.next_pass = material.next_pass

func remove_nextpass_material(material: Material, node: Node) -> void:
	if node is MeshInstance3D:
		_nextpass_remove_mesh(material, node.mesh)
		for i in range(node.get_surface_override_material_count()):
			var mat: Material = node.get_surface_override_material(i)
			if not mat:
				continue
			while not mat.next_pass in [null, material]:
				mat = mat.next_pass
			if mat.next_pass == material:
				mat.next_pass = material.next_pass

	for child in node.get_children():
		remove_nextpass_material(material, child)

func _shape_to_aabb(s: Shape3D) -> AABB:
	if s is BoxShape3D:
		return AABB(-0.5 * s.size, s.size)
	elif s is SphereShape3D:
		var v := Vector3(s.radius, s.radius, s.radius)
		return AABB(-0.5 * v, v)
	elif s is CylinderShape3D:
		var v := Vector3(s.radius, s.height, s.radius)
		return AABB(-0.5 * v, v)
	elif s is CapsuleShape3D:
		var v := Vector3(s.radius, s.height + 2 * s.radius, s.radius)
		return AABB(-0.5 * v, v)
	elif s is ConvexPolygonShape3D:
		var begin := Vector3()
		var end := Vector3()

		for point in s.points:
			begin.x = min(point.x, begin.x)
			begin.y = min(point.y, begin.y)
			begin.z = min(point.z, begin.z)

			end.x = max(point.x, end.x)
			end.y = max(point.y, end.y)
			end.z = max(point.z, end.z)

		return AABB(begin, end - begin)
	elif s is ConcavePolygonShape3D:
		var begin := Vector3()
		var end := Vector3()

		for point in s.get_faces():
			begin.x = min(point.x, begin.x)
			begin.y = min(point.y, begin.y)
			begin.z = min(point.z, begin.z)

			end.x = max(point.x, end.x)
			end.y = max(point.y, end.y)
			end.z = max(point.z, end.z)

		return AABB(begin, end - begin)

	push_error("Unexpected Shape3D type in get_aabb_from_shape: %s" %\
			s.get_class())
	return AABB()

func get_aabb_from_shape(s: Shape3D, transform := Transform3D()) -> AABB:
	return transform * (_shape_to_aabb(s))

func propagate_process_call(n: Node, fun: StringName, args: Array, enabled := true):
	match n.process_mode:
		PROCESS_MODE_ALWAYS:
			enabled = true
		PROCESS_MODE_DISABLED:
			enabled = false
		PROCESS_MODE_PAUSABLE:
			enabled = not get_tree().paused
		PROCESS_MODE_WHEN_PAUSED:
			enabled = get_tree().paused
		PROCESS_MODE_INHERIT:
			# Keep the parent enabled property
			pass
	if enabled and n.has_method(fun):
		n.callv(fun, args)
	for child in n.get_children():
		propagate_process_call(child, fun, args, enabled)
