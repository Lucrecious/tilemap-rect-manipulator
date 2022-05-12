tool
extends Sprite

signal id_changed()
signal tilemap_rect_changed()

func _init() -> void:
	texture = preload('res://addons/tilemap_rect_manipulators/tmp.png')
	self_modulate = Color.transparent
	centered = false
	set_notify_local_transform(true)
	set_notify_transform(true)

export(int) var id := -1 setget _id_set
var _previous_id := id
func _id_set(value: int) -> void:
	if id == value:
		return
	
	_previous_id = id
	id = value
	emit_signal('id_changed')

var _tilemap: TileMap

func update_tiles() -> void:
	if not _tilemap:
		return
	
	set_tiles(_tilemap, get_tilemap_rect(), id)

var _previous_tilemap_rect := Rect2()
func get_tilemap_rect() -> Rect2:
	if not _tilemap:
		return Rect2()
	
	var rect_position := _tilemap.world_to_map(position + Vector2.ONE)
	var rect_size := _tilemap.world_to_map(position + (texture.get_size() * scale) - Vector2.ONE) - rect_position
	
	return Rect2(rect_position, rect_size)

func _enter_tree() -> void:
	update_configuration_warning()
	
	if not get_parent() is TileMap:
		return
	
	_tilemap = get_parent() 
	
	connect('id_changed', self, '_on_id_changed')
	connect('tilemap_rect_changed', self, '_on_tilemap_rect_changed')

func _exit_tree() -> void:
	if not get_parent() is TileMap:
		return
		
	_tilemap = null
	
	disconnect('id_changed', self, '_on_id_changed')
	disconnect('tilemap_rect_changed', self, '_on_tilemap_rect_changed')

func _notification(what: int) -> void:
	if not _tilemap:
		return
	
	if what == NOTIFICATION_MOVED_IN_PARENT:
		_update_tile_manipulate_stack(_tilemap, get_tilemap_rect())
	
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var current_tilemap_rect := get_tilemap_rect()
		if _previous_tilemap_rect == current_tilemap_rect:
			return
		
		emit_signal('tilemap_rect_changed')
		
		_previous_tilemap_rect = current_tilemap_rect
			

func _on_id_changed() -> void:
	_update_tile_manipulate_stack(_tilemap, get_tilemap_rect())

func _on_tilemap_rect_changed() -> void:
	_update_tile_manipulate_stack(_tilemap, _previous_tilemap_rect)
	_update_tile_manipulate_stack(_tilemap, get_tilemap_rect())

func _get_configuration_warning() -> String:
	if not is_inside_tree():
		return ''
	
	if get_parent() is TileMap:
		return ''
	
	return 'Must be direct child of a tilemap'

func _get_all_intersecting_manipulator_indices_recursive(tilemap: TileMap, start_rect: Rect2) -> Array:
	var rects_to_test := [start_rect]
	var manipulators := {}
	
	while not rects_to_test.empty():
		var rect := rects_to_test.pop_back() as Rect2
		for child in tilemap.get_children():
			if not child is get_script():
				continue
			
			if child.get_index() in manipulators:
				continue
			
			if not child.get_tilemap_rect().intersects(rect, false):
				continue
			
			manipulators[child.get_index()] = true
			rects_to_test.push_back(child.get_tilemap_rect())
	
	return manipulators.keys()
	

func _update_tile_manipulate_stack(tilemap: TileMap, rect: Rect2) -> void:
	set_tiles(tilemap, rect, -1)
	
	var other_manipulators := []
	for child in tilemap.get_children():
		if not child is get_script():
			continue
		
		other_manipulators.push_back(child)
	
	var intersections := _get_all_intersecting_manipulator_indices_recursive(tilemap, rect)
	intersections.sort()
	
	for i in intersections:
		tilemap.get_child(i).update_tiles()


static func set_tiles(tilemap: TileMap, rect: Rect2, id: int) -> void:
	for i in rect.size.x + 1:
		for j in rect.size.y + 1:
			var x := int(rect.position.x + i)
			var y := int(rect.position.y + j)
			tilemap.set_cell(x, y, id)
	
	rect = rect.grow(1)
	tilemap.update_bitmask_region(rect.position, rect.position + rect.size)
