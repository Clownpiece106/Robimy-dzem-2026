@tool
extends Resource

@export var small: Texture2D:
	set(value):
		small = value
		emit_changed()
@export var medium: Texture2D:
	set(value):
		medium = value
		emit_changed()
@export var big: Texture2D:
	set(value):
		big = value
		emit_changed()
