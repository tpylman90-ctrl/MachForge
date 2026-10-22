extends Control

const SKY_TOP := Color(0.035, 0.075, 0.11)
const SKY_HORIZON := Color(0.12, 0.22, 0.28)
const RANGE_GROUND := Color(0.09, 0.14, 0.16)
const STEEL := Color(0.49, 0.61, 0.65)
const STEEL_DARK := Color(0.20, 0.29, 0.33)
const ACCENT := Color(0.18, 0.86, 0.76)
const LABEL := Color(0.72, 0.84, 0.84)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 100.0 or h < 100.0:
		return

	var horizon := h * 0.61
	for band in range(18):
		var t := float(band) / 17.0
		var band_top := horizon * t
		var band_bottom := horizon * float(band + 1) / 18.0
		draw_rect(Rect2(0.0, band_top, w, band_bottom - band_top + 1.0), SKY_TOP.lerp(SKY_HORIZON, t))

	# Distant terrain gives the range a clear horizon without cluttering the firing lane.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, horizon + 10.0),
		Vector2(w * 0.13, horizon - 25.0),
		Vector2(w * 0.23, horizon + 4.0),
		Vector2(w * 0.37, horizon - 37.0),
		Vector2(w * 0.51, horizon + 2.0),
		Vector2(w * 0.67, horizon - 24.0),
		Vector2(w * 0.82, horizon + 5.0),
		Vector2(w, horizon - 28.0),
		Vector2(w, h),
		Vector2(0.0, h)
	]), Color(0.10, 0.17, 0.19))
	draw_rect(Rect2(0.0, horizon + 20.0, w, h - horizon - 20.0), RANGE_GROUND)
	draw_line(Vector2(0.0, horizon + 20.0), Vector2(w, horizon + 20.0), Color(0.28, 0.40, 0.42), 2.0, true)

	# Sparse range stripes keep depth readable while leaving space around the cannon.
	var base_y := h * 0.735
	for stripe in range(8):
		var stripe_y := base_y + 48.0 + float(stripe) * 31.0
		draw_line(Vector2(w * 0.20, stripe_y), Vector2(w * 0.80, stripe_y), Color(0.15, 0.22, 0.23, 0.50), 1.0, true)

	var cannon_x := w * 0.235
	var deck_y := base_y + 18.0
	_draw_cannon(cannon_x, base_y, deck_y)

	var muzzle_x := cannon_x + minf(w * 0.105, 150.0)
	var scale_start := muzzle_x
	var scale_end := w * 0.84
	draw_line(Vector2(scale_start, deck_y), Vector2(scale_end, deck_y), Color(0.48, 0.66, 0.66), 2.0, true)
	for marker_index in range(17):
		var distance := float(marker_index) * 250.0
		var x := lerpf(scale_start, scale_end, distance / 4000.0)
		var major := marker_index % 2 == 0
		var tick := 19.0 if major else 10.0
		draw_line(Vector2(x, deck_y - tick), Vector2(x, deck_y + tick), Color(0.62, 0.78, 0.77), 1.5 if major else 1.0, true)
		if major:
			draw_string(ThemeDB.fallback_font, Vector2(x - 17.0, deck_y + 42.0), "%d m" % int(distance), HORIZONTAL_ALIGNMENT_CENTER, 62.0, 15, LABEL)

	# A low berm at the far end makes the 4 km limit easy to spot.
	var berm_x := scale_end
	draw_colored_polygon(PackedVector2Array([
		Vector2(berm_x - 22.0, deck_y),
		Vector2(berm_x + 4.0, deck_y - 48.0),
		Vector2(berm_x + 30.0, deck_y)
	]), Color(0.27, 0.36, 0.37))
	draw_line(Vector2(berm_x - 18.0, deck_y), Vector2(berm_x + 27.0, deck_y), Color(0.58, 0.73, 0.71), 2.0, true)

	_draw_heading(w, h)


func _draw_cannon(x: float, barrel_y: float, deck_y: float) -> void:
	# Test deck and recoil rails.
	draw_rect(Rect2(x - 62.0, deck_y - 8.0, 190.0, 18.0), Color(0.21, 0.29, 0.32))
	draw_line(Vector2(x - 47.0, deck_y + 13.0), Vector2(x + 120.0, deck_y + 13.0), Color(0.44, 0.55, 0.57), 3.0, true)
	draw_line(Vector2(x - 38.0, deck_y + 20.0), Vector2(x + 112.0, deck_y + 20.0), Color(0.15, 0.22, 0.25), 3.0, true)

	# Breech cradle and pivot.
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 24.0, deck_y - 8.0),
		Vector2(x - 6.0, barrel_y - 12.0),
		Vector2(x + 38.0, barrel_y - 18.0),
		Vector2(x + 51.0, deck_y - 8.0)
	]), Color(0.28, 0.38, 0.41))
	draw_circle(Vector2(x + 18.0, deck_y - 11.0), 17.0, STEEL_DARK)
	draw_circle(Vector2(x + 18.0, deck_y - 11.0), 8.0, Color(0.61, 0.72, 0.73))

	# Barrel body and liner, angled up-range.
	var breech := Vector2(x - 10.0, barrel_y - 30.0)
	var muzzle := Vector2(x + 122.0, barrel_y - 57.0)
	draw_line(breech, muzzle, STEEL_DARK, 28.0, true)
	draw_line(breech, muzzle, STEEL, 20.0, true)
	draw_line(breech + Vector2(0.0, -4.0), muzzle + Vector2(0.0, -4.0), Color(0.76, 0.84, 0.84), 3.0, true)
	draw_line(breech + Vector2(18.0, 0.0), breech + Vector2(18.0, -1.0), Color(0.72, 0.81, 0.82), 34.0, true)
	draw_line(muzzle + Vector2(-5.0, 1.0), muzzle + Vector2(-5.0, -1.0), Color(0.22, 0.32, 0.35), 30.0, true)
	draw_line(muzzle + Vector2(-5.0, 1.0), muzzle + Vector2(-5.0, -1.0), Color(0.76, 0.84, 0.84), 4.0, true)

	# Reinforced barrel bands and clean silhouette accents.
	for band_x in [x + 3.0, x + 72.0]:
		var t := (band_x - breech.x) / (muzzle.x - breech.x)
		var band_center := breech.lerp(muzzle, t)
		var band_offset := Vector2(-0.55, 1.0)
		draw_line(band_center + band_offset * 11.0, band_center - band_offset * 11.0, Color(0.27, 0.39, 0.42), 4.0, true)

	draw_string(ThemeDB.fallback_font, Vector2(x - 53.0, deck_y + 44.0), "GAS GUN", HORIZONTAL_ALIGNMENT_LEFT, 110.0, 14, Color(0.66, 0.78, 0.79))


func _draw_heading(w: float, h: float) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 54.0), "MACHFORGE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 25, Color(0.91, 0.96, 0.98))
	draw_string(ThemeDB.fallback_font, Vector2(46.0, 80.0), "TEST RANGE  /  0—4000 m", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, ACCENT)
	draw_line(Vector2(44.0, 96.0), Vector2(44.0 + minf(w * 0.24, 300.0), 96.0), Color(0.22, 0.43, 0.45), 1.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(w - 44.0, 54.0), "RANGE / CANNON BLOCKOUT", HORIZONTAL_ALIGNMENT_RIGHT, 320.0, 12, LABEL)
