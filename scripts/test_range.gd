extends Node3D

const FlightSolver = preload("res://scripts/flight_solver.gd")
const RANGE_MARKER_SPACING := 250.0
const RANGE_MARKER_COUNT := 16
const PANEL_DARK := Color(0.035, 0.055, 0.075, 0.94)
const ACCENT := Color(0.18, 0.86, 0.76)
const TEXT_MAIN := Color(0.91, 0.96, 0.98)
const TEXT_MUTED := Color(0.57, 0.68, 0.75)

var body_length := 3.0
var body_radius := 0.18
var nose_fullness := 0.35
var fin_count := 4
var fin_span := 0.45
var launch_drive := 55.0
var launch_angle := 12.0

var projectile_preview: Node3D
var flight_projectile: Node3D
var range_camera: Camera3D
var trajectory_instance: MeshInstance3D
var telemetry_label: Label
var result_label: Label
var flight_samples: Array[Dictionary] = []
var flight_elapsed := 0.0
var flight_active := false
var selected_finish := Color(0.82, 0.56, 0.23)
var finish_buttons: Array[Button] = []


func _ready() -> void:
	_build_world()
	_build_ui()
	_rebuild_preview()


func _process(delta: float) -> void:
	if not flight_active or flight_samples.is_empty():
		return
	flight_elapsed += delta
	var index := mini(int(flight_elapsed / FlightSolver.STEP_SECONDS), flight_samples.size() - 1)
	var sample: Dictionary = flight_samples[index]
	var position: Vector3 = sample["position"]
	var velocity: Vector3 = sample["velocity"]
	flight_projectile.global_position = position
	if velocity.length_squared() > 0.001:
		flight_projectile.look_at(position + velocity, Vector3.UP)
	var camera_offset := Vector3(48.0, 64.0, 53.0)
	var camera_target := position
	range_camera.global_position = range_camera.global_position.lerp(position + camera_offset, 1.0 - exp(-delta * 3.5))
	range_camera.look_at(camera_target, Vector3.UP)
	var range_value := maxf(0.0, -position.z - 5.0)
	telemetry_label.text = "FLIGHT TELEMETRY\n\nRange     %s m\nSpeed     %s m/s\nMach      %s\nAltitude  %s m\nTime      %s s" % [
		_format_number(range_value, 0),
		_format_number(float(sample["speed"]), 1),
		_format_number(float(sample["speed"]) / 343.0, 2),
		_format_number(position.y, 1),
		_format_number(float(sample["time"]), 2)
	]
	if index >= flight_samples.size() - 1:
		flight_active = false
		var final_range := maxf(0.0, -position.z - 5.0)
		result_label.text = "TEST COMPLETE  •  %s m" % _format_number(final_range, 0)
		result_label.add_theme_color_override("font_color", ACCENT)


func _build_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.17, 0.29, 0.37)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.46, 0.59, 0.68)
	environment.ambient_light_energy = 0.8
	environment_node.environment = environment
	add_child(environment_node)

	range_camera = Camera3D.new()
	range_camera.name = "RangeCamera"
	range_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	range_camera.size = 78.0
	range_camera.position = Vector3(48.0, 64.0, 38.0)
	range_camera.look_at(Vector3(0.0, 0.0, -15.0), Vector3.UP)
	range_camera.current = true
	add_child(range_camera)
	range_camera.make_current()

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-52.0, -24.0, 0.0)
	sunlight.light_energy = 1.6
	sunlight.shadow_enabled = true
	add_child(sunlight)

	_add_box("Range Ground", Vector3(360.0, 0.2, 4300.0), Vector3(0.0, -0.18, -1900.0), Color(0.10, 0.15, 0.17))
	_add_box("Launch Deck", Vector3(18.0, 0.45, 18.0), Vector3(0.0, 0.15, 1.0), Color(0.18, 0.24, 0.27))
	_add_cannon()
	_add_distance_markers()

	projectile_preview = Node3D.new()
	projectile_preview.name = "ProjectilePreview"
	projectile_preview.position = Vector3(0.0, 2.4, -5.2)
	add_child(projectile_preview)

	flight_projectile = Node3D.new()
	flight_projectile.name = "FlightProjectile"
	flight_projectile.visible = false
	add_child(flight_projectile)

	trajectory_instance = MeshInstance3D.new()
	trajectory_instance.name = "Trajectory"
	trajectory_instance.visible = false
	add_child(trajectory_instance)


