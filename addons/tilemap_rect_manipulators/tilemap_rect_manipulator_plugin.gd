tool
extends EditorPlugin

const TileManipulatorsType := 'TileMapRectManipulator'

func _enter_tree():
	add_custom_type(TileManipulatorsType, 'Sprite', preload('res://addons/tilemap_rect_manipulators/tilemap_rect_manipulator.gd'), preload('res://addons/tilemap_rect_manipulators/rectangle.svg'))


func _exit_tree():
	remove_custom_type(TileManipulatorsType)
