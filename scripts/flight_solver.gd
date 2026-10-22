extends RefCounted
## Deterministic first-pass flight model for the virtual test range.
## The drive control is a game-scale setting, not a real launcher specification.

const STEP_SECONDS := 1.0 / 120.0
const GRAVITY := 9.81
const MAX_STEPS := 14400


static func simulate(
	start_position: Vector3,
	launch_speed: float,
	elevation_degrees: float,
	body_length: float,
	body_radius: float,
	nose_fullness: float,
	fin_count: int,
	fin_span: float
) -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	var angle := deg_to_rad(elevation_degrees)
	var velocity := Vector3(0.0, sin(angle), -cos(angle)) * launch_speed
	var position := start_position
	var shape_drag := 0.12 + nose_fullness * 0.12 + float(fin_count) * fin_span * 0.025
	var mass_score := maxf(0.2, body_length * body_radius * body_radius * 18.0)
	var time := 0.0
	var highest_y := position.y

	for step in range(MAX_STEPS):
		var speed := velocity.length()
		points.append({
			"position": position,
			"velocity": velocity,
			"speed": speed,
			"time": time,
			"max_height": highest_y
		})
		if position.y <= 0.0 and step > 0:
			break

		var air_density_scale := exp(-maxf(position.y, 0.0) / 8500.0)
		var drag_acceleration := shape_drag * air_density_scale * speed * speed / (18.0 * mass_score)
		var acceleration := Vector3.DOWN * GRAVITY
		if speed > 0.001:
			acceleration -= velocity / speed * drag_acceleration
		velocity += acceleration * STEP_SECONDS
		position += velocity * STEP_SECONDS
		highest_y = maxf(highest_y, position.y)
		time += STEP_SECONDS
		if position.y < -50.0 or -position.z > 6000.0:
			break

	return points
