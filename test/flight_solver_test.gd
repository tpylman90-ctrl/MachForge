extends GdUnitTestSuite

const FlightSolver = preload("res://scripts/flight_solver.gd")


func test_flight_replays_deterministically_and_returns_to_the_range() -> void:
	var first_run := FlightSolver.simulate(Vector3(0.0, 2.0, -5.0), 150.0, 18.0, 3.0, 0.18, 0.2, 0, 0.3)
	var second_run := FlightSolver.simulate(Vector3(0.0, 2.0, -5.0), 150.0, 18.0, 3.0, 0.18, 0.2, 0, 0.3)
	assert_that(first_run.size() > 20).is_true()
	assert_that(first_run.size() == second_run.size()).is_true()
	var first_point: Dictionary = first_run[0]
	var last_point: Dictionary = first_run[-1]
	var final_position: Vector3 = last_point["position"]
	assert_that(is_equal_approx(float(first_point["speed"]), 150.0)).is_true()
	assert_that(final_position.y <= 0.0).is_true()


func test_blunter_shape_has_shorter_simulated_range() -> void:
	var pointed := FlightSolver.simulate(Vector3(0.0, 2.0, -5.0), 150.0, 18.0, 3.0, 0.18, 0.0, 0, 0.3)
	var blunt := FlightSolver.simulate(Vector3(0.0, 2.0, -5.0), 150.0, 18.0, 3.0, 0.18, 1.0, 0, 0.3)
	var pointed_position: Vector3 = pointed[-1]["position"]
	var blunt_position: Vector3 = blunt[-1]["position"]
	var pointed_range := -pointed_position.z
	var blunt_range := -blunt_position.z
	assert_that(pointed_range > blunt_range).is_true()