func _add_cannon() -> void:
	_add_cylinder("Cannon Pedestal", 3.0, 1.0, Vector3(0.0, 0.8, 0.2), Color(0.27, 0.34, 0.38))
	_add_box("Cannon Cradle", Vector3(4.0, 0.8, 5.0), Vector3(0.0, 1.5, -1.0), Color(0.19, 0.25, 0.29))
	_add_cylinder("Cannon Barrel", 0.86, 6.4, Vector3(0.0, 2.0, -3.0), Color(0.40, 0.49, 0.53), PI * 0.5)
	_add_cylinder("Muzzle Ring", 1.02, 0.34, Vector3(0.0, 2.0, -6.15), Color(0.58, 0.66, 0.68), PI * 0.5)


func _add_distance_markers() -> void:
	for marker_index in range(1, RANGE_MARKER_COUNT + 1):
		var distance := RANGE_MARKER_SPACING * marker_index
		var z_position := -distance
		_add_box("Marker %d" % marker_index, Vector3(28.0, 0.045, 0.28), Vector3(0.0, 0.015, z_position), Color(0.56, 0.78, 0.74))
		var label := Label3D.new()
		label.text = "%d m" % int(distance)
		label.position = Vector3(16.0, 0.08, z_position - 8.0)
		label.font_size = 48
		label.pixel_size = 0.025
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(0.69, 0.82, 0.84)
		add_child(label)


