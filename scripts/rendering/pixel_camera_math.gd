class_name PixelCameraMath
extends RefCounted

## Orthographic pixel-grid helpers for low-res SubViewport rendering.


static func units_per_pixel(ortho_vertical_size: float, render_height: int) -> float:
	return (ortho_vertical_size * 2.0) / float(render_height)


static func snap_camera_origin(
	camera_basis: Basis,
	camera_origin: Vector3,
	ortho_vertical_size: float,
	render_height: int,
) -> Dictionary:
	var pixel_world_size := units_per_pixel(ortho_vertical_size, render_height)
	var inv_basis := camera_basis.inverse()
	var local_pos: Vector3 = inv_basis * camera_origin

	var snapped_local := Vector3(
		floor(local_pos.x / pixel_world_size) * pixel_world_size,
		floor(local_pos.y / pixel_world_size) * pixel_world_size,
		local_pos.z,
	)

	var sub_pixel := Vector2(
		(local_pos.x - snapped_local.x) / pixel_world_size,
		(local_pos.y - snapped_local.y) / pixel_world_size,
	)

	var snapped_origin: Vector3 = camera_basis * snapped_local
	return {
		"snapped_origin": snapped_origin,
		"sub_pixel": sub_pixel,
	}


static func integer_upscale_factor(window_size: Vector2i, render_size: Vector2i) -> int:
	if render_size.x <= 0 or render_size.y <= 0:
		return 1
	var scale_x := window_size.x / render_size.x
	var scale_y := window_size.y / render_size.y
	return maxi(1, mini(scale_x, scale_y))
