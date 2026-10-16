class_name PixelCameraMath
extends RefCounted

## Orthographic pixel-grid helpers for low-res SubViewport rendering.


static func units_per_pixel(ortho_vertical_size: float, render_height: int) -> float:
	return (ortho_vertical_size * 2.0) / float(render_height)


## Projects @param world_position onto the camera right/up axes and snaps in steps of @param pixel_world_size.
static func snap_on_camera_plane(
	camera_basis: Basis,
	world_position: Vector3,
	pixel_world_size: float,
) -> Dictionary:
	var inv_basis := camera_basis.inverse()
	var local_pos: Vector3 = inv_basis * world_position

	var snapped_local := Vector3(
		floor(local_pos.x / pixel_world_size) * pixel_world_size,
		floor(local_pos.y / pixel_world_size) * pixel_world_size,
		local_pos.z,
	)

	var sub_pixel := Vector2(
		(local_pos.x - snapped_local.x) / pixel_world_size,
		(local_pos.y - snapped_local.y) / pixel_world_size,
	)

	var snapped_world: Vector3 = camera_basis * snapped_local
	return {
		"snapped_world": snapped_world,
		"sub_pixel": sub_pixel,
	}


static func snap_camera_origin(
	camera_basis: Basis,
	camera_origin: Vector3,
	ortho_vertical_size: float,
	render_height: int,
) -> Dictionary:
	var pixel_world_size := units_per_pixel(ortho_vertical_size, render_height)
	var result := snap_on_camera_plane(camera_basis, camera_origin, pixel_world_size)
	result["snapped_origin"] = result["snapped_world"]
	return result


## World-space delta from a sub-pixel remainder on the camera view plane.
static func remainder_world_delta(camera_basis: Basis, sub_pixel: Vector2, pixel_world_size: float) -> Vector3:
	return camera_basis.x * (sub_pixel.x * pixel_world_size) + camera_basis.y * (sub_pixel.y * pixel_world_size)


## Maps a view-plane remainder to low-res viewport pixels (before integer upscale).
static func remainder_to_viewport_offset(
	camera_basis: Basis,
	sub_pixel: Vector2,
	pixel_world_size: float,
) -> Vector2:
	if pixel_world_size <= 0.0:
		return Vector2.ZERO
	var world_delta := remainder_world_delta(camera_basis, sub_pixel, pixel_world_size)
	var right := camera_basis.x
	var up := camera_basis.y
	var forward := -camera_basis.z
	var screen_right := Vector2(right.x, -right.z).normalized()
	var screen_up := Vector2(
		up.x * forward.z - up.z * forward.x,
		up.y,
	).normalized()
	var offset := screen_right * world_delta.dot(right) + screen_up * world_delta.dot(up)
	return offset / pixel_world_size


static func remainder_to_viewport_offset_unproject(
	camera: Camera3D,
	sub_pixel: Vector2,
	pixel_world_size: float,
) -> Vector2:
	if camera == null or pixel_world_size <= 0.0:
		return Vector2.ZERO
	var basis := camera.global_transform.basis
	var world_delta := remainder_world_delta(basis, sub_pixel, pixel_world_size)
	var origin := camera.global_position
	var p0 := camera.unproject_position(origin)
	var p1 := camera.unproject_position(origin + world_delta)
	return p1 - p0


static func integer_upscale_factor(window_size: Vector2i, render_size: Vector2i) -> int:
	if render_size.x <= 0 or render_size.y <= 0:
		return 1
	var scale_x := window_size.x / render_size.x
	var scale_y := window_size.y / render_size.y
	return maxi(1, mini(scale_x, scale_y))