func _add_box(node_name: String, size: Vector3, location: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	instance.position = location
	instance.material_override = _make_material(color, 0.82)
	add_child(instance)
	return instance


func _add_cylinder(node_name: String, radius: float, height: float, location: Vector3, color: Color, tilt: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 32
	instance.mesh = cylinder
	instance.position = location
	instance.rotation.x = tilt
	instance.material_override = _make_material(color, 0.48)
	add_child(instance)
	return instance


func _make_material(color: Color, roughness: float = 0.6) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.roughness = roughness
	return material


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(screen)

	var left_panel := _make_panel()
	left_panel.anchor_left = 0.0
	left_panel.anchor_right = 0.0
	left_panel.anchor_top = 0.0
	left_panel.anchor_bottom = 1.0
	left_panel.offset_left = 20.0
	left_panel.offset_top = 20.0
	left_panel.offset_right = 344.0
	left_panel.offset_bottom = -20.0
	screen.add_child(left_panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(scroll)
	var left_content := VBoxContainer.new()
	left_content.custom_minimum_size = Vector2(280.0, 0.0)
	left_content.add_theme_constant_override("separation", 10)
	scroll.add_child(left_content)

	_add_title(left_content, "MACHFORGE", "PROJECTILE WORKSHOP")
	_add_section(left_content, "SHAPE YOUR DESIGN")
	_add_slider(left_content, "Body length", 1.2, 5.0, 0.1, body_length, " m", 1, "body_length", true)
	_add_slider(left_content, "Body radius", 0.08, 0.32, 0.01, body_radius, " m", 2, "body_radius", true)
	_add_slider(left_content, "Nose fullness", 0.0, 1.0, 0.01, nose_fullness, "", 2, "nose_fullness", true)
	_add_fin_picker(left_content)
	_add_slider(left_content, "Fin span", 0.15, 0.8, 0.01, fin_span, " m", 2, "fin_span", true)
	_add_section(left_content, "VIRTUAL TEST SETUP")
	_add_slider(left_content, "Drive level", 0.0, 100.0, 1.0, launch_drive, "", 0, "launch_drive", false)
	_add_slider(left_content, "Launch angle", 3.0, 30.0, 0.5, launch_angle, "°", 1, "launch_angle", false)
	_add_finish_picker(left_content)
	var launch_button := Button.new()
	launch_button.text = "LAUNCH TEST"
	launch_button.custom_minimum_size = Vector2(0.0, 54.0)
	launch_button.add_theme_font_size_override("font_size", 19)
	launch_button.add_theme_color_override("font_color", Color(0.02, 0.09, 0.10))
	var launch_style := StyleBoxFlat.new()
	launch_style.bg_color = ACCENT
	launch_style.corner_radius_top_left = 8
	launch_style.corner_radius_top_right = 8
	launch_style.corner_radius_bottom_left = 8
	launch_style.corner_radius_bottom_right = 8
	launch_button.add_theme_stylebox_override("normal", launch_style)
	launch_button.pressed.connect(_launch_test)
	left_content.add_child(launch_button)
	result_label = _make_label("READY TO TEST", 14, ACCENT)
	left_content.add_child(result_label)

	var right_panel := _make_panel()
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_top = 0.0
	right_panel.anchor_bottom = 0.0
	right_panel.offset_left = -310.0
	right_panel.offset_right = -20.0
	right_panel.offset_top = 20.0
	right_panel.offset_bottom = 300.0
	screen.add_child(right_panel)
	var right_content := VBoxContainer.new()
	right_content.add_theme_constant_override("separation", 8)
	right_panel.add_child(right_content)
	telemetry_label = _make_label("FLIGHT TELEMETRY\n\nNo test launched", 16, TEXT_MAIN)
	telemetry_label.custom_minimum_size = Vector2(252.0, 210.0)
	right_content.add_child(telemetry_label)
	var note := _make_label("Shape preview updates live.\nDrive level uses game-scale units.", 12, TEXT_MUTED)
	right_content.add_child(note)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_DARK
	style.border_color = Color(0.20, 0.36, 0.40, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 15.0
	style.content_margin_bottom = 15.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _add_title(parent: VBoxContainer, title: String, subtitle: String) -> void:
	var title_label := _make_label(title, 25, TEXT_MAIN)
	title_label.add_theme_font_size_override("font_size", 25)
	parent.add_child(title_label)
	parent.add_child(_make_label(subtitle, 11, ACCENT))


func _add_section(parent: VBoxContainer, title: String) -> void:
	var label := _make_label(title, 12, Color(0.62, 0.77, 0.80))
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	parent.add_child(label)


func _make_label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_slider(parent: VBoxContainer, title: String, minimum: float, maximum: float, step: float, initial: float, suffix: String, decimals: int, property_name: String, edits_shape: bool) -> HSlider:
	var header := HBoxContainer.new()
	var title_label := _make_label(title, 13, TEXT_MAIN)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var value_label := _make_label(_format_number(initial, decimals) + suffix, 13, ACCENT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(value_label)
	parent.add_child(header)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 22.0
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = _format_number(value, decimals) + suffix
		set(property_name, value)
		if edits_shape:
			_rebuild_preview()
	)
	parent.add_child(slider)
	return slider


func _add_fin_picker(parent: VBoxContainer) -> void:
	parent.add_child(_make_label("Fin count", 13, TEXT_MAIN))
	var picker := OptionButton.new()
	picker.add_item("No fins", 0)
	picker.add_item("Two fins", 2)
	picker.add_item("Four fins", 4)
	picker.select(2)
	picker.item_selected.connect(func(index: int) -> void:
		fin_count = picker.get_item_id(index)
		_rebuild_preview()
	)
	parent.add_child(picker)


func _add_finish_picker(parent: VBoxContainer) -> void:
	parent.add_child(_make_label("Body finish", 13, TEXT_MAIN))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var colors := [Color(0.82, 0.56, 0.23), Color(0.36, 0.72, 0.84), Color(0.67, 0.75, 0.67), Color(0.79, 0.35, 0.28)]
	for color in colors:
		var button := Button.new()
		button.custom_minimum_size = Vector2(38.0, 32.0)
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("normal", style)
		button.pressed.connect(func() -> void:
			selected_finish = color
			_rebuild_preview()
		)
		row.add_child(button)
	parent.add_child(row)


func _rebuild_preview() -> void:
	if not is_instance_valid(projectile_preview):
		return
	for child in projectile_preview.get_children():
		child.queue_free()
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = _build_body_mesh(body_length, body_radius, nose_fullness)
	body.material_override = _make_material(selected_finish, 0.34)
	projectile_preview.add_child(body)
	for fin_index in range(fin_count):
		var fin := MeshInstance3D.new()
		fin.name = "Fin_%d" % fin_index
		var box := BoxMesh.new()
		box.size = Vector3(fin_span, 0.055, body_length * 0.23)
		fin.mesh = box
		fin.position = Vector3(body_radius + fin_span * 0.37, 0.0, body_length * 0.30)
		fin.rotation.z = TAU * float(fin_index) / float(maxi(fin_count, 1))
		fin.material_override = _make_material(selected_finish.darkened(0.24), 0.38)
		projectile_preview.add_child(fin)


func _build_body_mesh(length: float, radius: float, fullness: float) -> ArrayMesh:
	var rings: Array[Vector2] = []
	var tip_z := -length * 0.5
	var nose_length := length * 0.36
	var exponent := lerpf(0.58, 2.2, fullness)
	for index in range(9):
		var t := float(index) / 8.0
		var ring_radius := radius * pow(t, exponent)
		rings.append(Vector2(tip_z + nose_length * t, maxf(ring_radius, 0.006)))
	rings.append(Vector2(length * 0.08, radius))
	rings.append(Vector2(length * 0.38, radius))
	rings.append(Vector2(length * 0.48, radius * 0.82))

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 20
	for ring_index in range(rings.size() - 1):
		for segment in range(SEGMENTS):
			var next_segment := (segment + 1) % SEGMENTS
			var angle_a := TAU * float(segment) / float(SEGMENTS)
			var angle_b := TAU * float(next_segment) / float(SEGMENTS)
			var ring_a: Vector2 = rings[ring_index]
			var ring_b: Vector2 = rings[ring_index + 1]
			var a := Vector3(cos(angle_a) * ring_a.y, sin(angle_a) * ring_a.y, ring_a.x)
			var b := Vector3(cos(angle_b) * ring_a.y, sin(angle_b) * ring_a.y, ring_a.x)
			var c := Vector3(cos(angle_b) * ring_b.y, sin(angle_b) * ring_b.y, ring_b.x)
			var d := Vector3(cos(angle_a) * ring_b.y, sin(angle_a) * ring_b.y, ring_b.x)
			surface.add_vertex(a)
			surface.add_vertex(b)
			surface.add_vertex(c)
			surface.add_vertex(a)
			surface.add_vertex(c)
			surface.add_vertex(d)
	surface.generate_normals()
	var mesh := surface.commit()
	return mesh


func _launch_test() -> void:
	flight_samples = FlightSolver.simulate(
		Vector3(0.0, 2.45, -5.2),
		lerpf(90.0, 240.0, launch_drive / 100.0),
		launch_angle,
		body_length,
		body_radius,
		nose_fullness,
		fin_count,
		fin_span
	)
	if flight_samples.is_empty():
		return
	for child in flight_projectile.get_children():
		child.queue_free()
	var projectile_body := MeshInstance3D.new()
	projectile_body.mesh = _build_body_mesh(body_length, body_radius, nose_fullness)
	projectile_body.material_override = _make_material(selected_finish, 0.34)
	flight_projectile.add_child(projectile_body)
	for fin_index in range(fin_count):
		var fin := MeshInstance3D.new()
		var fin_mesh := BoxMesh.new()
		fin_mesh.size = Vector3(fin_span, 0.055, body_length * 0.23)
		fin.mesh = fin_mesh
		fin.position = Vector3(body_radius + fin_span * 0.37, 0.0, body_length * 0.30)
		fin.rotation.z = TAU * float(fin_index) / float(maxi(fin_count, 1))
		fin.material_override = _make_material(selected_finish.darkened(0.24), 0.38)
		flight_projectile.add_child(fin)

	var line_mesh := ImmediateMesh.new()
	var line_material := StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = ACCENT
	line_material.no_depth_test = true
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, line_material)
	for sample in flight_samples:
		line_mesh.surface_add_vertex(sample["position"])
	line_mesh.surface_end()
	trajectory_instance.mesh = line_mesh
	trajectory_instance.visible = true
	flight_projectile.visible = true
	flight_projectile.global_position = flight_samples[0]["position"]
	flight_elapsed = 0.0
	flight_active = true
	result_label.text = "SIMULATING FLIGHT..."
	result_label.add_theme_color_override("font_color", ACCENT)


func _format_number(value: float, decimals: int) -> String:
	return String.num(value, decimals)
